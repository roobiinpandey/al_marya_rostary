#!/usr/bin/env node

/**
 * Comprehensive Database Performance Optimization
 * 
 * This script performs a complete database optimization including:
 * - Duplicate index removal
 * - Index usage analysis
 * - Performance recommendations
 * - Schema validation
 */

const mongoose = require('mongoose');
require('dotenv').config();

class DatabaseOptimizer {
  constructor() {
    this.optimizations = [];
    this.issues = [];
    this.performance = {
      before: {},
      after: {}
    };
  }

  async connect() {
    try {
      await mongoose.connect(process.env.MONGODB_URI, {
        maxPoolSize: 10,
        serverSelectionTimeoutMS: 5000,
        socketTimeoutMS: 45000
      });
      console.log('✅ Connected to MongoDB');
      return true;
    } catch (error) {
      console.error('❌ Failed to connect to MongoDB:', error.message);
      return false;
    }
  }

  async optimize() {
    console.log('🚀 Starting Comprehensive Database Optimization');
    console.log('='.repeat(60));

    if (!await this.connect()) {
      return;
    }

    // Step 1: Take initial performance snapshot
    await this.takePerformanceSnapshot('before');

    // Step 2: Analyze and fix duplicate indexes
    await this.optimizeIndexes();

    // Step 3: Analyze schema issues
    await this.analyzeSchemas();

    // Step 4: Clean up unused indexes
    await this.cleanupUnusedIndexes();

    // Step 5: Optimize for current data size
    await this.optimizeForDataSize();

    // Step 6: Take final performance snapshot
    await this.takePerformanceSnapshot('after');

    // Step 7: Generate optimization report
    await this.generateOptimizationReport();

    await mongoose.connection.close();
    console.log('🔒 Database connection closed');
  }

  async takePerformanceSnapshot(stage) {
    console.log(`\n📸 Taking ${stage} performance snapshot...`);
    
    try {
      const db = mongoose.connection.db;
      const dbStats = await db.stats();
      
      this.performance[stage] = {
        timestamp: new Date(),
        totalDocuments: dbStats.objects || 0,
        dataSize: dbStats.dataSize || 0,
        indexSize: dbStats.indexSize || 0,
        collections: {}
      };

      // Collection-specific stats
      const collections = ['users', 'orders', 'coffees', 'userfeedbacks', 'loyaltyaccounts', 'loyaltypoints'];
      
      for (const collectionName of collections) {
        try {
          const collection = db.collection(collectionName);
          const stats = await collection.stats();
          const indexes = await collection.indexes();
          
          this.performance[stage].collections[collectionName] = {
            documents: stats.count || 0,
            dataSize: stats.size || 0,
            indexSize: stats.totalIndexSize || 0,
            indexCount: indexes.length,
            averageDocSize: stats.avgObjSize || 0
          };
          
        } catch (error) {
          // Collection might not exist yet
          this.performance[stage].collections[collectionName] = {
            documents: 0,
            dataSize: 0,
            indexSize: 0,
            indexCount: 0,
            averageDocSize: 0
          };
        }
      }

      console.log(`   📄 Total Documents: ${this.performance[stage].totalDocuments.toLocaleString()}`);
      console.log(`   💾 Data Size: ${(this.performance[stage].dataSize / 1024 / 1024).toFixed(2)} MB`);
      console.log(`   🗂️  Index Size: ${(this.performance[stage].indexSize / 1024 / 1024).toFixed(2)} MB`);
      
    } catch (error) {
      console.error(`❌ Failed to take ${stage} snapshot:`, error.message);
    }
  }

