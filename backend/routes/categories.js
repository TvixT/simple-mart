const express = require('express');
const router = express.Router();
const CategoryController = require('../controllers/CategoryController');
const { authenticateToken, requireAdmin, rateLimit } = require('../middleware/auth');

// Rate limiting for API protection
const categoryRateLimit = rateLimit(100, 15 * 60 * 1000); // 100 requests per 15 minutes

// PUBLIC ROUTES (no authentication required)

// Get all categories
router.get('/', categoryRateLimit, CategoryController.getCategories);

// Get single category by ID
router.get('/:id', categoryRateLimit, CategoryController.getCategoryById);

// Search categories
router.get('/search/query', categoryRateLimit, CategoryController.searchCategories);

// ADMIN ROUTES (require authentication and admin role)

// Create new category (admin only)
router.post('/', authenticateToken, requireAdmin, CategoryController.createCategory);

// Update category (admin only)
router.put('/:id', authenticateToken, requireAdmin, CategoryController.updateCategory);

// Delete category (admin only)
router.delete('/:id', authenticateToken, requireAdmin, CategoryController.deleteCategory);

module.exports = router;