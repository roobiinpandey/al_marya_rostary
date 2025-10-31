#!/usr/bin/env node

/**
 * Database Performance Monitor
 * 
 * This script continuously monitors your database performance,
 * identifies slow queries, and provides optimization recommendations.
 */

const mongoose = require('mongoose');
require('dotenv').config();

class DatabaseMonitor {
  constructor() {
    this.slowQueryThreshold = 100; // milliseconds
    this.monitoringInterval = 30000; // 30 seconds
    this.isMonitoring = false;
  }

  async connect() {
    try {
      await mongoose.connect(process.env.MONGODB_URI, {
        // Enable query profiling
        maxPoolSize: 10,
        serverSelectionTimeoutMS: 5000,
        socketTimeoutMS: 45000
      });
      
      console.log('✅ Connected to MongoDB for monitoring');
      return true;
    } catch (error) {
      console.error('❌ Failed to connect to MongoDB:', error.message);
      return false;
    }
  }

  async startMonitoring() {
    if (!await this.connect()) {
      return;
    }

    console.log('🔍 Starting Database Performance Monitoring...');
    console.log('================================================');
    
    this.isMonitoring = true;
    
    // Initial performance snapshot
    await this.performanceSnapshot();
    
    // Start continuous monitoring
    this.monitoringTimer = setInterval(async () => {
      if (this.isMonitoring) {
        await this.checkPerformanceMetrics();
      }
    }, this.monitoringInterval);
    
    // Monitor slow operations
    await this.enableSlowQueryProfiling();
    
    console.log(`📊 Monitoring active (checking every ${this.monitoringInterval/1000}s)`);
    console.log('Press Ctrl+C to stop monitoring\n');
  }

  async performanceSnapshot() {
    console.log('📸 Performance Snapshot:', new Date().toISOString());
    console.log('─'.repeat(50));
    
    try {
      const db = mongoose.connection.db;
      
      // Database stats
      const dbStats = await db.stats();
      console.log(`📄 Total Documents: ${dbStats.objects?.toLocaleString() || 'N/A'}`);
      console.log(`💾 Database Size: ${(dbStats.dataSize / 1024 / 1024).toFixed(2)} MB`);
      console.log(`🗂️  Index Size: ${(dbStats.indexSize / 1024 / 1024).toFixed(2)} MB`);
      console.log(`🔗 Active Connections: ${dbStats.connections || 'N/A'}`);
      
      // Collection-specific stats
      const collections = ['users', 'orders', 'coffees', 'userfeedbacks', 'loyaltyaccounts'];
      
      for (const collectionName of collections) {
        try {
          const collection = db.collection(collectionName);
          const stats = await collection.stats();
          const indexes = await collection.indexes();
          
          console.log(`\n📋 ${collectionName.toUpperCase()}:`);
          console.log(`   📄 Documents: ${stats.count?.toLocaleString() || 0}`);
          console.log(`   💾 Size: ${(stats.size / 1024).toFixed(1)} KB`);
          console.log(`   🗂️  Indexes: ${indexes.length}`);
          
          // Check for potential issues
          if (stats.count > 10000 && indexes.length < 3) {
            console.log(`   ⚠️  Large collection with few indexes - consider optimization`);
          }
          
          if (stats.totalIndexSize > stats.size) {
            console.log(`   ⚠️  Index size exceeds data size - check for over-indexing`);
          }
          
        } catch (error) {
          console.log(`   ❌ Could not get stats for ${collectionName}`);
        }
      }
      
    } catch (error) {
      console.error('❌ Failed to get performance snapshot:', error.message);
    }
    
    console.log('─'.repeat(50));
  }

  async checkPerformanceMetrics() {
    try {
      const db = mongoose.connection.db;
      
      // Get current operations
      const currentOps = await db.admin().command({ currentOp: true });
      
      // Check for slow operations
      const slowOps = currentOps.inprog.filter(op => 
        op.secs_running > this.slowQueryThreshold / 1000
      );
      
      if (slowOps.length > 0) {
        console.log(`⚠️  Detected ${slowOps.length} slow operations:`);
        slowOps.forEach(op => {
          console.log(`   - ${op.command?.collection || 'unknown'}: ${op.secs_running}s`);
        });
      }
      
      // Check connection pool status
      const connectionStats = await this.getConnectionStats();
      if (connectionStats.available < 5) {
        console.log(`⚠️  Low connection pool availability: ${connectionStats.available}`);
      }
      
    } catch (error) {
      console.error('❌ Performance check failed:', error.message);
    }
  }

