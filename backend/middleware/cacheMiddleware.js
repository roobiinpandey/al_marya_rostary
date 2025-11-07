/**
 * ⚡ CACHE MIDDLEWARE
 * 
 * Express middleware for automatic response caching
 * Works with the CacheManager utility
 */

const { cacheManager, CACHE_TTL } = require('../utils/cacheManager');

/**
 * Cache middleware - automatically caches GET request responses
 * 
 * @param {string} namespace - Cache namespace (e.g., 'api', 'dashboard')
 * @param {number} ttl - Time to live in seconds
 * @param {Function} keyGenerator - Optional custom key generator function
 * 
 * Usage:
 *   router.get('/dashboard', cache('dashboard', 60), getDashboard);
 *   router.get('/user/:id', cache('user', 300, (req) => req.params.id), getUser);
 */
const cache = (namespace, ttl = CACHE_TTL.MEDIUM, keyGenerator = null) => {
  return (req, res, next) => {
    // Only cache GET requests
    if (req.method !== 'GET') {
      return next();
    }

    // Generate cache key
    const cacheKey = keyGenerator 
      ? keyGenerator(req)
      : `${req.originalUrl || req.url}`;

    // Try to get from cache
    const cachedResponse = cacheManager.get(namespace, cacheKey);
    
    if (cachedResponse) {
      // Cache hit - return cached response
      console.log(`⚡ Cache HIT: ${namespace}:${cacheKey}`);
      return res.json(cachedResponse);
    }

    // Cache miss - continue to route handler
    console.log(`💾 Cache MISS: ${namespace}:${cacheKey}`);

    // Store original res.json function
    const originalJson = res.json.bind(res);

    // Override res.json to cache the response
    res.json = (body) => {
      // Only cache successful responses
      if (res.statusCode >= 200 && res.statusCode < 300) {
        cacheManager.set(namespace, cacheKey, body, ttl);
      }
      return originalJson(body);
    };

    next();
  };
};

/**
 * Invalidate cache for a namespace
 * Can be used in mutation routes (POST, PUT, DELETE)
 * 
 * Usage:
 *   router.post('/products', invalidateCache('product'), createProduct);
 */
const invalidateCache = (...namespaces) => {
  return (req, res, next) => {
    // Store original res.json to add cache invalidation
    const originalJson = res.json.bind(res);

    res.json = (body) => {
      // Only invalidate on successful mutations
      if (res.statusCode >= 200 && res.statusCode < 300) {
        namespaces.forEach(namespace => {
          const count = cacheManager.deleteNamespace(namespace);
          console.log(`🗑️ Invalidated ${count} entries from ${namespace} cache`);
        });
      }
      return originalJson(body);
    };

    next();
  };
};

/**
 * Cache statistics middleware
 * Adds cache stats to response headers (for debugging)
 */
const cacheStats = (req, res, next) => {
  const stats = cacheManager.getStats();
  res.setHeader('X-Cache-Hit-Rate', stats.hitRate);
  res.setHeader('X-Cache-Size', stats.size);
  next();
};

module.exports = {
  cache,
  invalidateCache,
  cacheStats
};
