const { promisePool } = require('../config/database');

class Cart {
  constructor(data) {
    this.id = data.id;
    this.user_id = data.user_id;
    this.product_id = data.product_id;
    this.quantity = data.quantity;
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;
    
    // Include product details if available
    if (data.product_name) {
      this.product = {
        id: data.product_id,
        name: data.product_name,
        price: parseFloat(data.product_price),
        stock: data.product_stock,
        image_url: data.product_image_url
      };
    }
  }

  // Add item to cart
  static async addItem(userId, productId, quantity = 1) {
    try {
      // Check if item already exists in cart
      const [existing] = await promisePool.execute(
        'SELECT * FROM cart WHERE user_id = ? AND product_id = ?',
        [userId, productId]
      );

      if (existing.length > 0) {
        // Update existing item quantity
        return await Cart.updateQuantity(userId, productId, existing[0].quantity + quantity);
      } else {
        // Add new item to cart
        const [result] = await promisePool.execute(
          'INSERT INTO cart (user_id, product_id, quantity) VALUES (?, ?, ?)',
          [userId, productId, quantity]
        );

        return await Cart.getCartItem(result.insertId);
      }
    } catch (error) {
      throw error;
    }
  }

  // Get cart item by ID
  static async getCartItem(cartId) {
    try {
      const [rows] = await promisePool.execute(
        `SELECT c.*, p.name as product_name, p.price as product_price, 
                p.stock as product_stock, p.image_url as product_image_url
         FROM cart c
         JOIN products p ON c.product_id = p.id
         WHERE c.id = ?`,
        [cartId]
      );

      if (rows.length === 0) {
        return null;
      }

      return new Cart(rows[0]);
    } catch (error) {
      throw error;
    }
  }

  // Get user's cart
  static async getUserCart(userId) {
    try {
      const [rows] = await promisePool.execute(
        `SELECT c.*, p.name as product_name, p.price as product_price, 
                p.stock as product_stock, p.image_url as product_image_url
         FROM cart c
         JOIN products p ON c.product_id = p.id
         WHERE c.user_id = ?
         ORDER BY c.created_at DESC`,
        [userId]
      );

      const cartItems = rows.map(row => new Cart(row));
      
      // Calculate totals
      const subtotal = cartItems.reduce((total, item) => {
        return total + (item.product.price * item.quantity);
      }, 0);

      const totalItems = cartItems.reduce((total, item) => total + item.quantity, 0);

      return {
        items: cartItems,
        summary: {
          total_items: totalItems,
          subtotal: parseFloat(subtotal.toFixed(2)),
          estimated_total: parseFloat(subtotal.toFixed(2)) // Can add tax, shipping, etc.
        }
      };
    } catch (error) {
      throw error;
    }
  }

  // Update item quantity
  static async updateQuantity(userId, productId, newQuantity) {
    try {
      if (newQuantity <= 0) {
        return await Cart.removeItem(userId, productId);
      }

      await promisePool.execute(
        'UPDATE cart SET quantity = ?, updated_at = NOW() WHERE user_id = ? AND product_id = ?',
        [newQuantity, userId, productId]
      );

      // Return updated cart item
      const [rows] = await promisePool.execute(
        `SELECT c.*, p.name as product_name, p.price as product_price, 
                p.stock as product_stock, p.image_url as product_image_url
         FROM cart c
         JOIN products p ON c.product_id = p.id
         WHERE c.user_id = ? AND c.product_id = ?`,
        [userId, productId]
      );

      return rows.length > 0 ? new Cart(rows[0]) : null;
    } catch (error) {
      throw error;
    }
  }

