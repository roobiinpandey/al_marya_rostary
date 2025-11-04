/**
 * Token Blacklist Management Controller
 * Admin endpoints for monitoring and managing token blacklist
 */

const { 
  getBlacklistStats, 
  clearBlacklist, 
  cleanupExpiredTokens,
  blacklistToken,
  removeFromBlacklist,
  getBlacklistInfo
} = require('../utils/tokenBlacklist');

/**
 * @desc    Get blacklist statistics
 * @route   GET /api/admin/token-blacklist/stats
 * @access  Private/Admin
 */
exports.getStats = async (req, res) => {
  try {
    const stats = getBlacklistStats();
    
    res.json({
      success: true,
      data: {
        ...stats,
        message: `${stats.total} tokens currently blacklisted`
      }
    });
  } catch (error) {
    console.error('Error getting blacklist stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get blacklist statistics'
    });
  }
};

/**
 * @desc    Manual cleanup of expired tokens
 * @route   POST /api/admin/token-blacklist/cleanup
 * @access  Private/Admin
 */
exports.cleanup = async (req, res) => {
  try {
    const cleaned = cleanupExpiredTokens();
    
    res.json({
      success: true,
      message: `Cleaned up ${cleaned} expired tokens`,
      data: { cleaned }
    });
  } catch (error) {
    console.error('Error cleaning up blacklist:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to cleanup blacklist'
    });
  }
};

/**
 * @desc    Clear entire blacklist (use with caution!)
 * @route   POST /api/admin/token-blacklist/clear
 * @access  Private/Admin
 */
exports.clear = async (req, res) => {
  try {
    const { confirm } = req.body;
    
    if (confirm !== 'CLEAR_ALL_TOKENS') {
      return res.status(400).json({
        success: false,
        message: 'Confirmation required. Send { "confirm": "CLEAR_ALL_TOKENS" } to proceed.'
      });
    }
    
    const cleared = clearBlacklist();
    
    res.json({
      success: true,
      message: `Cleared ${cleared} tokens from blacklist`,
      data: { cleared },
      warning: 'All previously logged-out users can now use their old tokens until expiration'
    });
  } catch (error) {
    console.error('Error clearing blacklist:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to clear blacklist'
    });
  }
};

/**
 * @desc    Manually blacklist a specific token
 * @route   POST /api/admin/token-blacklist/add
 * @access  Private/Admin
 */
exports.addToken = async (req, res) => {
  try {
    const { token, reason } = req.body;
    
    if (!token) {
      return res.status(400).json({
        success: false,
        message: 'Token is required'
      });
    }
    
    const blacklisted = blacklistToken(token, reason || 'Admin manual blacklist');
    
    if (blacklisted) {
      res.json({
        success: true,
        message: 'Token blacklisted successfully'
      });
    } else {
      res.status(400).json({
        success: false,
        message: 'Token is already expired or invalid'
      });
    }
  } catch (error) {
    console.error('Error blacklisting token:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to blacklist token',
      error: error.message
    });
  }
};

/**
 * @desc    Remove token from blacklist
 * @route   POST /api/admin/token-blacklist/remove
 * @access  Private/Admin
 */
exports.removeToken = async (req, res) => {
  try {
    const { token } = req.body;
    
    if (!token) {
      return res.status(400).json({
        success: false,
        message: 'Token is required'
      });
    }
    
    const removed = removeFromBlacklist(token);
    
    if (removed) {
      res.json({
        success: true,
        message: 'Token removed from blacklist'
      });
    } else {
      res.status(404).json({
        success: false,
        message: 'Token not found in blacklist'
      });
    }
  } catch (error) {
    console.error('Error removing token:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to remove token from blacklist'
    });
  }
};

/**
 * @desc    Check if a token is blacklisted
 * @route   POST /api/admin/token-blacklist/check
 * @access  Private/Admin
 */
exports.checkToken = async (req, res) => {
  try {
    const { token } = req.body;
    
    if (!token) {
      return res.status(400).json({
        success: false,
        message: 'Token is required'
      });
    }
    
    const info = getBlacklistInfo(token);
    
    if (info) {
      res.json({
        success: true,
        isBlacklisted: true,
        data: info
      });
    } else {
      res.json({
        success: true,
        isBlacklisted: false,
        message: 'Token is not blacklisted'
      });
    }
  } catch (error) {
    console.error('Error checking token:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to check token status'
    });
  }
};
