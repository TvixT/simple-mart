const Cart = require('../models/Cart');
const Product = require('../models/Product');

class CartController {
  // Add item to cart
  static async addToCart(req, res) {
    try {
      const { product_id, quantity = 1 } = req.body;
      const userId = req.user.id;

      // Validation
      if (!product_id) {
        return res.status(400).json({
          success: false,
          message: 'Product ID is required'
        });
      }

      if (quantity <= 0) {
        return res.status(400).json({
          success: false,
          message: 'Quantity must be greater than 0'
        });
      }

      // Check if product exists
      const product = await Product.findById(product_id);
      if (!product) {
        return res.status(404).json({
          success: false,
          message: 'Product not found'
        });
      }

      // Check stock availability
      const stockCheck = await Product.checkStock(product_id, quantity);
      if (!stockCheck.available) {
        return res.status(400).json({
          success: false,
          message: `Insufficient stock. Available: ${stockCheck.currentStock}, Requested: ${stockCheck.requiredQuantity}`
        });
      }

      // Add to cart
      const cartItem = await Cart.addItem(userId, product_id, quantity);

      res.status(201).json({
        success: true,
        message: 'Item added to cart successfully',
        data: {
          cartItem: cartItem.toJSON()
        }
      });

    } catch (error) {
      console.error('Add to cart error:', error);
      res.status(500).json({
        success: false,
        message: 'Error adding item to cart',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Get user's cart
  static async getCart(req, res) {
    try {
      const userId = req.params.userId || req.user.id;

      // Check if user is requesting their own cart or if they're admin
      if (userId != req.user.id && !req.user.email.includes('admin')) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. You can only view your own cart'
        });
      }

      const cart = await Cart.getUserCart(parseInt(userId));

      res.json({
        success: true,
        message: 'Cart retrieved successfully',
        data: cart
      });

    } catch (error) {
      console.error('Get cart error:', error);
      res.status(500).json({
        success: false,
        message: 'Error retrieving cart',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Update cart item quantity
  static async updateCartItem(req, res) {
    try {
      const { product_id, quantity } = req.body;
      const userId = req.user.id;

      // Validation
      if (!product_id || quantity === undefined) {
        return res.status(400).json({
          success: false,
          message: 'Product ID and quantity are required'
        });
      }

      if (quantity < 0) {
        return res.status(400).json({
          success: false,
          message: 'Quantity cannot be negative'
        });
      }

      // If quantity is 0, remove the item
      if (quantity === 0) {
        const removed = await Cart.removeItem(userId, product_id);
        if (removed) {
          return res.json({
            success: true,
            message: 'Item removed from cart'
          });
        } else {
          return res.status(404).json({
            success: false,
            message: 'Item not found in cart'
          });
        }
      }

      // Check stock availability for the new quantity
      const stockCheck = await Product.checkStock(product_id, quantity);
      if (!stockCheck.available) {
        return res.status(400).json({
          success: false,
          message: `Insufficient stock. Available: ${stockCheck.currentStock}, Requested: ${stockCheck.requiredQuantity}`
        });
      }

      // Update quantity
      const updatedItem = await Cart.updateQuantity(userId, product_id, quantity);

      if (!updatedItem) {
        return res.status(404).json({
          success: false,
          message: 'Item not found in cart'
        });
      }

      res.json({
        success: true,
        message: 'Cart item updated successfully',
        data: {
          cartItem: updatedItem.toJSON()
        }
      });

    } catch (error) {
      console.error('Update cart item error:', error);
      res.status(500).json({
        success: false,
        message: 'Error updating cart item',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Remove item from cart
  static async removeFromCart(req, res) {
    try {
      const { id: productId } = req.params;
      const userId = req.user.id;

      if (!productId || isNaN(productId)) {
        return res.status(400).json({
          success: false,
          message: 'Valid product ID is required'
        });
      }

      const removed = await Cart.removeItem(userId, parseInt(productId));

      if (removed) {
        res.json({
          success: true,
          message: 'Item removed from cart successfully'
        });
      } else {
        res.status(404).json({
          success: false,
          message: 'Item not found in cart'
        });
      }

    } catch (error) {
      console.error('Remove from cart error:', error);
      res.status(500).json({
        success: false,
        message: 'Error removing item from cart',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Clear entire cart
  static async clearCart(req, res) {
    try {
      const userId = req.user.id;

      const removedCount = await Cart.clearCart(userId);

      res.json({
        success: true,
        message: `Cart cleared successfully. ${removedCount} items removed.`,
        data: {
          removedCount
        }
      });

    } catch (error) {
      console.error('Clear cart error:', error);
      res.status(500).json({
        success: false,
        message: 'Error clearing cart',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Get cart item count
  static async getCartCount(req, res) {
    try {
      const userId = req.user.id;

      const count = await Cart.getCartCount(userId);

      res.json({
        success: true,
        message: 'Cart count retrieved successfully',
        data: {
          count
        }
      });

    } catch (error) {
      console.error('Get cart count error:', error);
      res.status(500).json({
        success: false,
        message: 'Error retrieving cart count',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Validate cart (check stock availability)
  static async validateCart(req, res) {
    try {
      const userId = req.user.id;

      const validation = await Cart.validateCartStock(userId);

      res.json({
        success: true,
        message: 'Cart validation completed',
        data: validation
      });

    } catch (error) {
      console.error('Validate cart error:', error);
      res.status(500).json({
        success: false,
        message: 'Error validating cart',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Get cart statistics (admin only)
  static async getCartStats(req, res) {
    try {
      const stats = await Cart.getStats();

      res.json({
        success: true,
        message: 'Cart statistics retrieved successfully',
        data: {
          statistics: stats
        }
      });

    } catch (error) {
      console.error('Get cart stats error:', error);
      res.status(500).json({
        success: false,
        message: 'Error retrieving cart statistics',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Get popular cart items (admin only)
  static async getPopularCartItems(req, res) {
    try {
      const { limit = 10 } = req.query;

      const popularItems = await Cart.getPopularCartItems(parseInt(limit));

      res.json({
        success: true,
        message: 'Popular cart items retrieved successfully',
        data: {
          popularItems
        }
      });

    } catch (error) {
      console.error('Get popular cart items error:', error);
      res.status(500).json({
        success: false,
        message: 'Error retrieving popular cart items',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
}

module.exports = CartController;