const mongoose = require('mongoose');
const { getConnectionHealth } = require('./database');
const { monitorMemoryUsage } = require('./performance');

/**
 * Application monitoring and health check system
 */
class MonitoringSystem {
  constructor() {
    this.startTime = Date.now();
    this.requestCount = 0;
    this.errorCount = 0;
    this.slowRequestCount = 0;
    this.lastError = null;
    this.healthStatus = 'healthy';
  }

  /**
   * Initialize monitoring middleware
   */
  initializeMiddleware(app) {
    console.log('📊 Initializing monitoring system...');

    // Request tracking middleware
    app.use((req, res, next) => {
      this.requestCount++;
      
      const startTime = Date.now();
      
      // Track response completion
      res.on('finish', () => {
        const responseTime = Date.now() - startTime;
        
        // Track slow requests (>1 second)
        if (responseTime > 1000) {
          this.slowRequestCount++;
          console.warn(`🐌 Slow request detected: ${req.method} ${req.path} - ${responseTime}ms`);
        }
        
        // Log request details in development
        if (process.env.NODE_ENV !== 'production') {
          console.log(`${req.method} ${req.path} - ${res.statusCode} - ${responseTime}ms`);
        }
      });
      
      next();
    });

    // Error tracking middleware
    app.use((error, req, res, next) => {
      this.errorCount++;
      this.lastError = {
        message: error.message,
        stack: error.stack,
        path: req.path,
        method: req.method,
        timestamp: new Date().toISOString(),
        ip: req.ip
      };

      // Log error details
      console.error('🚨 Application Error:', {
        error: error.message,
        path: req.path,
        method: req.method,
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        timestamp: new Date().toISOString()
      });

      // Update health status on critical errors
      if (error.message.includes('Database') || error.message.includes('ECONNREFUSED')) {
        this.healthStatus = 'unhealthy';
      }

      // Send appropriate error response
      const statusCode = error.status || error.statusCode || 500;
      res.status(statusCode).json({
        success: false,
        message: process.env.NODE_ENV === 'production' 
          ? 'An error occurred while processing your request'
          : error.message,
        timestamp: new Date().toISOString()
      });
    });

    console.log('✅ Monitoring middleware initialized');
  }

  /**
   * Get comprehensive system health status
   */
  async getHealthStatus() {
    try {
      const uptime = Date.now() - this.startTime;
      const memoryStats = monitorMemoryUsage();
      const dbHealth = getConnectionHealth();

      // Check database connection
      let dbStatus = 'connected';
      try {
        await mongoose.connection.db.admin().ping();
      } catch (dbError) {
        dbStatus = 'disconnected';
        this.healthStatus = 'unhealthy';
      }

      // Determine overall health
      let overallHealth = 'healthy';
      const memoryUsageMB = parseInt(memoryStats.process.heapUsed);
      
      if (
        dbStatus !== 'connected' || 
        memoryUsageMB > 400 || // Alert if memory usage > 400MB
        this.errorCount > 100 ||
        this.slowRequestCount > 50
      ) {
        overallHealth = 'degraded';
      }

      if (
        dbStatus === 'disconnected' ||
        memoryUsageMB > 800 || // Critical if memory usage > 800MB
        this.errorCount > 500
      ) {
        overallHealth = 'unhealthy';
      }

      return {
        status: overallHealth,
        timestamp: new Date().toISOString(),
        uptime: {
          milliseconds: uptime,
          seconds: Math.floor(uptime / 1000),
          minutes: Math.floor(uptime / 60000),
          hours: Math.floor(uptime / 3600000)
        },
        system: {
          nodejs: process.version,
          platform: process.platform,
          arch: process.arch,
          pid: process.pid
        },
        memory: memoryStats,
        database: {
          status: dbStatus,
          connectionState: dbHealth.status,
          host: dbHealth.host,
          name: dbHealth.name,
          collections: dbHealth.collections
        },
        metrics: {
          totalRequests: this.requestCount,
          totalErrors: this.errorCount,
          slowRequests: this.slowRequestCount,
          errorRate: this.requestCount > 0 ? Math.round((this.errorCount / this.requestCount) * 100) : 0
        },
        lastError: this.lastError
      };
    } catch (error) {
      console.error('Health check error:', error);
      return {
        status: 'unhealthy',
        error: 'Health check failed',
        timestamp: new Date().toISOString()
      };
    }
  }

