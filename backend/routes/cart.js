const express = require('express');
const CartController = require('../controllers/CartController');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// All cart routes require authentication
router.use(authenticateToken);

// User cart operations
router.post('/', CartController.addToCart);                    // POST /api/cart (add item)
router.get('/', CartController.getCart);                       // GET /api/cart (view own cart)
router.get('/:userId', CartController.getCart);                // GET /api/cart/:userId (view specific cart)
router.put('/', CartController.updateCartItem);                // PUT /api/cart (update quantity)
router.delete('/:id', CartController.removeFromCart);          // DELETE /api/cart/:id (remove item)
router.delete('/', CartController.clearCart);                  // DELETE /api/cart (clear entire cart)

// Utility routes
router.get('/utils/count', CartController.getCartCount);       // GET /api/cart/utils/count
router.get('/utils/validate', CartController.validateCart);    // GET /api/cart/utils/validate

// Admin routes
router.get('/admin/statistics', requireAdmin, CartController.getCartStats);
router.get('/admin/popular-items', requireAdmin, CartController.getPopularCartItems);

module.exports = router;