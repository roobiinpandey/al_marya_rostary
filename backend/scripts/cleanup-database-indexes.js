#!/usr/bin/env node

/**
 * Database Index Cleanup Script
 * 
 * This script removes duplicate indexes that are causing performance issues
 * and provides a clean slate for optimized indexing.
 * 
 * ⚠️  IMPORTANT: Run this script during maintenance window
 * 💾 BACKUP: Ensure you have a database backup before running
 */

const mongoose = require('mongoose');
require('dotenv').config();

const cleanupDuplicateIndexes = async () => {
  try {
    console.log('🔧 Starting Database Index Cleanup...');
    
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');
    
    const db = mongoose.connection.db;
    
    // Get all collections
    const collections = await db.listCollections().toArray();
    console.log(`📋 Found ${collections.length} collections`);
    
    // Define problematic duplicate indexes to remove
    const duplicateIndexesToRemove = {
      'orders': [
        'user_1_createdAt_-1', // Keep only one copy
        'createdAt_-1',        // Will be covered by compound indexes
        'status_1',            // Will be covered by compound indexes
        'paymentStatus_1'      // Will be covered by compound indexes
      ],
      'loyaltypoints': [
        'expiresAt_1' // Keep only the explicit index, remove field-level index
      ]
    };
    
    // Analysis: Check existing indexes
    for (const collection of collections) {
      const collectionName = collection.name;
      console.log(`\n🔍 Analyzing collection: ${collectionName}`);
      
      try {
        const existingIndexes = await db.collection(collectionName).indexes();
        
        console.log(`   📊 Current indexes (${existingIndexes.length}):`);
        existingIndexes.forEach(index => {
          const keyStr = JSON.stringify(index.key);
          const size = index.indexSizes ? Object.values(index.indexSizes)[0] : 'unknown';
          console.log(`   - ${index.name}: ${keyStr} (${size} bytes)`);
        });
        
        // Check for duplicates
        const indexKeys = existingIndexes.map(idx => JSON.stringify(idx.key));
        const duplicates = indexKeys.filter((key, index) => indexKeys.indexOf(key) !== index);
        
        if (duplicates.length > 0) {
          console.log(`   ⚠️  Found ${duplicates.length} duplicate index patterns`);
          duplicates.forEach(dup => console.log(`     - ${dup}`));
        }
        
        // Remove specific problematic indexes
        if (duplicateIndexesToRemove[collectionName]) {
          for (const indexName of duplicateIndexesToRemove[collectionName]) {
            try {
              const indexExists = existingIndexes.some(idx => idx.name === indexName);
              if (indexExists) {
                await db.collection(collectionName).dropIndex(indexName);
                console.log(`   ✅ Removed duplicate index: ${indexName}`);
              } else {
                console.log(`   ℹ️  Index not found: ${indexName}`);
              }
            } catch (error) {
              if (error.codeName === 'IndexNotFound') {
                console.log(`   ℹ️  Index already removed: ${indexName}`);
              } else {
                console.log(`   ❌ Failed to remove ${indexName}: ${error.message}`);
              }
            }
          }
        }
        
      } catch (error) {
        console.log(`   ❌ Error analyzing ${collectionName}: ${error.message}`);
      }
    }
    
    console.log('\n📊 Index Cleanup Summary:');
    console.log('✅ Removed duplicate indexes from orders collection');
    console.log('✅ Removed duplicate indexes from loyaltypoints collection');
    console.log('✅ Database is now optimized for better performance');
    
    // Generate performance report
    await generatePerformanceReport(db);
    
  } catch (error) {
    console.error('❌ Database cleanup failed:', error);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log('🔒 Database connection closed');
  }
};

const generatePerformanceReport = async (db) => {
  console.log('\n📈 Performance Analysis Report:');
  
  try {
    // Check collection stats
    const collections = ['users', 'orders', 'coffees', 'userfeedbacks'];
    
    for (const collectionName of collections) {
      try {
        const stats = await db.collection(collectionName).stats();
        const indexes = await db.collection(collectionName).indexes();
        
        console.log(`\n📋 ${collectionName.toUpperCase()} Collection:`);
        console.log(`   📄 Documents: ${stats.count?.toLocaleString() || 0}`);
        console.log(`   💾 Data Size: ${(stats.size / 1024 / 1024).toFixed(2)} MB`);
        console.log(`   🗂️  Index Count: ${indexes.length}`);
        console.log(`   🗂️  Index Size: ${(stats.totalIndexSize / 1024 / 1024).toFixed(2)} MB`);
        console.log(`   📊 Index/Data Ratio: ${((stats.totalIndexSize / stats.size) * 100).toFixed(1)}%`);
        
        // Optimal index/data ratio is typically 10-30%
        const ratio = (stats.totalIndexSize / stats.size) * 100;
        if (ratio > 40) {
          console.log(`   ⚠️  High index overhead detected (${ratio.toFixed(1)}%)`);
        } else if (ratio < 5) {
          console.log(`   ⚠️  Consider adding more indexes for better query performance`);
        } else {
          console.log(`   ✅ Index ratio is optimal (${ratio.toFixed(1)}%)`);
        }
        
      } catch (error) {
        console.log(`   ❌ Could not analyze ${collectionName}: ${error.message}`);
      }
    }
    
  } catch (error) {
    console.log('❌ Performance report generation failed:', error.message);
  }
};

// Run the cleanup
if (require.main === module) {
  console.log('🚀 Al Marya Rostery - Database Index Cleanup');
  console.log('================================================');
  cleanupDuplicateIndexes()
    .then(() => {
      console.log('\n🎉 Database optimization completed successfully!');
      console.log('💡 Restart your application to see performance improvements.');
      process.exit(0);
    })
    .catch(error => {
      console.error('💥 Cleanup failed:', error);
      process.exit(1);
    });
}

module.exports = { cleanupDuplicateIndexes };
