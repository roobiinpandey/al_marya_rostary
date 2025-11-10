const admin = require('firebase-admin');
const mongoose = require('mongoose');
require('dotenv').config();

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function checkStatus() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    const User = require('../models/User');
    const LoyaltyAccount = require('../models/Loyalty');
    
    console.log('\n📊 FINAL SYNC STATUS REPORT\n');
    console.log('='.repeat(60));
    
    const mongoUsers = await User.find({});
    const firebaseUsers = await admin.auth().listUsers();
    const loyaltyAccounts = await LoyaltyAccount.find({});
    
    console.log(`\n📈 Summary:`);
    console.log(`   MongoDB Users: ${mongoUsers.length}`);
    console.log(`   Firebase Users: ${firebaseUsers.users.length}`);
    console.log(`   Loyalty Accounts: ${loyaltyAccounts.length}`);
    
    console.log('\n📋 User Details:\n');
    
    for (const user of mongoUsers) {
      const loyalty = await LoyaltyAccount.findOne({ userId: user.firebaseUid });
      console.log(`✓ ${user.email}`);
      console.log(`  Name: ${user.displayName || 'N/A'}`);
      console.log(`  Firebase UID: ${user.firebaseUid || '❌ MISSING'}`);
      console.log(`  Loyalty: ${loyalty ? '✓ Active' : '❌ MISSING'}`);
      if (loyalty) {
        console.log(`  Points: ${loyalty.points}`);
      }
      console.log('');
    }
    
    const syncHealth = (mongoUsers.filter(u => u.firebaseUid).length / mongoUsers.length) * 100;
    console.log('='.repeat(60));
    console.log(`\n🎯 Sync Health: ${syncHealth.toFixed(0)}%`);
    console.log(`✅ All users synced: ${syncHealth === 100 ? 'YES' : 'NO'}\n`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

checkStatus();
