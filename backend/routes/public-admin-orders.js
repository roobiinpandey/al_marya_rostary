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

// Public admin order routes (no auth required for local development)
// These routes should be secured in production
router.get('/', getOrders);
router.get('/stats', getOrderStats);
router.get('/analytics', getOrderAnalytics);
router.get('/export', exportOrders);

router.get('/:id', getOrder);
router.put('/:id/status', updateOrderStatus);
router.put('/:id/payment', updatePaymentStatus);
router.delete('/:id', deleteOrder);

module.exports = router;
