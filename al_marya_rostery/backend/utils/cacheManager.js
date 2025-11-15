/**
 * ⚡ HIGH-PERFORMANCE IN-MEMORY CACHE MANAGER
 * 
 * Features:
 * - TTL-based expiration
 * - Memory-efficient storage
 * - Automatic cleanup of expired entries
 * - Cache statistics and monitoring
 * - Multiple cache namespaces
 */

class CacheManager {
  constructor() {
    this.cache = new Map();
    this.stats = {
      hits: 0,
      misses: 0,
      sets: 0,
      deletes: 0,
      evictions: 0
    };
    
    // Start cleanup interval (every 30 seconds)
    this.cleanupInterval = setInterval(() => {
      this.cleanup();
    }, 30000);
    
    console.log('💾 Cache Manager initialized');
  }

  /**
   * Generate cache key with namespace
   */
  _generateKey(namespace, key) {
    return `${namespace}:${key}`;
  }

  /**
   * Set a cache entry with TTL
   * @param {string} namespace - Cache namespace (e.g., 'user', 'firebase', 'product')
   * @param {string} key - Cache key
   * @param {*} value - Value to cache
   * @param {number} ttl - Time to live in seconds
   */
  set(namespace, key, value, ttl) {
    const cacheKey = this._generateKey(namespace, key);
    const expiresAt = Date.now() + (ttl * 1000);
    
    this.cache.set(cacheKey, {
      value,
      expiresAt,
      createdAt: Date.now()
    });
    
    this.stats.sets++;
  }

  /**
   * Get a cache entry
   * @param {string} namespace - Cache namespace
   * @param {string} key - Cache key
   * @returns {*} Cached value or null if not found/expired
   */
  get(namespace, key) {
    const cacheKey = this._generateKey(namespace, key);
    const entry = this.cache.get(cacheKey);
    
    if (!entry) {
      this.stats.misses++;
      return null;
    }
    
    // Check if expired
    if (Date.now() > entry.expiresAt) {
      this.cache.delete(cacheKey);
      this.stats.misses++;
      this.stats.evictions++;
      return null;
    }
    
    this.stats.hits++;
    return entry.value;
  }

  /**
   * Check if key exists and is not expired
   */
  has(namespace, key) {
    const value = this.get(namespace, key);
    return value !== null;
  }

  /**
   * Delete a specific cache entry
   */
  delete(namespace, key) {
    const cacheKey = this._generateKey(namespace, key);
    const deleted = this.cache.delete(cacheKey);
    if (deleted) {
      this.stats.deletes++;
    }
    return deleted;
  }

  /**
   * Delete all entries in a namespace
   */
  deleteNamespace(namespace) {
    let count = 0;
    const prefix = `${namespace}:`;
    
    for (const key of this.cache.keys()) {
      if (key.startsWith(prefix)) {
        this.cache.delete(key);
        count++;
      }
    }
    
    this.stats.deletes += count;
    return count;
  }

  /**
   * Clear all cache entries
   */
  clear() {
    const size = this.cache.size;
    this.cache.clear();
    this.stats.deletes += size;
    return size;
  }

  /**
   * Get or set pattern - fetch from cache or execute function
   * @param {string} namespace - Cache namespace
   * @param {string} key - Cache key
   * @param {Function} fetchFn - Async function to fetch data if not cached
   * @param {number} ttl - Time to live in seconds
   */
  async getOrSet(namespace, key, fetchFn, ttl) {
    // Try to get from cache first
    const cached = this.get(namespace, key);
    if (cached !== null) {
      return cached;
    }
    
    // Fetch fresh data
    const value = await fetchFn();
    
    // Cache it
    if (value !== null && value !== undefined) {
      this.set(namespace, key, value, ttl);
    }
    
    return value;
  }

  /**
   * Cleanup expired entries
   */
  cleanup() {
    const now = Date.now();
    let cleaned = 0;
    
    for (const [key, entry] of this.cache.entries()) {
      if (now > entry.expiresAt) {
        this.cache.delete(key);
        cleaned++;
        this.stats.evictions++;
      }
    }
    
    if (cleaned > 0) {
      console.log(`🧹 Cache cleanup: Removed ${cleaned} expired entries`);
    }
  }

  /**
   * Get cache statistics
   */
  getStats() {
    const totalRequests = this.stats.hits + this.stats.misses;
    const hitRate = totalRequests > 0 
      ? ((this.stats.hits / totalRequests) * 100).toFixed(2)
      : 0;
    
    return {
      size: this.cache.size,
      hits: this.stats.hits,
      misses: this.stats.misses,
      hitRate: `${hitRate}%`,
      sets: this.stats.sets,
      deletes: this.stats.deletes,
      evictions: this.stats.evictions,
      totalRequests
    };
  }

