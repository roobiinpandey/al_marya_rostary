const compression = require('compression');
const NodeCache = require('node-cache');

// Initialize memory cache
const memoryCache = new NodeCache({ 
  stdTTL: 600, // Default 10 minutes TTL
  checkperiod: 120, // Check for expired keys every 2 minutes
  useClones: false, // Better performance, but be careful with object mutations
  deleteOnExpire: true,
  enableLegacyCallbacks: false,
  maxKeys: 1000 // Prevent memory issues
});

/**
 * Performance optimization middleware
 */
const performanceMiddleware = (app) => {
  console.log('⚡ Configuring performance middleware...');

  // Enable gzip/deflate compression
  app.use(compression({
    level: 6, // Balance between compression ratio and speed
    threshold: 1024, // Only compress responses larger than 1KB
    filter: (req, res) => {
      // Don't compress if the client doesn't accept encoding
      if (req.headers['x-no-compression']) {
        return false;
      }
      
      // Don't compress already compressed content
      const contentType = res.getHeader('content-type');
      if (contentType && (
        contentType.includes('image/') ||
        contentType.includes('video/') ||
        contentType.includes('audio/') ||
        contentType.includes('application/zip') ||
        contentType.includes('application/gzip')
      )) {
        return false;
      }
      
      return compression.filter(req, res);
    }
  }));

  // Request timing middleware
  app.use((req, res, next) => {
    req.startTime = Date.now();
    
    // Override res.json to measure response time
    const originalJson = res.json;
    res.json = function(data) {
      const responseTime = Date.now() - req.startTime;
      
      // Add performance headers
      res.setHeader('X-Response-Time', `${responseTime}ms`);
      res.setHeader('X-Timestamp', new Date().toISOString());
      
      // Log slow requests
      if (responseTime > 1000) {
        console.warn(`⚠️ Slow request: ${req.method} ${req.path} took ${responseTime}ms`);
      }
      
      return originalJson.call(this, data);
    };
    
    next();
  });

  console.log('✅ Performance middleware configured');
};

/**
 * Caching middleware factory
 */
const createCacheMiddleware = (options = {}) => {
  const {
    ttl = 300, // 5 minutes default
    keyGenerator = (req) => `${req.method}_${req.originalUrl}`,
    skipCache = () => false,
    onHit = () => {},
    onMiss = () => {}
  } = options;

  return (req, res, next) => {
    // Skip caching for certain conditions
    if (skipCache(req, res)) {
      return next();
    }

    // Skip caching for authenticated requests (unless specified)
    if (req.headers.authorization && !options.cacheAuthenticated) {
      return next();
    }

    // Skip caching for non-GET requests
    if (req.method !== 'GET') {
      return next();
    }

    const cacheKey = keyGenerator(req);
    
    try {
      // Check cache
      const cachedData = memoryCache.get(cacheKey);
      if (cachedData) {
        onHit(cacheKey, cachedData);
        res.setHeader('X-Cache', 'HIT');
        res.setHeader('X-Cache-Key', cacheKey);
        return res.json(cachedData);
      }

      // Cache miss - store original json method
      const originalJson = res.json;
      
      // Override json method to cache response
      res.json = function(data) {
        // Only cache successful responses
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            memoryCache.set(cacheKey, data, ttl);
            res.setHeader('X-Cache', 'MISS');
            res.setHeader('X-Cache-TTL', ttl.toString());
            onMiss(cacheKey, data);
          } catch (cacheError) {
            console.error('Cache storage error:', cacheError);
          }
        }
        
        res.setHeader('X-Cache-Key', cacheKey);
        return originalJson.call(this, data);
      };

      next();
    } catch (error) {
      console.error('Cache middleware error:', error);
      next();
    }
  };
};

/**
 * Cache management utilities
 */
const cacheUtils = {
  // Clear specific cache key
  invalidate: (key) => {
    return memoryCache.del(key);
  },

  // Clear cache by pattern
  invalidateByPattern: (pattern) => {
    const keys = memoryCache.keys();
    const matchingKeys = keys.filter(key => key.includes(pattern));
    return memoryCache.del(matchingKeys);
  },

  // Clear all cache
  flush: () => {
    return memoryCache.flushAll();
  },

  // Get cache statistics
  getStats: () => {
    return memoryCache.getStats();
  },

  // Get cache size
  getKeys: () => {
    return memoryCache.keys();
  },

  // Manually set cache
  set: (key, value, ttl) => {
    return memoryCache.set(key, value, ttl);
  },

  // Manually get cache
  get: (key) => {
    return memoryCache.get(key);
  }
};

