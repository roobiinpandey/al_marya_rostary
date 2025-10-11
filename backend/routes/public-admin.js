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

// Simple admin routes without authentication (for local development)
// These routes should be secured in production
router.get('/users', getUsers);
router.post('/users', createUser);
router.get('/users/stats', getUserStats);
router.get('/users/export', exportUsers);

router.get('/users/:id', getUser);
router.put('/users/:id', updateUser);
router.delete('/users/:id', deleteUser);
router.patch('/users/:id/toggle-status', toggleUserStatus);

module.exports = router;
