#!/usr/bin/env node

/**
 * Fix Firebase UID Null Issue
 * Removes null firebaseUid from users to prevent duplicate key errors
 */

const mongoose = require('mongoose');
require('dotenv').config();

async function fixNullFirebaseUid() {
  try {
    // Connect to MongoDB
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Load User model
    const User = require('./models/User');

    // Find users with null firebaseUid
    console.log('\n🔍 Finding users with null firebaseUid...');
    const usersWithNullUid = await User.find({ firebaseUid: null });
    
    console.log(`Found ${usersWithNullUid.length} users with null firebaseUid:`);
    usersWithNullUid.forEach(user => {
      console.log(`  - ${user.email} (ID: ${user._id})`);
    });

    if (usersWithNullUid.length === 0) {
      console.log('\n✅ No users with null firebaseUid found!');
      process.exit(0);
    }

    // Option 1: Unset firebaseUid field (remove it completely)
    console.log('\n🔧 Removing firebaseUid field from these users...');
    const result = await User.updateMany(
      { firebaseUid: null },
      { $unset: { firebaseUid: "" } }
    );

    console.log(`✅ Updated ${result.modifiedCount} users`);
    console.log('\n✨ Fix complete!');
    console.log('💡 Users will get a new firebaseUid when they login next time');

    process.exit(0);

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

// Run the fix
fixNullFirebaseUid();