  /**
   * Get memory usage information
   */
  getMemoryInfo() {
    // Approximate memory usage
    let bytes = 0;
    for (const [key, value] of this.cache.entries()) {
      bytes += key.length * 2; // UTF-16 characters
      bytes += JSON.stringify(value).length * 2;
    }
    
    return {
      entries: this.cache.size,
      approximateBytes: bytes,
      approximateKB: (bytes / 1024).toFixed(2),
      approximateMB: (bytes / (1024 * 1024)).toFixed(2)
    };
  }

  /**
   * Destroy cache manager and cleanup
   */
  destroy() {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
    }
    this.cache.clear();
    console.log('💾 Cache Manager destroyed');
  }
}

// Create singleton instance
const cacheManager = new CacheManager();

// ⚡ CACHE TTL CONSTANTS (in seconds)
const CACHE_TTL = {
  USER_PROFILE: 5 * 60,        // 5 minutes
  FIREBASE_USER: 2 * 60,       // 2 minutes
  FIREBASE_TOKEN: 5 * 60,      // 5 minutes
  PRODUCT: 10 * 60,            // 10 minutes
  CATEGORY: 15 * 60,           // 15 minutes
  ORDER: 1 * 60,               // 1 minute
  SETTINGS: 30 * 60,           // 30 minutes
  SHORT: 1 * 60,               // 1 minute
  MEDIUM: 5 * 60,              // 5 minutes
  LONG: 15 * 60                // 15 minutes
};

// ⚡ HELPER FUNCTIONS FOR COMMON CACHE OPERATIONS

/**
 * Cache user profile
 */
const cacheUserProfile = (userId, userData) => {
  cacheManager.set('user', userId, userData, CACHE_TTL.USER_PROFILE);
};

/**
 * Get cached user profile
 */
const getCachedUserProfile = (userId) => {
  return cacheManager.get('user', userId);
};

/**
 * Invalidate user cache
 */
const invalidateUserCache = (userId) => {
  cacheManager.delete('user', userId);
};

/**
 * Cache Firebase user data
 */
const cacheFirebaseUser = (firebaseUid, userData) => {
  cacheManager.set('firebase', firebaseUid, userData, CACHE_TTL.FIREBASE_USER);
};

/**
 * Get cached Firebase user
 */
const getCachedFirebaseUser = (firebaseUid) => {
  return cacheManager.get('firebase', firebaseUid);
};

/**
 * Cache Firebase token verification result
 */
const cacheFirebaseToken = (token, decodedToken) => {
  // Use a hash of the token as key (first 32 chars for reasonable key length)
  const tokenKey = token.substring(0, 32);
  cacheManager.set('firebase-token', tokenKey, decodedToken, CACHE_TTL.FIREBASE_TOKEN);
};

/**
 * Get cached Firebase token verification
 */
const getCachedFirebaseToken = (token) => {
  const tokenKey = token.substring(0, 32);
  return cacheManager.get('firebase-token', tokenKey);
};

/**
 * Cache product data
 */
const cacheProduct = (productId, productData) => {
  cacheManager.set('product', productId, productData, CACHE_TTL.PRODUCT);
};

/**
 * Get cached product
 */
const getCachedProduct = (productId) => {
  return cacheManager.get('product', productId);
};

/**
 * Invalidate product cache
 */
const invalidateProductCache = (productId) => {
  if (productId) {
    cacheManager.delete('product', productId);
  } else {
    // Invalidate all products
    cacheManager.deleteNamespace('product');
  }
};

/**
 * Cache category list
 */
const cacheCategories = (categories) => {
  cacheManager.set('category', 'list', categories, CACHE_TTL.CATEGORY);
};

/**
 * Get cached categories
 */
const getCachedCategories = () => {
  return cacheManager.get('category', 'list');
};

// Graceful shutdown
process.on('SIGTERM', () => {
  cacheManager.destroy();
});

process.on('SIGINT', () => {
  cacheManager.destroy();
});

module.exports = {
  cacheManager,
  CACHE_TTL,
  // User cache helpers
  cacheUserProfile,
  getCachedUserProfile,
  invalidateUserCache,
  // Firebase cache helpers
  cacheFirebaseUser,
  getCachedFirebaseUser,
  cacheFirebaseToken,
  getCachedFirebaseToken,
  // Product cache helpers
  cacheProduct,
  getCachedProduct,
  invalidateProductCache,
  // Category cache helpers
  cacheCategories,
  getCachedCategories
};
