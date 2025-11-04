/**
 * Token Blacklist Manager
 * In-memory token blacklist for JWT revocation
 * Tokens are automatically removed after expiration
 */

const jwt = require('jsonwebtoken');

// In-memory storage for blacklisted tokens
const blacklistedTokens = new Map();

/**
 * Add token to blacklist
 * @param {string} token - JWT token to blacklist
 * @param {string} reason - Reason for blacklisting (optional)
 */
const blacklistToken = (token, reason = 'User logout') => {
  try {
    // Decode token to get expiration time
    const decoded = jwt.decode(token);
    
    if (!decoded || !decoded.exp) {
      console.error('❌ Cannot blacklist token: Invalid or no expiration');
      return false;
    }

    const expiresAt = decoded.exp * 1000; // Convert to milliseconds
    const now = Date.now();
    const ttl = expiresAt - now;

    // Only blacklist if token hasn't expired yet
    if (ttl > 0) {
      blacklistedTokens.set(token, {
        reason,
        blacklistedAt: now,
        expiresAt,
        userId: decoded.userId
      });

      // Auto-remove from blacklist after expiration
      setTimeout(() => {
        blacklistedTokens.delete(token);
        console.log(`🗑️ Auto-removed expired token from blacklist (userId: ${decoded.userId})`);
      }, ttl);

      console.log(`🚫 Token blacklisted: ${reason} (userId: ${decoded.userId}, expires in ${Math.round(ttl / 1000 / 60)} minutes)`);
      return true;
    } else {
      console.log(`⏰ Token already expired, not adding to blacklist`);
      return false;
    }
  } catch (error) {
    console.error('❌ Error blacklisting token:', error.message);
    return false;
  }
};

/**
 * Check if token is blacklisted
 * @param {string} token - JWT token to check
 * @returns {boolean} - True if blacklisted
 */
const isBlacklisted = (token) => {
  return blacklistedTokens.has(token);
};

/**
 * Get blacklist info for token
 * @param {string} token - JWT token
 * @returns {object|null} - Blacklist info or null
 */
const getBlacklistInfo = (token) => {
  return blacklistedTokens.get(token) || null;
};

/**
 * Remove token from blacklist (useful for testing or admin override)
 * @param {string} token - JWT token to remove
 */
const removeFromBlacklist = (token) => {
  const deleted = blacklistedTokens.delete(token);
  if (deleted) {
    console.log(`✅ Token removed from blacklist`);
  }
  return deleted;
};

/**
 * Get blacklist statistics
 * @returns {object} - Stats about blacklist
 */
const getBlacklistStats = () => {
  const tokens = Array.from(blacklistedTokens.values());
  const now = Date.now();
  
  return {
    total: blacklistedTokens.size,
    byReason: tokens.reduce((acc, info) => {
      acc[info.reason] = (acc[info.reason] || 0) + 1;
      return acc;
    }, {}),
    oldestEntry: tokens.length > 0 
      ? Math.min(...tokens.map(t => t.blacklistedAt))
      : null,
    averageTimeToExpiry: tokens.length > 0
      ? tokens.reduce((sum, t) => sum + (t.expiresAt - now), 0) / tokens.length / 1000 / 60
      : 0
  };
};

/**
 * Clear all blacklisted tokens (use with caution!)
 */
const clearBlacklist = () => {
  const size = blacklistedTokens.size;
  blacklistedTokens.clear();
  console.log(`🗑️ Cleared ${size} tokens from blacklist`);
  return size;
};

/**
 * Cleanup expired tokens (called periodically)
 * This is a backup cleanup in case setTimeout fails
 */
const cleanupExpiredTokens = () => {
  const now = Date.now();
  let cleaned = 0;

  for (const [token, info] of blacklistedTokens.entries()) {
    if (info.expiresAt < now) {
      blacklistedTokens.delete(token);
      cleaned++;
    }
  }

  if (cleaned > 0) {
    console.log(`🧹 Cleaned up ${cleaned} expired tokens from blacklist`);
  }

  return cleaned;
};

// Run cleanup every hour as backup
setInterval(cleanupExpiredTokens, 60 * 60 * 1000);

module.exports = {
  blacklistToken,
  isBlacklisted,
  getBlacklistInfo,
  removeFromBlacklist,
  getBlacklistStats,
  clearBlacklist,
  cleanupExpiredTokens
};
