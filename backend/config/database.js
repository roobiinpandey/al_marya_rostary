const mongoose = require('mongoose');

/**
 * Secure MongoDB connection with optimized settings for production
 */
const connectDB = async () => {
  try {
    console.log('🔌 Connecting to MongoDB...');
    
    const connectionOptions = {
      // Performance optimizations
      maxPoolSize: 10, // Maintain up to 10 socket connections
      serverSelectionTimeoutMS: 5000, // Keep trying to send operations for 5 seconds
      socketTimeoutMS: 45000, // Close sockets after 45 seconds of inactivity
      // Disable mongoose buffering for better error handling
      // Note: bufferMaxEntries and bufferCommands are mongoose options, not MongoDB driver options
      
      // Connection compression for better performance
      compressors: ['zlib'],
      zlibCompressionLevel: 6,
      
      // Read preferences for better performance
      readPreference: 'secondaryPreferred',
      
      // Write concern for consistency vs performance balance
      w: 'majority',
      journal: true, // Journal acknowledgment (updated from deprecated 'j' option)
      
      // Connection retry settings
      retryWrites: true,
      retryReads: true,
      
      // SSL/TLS settings for security
      ssl: true,
      authSource: 'admin'
    };

    // Configure mongoose settings for better performance
    mongoose.set('strictQuery', false);
    
    const conn = await mongoose.connect(process.env.MONGODB_URI, connectionOptions);
    
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
    
    // Setup connection event handlers
    setupConnectionHandlers();
    
    // Create optimized indexes
    await createOptimizedIndexes();
    
    return conn;
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    
    // In production, we should gracefully handle connection failures
    if (process.env.NODE_ENV === 'production') {
      console.error('💥 Critical: Database connection failed in production');
      setTimeout(() => {
        console.log('🔄 Retrying database connection...');
        connectDB();
      }, 5000);
    } else {
      process.exit(1);
    }
  }
};

/**
 * Setup MongoDB connection event handlers
 */
const setupConnectionHandlers = () => {
  // Connection events
  mongoose.connection.on('connected', () => {
    console.log('📡 MongoDB connection established');
  });

  mongoose.connection.on('error', (err) => {
    console.error('🚨 MongoDB connection error:', err);
  });

  mongoose.connection.on('disconnected', () => {
    console.log('📴 MongoDB disconnected');
  });

  mongoose.connection.on('reconnected', () => {
    console.log('🔄 MongoDB reconnected');
  });

  // Handle application termination
  process.on('SIGINT', async () => {
    try {
      await mongoose.connection.close();
      console.log('🔒 MongoDB connection closed through app termination');
      process.exit(0);
    } catch (err) {
      console.error('Error closing MongoDB connection:', err);
      process.exit(1);
    }
  });
};

/**
 * Create optimized database indexes for better performance
 */
const createOptimizedIndexes = async () => {
  try {
    console.log('🗂️ Creating database indexes...');
    
    const collections = mongoose.connection.db.listCollections();
    const collectionNames = [];
    
    await collections.forEach(collection => {
      collectionNames.push(collection.name);
    });

    // User collection indexes
    if (collectionNames.includes('users')) {
      const userCollection = mongoose.connection.db.collection('users');
      
      await userCollection.createIndex(
        { email: 1 }, 
        { unique: true, background: true, name: 'email_unique' }
      );
      
      await userCollection.createIndex(
        { firebaseUid: 1 }, 
        { sparse: true, background: true, name: 'firebase_uid_sparse' }
      );
      
      await userCollection.createIndex(
        { createdAt: -1 }, 
        { background: true, name: 'created_desc' }
      );
      
      await userCollection.createIndex(
        { isActive: 1, roles: 1 }, 
        { background: true, name: 'active_roles' }
      );
    }

    // Coffee collection indexes
    if (collectionNames.includes('coffees')) {
      const coffeeCollection = mongoose.connection.db.collection('coffees');
      
      await coffeeCollection.createIndex(
        { category: 1, isActive: 1 }, 
        { background: true, name: 'category_active' }
      );
      
      await coffeeCollection.createIndex(
        { 'nameEn': 'text', 'nameAr': 'text', 'descriptionEn': 'text', 'descriptionAr': 'text' },
        { background: true, name: 'text_search' }
      );
      
      await coffeeCollection.createIndex(
        { 'variants.price': 1 }, 
        { background: true, name: 'price_range' }
      );
    }

    // Order collection indexes
    if (collectionNames.includes('orders')) {
      const orderCollection = mongoose.connection.db.collection('orders');
      
      await orderCollection.createIndex(
        { userId: 1, createdAt: -1 }, 
        { background: true, name: 'user_orders' }
      );
      
      await orderCollection.createIndex(
        { status: 1, paymentStatus: 1 }, 
        { background: true, name: 'status_payment' }
      );
      
      await orderCollection.createIndex(
        { createdAt: -1 }, 
        { background: true, name: 'recent_orders' }
      );
    }

    // Category collection indexes
    if (collectionNames.includes('categories')) {
      const categoryCollection = mongoose.connection.db.collection('categories');
      
      await categoryCollection.createIndex(
        { displayOrder: 1, isActive: 1 }, 
        { background: true, name: 'display_active' }
      );
    }

    // Admin logs indexes
    if (collectionNames.includes('adminlogs')) {
      const logCollection = mongoose.connection.db.collection('adminlogs');
      
      await logCollection.createIndex(
        { timestamp: -1 }, 
        { background: true, name: 'timestamp_desc' }
      );
      
      await logCollection.createIndex(
        { action: 1, timestamp: -1 }, 
        { background: true, name: 'action_time' }
      );
    }

    console.log('✅ Database indexes created successfully');
  } catch (error) {
    console.error('❌ Error creating indexes:', error.message);
    // Don't fail the connection for index creation errors
  }
};

/**
 * Get database connection health status
 */
const getConnectionHealth = () => {
  const state = mongoose.connection.readyState;
  const states = {
    0: 'disconnected',
    1: 'connected',
    2: 'connecting',
    3: 'disconnecting'
  };
  
  return {
    status: states[state] || 'unknown',
    host: mongoose.connection.host,
    name: mongoose.connection.name,
    collections: mongoose.connection.db ? Object.keys(mongoose.connection.collections).length : 0
  };
};

module.exports = { 
  connectDB, 
  getConnectionHealth,
  createOptimizedIndexes 
};
