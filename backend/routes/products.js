const express = require('express');
const ProductController = require('../controllers/ProductController');
const { authenticateToken, optionalAuth, requireAdmin, requireStaff } = require('../middleware/auth');

const router = express.Router();

// Public routes (no authentication required)
router.get('/', ProductController.getProducts);
router.get('/search', ProductController.searchProducts);
router.get('/featured', ProductController.getFeaturedProducts);
router.get('/category/:categoryId', ProductController.getProductsByCategory);
router.get('/:id', ProductController.getProduct);

// Admin-only routes (require authentication and admin privileges)
router.post('/', authenticateToken, requireAdmin, ProductController.createProduct);
router.put('/:id', authenticateToken, requireAdmin, ProductController.updateProduct);
router.delete('/:id', authenticateToken, requireAdmin, ProductController.deleteProduct);
router.get('/admin/low-stock', authenticateToken, requireAdmin, ProductController.getLowStockProducts);
router.get('/admin/statistics', authenticateToken, requireAdmin, ProductController.getProductStats);

module.exports = router;