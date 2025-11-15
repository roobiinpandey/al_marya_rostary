/**
 * Token Blacklist Management Routes
 * Admin routes for monitoring and managing JWT token blacklist
 */

const express = require('express');
const { protect, authorize } = require('../middleware/auth');
const {
  getStats,
  cleanup,
  clear,
  addToken,
  removeToken,
  checkToken
} = require('../controllers/tokenBlacklistController');

const router = express.Router();

// All routes require admin authentication
router.use(protect);
router.use(authorize('admin'));

/**
 * @route   GET /api/admin/token-blacklist/stats
 * @desc    Get blacklist statistics
 * @access  Private/Admin
 */
router.get('/stats', getStats);

/**
 * @route   POST /api/admin/token-blacklist/cleanup
 * @desc    Manually cleanup expired tokens
 * @access  Private/Admin
 */
router.post('/cleanup', cleanup);

/**
 * @route   POST /api/admin/token-blacklist/clear
 * @desc    Clear entire blacklist (requires confirmation)
 * @access  Private/Admin
 */
router.post('/clear', clear);

/**
 * @route   POST /api/admin/token-blacklist/add
 * @desc    Manually blacklist a token
 * @access  Private/Admin
 */
router.post('/add', addToken);

/**
 * @route   POST /api/admin/token-blacklist/remove
 * @desc    Remove token from blacklist
 * @access  Private/Admin
 */
router.post('/remove', removeToken);

/**
 * @route   POST /api/admin/token-blacklist/check
 * @desc    Check if token is blacklisted
 * @access  Private/Admin
 */
router.post('/check', checkToken);

module.exports = router;
