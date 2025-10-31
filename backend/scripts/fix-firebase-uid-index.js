/**
 * Fix Firebase UID Index - Migration Script
 * 
 * This script fixes the duplicate key error for firebaseUid by:
 * 1. Dropping the old index
 * 2. Ensuring the sparse index is properly created
 * 3. Fixing any duplicate null values
 */

require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');

async function fixFirebaseUidIndex() {
  try {
    console.log('🔧 Starting Firebase UID index fix...\n');

    // Connect to MongoDB
    console.log('📡 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Get the User collection
    const userCollection = mongoose.connection.collection('users');

    // Check current indexes
    console.log('📊 Current indexes:');
    const indexes = await userCollection.indexes();
    indexes.forEach(index => {
      console.log(`  - ${JSON.stringify(index.key)}: ${JSON.stringify(index)}`);
    });
    console.log();

    // Drop the firebaseUid index if it exists
    console.log('🗑️  Dropping old firebaseUid index...');
    try {
      await userCollection.dropIndex('firebaseUid_1');
      console.log('✅ Old index dropped\n');
    } catch (error) {
      if (error.code === 27 || error.message.includes('index not found')) {
        console.log('ℹ️  Index already dropped or doesn\'t exist\n');
      } else {
        throw error;
      }
    }

    // Create new sparse unique index
    console.log('🔨 Creating new sparse unique index...');
    await userCollection.createIndex(
      { firebaseUid: 1 },
      { 
        unique: true, 
        sparse: true,
        name: 'firebaseUid_1'
      }
    );
    console.log('✅ New sparse index created\n');

    // Count users with null firebaseUid
    const nullCount = await User.countDocuments({ firebaseUid: null });
    console.log(`📊 Users with null firebaseUid: ${nullCount}`);

    // Count guest users
    const guestCount = await User.countDocuments({ 
      email: /^guest_.*@temp\.com$/ 
    });
    console.log(`👤 Guest users: ${guestCount}`);

    // Count users with firebaseUid
    const withFirebaseCount = await User.countDocuments({ 
      firebaseUid: { $exists: true, $ne: null } 
    });
    console.log(`🔥 Users with Firebase UID: ${withFirebaseCount}\n`);

    // Verify the new index
    console.log('✅ Verifying new indexes:');
    const newIndexes = await userCollection.indexes();
    const firebaseUidIndex = newIndexes.find(idx => idx.key.firebaseUid);
    if (firebaseUidIndex) {
      console.log('  firebaseUid index:', JSON.stringify(firebaseUidIndex));
      if (firebaseUidIndex.unique && firebaseUidIndex.sparse) {
        console.log('  ✅ Index is properly configured (unique + sparse)\n');
      } else {
        console.log('  ⚠️  Index might not be properly configured\n');
      }
    } else {
      console.log('  ❌ firebaseUid index not found!\n');
    }

    console.log('🎉 Firebase UID index fix completed successfully!');
    console.log('\n📝 Summary:');
    console.log(`  - Total users: ${await User.countDocuments()}`);
    console.log(`  - Guest users: ${guestCount}`);
    console.log(`  - Users with Firebase: ${withFirebaseCount}`);
    console.log(`  - Users with null Firebase UID: ${nullCount}`);

  } catch (error) {
    console.error('❌ Error fixing Firebase UID index:', error);
    throw error;
  } finally {
    // Close connection
    await mongoose.connection.close();
    console.log('\n👋 Database connection closed');
  }
}

// Run the migration
if (require.main === module) {
  fixFirebaseUidIndex()
    .then(() => {
      console.log('\n✅ Migration completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ Migration failed:', error);
      process.exit(1);
    });
}

module.exports = fixFirebaseUidIndex;
