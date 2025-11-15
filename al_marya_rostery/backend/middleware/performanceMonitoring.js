/**
 * ⚡ PERFORMANCE MONITORING MIDDLEWARE
 * 
 * Features:
 * - Request duration tracking
 * - Slow request detection and logging
 * - Database query time monitoring
 * - Memory usage tracking
 * - Performance metrics collection
 */

const { cacheManager } = require('../utils/cacheManager');

// Performance thresholds (in milliseconds)
const THRESHOLDS = {
  SLOW_REQUEST: 1000,      // Warn if request > 1 second
  VERY_SLOW_REQUEST: 3000, // Alert if request > 3 seconds
  CRITICAL_REQUEST: 5000   // Critical if request > 5 seconds
};

// Performance metrics storage
const metrics = {
  totalRequests: 0,
  slowRequests: 0,
  verySlowRequests: 0,
  criticalRequests: 0,
  averageResponseTime: 0,
  totalResponseTime: 0,
  requestsByEndpoint: new Map(),
  slowestRequests: [] // Keep track of 10 slowest requests
};

/**
 * Performance monitoring middleware
 */
const performanceMonitoring = (req, res, next) => {
  const startTime = Date.now();
  const startMemory = process.memoryUsage();
  
  // Store original end function
  const originalEnd = res.end;
  
  // Override end function to capture response time
  res.end = function(...args) {
    const duration = Date.now() - startTime;
    const endMemory = process.memoryUsage();
    const memoryDelta = {
      rss: ((endMemory.rss - startMemory.rss) / 1024 / 1024).toFixed(2),
      heapUsed: ((endMemory.heapUsed - startMemory.heapUsed) / 1024 / 1024).toFixed(2)
    };
    
    // Update metrics
    updateMetrics(req, res, duration, memoryDelta);
    
    // Log slow requests
    logSlowRequest(req, res, duration, memoryDelta);
    
    // Call original end function
    originalEnd.apply(res, args);
  };
  
  next();
};

/**
 * Update performance metrics
 */
const updateMetrics = (req, res, duration, memoryDelta) => {
  metrics.totalRequests++;
  metrics.totalResponseTime += duration;
  metrics.averageResponseTime = (metrics.totalResponseTime / metrics.totalRequests).toFixed(2);
  
  // Count slow requests
  if (duration > THRESHOLDS.CRITICAL_REQUEST) {
    metrics.criticalRequests++;
  } else if (duration > THRESHOLDS.VERY_SLOW_REQUEST) {
    metrics.verySlowRequests++;
  } else if (duration > THRESHOLDS.SLOW_REQUEST) {
    metrics.slowRequests++;
  }
  
  // Track by endpoint
  const endpoint = `${req.method} ${req.path}`;
  if (!metrics.requestsByEndpoint.has(endpoint)) {
    metrics.requestsByEndpoint.set(endpoint, {
      count: 0,
      totalTime: 0,
      avgTime: 0,
      minTime: duration,
      maxTime: duration
    });
  }
  
  const endpointStats = metrics.requestsByEndpoint.get(endpoint);
  endpointStats.count++;
  endpointStats.totalTime += duration;
  endpointStats.avgTime = (endpointStats.totalTime / endpointStats.count).toFixed(2);
  endpointStats.minTime = Math.min(endpointStats.minTime, duration);
  endpointStats.maxTime = Math.max(endpointStats.maxTime, duration);
  
  // Track slowest requests (keep top 10)
  if (duration > THRESHOLDS.SLOW_REQUEST) {
    metrics.slowestRequests.push({
      method: req.method,
      path: req.path,
      duration,
      timestamp: new Date().toISOString(),
      statusCode: res.statusCode,
      memoryDelta
    });
    
    // Keep only top 10 slowest
    metrics.slowestRequests.sort((a, b) => b.duration - a.duration);
    if (metrics.slowestRequests.length > 10) {
      metrics.slowestRequests = metrics.slowestRequests.slice(0, 10);
    }
  }
};

/**
 * Log slow requests with detailed information
 */
const logSlowRequest = (req, res, duration, memoryDelta) => {
  const endpoint = `${req.method} ${req.path}`;
  
  if (duration > THRESHOLDS.CRITICAL_REQUEST) {
    console.error(`🚨 CRITICAL SLOW REQUEST (${duration}ms): ${endpoint}`);
    console.error(`   Status: ${res.statusCode}`);
    console.error(`   Memory: RSS +${memoryDelta.rss}MB, Heap +${memoryDelta.heapUsed}MB`);
    console.error(`   User: ${req.user?.id || 'Guest'}`);
    console.error(`   Query: ${JSON.stringify(req.query)}`);
  } else if (duration > THRESHOLDS.VERY_SLOW_REQUEST) {
    console.warn(`⚠️  VERY SLOW REQUEST (${duration}ms): ${endpoint}`);
    console.warn(`   Status: ${res.statusCode}`);
    console.warn(`   Memory: RSS +${memoryDelta.rss}MB, Heap +${memoryDelta.heapUsed}MB`);
  } else if (duration > THRESHOLDS.SLOW_REQUEST) {
    console.warn(`⏱️  Slow request (${duration}ms): ${endpoint}`);
  }
};

/**
 * Get performance metrics
 */