  // Remove item from cart
  static async removeItem(userId, productId) {
    try {
      const [result] = await promisePool.execute(
        'DELETE FROM cart WHERE user_id = ? AND product_id = ?',
        [userId, productId]
      );

      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Clear user's entire cart
  static async clearCart(userId) {
    try {
      const [result] = await promisePool.execute(
        'DELETE FROM cart WHERE user_id = ?',
        [userId]
      );

      return result.affectedRows;
    } catch (error) {
      throw error;
    }
  }

  // Get cart item count for user
  static async getCartCount(userId) {
    try {
      const [rows] = await promisePool.execute(
        'SELECT SUM(quantity) as total_items FROM cart WHERE user_id = ?',
        [userId]
      );

      return rows[0].total_items || 0;
    } catch (error) {
      throw error;
    }
  }

  // Check if all cart items are in stock
  static async validateCartStock(userId) {
    try {
      const [rows] = await promisePool.execute(
        `SELECT c.quantity, c.product_id, p.name as product_name, p.stock
         FROM cart c
         JOIN products p ON c.product_id = p.id
         WHERE c.user_id = ?`,
        [userId]
      );

      const invalidItems = [];
      
      for (const item of rows) {
        if (item.stock < item.quantity) {
          invalidItems.push({
            product_id: item.product_id,
            product_name: item.product_name,
            requested_quantity: item.quantity,
            available_stock: item.stock
          });
        }
      }

      return {
        valid: invalidItems.length === 0,
        invalid_items: invalidItems
      };
    } catch (error) {
      throw error;
    }
  }

  // Move cart items to order (used during checkout)
  static async moveToOrder(userId, orderId) {
    try {
      // Get cart items
      const cart = await Cart.getUserCart(userId);
      
      if (cart.items.length === 0) {
        throw new Error('Cart is empty');
      }

      // Validate stock
      const stockValidation = await Cart.validateCartStock(userId);
      if (!stockValidation.valid) {
        throw new Error(`Insufficient stock for some items: ${JSON.stringify(stockValidation.invalid_items)}`);
      }

      // Insert into order_items
      for (const item of cart.items) {
        await promisePool.execute(
          'INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)',
          [orderId, item.product_id, item.quantity, item.product.price]
        );

        // Update product stock
        await promisePool.execute(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item.quantity, item.product_id]
        );
      }

      // Clear cart
      await Cart.clearCart(userId);

      return cart;
    } catch (error) {
      throw error;
    }
  }

  // Get cart statistics
  static async getStats() {
    try {
      const [results] = await promisePool.execute(`
        SELECT 
          COUNT(DISTINCT user_id) as active_carts,
          COUNT(*) as total_cart_items,
          AVG(quantity) as avg_items_per_product,
          SUM(c.quantity * p.price) as total_cart_value
        FROM cart c
        JOIN products p ON c.product_id = p.id
      `);

      return results[0];
    } catch (error) {
      throw error;
    }
  }

  // Get most popular items in carts
  static async getPopularCartItems(limit = 10) {
    try {
      const [rows] = await promisePool.execute(
        `SELECT p.id, p.name, p.price, SUM(c.quantity) as total_quantity,
                COUNT(DISTINCT c.user_id) as users_count
         FROM cart c
         JOIN products p ON c.product_id = p.id
         GROUP BY p.id, p.name, p.price
         ORDER BY total_quantity DESC
         LIMIT ?`,
        [limit]
      );

      return rows;
    } catch (error) {
      throw error;
    }
  }

  // Calculate line total (quantity * price)
  getLineTotal() {
    if (this.product) {
      return this.quantity * this.product.price;
    }
    return 0;
  }

  // Check if item is available in requested quantity
  isAvailable() {
    if (this.product) {
      return this.product.stock >= this.quantity;
    }
    return false;
  }

  // Convert to JSON
  toJSON() {
    return {
      id: this.id,
      user_id: this.user_id,
      product_id: this.product_id,
      quantity: this.quantity,
      product: this.product,
      line_total: this.getLineTotal(),
      available: this.isAvailable(),
      created_at: this.created_at,
      updated_at: this.updated_at
    };
  }
}

module.exports = Cart;