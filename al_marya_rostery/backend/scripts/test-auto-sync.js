// Load environment variables FIRST before any other imports
require('dotenv').config();

const autoSyncService = require('../services/autoSyncService');
const User = require('../models/User');
const LoyaltyAccount = require('../models/Loyalty').LoyaltyAccount;
const mongoose = require('mongoose');

/**
 * Test Auto-Sync Service
 * Verifies that new users are automatically synced to Firebase and get loyalty accounts
 */
async function testAutoSync() {
  try {
    console.log('🧪 Testing Auto-Sync Service\n');
    console.log('='.repeat(60));

    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Test 1: Create a test user
    console.log('📝 Test 1: Creating test user...');
    const testEmail = `test_${Date.now()}@autotest.com`;
    
    const testUser = await User.create({
      name: 'Auto Sync Test User',
      email: testEmail,
      password: 'Test@123456',  // Valid password with uppercase, lowercase, number, and special char
      phone: '+12025551234'  // Valid US phone number format
    });
    
    console.log(`✅ Test user created: ${testEmail} (ID: ${testUser._id})\n`);

    // Test 2: Run auto-sync
    console.log('🔄 Test 2: Running auto-sync...');
    const syncResult = await autoSyncService.syncNewUser(testUser);
    
    console.log('\n📊 Sync Result:');
    console.log(JSON.stringify(syncResult, null, 2));
    console.log('');

    // Test 3: Verify Firebase UID was added
    console.log('🔍 Test 3: Verifying Firebase UID...');
    const updatedUser = await User.findById(testUser._id);
    
    if (updatedUser.firebaseUid) {
      console.log(`✅ Firebase UID assigned: ${updatedUser.firebaseUid}`);
    } else {
      console.log('❌ Firebase UID not assigned');
    }
    console.log('');

    // Test 4: Verify loyalty account was created
    console.log('🔍 Test 4: Verifying loyalty account...');
    const loyaltyAccount = await LoyaltyAccount.findOne({ 
      userId: updatedUser.firebaseUid 
    });
    
    if (loyaltyAccount) {
      console.log(`✅ Loyalty account created:`);
      console.log(`   ID: ${loyaltyAccount._id}`);
      console.log(`   Email: ${loyaltyAccount.userEmail}`);
      console.log(`   Balance: ${loyaltyAccount.currentBalance}`);
      console.log(`   Tier: ${loyaltyAccount.currentTier}`);
    } else {
      console.log('❌ Loyalty account not created');
    }
    console.log('');

    // Test 5: Clean up test user
    console.log('🧹 Test 5: Cleaning up test user...');
    
    // Delete from Firebase
    if (updatedUser.firebaseUid && syncResult.firebaseSync?.success) {
      const admin = require('firebase-admin');
      try {
        await admin.auth().deleteUser(updatedUser.firebaseUid);
        console.log(`✅ Deleted from Firebase: ${updatedUser.firebaseUid}`);
      } catch (fbError) {
        console.log(`⚠️ Failed to delete from Firebase: ${fbError.message}`);
      }
    }
    
    // Delete loyalty account
    if (loyaltyAccount) {
      await LoyaltyAccount.deleteOne({ _id: loyaltyAccount._id });
      console.log(`✅ Deleted loyalty account: ${loyaltyAccount._id}`);
    }
    
    // Delete MongoDB user
    await User.deleteOne({ _id: testUser._id });
    console.log(`✅ Deleted from MongoDB: ${testUser._id}`);
    console.log('');

    // Summary
    console.log('='.repeat(60));
    console.log('\n✅ AUTO-SYNC TEST SUMMARY:\n');
    console.log(`   Firebase Sync: ${syncResult.firebaseSync?.success ? '✅ SUCCESS' : '❌ FAILED'}`);
    console.log(`   Loyalty Account: ${syncResult.loyaltyAccount?.success ? '✅ SUCCESS' : '❌ FAILED'}`);
    console.log(`   Overall: ${syncResult.success ? '✅ ALL PASSED' : '❌ SOME FAILED'}`);
    console.log('');
    
    if (syncResult.errors.length > 0) {
      console.log('⚠️ Errors encountered:');
      syncResult.errors.forEach(err => {
        console.log(`   - ${err.service}: ${err.error}`);
      });
      console.log('');
    }

    process.exit(0);
  } catch (error) {
    console.error('\n❌ Test failed:', error);
    console.error(error.stack);
    process.exit(1);
  }
}

// Run the test
testAutoSync();
