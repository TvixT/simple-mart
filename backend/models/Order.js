const { promisePool } = require('../config/database');
const Cart = require('./Cart');

class Order {
  constructor(data) {
    this.id = data.id;
    this.user_id = data.user_id;
    this.total_price = parseFloat(data.total_price);
    this.status = data.status;
    this.shipping_address = data.shipping_address;
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;
    
    // Include user details if available
    if (data.user_name) {
      this.user = {
        id: data.user_id,
        name: data.user_name,
        email: data.user_email
      };
    }
  }

  // Create a new order
  static async create(orderData) {
    try {
      const { user_id, total_price, shipping_address, status = 'pending' } = orderData;

      const [result] = await promisePool.execute(
        'INSERT INTO orders (user_id, total_price, status, shipping_address) VALUES (?, ?, ?, ?)',
        [user_id, total_price, status, shipping_address]
      );

      return await Order.findById(result.insertId);
    } catch (error) {
      throw error;
    }
  }

  // Create order from cart
  static async createFromCart(userId, shippingAddress) {
    const connection = await promisePool.getConnection();
    
    try {
      await connection.beginTransaction();

      // Get user's cart
      const cart = await Cart.getUserCart(userId);
      
      if (cart.items.length === 0) {
        throw new Error('Cart is empty');
      }

      // Validate stock availability
      const stockValidation = await Cart.validateCartStock(userId);
      if (!stockValidation.valid) {
        throw new Error(`Insufficient stock: ${JSON.stringify(stockValidation.invalid_items)}`);
      }

      // Create order
      const [orderResult] = await connection.execute(
        'INSERT INTO orders (user_id, total_price, status, shipping_address) VALUES (?, ?, ?, ?)',
        [userId, cart.summary.subtotal, 'pending', shippingAddress]
      );

      const orderId = orderResult.insertId;

      // Move cart items to order
      await Cart.moveToOrder(userId, orderId);

      await connection.commit();
      
      return await Order.findById(orderId);
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  // Find order by ID
  static async findById(id) {
    try {
      const [rows] = await promisePool.execute(
        `SELECT o.*, u.name as user_name, u.email as user_email
         FROM orders o
         JOIN users u ON o.user_id = u.id
         WHERE o.id = ?`,
        [id]
      );

      if (rows.length === 0) {
        return null;
      }

      return new Order(rows[0]);
    } catch (error) {
      throw error;
    }
  }

  // Get order with items
  static async getOrderWithItems(orderId) {
    try {
      const order = await Order.findById(orderId);
      if (!order) {
        return null;
      }

      // Get order items
      const [items] = await promisePool.execute(
        `SELECT oi.*, p.name as product_name, p.description as product_description,
                p.image_url as product_image_url
         FROM order_items oi
         JOIN products p ON oi.product_id = p.id
         WHERE oi.order_id = ?
         ORDER BY oi.id`,
        [orderId]
      );

      order.items = items.map(item => ({
        id: item.id,
        product_id: item.product_id,
        product_name: item.product_name,
        product_description: item.product_description,
        product_image_url: item.product_image_url,
        quantity: item.quantity,
        price: parseFloat(item.price),
        line_total: item.quantity * parseFloat(item.price)
      }));

      return order;
    } catch (error) {
      throw error;
    }
  }

  // Get user's orders
  static async getUserOrders(userId, page = 1, limit = 10) {
    try {
      const offset = (page - 1) * limit;

      const [rows] = await promisePool.execute(
        `SELECT o.*, u.name as user_name, u.email as user_email
         FROM orders o
         JOIN users u ON o.user_id = u.id
         WHERE o.user_id = ?
         ORDER BY o.created_at DESC
         LIMIT ? OFFSET ?`,
        [userId, limit, offset]
      );

      const [countResult] = await promisePool.execute(
        'SELECT COUNT(*) as total FROM orders WHERE user_id = ?',
        [userId]
      );

      const orders = rows.map(row => new Order(row));
      const total = countResult[0].total;
      const totalPages = Math.ceil(total / limit);

      return {
        orders,
        pagination: {
          currentPage: page,
          totalPages,
          totalOrders: total,
          hasNext: page < totalPages,
          hasPrev: page > 1
        }
      };
    } catch (error) {
      throw error;
    }
  }

  // Get all orders with filters
  static async findAll(options = {}) {
    try {
      const {
        page = 1,
        limit = 10,
        status,
        user_id,
        start_date,
        end_date,
        sort_by = 'created_at',
        sort_order = 'DESC'
      } = options;

      const offset = (page - 1) * limit;
      let whereClause = '1=1';
      const params = [];

      // Build WHERE clause
      if (status) {
        whereClause += ' AND o.status = ?';
        params.push(status);
      }

      if (user_id) {
        whereClause += ' AND o.user_id = ?';
        params.push(user_id);
      }

      if (start_date) {
        whereClause += ' AND o.created_at >= ?';
        params.push(start_date);
      }

      if (end_date) {
        whereClause += ' AND o.created_at <= ?';
        params.push(end_date);
      }

      // Validate sort fields
      const validSortFields = ['id', 'total_price', 'status', 'created_at'];
      const sortField = validSortFields.includes(sort_by) ? sort_by : 'created_at';
      const sortDirection = sort_order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

      const query = `
        SELECT o.*, u.name as user_name, u.email as user_email
        FROM orders o
        JOIN users u ON o.user_id = u.id
        WHERE ${whereClause}
        ORDER BY o.${sortField} ${sortDirection}
        LIMIT ? OFFSET ?
      `;

      const [rows] = await promisePool.execute(query, [...params, limit, offset]);

      // Get total count
      const countQuery = `
        SELECT COUNT(*) as total
        FROM orders o
        WHERE ${whereClause}
      `;
      const [countResult] = await promisePool.execute(countQuery, params);

      const orders = rows.map(row => new Order(row));
      const total = countResult[0].total;
      const totalPages = Math.ceil(total / limit);

      return {
        orders,
        pagination: {
          currentPage: page,
          totalPages,
          totalOrders: total,
          hasNext: page < totalPages,
          hasPrev: page > 1
        }
      };
    } catch (error) {
      throw error;
    }
  }

  // Update order status
  static async updateStatus(id, newStatus) {
    try {
      const validStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
      
      if (!validStatuses.includes(newStatus)) {
        throw new Error(`Invalid status. Must be one of: ${validStatuses.join(', ')}`);
      }

      await promisePool.execute(
        'UPDATE orders SET status = ?, updated_at = NOW() WHERE id = ?',
        [newStatus, id]
      );

      return await Order.findById(id);
    } catch (error) {
      throw error;
    }
  }

  // Update shipping address
  static async updateShippingAddress(id, newAddress) {
    try {
      await promisePool.execute(
        'UPDATE orders SET shipping_address = ?, updated_at = NOW() WHERE id = ?',
        [newAddress, id]
      );

      return await Order.findById(id);
    } catch (error) {
      throw error;
    }
  }

  // Cancel order
  static async cancel(id) {
    const connection = await promisePool.getConnection();
    
    try {
      await connection.beginTransaction();

      // Get order details
      const order = await Order.getOrderWithItems(id);
      if (!order) {
        throw new Error('Order not found');
      }

      if (order.status === 'delivered') {
        throw new Error('Cannot cancel delivered order');
      }

      if (order.status === 'cancelled') {
        throw new Error('Order is already cancelled');
      }

      // Restore product stock
      for (const item of order.items) {
        await connection.execute(
          'UPDATE products SET stock = stock + ? WHERE id = ?',
          [item.quantity, item.product_id]
        );
      }

      // Update order status
      await connection.execute(
        'UPDATE orders SET status = ?, updated_at = NOW() WHERE id = ?',
        ['cancelled', id]
      );

      await connection.commit();
      
      return await Order.findById(id);
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  // Delete order (admin only)
  static async delete(id) {
    try {
      // First delete order items
      await promisePool.execute('DELETE FROM order_items WHERE order_id = ?', [id]);
      
      // Then delete the order
      const [result] = await promisePool.execute('DELETE FROM orders WHERE id = ?', [id]);
      
      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Get order statistics
  static async getStats() {
    try {
      const [results] = await promisePool.execute(`
        SELECT 
          COUNT(*) as total_orders,
          COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_orders,
          COUNT(CASE WHEN status = 'processing' THEN 1 END) as processing_orders,
          COUNT(CASE WHEN status = 'shipped' THEN 1 END) as shipped_orders,
          COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered_orders,
          COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_orders,
          AVG(total_price) as average_order_value,
          SUM(total_price) as total_revenue
        FROM orders
      `);

      return results[0];
    } catch (error) {
      throw error;
    }
  }

  // Get daily sales
  static async getDailySales(days = 30) {
    try {
      const [rows] = await promisePool.execute(
        `SELECT 
           DATE(created_at) as date,
           COUNT(*) as order_count,
           SUM(total_price) as daily_revenue
         FROM orders 
         WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
           AND status != 'cancelled'
         GROUP BY DATE(created_at)
         ORDER BY date DESC`,
        [days]
      );

      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Get formatted status
  getFormattedStatus() {
    return this.status.charAt(0).toUpperCase() + this.status.slice(1);
  }

  // Get formatted total
  getFormattedTotal(currency = '$') {
    return `${currency}${this.total_price.toFixed(2)}`;
  }

  // Check if order can be cancelled
  canBeCancelled() {
    return ['pending', 'processing'].includes(this.status);
  }

  // Convert to JSON
  toJSON() {
    return {
      id: this.id,
      user_id: this.user_id,
      user: this.user,
      total_price: this.total_price,
      formatted_total: this.getFormattedTotal(),
      status: this.status,
      formatted_status: this.getFormattedStatus(),
      shipping_address: this.shipping_address,
      can_be_cancelled: this.canBeCancelled(),
      items: this.items || [],
      created_at: this.created_at,
      updated_at: this.updated_at
    };
  }
}

module.exports = Order;