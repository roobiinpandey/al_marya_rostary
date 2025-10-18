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
const { getAuditLogs, getAuditStats, cleanupOldLogs } = require('../utils/auditLogger');
const { protect } = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth');

// Apply authentication and admin authorization to ALL admin routes
router.use(protect);
router.use(adminAuth);

// User management routes
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

// Audit log routes
router.get('/audit-logs', getAuditLogs);
router.get('/audit-logs/stats', getAuditStats);
router.post('/audit-logs/cleanup', cleanupOldLogs);

module.exports = router;
