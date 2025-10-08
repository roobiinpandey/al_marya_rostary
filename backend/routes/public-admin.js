const express = require('express');
const router = express.Router();
const {
  getUsers,
  getUser,
  createUser,
  updateUser,
  deleteUser,
  getUserStats,
  bulkUpdateUsers,
  toggleUserStatus,
  updateUserRoles,
  getUserActivity,
  exportUsers
} = require('../controllers/userController');

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

// Simple admin routes without authentication (for local development)
// These routes should be secured in production
router.get('/users', getUsers);
router.post('/users', createUser);
router.get('/users/stats', getUserStats);
router.get('/users/export', exportUsers);
router.put('/users/bulk', bulkUpdateUsers);

router.get('/users/:id', getUser);
router.put('/users/:id', updateUser);
router.delete('/users/:id', deleteUser);
router.patch('/users/:id/toggle-status', toggleUserStatus);
router.patch('/users/:id/roles', updateUserRoles);
router.get('/users/:id/activity', getUserActivity);

// Order management routes (without authentication for local development)
router.get('/orders', getOrders);
router.get('/orders/stats', getOrderStats);
router.get('/orders/analytics', getOrderAnalytics);
router.get('/orders/export', exportOrders);
router.get('/orders/:id', getOrder);
router.put('/orders/:id/status', updateOrderStatus);
router.put('/orders/:id/payment', updatePaymentStatus);
router.delete('/orders/:id', deleteOrder);

module.exports = router;
