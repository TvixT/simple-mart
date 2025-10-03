const express = require('express');
const OrderController = require('../controllers/OrderController');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// All order routes require authentication
router.use(authenticateToken);

// User order operations
router.post('/', OrderController.createOrder);                      // POST /api/orders (create order)
router.get('/user', OrderController.getUserOrders);             // GET /api/orders/user (view own orders)
router.get('/user/:userId', OrderController.getUserOrders);        // GET /api/orders/user/:userId (view user orders)
router.get('/:id', OrderController.getOrder);                       // GET /api/orders/:id (get single order)
router.post('/:id/cancel', OrderController.cancelOrder);            // POST /api/orders/:id/cancel (cancel order)
router.put('/:id/shipping', OrderController.updateShippingAddress); // PUT /api/orders/:id/shipping (update address)

// Admin-only routes
router.get('/', requireAdmin, OrderController.getAllOrders);         // GET /api/orders (all orders - admin)
router.put('/:id/status', requireAdmin, OrderController.updateOrderStatus); // PUT /api/orders/:id/status (update status)
router.get('/admin/statistics', requireAdmin, OrderController.getOrderStats);
router.get('/admin/daily-sales', requireAdmin, OrderController.getDailySales);

module.exports = router;