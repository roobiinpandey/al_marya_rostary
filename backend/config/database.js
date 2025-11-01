const mongoose = require('mongoose');

/**
 * Secure MongoDB connection with optimized settings for production
 */
const connectDB = async () => {
  try {
    console.log('🔌 Connecting to MongoDB...');
    
    // Check if we're using local MongoDB or Atlas
    const isLocalMongo = process.env.MONGODB_URI.includes('localhost') || process.env.MONGODB_URI.includes('127.0.0.1');
    
    const connectionOptions = {
      // ⚡ OPTIMIZED CONNECTION POOLING
      maxPoolSize: isLocalMongo ? 10 : 50, // Reduce for local development
      minPoolSize: isLocalMongo ? 2 : 10, // Reduce for local development
      maxIdleTimeMS: 30000, // Close idle connections after 30 seconds
      
      // ⚡ OPTIMIZED TIMEOUT SETTINGS
      serverSelectionTimeoutMS: 5000, // 5 seconds for server selection
      socketTimeoutMS: 30000, // Reduced from 45s to 30s for faster failure detection
      connectTimeoutMS: 10000, // 10 seconds for initial connection
      
      // ⚡ CONNECTION RETRY SETTINGS
      retryWrites: true,
      retryReads: true,
      
      // ⚡ WRITE CONCERN - balanced for performance and consistency
      w: 'majority',
      journal: true,
      wtimeoutMS: 5000, // Write timeout of 5 seconds
    };

    // Add production-specific options only for Atlas connections
    if (!isLocalMongo) {
      connectionOptions.compressors = ['zlib'];
      connectionOptions.zlibCompressionLevel = 6;
      connectionOptions.readPreference = 'secondaryPreferred';
      connectionOptions.maxStalenessSeconds = 90;
      connectionOptions.ssl = true;
      connectionOptions.authSource = 'admin';
      connectionOptions.heartbeatFrequencyMS = 10000;
      connectionOptions.minHeartbeatFrequencyMS = 5000;
    }

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
 * Helper function to create indexes safely (ignore if already exists)
 */
const createIndexSafely = async (collection, indexSpec, options = {}) => {
  try {
    await collection.createIndex(indexSpec, options);
  } catch (error) {
    // Ignore index already exists errors
    if (error.code !== 85 && !error.message.includes('already exists')) {
      console.warn(`⚠️  Index creation warning: ${error.message}`);
    }
  }
};

/**
 * Create optimized database indexes for better performance
 */
const createOptimizedIndexes = async () => {
  try {
    console.log('🗂️ Creating database indexes...');
    
    const collections = await mongoose.connection.db.listCollections().toArray();
    const collectionNames = collections.map(collection => collection.name);

    // User collection indexes
    if (collectionNames.includes('users')) {
      const userCollection = mongoose.connection.db.collection('users');
      
      // Check and handle existing email index
      try {
        const existingIndexes = await userCollection.indexes();
        const emailIndexExists = existingIndexes.some(index => 
          index.key && index.key.email === 1
        );
        
        if (!emailIndexExists) {
          await userCollection.createIndex(
            { email: 1 }, 
            { unique: true, background: true, name: 'email_unique' }
          );
        }
      } catch (indexError) {
        console.log('ℹ️  Email index already exists with different configuration');
      }
      
      // Create other indexes safely
      await createIndexSafely(userCollection, { firebaseUid: 1 }, { sparse: true, background: true, name: 'firebase_uid_sparse' });
      await createIndexSafely(userCollection, { createdAt: -1 }, { background: true, name: 'created_desc' });
      await createIndexSafely(userCollection, { isActive: 1, roles: 1 }, { background: true, name: 'active_roles' });
    }

    // Coffee collection indexes
    if (collectionNames.includes('coffees')) {
      const coffeeCollection = mongoose.connection.db.collection('coffees');
      
      await createIndexSafely(coffeeCollection, { category: 1, isActive: 1 }, { background: true, name: 'category_active' });
      
      // Check if text index already exists before creating
      try {
        const existingIndexes = await coffeeCollection.indexes();
        const textIndexExists = existingIndexes.some(index => 
          index.key && (index.key._fts === 'text' || Object.keys(index.key).some(key => key.includes('text')))
        );
        
        if (!textIndexExists) {
          await coffeeCollection.createIndex(
            { 'nameEn': 'text', 'nameAr': 'text', 'descriptionEn': 'text', 'descriptionAr': 'text' },
            { background: true, name: 'text_search_new' }
          );
        }
      } catch (e) {
        console.log('ℹ️  Text search index already exists with different configuration');
      }
      
      await createIndexSafely(coffeeCollection, { 'variants.price': 1 }, { background: true, name: 'price_range' });
    }

    // Order collection indexes
    if (collectionNames.includes('orders')) {
      const orderCollection = mongoose.connection.db.collection('orders');
      
      await createIndexSafely(orderCollection, { userId: 1, createdAt: -1 }, { background: true, name: 'user_orders' });
      await createIndexSafely(orderCollection, { status: 1, paymentStatus: 1 }, { background: true, name: 'status_payment' });
      await createIndexSafely(orderCollection, { createdAt: -1 }, { background: true, name: 'recent_orders' });
    }

    // Category collection indexes
    if (collectionNames.includes('categories')) {
      const categoryCollection = mongoose.connection.db.collection('categories');
      
      await createIndexSafely(categoryCollection, { displayOrder: 1, isActive: 1 }, { background: true, name: 'display_active' });
    }

    // Admin logs indexes
    if (collectionNames.includes('adminlogs')) {
      const logCollection = mongoose.connection.db.collection('adminlogs');
      
      await createIndexSafely(logCollection, { timestamp: -1 }, { background: true, name: 'timestamp_desc' });
      await createIndexSafely(logCollection, { action: 1, timestamp: -1 }, { background: true, name: 'action_time' });
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
