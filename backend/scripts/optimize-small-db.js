#!/usr/bin/env node

/**
 * Small Database Index Optimization
 * 
 * This script removes non-essential indexes for databases with < 1000 documents
 * to improve write performance and reduce memory usage.
 */

const mongoose = require('mongoose');
require('dotenv').config();

const optimizeSmallDatabase = async () => {
  try {
    console.log('🎯 Small Database Index Optimization');
    console.log('=====================================');
    
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');
    
    const db = mongoose.connection.db;
    const dbStats = await db.stats();
    
    console.log(`📊 Database stats:`);
    console.log(`   Documents: ${dbStats.objects || 0}`);
    console.log(`   Data size: ${(dbStats.dataSize / 1024).toFixed(1)} KB`);
    console.log(`   Index size: ${(dbStats.indexSize / 1024).toFixed(1)} KB`);
    console.log(`   Index/Data ratio: ${((dbStats.indexSize / Math.max(dbStats.dataSize, 1)) * 100).toFixed(1)}%`);
    
    if (dbStats.objects > 1000) {
      console.log('⚠️  Database has > 1000 documents. This optimization is for small databases only.');
      console.log('💡 Consider using the full database optimizer instead.');
      return;
    }
    
    // Define essential indexes only (for databases < 1000 documents)
    const essentialIndexes = {
      'users': [
        '_id_',           // MongoDB default
        'email_1',        // Login lookups (unique)
        'firebaseUid_1'   // Firebase integration (unique)
      ],
      'orders': [
        '_id_',           // MongoDB default
        'orderNumber_1',  // Order lookups (unique)
        'user_1_createdAt_-1'  // User's order history
      ],
      'coffees': [
        '_id_',           // MongoDB default
        'name.en_text_name.ar_text_description.en_text_description.ar_text'  // Search
      ],
      'userfeedbacks': [
        '_id_',           // MongoDB default
        'product_1',      // Product reviews
        'user_1_product_1' // Unique constraint
      ]
    };
    
    let totalRemoved = 0;
    let totalKeptEssential = 0;
    
    for (const [collectionName, keepIndexes] of Object.entries(essentialIndexes)) {
      try {
        console.log(`\n🔍 Optimizing ${collectionName}...`);
        
        const collection = db.collection(collectionName);
        const existingIndexes = await collection.indexes();
        
        console.log(`   Current indexes: ${existingIndexes.length}`);
        
        for (const index of existingIndexes) {
          if (keepIndexes.includes(index.name)) {
            console.log(`   ✅ Keeping essential: ${index.name}`);
            totalKeptEssential++;
          } else if (index.name === '_id_') {
            console.log(`   ✅ Keeping MongoDB default: ${index.name}`);
            totalKeptEssential++;
          } else {
            try {
              await collection.dropIndex(index.name);
              console.log(`   🗑️  Removed non-essential: ${index.name}`);
              totalRemoved++;
            } catch (error) {
              if (error.codeName === 'IndexNotFound') {
                console.log(`   ℹ️  Already removed: ${index.name}`);
              } else {
                console.log(`   ❌ Failed to remove ${index.name}: ${error.message}`);
              }
            }
          }
        }
        
      } catch (error) {
        console.log(`   ℹ️  Collection ${collectionName} not found or empty`);
      }
    }
    
    // Take final stats
    const finalStats = await db.stats();
    const indexReduction = ((dbStats.indexSize - finalStats.indexSize) / dbStats.indexSize) * 100;
    
    console.log('\n📊 OPTIMIZATION RESULTS');
    console.log('=======================');
    console.log(`🗑️  Indexes removed: ${totalRemoved}`);
    console.log(`✅ Essential indexes kept: ${totalKeptEssential}`);
    console.log(`📉 Index size reduction: ${indexReduction.toFixed(1)}%`);
    console.log(`💾 Final index size: ${(finalStats.indexSize / 1024).toFixed(1)} KB`);
    console.log(`📊 New index/data ratio: ${((finalStats.indexSize / Math.max(finalStats.dataSize, 1)) * 100).toFixed(1)}%`);
    
    if (indexReduction > 0) {
      console.log('\n🎉 Database optimized for small dataset!');
      console.log('⚡ You should see improved write performance and reduced memory usage.');
      console.log('📈 Add indexes back when you reach 1000+ documents.');
    } else {
      console.log('\n✅ Database was already optimally indexed for small dataset.');
    }
    
  } catch (error) {
    console.error('❌ Optimization failed:', error.message);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log('🔒 Database connection closed');
  }
};

// Run optimization
if (require.main === module) {
  optimizeSmallDatabase()
    .then(() => {
      console.log('\n💡 Restart your application to see the performance improvements!');
      process.exit(0);
    })
    .catch(error => {
      console.error('\n💥 Optimization failed:', error);
      process.exit(1);
    });
}

module.exports = { optimizeSmallDatabase };