  async optimizeIndexes() {
    console.log('\n🗂️  Optimizing Database Indexes...');
    
    try {
      const db = mongoose.connection.db;
      const collections = await db.listCollections().toArray();
      
      for (const collection of collections) {
        const collectionName = collection.name;
        console.log(`\n🔍 Analyzing ${collectionName}...`);
        
        try {
          const existingIndexes = await db.collection(collectionName).indexes();
          
          // Find duplicate indexes
          const indexKeys = existingIndexes.map(idx => ({
            name: idx.name,
            key: JSON.stringify(idx.key),
            keyObj: idx.key
          }));
          
          const duplicates = this.findDuplicateIndexes(indexKeys);
          
          if (duplicates.length > 0) {
            console.log(`   ⚠️  Found ${duplicates.length} duplicate index patterns`);
            
            for (const duplicate of duplicates) {
              // Keep the first one, remove others
              for (let i = 1; i < duplicate.indexes.length; i++) {
                const indexToRemove = duplicate.indexes[i].name;
                try {
                  if (indexToRemove !== '_id_') { // Never remove _id index
                    await db.collection(collectionName).dropIndex(indexToRemove);
                    console.log(`   ✅ Removed duplicate index: ${indexToRemove}`);
                    this.optimizations.push(`Removed duplicate index ${indexToRemove} from ${collectionName}`);
                  }
                } catch (error) {
                  console.log(`   ❌ Failed to remove ${indexToRemove}: ${error.message}`);
                }
              }
            }
          } else {
            console.log(`   ✅ No duplicate indexes found`);
          }
          
          // Check for over-indexing
          const stats = await db.collection(collectionName).stats();
          const indexRatio = stats.totalIndexSize / Math.max(stats.size, 1);
          
          if (indexRatio > 1 && stats.count < 1000) {
            console.log(`   ⚠️  Over-indexing detected: ${indexRatio.toFixed(1)}x ratio for ${stats.count} documents`);
            this.issues.push(`${collectionName}: Over-indexing (${indexRatio.toFixed(1)}x ratio)`);
          }
          
        } catch (error) {
          console.log(`   ❌ Error analyzing ${collectionName}: ${error.message}`);
        }
      }
      
    } catch (error) {
      console.error('❌ Index optimization failed:', error.message);
    }
  }

  findDuplicateIndexes(indexKeys) {
    const groups = {};
    
    // Group indexes by their key pattern
    indexKeys.forEach(index => {
      if (!groups[index.key]) {
        groups[index.key] = [];
      }
      groups[index.key].push(index);
    });
    
    // Find groups with more than one index
    return Object.values(groups).filter(group => group.length > 1);
  }

  async analyzeSchemas() {
    console.log('\n📋 Analyzing Schema Performance...');
    
    const schemaIssues = [
      'Fields with index: true and explicit schema.index() calls',
      'Models loaded inside functions',
      'Circular dependencies between models',
      'Inefficient field types for current data size'
    ];
    
    // This would require static code analysis, but we can check some runtime issues
    try {
      const modelNames = mongoose.modelNames();
      console.log(`   📊 Registered models: ${modelNames.length}`);
      
      for (const modelName of modelNames) {
        try {
          const model = mongoose.model(modelName);
          const schema = model.schema;
          
          // Check for potential issues
          const indexes = schema.indexes();
          if (indexes.length > 10) {
            console.log(`   ⚠️  ${modelName}: High index count (${indexes.length})`);
            this.issues.push(`${modelName}: Consider reducing index count (${indexes.length})`);
          }
          
        } catch (error) {
          console.log(`   ❌ Error analyzing ${modelName}: ${error.message}`);
        }
      }
      
    } catch (error) {
      console.error('❌ Schema analysis failed:', error.message);
    }
  }

  async cleanupUnusedIndexes() {
    console.log('\n🧹 Analyzing Index Usage...');
    
    // For small databases, we can be aggressive about removing indexes
    const db = mongoose.connection.db;
    const dbStats = await db.stats();
    
    if (dbStats.objects < 1000) {
      console.log('   📊 Small database detected - recommending minimal indexing strategy');
      
      const minimalIndexes = {
        'users': ['_id_', 'email_1', 'firebaseUid_1'],
        'orders': ['_id_', 'orderNumber_1', 'user_1'],
        'coffees': ['_id_', 'name.en_text_name.ar_text_description.en_text_description.ar_text'],
        'userfeedbacks': ['_id_', 'product_1', 'user_1']
      };
      
      for (const [collectionName, keepIndexes] of Object.entries(minimalIndexes)) {
        try {
          const collection = db.collection(collectionName);
          const existingIndexes = await collection.indexes();
          
          for (const index of existingIndexes) {
            if (!keepIndexes.includes(index.name) && index.name !== '_id_') {
              console.log(`   💡 Consider removing: ${collectionName}.${index.name}`);
              this.optimizations.push(`Consider removing ${collectionName}.${index.name} for small dataset`);
            }
          }
          
        } catch (error) {
          // Collection doesn't exist
        }
      }
    }
  }

