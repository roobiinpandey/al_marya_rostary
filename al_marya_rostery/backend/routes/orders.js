const express = require('express');
const router = express.Router();
const {
  createOrder,
  createGuestOrder,
  getMyOrders,
  cancelOrder,
  getOrders,
  getOrder,
  updateOrderStatus,
  updatePaymentStatus,
  deleteOrder,
  getOrderStats,
  getOrderAnalytics,
  exportOrders
} = require('../controllers/orderController');
const { protect } = require('../middleware/auth');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth'); // Firebase auth for customer orders
const adminAuth = require('../middleware/adminAuth');
const { orderValidation } = require('../middleware/validation');

// ==========================================
// PUBLIC ROUTES (No Authentication Required)
// ==========================================

/**
 * POST /api/orders/guest
 * Create order without authentication
 * Body: { items, shippingAddress, guestInfo, paymentMethod, totalAmount, deliveryMethod, specialInstructions }
 */
router.post('/guest', orderValidation, createGuestOrder);

// ==========================================
// PROTECTED ROUTES (User Authentication Required)
// ==========================================

/**
 * POST /api/orders
 * Create authenticated user order
 * Body: { items, shippingAddress, paymentMethod, totalAmount, deliveryMethod, preferredDeliveryDate, preferredDeliveryTime, specialInstructions }
 * 🔥 Uses Firebase authentication (verifyFirebaseToken) - accepts Firebase ID tokens
 */
router.post('/', verifyFirebaseToken, orderValidation, createOrder);

/**
 * GET /api/orders/my-orders
 * Get current user's orders
 * 🔥 Uses Firebase authentication (verifyFirebaseToken) - accepts Firebase ID tokens
 */
router.get('/my-orders', verifyFirebaseToken, getMyOrders);

/**
 * PUT /api/orders/:id/cancel
 * Cancel an order
 * Body: { reason }
 * 🔥 Uses Firebase authentication (verifyFirebaseToken) - accepts Firebase ID tokens
 */
router.put('/:id/cancel', verifyFirebaseToken, cancelOrder);

// ==========================================
// ADMIN ROUTES (Admin Authentication Required)
// ==========================================

// Apply auth middleware to remaining routes
router.use(protect);
router.use(adminAuth);

/**
 * GET /api/orders
 * Get all orders (admin only)
 */
router.get('/', getOrders);

/**
 * GET /api/orders/stats
 * Get order statistics (admin only)
 */
router.get('/stats', getOrderStats);

/**
 * GET /api/orders/analytics
 * Get order analytics (admin only)
 */
router.get('/analytics', getOrderAnalytics);

/**
 * GET /api/orders/export
 * Export orders to CSV (admin only)
 */
router.get('/export', exportOrders);

/**
 * GET /api/orders/:id
 * Get specific order (admin only)
 */
router.get('/:id', getOrder);

/**
 * PUT /api/orders/:id/status
 * Update order status (admin only)
 */
router.put('/:id/status', updateOrderStatus);

/**
 * PUT /api/orders/:id/payment
 * Update payment status (admin only)
 */
router.put('/:id/payment', updatePaymentStatus);

/**
 * DELETE /api/orders/:id
 * Delete order (admin only)
 */
router.delete('/:id', deleteOrder);

module.exports = router;
