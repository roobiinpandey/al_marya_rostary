const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
require('dotenv').config();

const app = express();

// Middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'", "'unsafe-inline'", "https://accounts.google.com"],
      scriptSrcAttr: ["'unsafe-inline'"], // Allow inline event handlers (onclick, etc.)
      imgSrc: ["'self'", "data:", "https:", "http://localhost:5001"],
      connectSrc: ["'self'", "http://localhost:5001", "https://*.onrender.com", "https://*.render.com"],
      fontSrc: ["'self'", "https:", "data:"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"],
    },
  },
}));
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files from uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Serve static files from web directory (admin panel)
app.use(express.static(path.join(__dirname, '../web')));

// MongoDB Connection
const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGODB_URI;

    if (!mongoURI) {
      throw new Error('MONGODB_URI environment variable is not set');
    }

    await mongoose.connect(mongoURI, {
      // Removed deprecated options for MongoDB driver 4.0+
    });

    console.log('✅ MongoDB Connected Successfully');
    console.log('📊 Database:', mongoose.connection.db.databaseName);
  } catch (error) {
    console.error('❌ MongoDB Connection Error:', error.message);
    process.exit(1);
  }
};

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

// Health check endpoint for monitoring
app.get('/health', (req, res) => {
  const healthStatus = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    database: {
      status: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
      name: mongoose.connection.db?.databaseName || 'unknown'
    },
    memory: {
      used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024) + ' MB',
      total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024) + ' MB'
    }
  };

  // Return 200 if healthy, 503 if database is down
  const statusCode = mongoose.connection.readyState === 1 ? 200 : 503;
  res.status(statusCode).json(healthStatus);
});

// API Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/coffees', require('./routes/coffees'));
app.use('/api/categories', require('./routes/categories'));
app.use('/api/sliders', require('./routes/sliders'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/newsletters', require('./routes/newsletters'));
app.use('/api/support-tickets', require('./routes/support'));
app.use('/api/feedback', require('./routes/feedback'));
app.use('/api/analytics', require('./routes/analytics'));

// Public settings route (no auth required)
const { getPublicSettings } = require('./controllers/settingsController');
app.get('/api/settings/public', getPublicSettings);

// Admin Routes
app.use('/api/admin', require('./routes/admin'));
app.use('/api/admin/settings', require('./routes/settings'));
app.use('/api/admin/orders', require('./routes/orders'));

// Public Admin Routes (for local development - no auth required)
app.use('/api/public-admin', require('./routes/public-admin'));
app.use('/api/public-admin/orders', require('./routes/public-admin-orders'));
app.use('/api/public-admin/settings', require('./routes/public-admin-settings'));

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    mongodb: mongoose.connection.readyState === 1 ? 'Connected' : 'Disconnected'
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.message : {}
  });
});

// 404 handler - must be last
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'API endpoint not found'
  });
});

const PORT = process.env.PORT || 5001;

// Start server
const startServer = async () => {
  await connectDB();

  app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📱 API available at: http://localhost:${PORT}`);
  });
};

startServer();

module.exports = app;