/**
 * Database query optimization utilities
 */
const dbOptimization = {
  // Lean queries for better performance
  applyLeanQuery: (query) => {
    return query.lean({ getters: true, virtuals: false });
  },

  // Common projection for user data (excluding sensitive fields)
  userProjection: {
    password: 0,
    __v: 0,
    resetPasswordToken: 0,
    resetPasswordExpires: 0
  },

  // Pagination helper
  paginate: (query, page = 1, limit = 20) => {
    const skip = (page - 1) * limit;
    return query.skip(skip).limit(limit);
  },

  // Sort helper
  applySorting: (query, sort = '-createdAt') => {
    return query.sort(sort);
  }
};

/**
 * Memory usage monitoring
 */
const monitorMemoryUsage = () => {
  const usage = process.memoryUsage();
  const cacheStats = memoryCache.getStats();
  
  return {
    process: {
      heapUsed: Math.round(usage.heapUsed / 1024 / 1024) + ' MB',
      heapTotal: Math.round(usage.heapTotal / 1024 / 1024) + ' MB',
      external: Math.round(usage.external / 1024 / 1024) + ' MB',
      rss: Math.round(usage.rss / 1024 / 1024) + ' MB'
    },
    cache: {
      keys: cacheStats.keys,
      hits: cacheStats.hits,
      misses: cacheStats.misses,
      hitRate: cacheStats.hits > 0 ? Math.round((cacheStats.hits / (cacheStats.hits + cacheStats.misses)) * 100) : 0
    }
  };
};

/**
 * Optimize JSON responses
 */
const optimizeJsonResponse = (req, res, next) => {
  const originalJson = res.json;
  
  res.json = function(data) {
    // Remove null values and empty arrays/objects to reduce payload size
    if (typeof data === 'object' && data !== null) {
      data = removeEmpty(data);
    }
    
    // Set appropriate content type
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    
    return originalJson.call(this, data);
  };
  
  next();
};

/**
 * Remove empty values from objects to reduce response size
 */
const removeEmpty = (obj, seen = new WeakSet()) => {
  // Prevent circular references
  if (obj && typeof obj === 'object' && seen.has(obj)) {
    return obj;
  }
  
  if (Array.isArray(obj)) {
    // Skip Mongoose arrays to avoid circular references
    if (obj.constructor.name === 'MongooseDocumentArray' || obj.isMongooseArray) {
      return obj;
    }
    
    if (obj && typeof obj === 'object') {
      seen.add(obj);
    }
    
    const filtered = obj.map(item => removeEmpty(item, seen)).filter(item => 
      item !== null && 
      item !== undefined && 
      item !== '' &&
      !(Array.isArray(item) && item.length === 0) &&
      !(typeof item === 'object' && Object.keys(item).length === 0)
    );
    
    if (obj && typeof obj === 'object') {
      seen.delete(obj);
    }
    
    return filtered;
  }
  
  if (obj && typeof obj === 'object') {
    // Skip Mongoose documents to avoid circular references
    if (obj.constructor.name === 'model' || obj.$__ || obj._id) {
      return obj;
    }
    
    seen.add(obj);
    
    const cleaned = {};
    Object.keys(obj).forEach(key => {
      const value = removeEmpty(obj[key], seen);
      if (
        value !== null && 
        value !== undefined && 
        value !== '' &&
        !(Array.isArray(value) && value.length === 0) &&
        !(typeof value === 'object' && Object.keys(value).length === 0)
      ) {
        cleaned[key] = value;
      }
    });
    
    seen.delete(obj);
    return cleaned;
  }
  
  return obj;
};

module.exports = {
  performanceMiddleware,
  createCacheMiddleware,
  cacheUtils,
  dbOptimization,
  monitorMemoryUsage,
  optimizeJsonResponse,
  memoryCache
};