const getPerformanceMetrics = () => {
  const cacheStats = cacheManager.getStats();
  const cacheMemory = cacheManager.getMemoryInfo();
  const processMemory = process.memoryUsage();
  
  // Convert endpoint Map to array for JSON serialization
  const endpointStats = Array.from(metrics.requestsByEndpoint.entries()).map(([endpoint, stats]) => ({
    endpoint,
    ...stats
  }));
  
  // Sort by average time (slowest first)
  endpointStats.sort((a, b) => parseFloat(b.avgTime) - parseFloat(a.avgTime));
  
  return {
    requests: {
      total: metrics.totalRequests,
      slow: metrics.slowRequests,
      verySlow: metrics.verySlowRequests,
      critical: metrics.criticalRequests,
      slowPercentage: ((metrics.slowRequests / metrics.totalRequests) * 100).toFixed(2),
      averageResponseTime: `${metrics.averageResponseTime}ms`
    },
    cache: {
      ...cacheStats,
      memory: cacheMemory
    },
    memory: {
      rss: `${(processMemory.rss / 1024 / 1024).toFixed(2)}MB`,
      heapUsed: `${(processMemory.heapUsed / 1024 / 1024).toFixed(2)}MB`,
      heapTotal: `${(processMemory.heapTotal / 1024 / 1024).toFixed(2)}MB`,
      external: `${(processMemory.external / 1024 / 1024).toFixed(2)}MB`
    },
    endpoints: {
      total: endpointStats.length,
      slowest: endpointStats.slice(0, 10),
      all: endpointStats
    },
    slowestRequests: metrics.slowestRequests,
    uptime: `${(process.uptime() / 60).toFixed(2)} minutes`
  };
};

/**
 * Reset performance metrics
 */
const resetPerformanceMetrics = () => {
  metrics.totalRequests = 0;
  metrics.slowRequests = 0;
  metrics.verySlowRequests = 0;
  metrics.criticalRequests = 0;
  metrics.averageResponseTime = 0;
  metrics.totalResponseTime = 0;
  metrics.requestsByEndpoint.clear();
  metrics.slowestRequests = [];
  
  console.log('📊 Performance metrics reset');
};

/**
 * Mongoose query performance monitoring
 * Usage: await User.find().setOptions({ enableQueryLogging: true })
 */
const setupQueryMonitoring = (mongoose) => {
  // Hook into mongoose query execution
  mongoose.set('debug', (collectionName, methodName, ...methodArgs) => {
    const query = JSON.stringify(methodArgs[0] || {});
    console.log(`🔍 DB Query: ${collectionName}.${methodName}(${query})`);
  });
};

/**
 * Database query time wrapper
 * Wraps a database query to measure execution time
 */
const measureQuery = async (queryName, queryFn) => {
  const startTime = Date.now();
  
  try {
    const result = await queryFn();
    const duration = Date.now() - startTime;
    
    if (duration > 1000) {
      console.warn(`⚠️  Slow DB query "${queryName}": ${duration}ms`);
    } else if (duration > 500) {
      console.log(`⏱️  DB query "${queryName}": ${duration}ms`);
    }
    
    return result;
  } catch (error) {
    const duration = Date.now() - startTime;
    console.error(`❌ DB query "${queryName}" failed after ${duration}ms:`, error.message);
    throw error;
  }
};

/**
 * Express route performance wrapper
 * Usage: router.get('/users', measureRoute('getUsers', async (req, res) => { ... }))
 */
const measureRoute = (routeName, handler) => {
  return async (req, res, next) => {
    const startTime = Date.now();
    
    try {
      await handler(req, res, next);
      
      const duration = Date.now() - startTime;
      if (duration > THRESHOLDS.SLOW_REQUEST) {
        console.warn(`⚠️  Slow route "${routeName}": ${duration}ms`);
      }
    } catch (error) {
      const duration = Date.now() - startTime;
      console.error(`❌ Route "${routeName}" error after ${duration}ms:`, error.message);
      throw error;
    }
  };
};

/**
 * Periodic performance reporting (every 5 minutes)
 */
let reportingInterval;
const startPerformanceReporting = () => {
  reportingInterval = setInterval(() => {
    const metrics = getPerformanceMetrics();
    
    console.log('\n📊 === PERFORMANCE REPORT ===');
    console.log(`   Total Requests: ${metrics.requests.total}`);
    console.log(`   Avg Response Time: ${metrics.requests.averageResponseTime}`);
    console.log(`   Slow Requests: ${metrics.requests.slow} (${metrics.requests.slowPercentage}%)`);
    console.log(`   Cache Hit Rate: ${metrics.cache.hitRate}`);
    console.log(`   Memory Usage: ${metrics.memory.heapUsed} / ${metrics.memory.heapTotal}`);
    
    if (metrics.endpoints.slowest.length > 0) {
      console.log('\n   Slowest Endpoints:');
      metrics.endpoints.slowest.slice(0, 5).forEach((endpoint, i) => {
        console.log(`   ${i + 1}. ${endpoint.endpoint}: ${endpoint.avgTime}ms avg (${endpoint.count} requests)`);
      });
    }
    
    console.log('===========================\n');
  }, 5 * 60 * 1000); // Every 5 minutes
};

const stopPerformanceReporting = () => {
  if (reportingInterval) {
    clearInterval(reportingInterval);
  }
};

// Graceful shutdown
process.on('SIGTERM', stopPerformanceReporting);
process.on('SIGINT', stopPerformanceReporting);

module.exports = {
  performanceMonitoring,
  getPerformanceMetrics,
  resetPerformanceMetrics,
  setupQueryMonitoring,
  measureQuery,
  measureRoute,
  startPerformanceReporting,
  stopPerformanceReporting,
  THRESHOLDS
};
