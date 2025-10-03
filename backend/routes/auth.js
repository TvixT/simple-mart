const express = require('express');
const AuthController = require('../controllers/AuthController');
const { authenticateToken, rateLimit } = require('../middleware/auth');

const router = express.Router();

// Apply rate limiting to auth routes
const authRateLimit = rateLimit(10, 15 * 60 * 1000); // 10 requests per 15 minutes

// Public routes
router.post('/register', authRateLimit, AuthController.register);
router.post('/login', authRateLimit, AuthController.login);
router.post('/refresh', AuthController.refreshToken);

// Protected routes (require authentication)
router.get('/profile', authenticateToken, AuthController.getProfile);
router.put('/profile', authenticateToken, AuthController.updateProfile);
router.put('/change-password', authenticateToken, AuthController.changePassword);

// Test route to verify token
router.get('/verify', authenticateToken, (req, res) => {
  res.json({
    success: true,
    message: 'Token is valid',
    data: {
      user: req.user
    }
  });
});

module.exports = router;