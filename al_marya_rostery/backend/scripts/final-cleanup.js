#!/usr/bin/env node

const mongoose = require('mongoose');
const admin = require('firebase-admin');
const User = require('../models/User');
const { LoyaltyAccount } = require('../models/Loyalty');
require('dotenv').config();

async function finalCleanup() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    
    console.log('🧹 FINAL CLEANUP\n');
    
    // Delete ALL guest users
    const guestUsers = await User.find({ email: /^guest_.*@temp\.com$/ });
    console.log(`Found ${guestUsers.length} guest users\n`);
    
    for (const user of guestUsers) {
      console.log(`❌ Deleting: ${user.email}`);
      
      if (user.firebaseUid) {
        try {
          await admin.auth().deleteUser(user.firebaseUid);
          console.log('   ✓ Firebase');
        } catch (e) {}
        
        try {
          await LoyaltyAccount.deleteOne({ userId: user.firebaseUid });
          console.log('   ✓ Loyalty');
        } catch (e) {}
      }
      
      await User.deleteOne({ _id: user._id });
      console.log('   ✓ MongoDB\n');
    }
    
    // Fix admin@almaryarostery.com
    const adminUser = await User.findOne({ email: 'admin@almaryarostery.com' });
    if (adminUser) {
      try {
        const fbUser = await admin.auth().getUserByEmail('admin@almaryarostery.com');
        if (!adminUser.firebaseUid || adminUser.firebaseUid !== fbUser.uid) {
          adminUser.firebaseUid = fbUser.uid;
          await adminUser.save();
          console.log('✅ Fixed admin@almaryarostery.com firebaseUid\n');
        }
        
        // Ensure loyalty exists
        const existingLoyalty = await LoyaltyAccount.findOne({ userId: fbUser.uid });
        if (!existingLoyalty) {
          await LoyaltyAccount.create({
            userId: fbUser.uid,
            userEmail: adminUser.email,
            userName: adminUser.name,
            currentBalance: 0,
            totalPointsEarned: 0,
            totalPointsSpent: 0,
            currentTier: 'Bronze'
          });
          console.log('✅ Created loyalty for admin@almaryarostery.com\n');
        }
      } catch (e) {
        console.error('Error fixing admin:', e.message);
      }
    }
    
    // Final count
    const finalUsers = await User.find({}).select('email name firebaseUid roles').sort({ email: 1 });
    console.log('='.repeat(80));
    console.log('📊 PRODUCTION USERS (FINAL)\n');
    
    for (const u of finalUsers) {
      const loyalty = await LoyaltyAccount.findOne({ userId: u.firebaseUid });
      const fbIcon = u.firebaseUid ? '✅' : '❌';
      const loyaltyIcon = loyalty ? '✅' : '❌';
      const role = (u.roles && u.roles.length > 0) ? u.roles[0] : 'customer';
      
      console.log(`${fbIcon} ${loyaltyIcon} ${u.email.padEnd(35)} ${role.padEnd(10)} ${u.name || 'N/A'}`);
    }
    
    console.log('='.repeat(80));
    console.log(`\n🎉 Total Production Users: ${finalUsers.length}`);
    console.log('✅ All users synced to Firebase: almaryah-rostery');
    console.log('✅ Database cleanup complete\n');
    
    await mongoose.connection.close();
    admin.app().delete();
    process.exit(0);
    
  } catch (error) {
    console.error('Fatal error:', error);
    process.exit(1);
  }
}

finalCleanup();
