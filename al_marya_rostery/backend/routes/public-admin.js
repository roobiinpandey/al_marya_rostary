const express = require('express');
const router = express.Router();
const {
  getUsers,
  getUser,
  createUser,
  updateUser,
  deleteUser,
  getUserStats,
  toggleUserStatus,
  exportUsers
} = require('../controllers/publicAdminUserController');
const { protect } = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth');

// Apply authentication to all admin user routes
router.use(protect);
router.use(adminAuth);
router.get('/users', getUsers);
router.post('/users', createUser);
router.get('/users/stats', getUserStats);
router.get('/users/export', exportUsers);

router.get('/users/:id', getUser);
router.put('/users/:id', updateUser);
router.delete('/users/:id', deleteUser);
router.patch('/users/:id/toggle-status', toggleUserStatus);

module.exports = router;