  /**
   * Get system metrics for monitoring
   */
  getMetrics() {
    const uptime = Date.now() - this.startTime;
    
    return {
      uptime_seconds: Math.floor(uptime / 1000),
      total_requests: this.requestCount,
      total_errors: this.errorCount,
      slow_requests: this.slowRequestCount,
      error_rate: this.requestCount > 0 ? (this.errorCount / this.requestCount) : 0,
      memory_usage_mb: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
      timestamp: Date.now()
    };
  }

  /**
   * Reset metrics (useful for testing)
   */
  resetMetrics() {
    this.requestCount = 0;
    this.errorCount = 0;
    this.slowRequestCount = 0;
    this.lastError = null;
    this.healthStatus = 'healthy';
  }

  /**
   * Setup health check endpoints
   */
  setupHealthEndpoints(app) {
    // Basic health check
    app.get('/health', async (req, res) => {
      const health = await this.getHealthStatus();
      const statusCode = health.status === 'healthy' ? 200 : 
                        health.status === 'degraded' ? 200 : 503;
      
      res.status(statusCode).json(health);
    });

    // Detailed health check
    app.get('/api/health', async (req, res) => {
      const health = await this.getHealthStatus();
      const statusCode = health.status === 'healthy' ? 200 : 
                        health.status === 'degraded' ? 200 : 503;
      
      res.status(statusCode).json({
        success: health.status !== 'unhealthy',
        data: health
      });
    });

    // Metrics endpoint (for monitoring tools)
    app.get('/api/metrics', (req, res) => {
      res.json({
        success: true,
        data: this.getMetrics()
      });
    });

    // Readiness probe (for container orchestration)
    app.get('/ready', async (req, res) => {
      try {
        await mongoose.connection.db.admin().ping();
        res.status(200).json({ status: 'ready' });
      } catch (error) {
        res.status(503).json({ status: 'not ready', error: error.message });
      }
    });

    // Liveness probe (for container orchestration)
    app.get('/alive', (req, res) => {
      res.status(200).json({ 
        status: 'alive',
        timestamp: new Date().toISOString(),
        uptime: Date.now() - this.startTime
      });
    });

    console.log('✅ Health check endpoints configured');
  }

  /**
   * Setup periodic health checks
   */
  startPeriodicHealthChecks() {
    // Check health every 5 minutes
    setInterval(async () => {
      const health = await this.getHealthStatus();
      
      if (health.status === 'unhealthy') {
        console.error('🚨 System health check failed:', health);
      } else if (health.status === 'degraded') {
        console.warn('⚠️ System performance degraded:', health);
      }
    }, 5 * 60 * 1000);

    console.log('✅ Periodic health checks started');
  }

  /**
   * Setup graceful shutdown
   */
  setupGracefulShutdown() {
    const gracefulShutdown = async (signal) => {
      console.log(`\n📴 Received ${signal}. Starting graceful shutdown...`);
      
      try {
        // Close database connection
        await mongoose.connection.close();
        console.log('✅ Database connection closed');
        
        // Add any other cleanup tasks here
        
        console.log('✅ Graceful shutdown completed');
        process.exit(0);
      } catch (error) {
        console.error('❌ Error during graceful shutdown:', error);
        process.exit(1);
      }
    };

    // Handle various shutdown signals
    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));
    process.on('SIGUSR1', () => gracefulShutdown('SIGUSR1'));
    process.on('SIGUSR2', () => gracefulShutdown('SIGUSR2'));

    // Handle uncaught exceptions
    process.on('uncaughtException', (error) => {
      console.error('💥 Uncaught Exception:', error);
      gracefulShutdown('uncaughtException');
    });

    // Handle unhandled promise rejections
    process.on('unhandledRejection', (reason, promise) => {
      console.error('💥 Unhandled Rejection at:', promise, 'reason:', reason);
      gracefulShutdown('unhandledRejection');
    });

    console.log('✅ Graceful shutdown handlers configured');
  }
}

// Create singleton instance
const monitoring = new MonitoringSystem();

module.exports = {
  MonitoringSystem,
  monitoring
};
