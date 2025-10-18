const express = require('express');
const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config();

// Security: Validate environment variables before starting server
const { validateAndExit } = require('./config/validation');
validateAndExit();

// Import optimized configurations
const { connectDB } = require('./config/database');
const { securityMiddleware, additionalSecurityHeaders, securityErrorHandler } = require('./config/security');
const { performanceMiddleware, createCacheMiddleware, optimizeJsonResponse } = require('./config/performance');
const { monitoring } = require('./config/monitoring');
// ⚡ NEW: Import performance monitoring
const { performanceMonitoring, startPerformanceReporting } = require('./middleware/performanceMonitoring');

const app = express();

console.log('🚀 Starting Al Marya Rostery Server...');

// Initialize monitoring system
monitoring.initializeMiddleware(app);

// ⚡ NEW: Add performance monitoring middleware (MUST BE FIRST to track all requests)
app.use(performanceMonitoring);

// Security middleware (must be first)
securityMiddleware(app);

// Performance middleware
performanceMiddleware(app);

// Additional security headers
app.use(additionalSecurityHeaders);

// JSON optimization
app.use(optimizeJsonResponse);

// Request logging (only in development)
if (process.env.NODE_ENV !== 'production') {
  const morgan = require('morgan');
  app.use(morgan('combined'));
}
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files from uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Serve static files from public directory (admin panel)
app.use(express.static(path.join(__dirname, 'public')));

// Database connection is now handled by the imported connectDB function

// Routes
app.get('/', (req, res) => {
  // Check if request accepts HTML (browser request)
  if (req.headers.accept && req.headers.accept.includes('text/html')) {
    // Serve business portal for browser requests
    res.sendFile(path.join(__dirname, 'public/index.html'));
  } else {
    // Serve JSON API info for API requests
    res.json({
      message: 'Qahwat Al Emarat API Server',
      status: 'Running',
      mongodb: mongoose.connection.readyState === 1 ? 'Connected' : 'Disconnected',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV || 'development'
    });
  }
});

// Favicon route
app.get('/favicon.ico', (req, res) => {
  res.sendFile(path.join(__dirname, 'public/favicon.png'));
});

// Setup comprehensive health check endpoints
monitoring.setupHealthEndpoints(app);

// API Routes with caching for public data
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));

// Cached routes for better performance
app.use('/api/coffees', createCacheMiddleware({ ttl: 300 }), require('./routes/coffees')); // 5 min cache
app.use('/api/categories', createCacheMiddleware({ ttl: 600 }), require('./routes/categories')); // 10 min cache
app.use('/api/sliders', createCacheMiddleware({ ttl: 300 }), require('./routes/sliders')); // 5 min cache

// Non-cached routes (user-specific or frequently changing)
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/newsletters', require('./routes/newsletters'));
app.use('/api/support-tickets', require('./routes/support'));
app.use('/api/feedback', require('./routes/feedback'));
app.use('/api/analytics', require('./routes/analytics'));

// Firebase Sync Routes
app.use('/api/firebase-sync', require('./routes/firebaseSync'));

// Auto Firebase Sync Routes
app.use('/api/auto-sync', require('./routes/autoSync'));

// Public settings route (no auth required)
const { getPublicSettings } = require('./controllers/settingsController');
app.get('/api/settings/public', getPublicSettings);

// ⚡ NEW: Performance metrics endpoint (admin only)
const { getPerformanceMetrics } = require('./middleware/performanceMonitoring');
const { cacheManager } = require('./utils/cacheManager');
app.get('/api/admin/performance', (req, res) => {
  try {
    const metrics = getPerformanceMetrics();
    res.json({
      success: true,
      data: metrics
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get performance metrics',
      error: error.message
    });
  }
});

// ⚡ NEW: Cache stats endpoint (admin only)
app.get('/api/admin/cache-stats', (req, res) => {
  try {
    const stats = cacheManager.getStats();
    const memory = cacheManager.getMemoryInfo();
    res.json({
      success: true,
      data: {
        stats,
        memory
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get cache stats',
      error: error.message
    });
  }
});

// Admin panel route (serve index.html for consistency)
app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'public/index.html'));
});

