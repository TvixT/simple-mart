const Order = require('../models/Order');
const Cart = require('../models/Cart');

class OrderController {
  // Create order from cart
  static async createOrder(req, res) {
    try {
      const { shipping_address } = req.body;
      const userId = req.user.id;

      // Validation
      if (!shipping_address || shipping_address.trim() === '') {
        return res.status(400).json({
          success: false,
          message: 'Shipping address is required'
        });
      }

      // Check if cart has items
      const cart = await Cart.getUserCart(userId);
      if (cart.items.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Cannot create order from empty cart'
        });
      }

      // Validate cart stock
      const stockValidation = await Cart.validateCartStock(userId);
      if (!stockValidation.valid) {
        return res.status(400).json({
          success: false,
          message: 'Some items in your cart are out of stock',
          data: {
            invalid_items: stockValidation.invalid_items
          }
        });
      }

      // Create order from cart
      const order = await Order.createFromCart(userId, shipping_address.trim());

      // Get order with items for response
      const orderWithItems = await Order.getOrderWithItems(order.id);

      res.status(201).json({
        success: true,
        message: 'Order created successfully',
        data: {
          order: orderWithItems.toJSON()
        }
      });

    } catch (error) {
      console.error('Create order error:', error);
      res.status(500).json({
        success: false,
        message: 'Error creating order',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Get user's orders
  static async getUserOrders(req, res) {
    try {
      const userId = req.params.userId || req.user.id;
      const { page = 1, limit = 10 } = req.query;

      // Check if user is requesting their own orders or if they're admin
      if (userId != req.user.id && !req.user.email.includes('admin')) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. You can only view your own orders'
        });
      }

      const result = await Order.getUserOrders(parseInt(userId), parseInt(page), parseInt(limit));

      res.json({
        success: true,
        message: 'Orders retrieved successfully',
        data: result
      });

    } catch (error) {
      console.error('Get user orders error:', error);
      res.status(500).json({
        success: false,
        message: 'Error retrieving orders',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Get single order details
  static async getOrder(req, res) {
    try {
      const { id } = req.params;

      if (!id || isNaN(id)) {
        return res.status(400).json({
          success: false,
          message: 'Valid order ID is required'
        });
      }

      const order = await Order.getOrderWithItems(parseInt(id));

      if (!order) {
        return res.status(404).json({
          success: false,
          message: 'Order not found'
        });
      }

      // Check if user owns this order or is admin
      if (order.user_id !== req.user.id && !req.user.email.includes('admin')) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. You can only view your own orders'
        });
      }

      res.json({
        success: true,
        message: 'Order retrieved successfully',
        data: {
          order: order.toJSON()
        }
      });

    } catch (error) {
      console.error('Get order error:', error);
      res.status(500).json({
        success: false,
        message: 'Error retrieving order',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Get all orders with filters (admin only)
  static async getAllOrders(req, res) {
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
      } = req.query;

      const options = {
        page: parseInt(page),
        limit: parseInt(limit),
        status,
        user_id: user_id ? parseInt(user_id) : undefined,
        start_date,
        end_date,
        sort_by,
        sort_order
      };

      const result = await Order.findAll(options);

      res.json({
        success: true,
        message: 'Orders retrieved successfully',
        data: result
      });

    } catch (error) {
      console.error('Get all orders error:', error);
      res.status(500).json({
        success: false,
        message: 'Error retrieving orders',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Update order status (admin only)
  static async updateOrderStatus(req, res) {
    try {
      const { id } = req.params;
      const { status } = req.body;

      if (!id || isNaN(id)) {
        return res.status(400).json({
          success: false,
          message: 'Valid order ID is required'
        });
      }

      if (!status) {
        return res.status(400).json({
          success: false,
          message: 'Status is required'
        });
      }

      const validStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
      if (!validStatuses.includes(status)) {
        return res.status(400).json({
          success: false,
          message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`
        });
      }

      const updatedOrder = await Order.updateStatus(parseInt(id), status);

      if (!updatedOrder) {
        return res.status(404).json({
          success: false,
          message: 'Order not found'
        });
      }

      res.json({
        success: true,
        message: 'Order status updated successfully',
        data: {
          order: updatedOrder.toJSON()
        }
      });

    } catch (error) {
      console.error('Update order status error:', error);
      res.status(500).json({
        success: false,
        message: 'Error updating order status',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Cancel order
  static async cancelOrder(req, res) {
    try {
      const { id } = req.params;

      if (!id || isNaN(id)) {
        return res.status(400).json({
          success: false,
          message: 'Valid order ID is required'
        });
      }

      // Get order first to check ownership
      const order = await Order.findById(parseInt(id));
      if (!order) {
        return res.status(404).json({
          success: false,
          message: 'Order not found'
        });
      }

      // Check if user owns this order or is admin
      if (order.user_id !== req.user.id && !req.user.email.includes('admin')) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. You can only cancel your own orders'
        });
      }

      const cancelledOrder = await Order.cancel(parseInt(id));

      res.json({
        success: true,
        message: 'Order cancelled successfully',
        data: {
          order: cancelledOrder.toJSON()
        }
      });

    } catch (error) {
      console.error('Cancel order error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Error cancelling order',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Update shipping address
  static async updateShippingAddress(req, res) {
    try {
      const { id } = req.params;
      const { shipping_address } = req.body;

      if (!id || isNaN(id)) {
        return res.status(400).json({
          success: false,
          message: 'Valid order ID is required'
        });
      }

      if (!shipping_address || shipping_address.trim() === '') {
        return res.status(400).json({
          success: false,
          message: 'Shipping address is required'
        });
      }

      // Get order first to check ownership and status
      const order = await Order.findById(parseInt(id));
      if (!order) {
        return res.status(404).json({
          success: false,
          message: 'Order not found'
        });
      }

      // Check if user owns this order or is admin
      if (order.user_id !== req.user.id && !req.user.email.includes('admin')) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. You can only update your own orders'
        });
      }

      // Check if order can be modified
      if (order.status === 'shipped' || order.status === 'delivered') {
        return res.status(400).json({
          success: false,
          message: 'Cannot update shipping address for shipped or delivered orders'
        });
      }

      const updatedOrder = await Order.updateShippingAddress(parseInt(id), shipping_address.trim());

      res.json({
        success: true,
        message: 'Shipping address updated successfully',
        data: {
          order: updatedOrder.toJSON()
        }
      });

    } catch (error) {
      console.error('Update shipping address error:', error);
      res.status(500).json({
        success: false,
        message: 'Error updating shipping address',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Get order statistics (admin only)
  static async getOrderStats(req, res) {
    try {
      const stats = await Order.getStats();

      res.json({
        success: true,
        message: 'Order statistics retrieved successfully',
        data: {
          statistics: stats
        }
      });

    } catch (error) {
      console.error('Get order stats error:', error);
      res.status(500).json({
        success: false,
        message: 'Error retrieving order statistics',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Get daily sales (admin only)
  static async getDailySales(req, res) {
    try {
      const { days = 30 } = req.query;

      const salesData = await Order.getDailySales(parseInt(days));

      res.json({
        success: true,
        message: 'Daily sales data retrieved successfully',
        data: {
          salesData,
          period: `${days} days`
        }
      });

    } catch (error) {
      console.error('Get daily sales error:', error);
      res.status(500).json({
        success: false,
        message: 'Error retrieving daily sales data',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
}

module.exports = OrderController;