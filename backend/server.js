const express = require('express');
const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config();

// Import optimized configurations
const { connectDB } = require('./config/database');
const { securityMiddleware, additionalSecurityHeaders, securityErrorHandler } = require('./config/security');
const { performanceMiddleware, createCacheMiddleware, optimizeJsonResponse } = require('./config/performance');
const { monitoring } = require('./config/monitoring');

const app = express();

console.log('🚀 Starting Al Marya Rostery Server...');

// Initialize monitoring system
monitoring.initializeMiddleware(app);

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

// Serve static files from web directory (admin panel)
app.use(express.static(path.join(__dirname, '../web')));

// Database connection is now handled by the imported connectDB function

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'Qahwat Al Emarat API Server',
    status: 'Running',
    mongodb: mongoose.connection.readyState === 1 ? 'Connected' : 'Disconnected',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
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

// Public settings route (no auth required)
const { getPublicSettings } = require('./controllers/settingsController');
app.get('/api/settings/public', getPublicSettings);

// Admin Routes
app.use('/api/admin', require('./routes/admin'));
app.use('/api/admin/settings', require('./routes/settings'));
app.use('/api/admin/orders', require('./routes/orders'));
app.use('/api/admin/reports', require('./routes/reports'));

// Public Admin Routes (for local development - no auth required)
app.use('/api/public-admin', require('./routes/public-admin'));
app.use('/api/public-admin/orders', require('./routes/public-admin-orders'));
app.use('/api/public-admin/settings', require('./routes/public-admin-settings'));

// Security error handler
app.use(securityErrorHandler);

// 404 handler - must be last
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'API endpoint not found',
    path: req.path,
    method: req.method,
    timestamp: new Date().toISOString()
  });
});

const PORT = process.env.PORT || 10000;

// Production-ready server startup
const startServer = async () => {
  try {
    console.log('🔧 Initializing application...');
    
    // Connect to database with retry logic
    await connectDB();
    
    // Setup graceful shutdown
    monitoring.setupGracefulShutdown();
    
    // Start periodic health checks
    monitoring.startPeriodicHealthChecks();
    
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