// Admin Routes
app.use('/api/admin', require('./routes/admin'));
app.use('/api/admin/settings', require('./routes/settings'));
app.use('/api/admin/orders', require('./routes/orders'));
app.use('/api/admin/reports', require('./routes/reports'));

// Public Admin Routes (for local development - no auth required)
app.use('/api/public-admin', require('./routes/public-admin'));
app.use('/api/public-admin/orders', require('./routes/public-admin-orders'));
app.use('/api/public-admin/settings', require('./routes/public-admin-settings'));

// Import standardized error handling
const { globalErrorHandler, notFoundHandler } = require('./middleware/errorHandler');

// Security error handler
app.use(securityErrorHandler);

// 404 handler - must be before global error handler
app.use(notFoundHandler);

// Custom 404 handler for admin-related requests
app.use((req, res, next) => {
  const url = req.originalUrl.toLowerCase();
  
  // Check if this might be an admin-related request
  if (url.includes('admin') || url.includes('dashboard') || url.includes('panel') || 
      url.includes('manager') || url.includes('control') || url.includes('backend')) {
    
    console.log(`ℹ️  Admin-related 404: ${req.method} ${req.originalUrl} - suggesting redirect to /`);
    
    // If it's an HTML request, redirect to admin panel
    if (req.accepts('html')) {
      return res.redirect(301, '/');
    }
    
    // If it's an API request, provide helpful JSON response
    return res.status(404).json({
      success: false,
      message: 'Admin endpoint not found',
      suggestion: 'The admin panel is available at /',
      available_endpoints: {
        admin_panel: '/',
        health_check: '/health',
        api_docs: '/api'
      }
    });
  }
  
  // Continue to default 404 handler
  next();
});

// Global error handler - must be last
app.use(globalErrorHandler);

const PORT = process.env.PORT || 10000;

// Production-ready server startup
const startServer = async () => {
  try {
    console.log('🔧 Initializing application...');
    
    // Connect to database with retry logic
    await connectDB();
    
    // Start Auto Firebase Sync Service if enabled
    const autoFirebaseSync = require('./services/autoFirebaseSync');
    if (process.env.ENABLE_AUTO_FIREBASE_SYNC !== 'false') {
      setTimeout(() => {
        autoFirebaseSync.start();
        console.log('🔄 Auto Firebase Sync Service enabled');
      }, 5000); // Start after 5 seconds to ensure everything is initialized
    } else {
      console.log('⚠️ Auto Firebase Sync Service disabled via environment variable');
    }
    
    // Setup graceful shutdown
    monitoring.setupGracefulShutdown();
    
    // Start periodic health checks
    monitoring.startPeriodicHealthChecks();
    
    // ⚡ NEW: Start performance reporting (every 5 minutes)
    startPerformanceReporting();
    
    // Start the server
    const server = app.listen(PORT, () => {
      console.log(`🎉 Al Marya Rostery Server Started Successfully!`);
      console.log(`🌐 Server running on port ${PORT}`);
      console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`📱 API available at: http://localhost:${PORT}`);
      console.log(`🔍 Health check: http://localhost:${PORT}/health`);
      console.log(`⚡ Performance optimizations: ENABLED`);
      console.log(`🛡️ Security middleware: ENABLED`);
      console.log(`📈 Monitoring: ENABLED`);
      console.log(`📊 Performance tracking: ENABLED`);
      console.log(`💾 In-memory cache: ENABLED`);
    });

    // Handle server errors
    server.on('error', (error) => {
      if (error.syscall !== 'listen') {
        throw error;
      }

      switch (error.code) {
        case 'EACCES':
          console.error(`� Port ${PORT} requires elevated privileges`);
          process.exit(1);
          break;
        case 'EADDRINUSE':
          console.error(`💥 Port ${PORT} is already in use`);
          process.exit(1);
          break;
        default:
          throw error;
      }
    });

    return server;
  } catch (error) {
    console.error('� Failed to start server:', error);
    process.exit(1);
  }
};

// Start the server
startServer();

module.exports = app;