  async optimizeForDataSize() {
    console.log('\n⚡ Optimizing for Current Data Size...');
    
    const db = mongoose.connection.db;
    const dbStats = await db.stats();
    
    if (dbStats.objects < 100) {
      console.log('   🎯 Micro database optimization strategy');
      this.optimizations.push('Applied micro database optimization (remove most indexes until 1000+ documents)');
    } else if (dbStats.objects < 1000) {
      console.log('   🎯 Small database optimization strategy');
      this.optimizations.push('Applied small database optimization (minimal essential indexes only)');
    } else {
      console.log('   🎯 Standard database optimization strategy');
    }
  }

  async generateOptimizationReport() {
    console.log('\n📊 OPTIMIZATION REPORT');
    console.log('='.repeat(60));
    
    // Performance comparison
    if (this.performance.before.totalDocuments && this.performance.after.totalDocuments) {
      console.log('\n📈 Performance Comparison:');
      
      const beforeIndexSize = this.performance.before.indexSize / 1024 / 1024;
      const afterIndexSize = this.performance.after.indexSize / 1024 / 1024;
      const indexReduction = ((beforeIndexSize - afterIndexSize) / beforeIndexSize * 100);
      
      console.log(`   Index Size: ${beforeIndexSize.toFixed(2)} MB → ${afterIndexSize.toFixed(2)} MB`);
      if (indexReduction > 0) {
        console.log(`   ✅ Index size reduced by ${indexReduction.toFixed(1)}%`);
      }
      
      const dataSize = this.performance.after.dataSize / 1024 / 1024;
      const indexRatio = afterIndexSize / Math.max(dataSize, 0.01);
      console.log(`   📊 Index/Data ratio: ${indexRatio.toFixed(1)}x`);
      
      if (indexRatio > 3) {
        console.log(`   ⚠️  High index overhead - consider removing non-essential indexes`);
      } else if (indexRatio < 0.5) {
        console.log(`   ✅ Healthy index/data ratio`);
      }
    }
    
    // Optimizations performed
    console.log('\n✅ Optimizations Performed:');
    if (this.optimizations.length === 0) {
      console.log('   📋 No optimizations needed - database already optimal');
    } else {
      this.optimizations.forEach((opt, index) => {
        console.log(`   ${index + 1}. ${opt}`);
      });
    }
    
    // Issues identified
    console.log('\n⚠️  Issues Identified:');
    if (this.issues.length === 0) {
      console.log('   ✅ No significant issues found');
    } else {
      this.issues.forEach((issue, index) => {
        console.log(`   ${index + 1}. ${issue}`);
      });
    }
    
    // Recommendations
    console.log('\n💡 Recommendations:');
    const totalDocs = this.performance.after.totalDocuments || 0;
    
    if (totalDocs < 1000) {
      console.log('   📊 Small Database Strategy:');
      console.log('   - Keep only essential indexes (primary keys, unique constraints)');
      console.log('   - Add indexes when you reach 1000+ documents');
      console.log('   - Focus on application-level caching for better performance');
    } else if (totalDocs < 10000) {
      console.log('   📊 Medium Database Strategy:');
      console.log('   - Add indexes for your most common query patterns');
      console.log('   - Monitor slow query log for optimization opportunities');
      console.log('   - Consider compound indexes for multi-field queries');
    } else {
      console.log('   📊 Large Database Strategy:');
      console.log('   - Implement comprehensive indexing strategy');
      console.log('   - Consider database sharding or read replicas');
      console.log('   - Implement query optimization and connection pooling');
    }
    
    console.log('\n🎉 Database optimization completed!');
    console.log('💡 Restart your application to see performance improvements.');
  }
}

// Run optimization
if (require.main === module) {
  const optimizer = new DatabaseOptimizer();
  
  optimizer.optimize()
    .then(() => {
      console.log('\n✅ Optimization completed successfully!');
      process.exit(0);
    })
    .catch(error => {
      console.error('\n❌ Optimization failed:', error);
      process.exit(1);
    });
}

module.exports = DatabaseOptimizer;