  async enableSlowQueryProfiling() {
    try {
      const db = mongoose.connection.db;
      
      // Enable profiling for slow operations
      await db.admin().command({
        profile: 2, // Profile all operations
        slowms: this.slowQueryThreshold
      });
      
      console.log('🔍 Slow query profiling enabled');
      
    } catch (error) {
      console.warn('⚠️  Could not enable profiling:', error.message);
    }
  }

  async getConnectionStats() {
    try {
      const db = mongoose.connection.db;
      const serverStatus = await db.admin().command({ serverStatus: 1 });
      
      return {
        current: serverStatus.connections?.current || 0,
        available: serverStatus.connections?.available || 0,
        totalCreated: serverStatus.connections?.totalCreated || 0
      };
    } catch (error) {
      return { current: 0, available: 0, totalCreated: 0 };
    }
  }

  async getSlowQueries() {
    try {
      const db = mongoose.connection.db;
      const profileData = await db.collection('system.profile')
        .find({})
        .sort({ ts: -1 })
        .limit(10)
        .toArray();
      
      if (profileData.length > 0) {
        console.log('\n🐌 Recent Slow Queries:');
        profileData.forEach(query => {
          console.log(`   - ${query.command?.collection || 'unknown'}: ${query.millis}ms`);
          if (query.command) {
            console.log(`     Command: ${JSON.stringify(query.command).substring(0, 100)}...`);
          }
        });
      }
      
    } catch (error) {
      // system.profile collection might not exist
      console.log('ℹ️  No profiling data available');
    }
  }

  async generateOptimizationReport() {
    console.log('\n📈 OPTIMIZATION RECOMMENDATIONS');
    console.log('================================');
    
    try {
      const db = mongoose.connection.db;
      
      // Check for missing indexes
      console.log('🔍 Index Analysis:');
      
      const collections = ['users', 'orders', 'coffees', 'userfeedbacks'];
      
      for (const collectionName of collections) {
        const collection = db.collection(collectionName);
        const indexes = await collection.indexes();
        const stats = await collection.stats();
        
        console.log(`\n📋 ${collectionName}:`);
        
        // Recommend indexes based on collection size and current indexes
        if (stats.count > 1000 && indexes.length < 3) {
          console.log(`   💡 Consider adding indexes - large collection with minimal indexing`);
        }
        
        // Check for unused indexes (this would require query analysis)
        if (indexes.length > 8) {
          console.log(`   ⚠️  Many indexes detected - verify all are necessary`);
        }
      }
      
      // Memory recommendations
      const dbStats = await db.stats();
      const indexToDataRatio = dbStats.indexSize / dbStats.dataSize;
      
      console.log('\n💾 Memory Analysis:');
      if (indexToDataRatio > 0.5) {
        console.log('   ⚠️  High index-to-data ratio - consider index optimization');
      } else if (indexToDataRatio < 0.1) {
        console.log('   💡 Low index-to-data ratio - may benefit from additional indexes');
      } else {
        console.log('   ✅ Index-to-data ratio is healthy');
      }
      
    } catch (error) {
      console.error('❌ Failed to generate optimization report:', error.message);
    }
  }

  stop() {
    console.log('\n⏹️  Stopping database monitoring...');
    this.isMonitoring = false;
    
    if (this.monitoringTimer) {
      clearInterval(this.monitoringTimer);
    }
    
    mongoose.connection.close();
    console.log('✅ Monitoring stopped');
  }
}

// CLI interface
if (require.main === module) {
  const monitor = new DatabaseMonitor();
  
  console.log('🚀 Al Marya Rostery - Database Performance Monitor');
  console.log('==================================================');
  
  // Handle graceful shutdown
  process.on('SIGINT', () => {
    monitor.stop();
    process.exit(0);
  });
  
  process.on('SIGTERM', () => {
    monitor.stop();
    process.exit(0);
  });
  
  // Parse command line arguments
  const args = process.argv.slice(2);
  
  if (args.includes('--snapshot')) {
    // Just take a snapshot and exit
    monitor.connect().then(async () => {
      await monitor.performanceSnapshot();
      await monitor.generateOptimizationReport();
      monitor.stop();
    });
  } else if (args.includes('--slow-queries')) {
    // Show slow queries and exit
    monitor.connect().then(async () => {
      await monitor.getSlowQueries();
      monitor.stop();
    });
  } else {
    // Start continuous monitoring
    monitor.startMonitoring();
  }
}

module.exports = DatabaseMonitor;
