const express = require('express');
const router = express.Router();
const {
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
const adminAuth = require('../middleware/adminAuth');

// Apply auth middleware to all routes
router.use(protect);
router.use(adminAuth);

// Order management routes
router.get('/', getOrders);
router.get('/stats', getOrderStats);
router.get('/analytics', getOrderAnalytics);
router.get('/export', exportOrders);

router.get('/:id', getOrder);
router.put('/:id/status', updateOrderStatus);
router.put('/:id/payment', updatePaymentStatus);
router.delete('/:id', deleteOrder);

module.exports = router;
