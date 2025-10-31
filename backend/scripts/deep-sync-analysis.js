#!/usr/bin/env node

/**
 * Deep Sync Analysis - Truth Check
 * 
 * This script provides a detailed breakdown of ALL users across
 * MongoDB Users collection, Firebase Auth, and Loyalty system
 */

const mongoose = require('mongoose');
const admin = require('firebase-admin');
const User = require('../models/User');
const { LoyaltyAccount } = require('../models/Loyalty');
require('dotenv').config();

const deepSyncAnalysis = async () => {
  try {
    console.log('🔍 DEEP SYNC ANALYSIS - TRUTH CHECK');
    console.log('=====================================');
    
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');
    
    // Initialize Firebase
    if (!admin.apps.length) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: serviceAccount.project_id
      });
    }
    console.log('✅ Firebase Admin initialized');
    
    console.log('\n' + '='.repeat(60));
    console.log('📊 SYSTEM 1: MONGODB USERS COLLECTION');
    console.log('='.repeat(60));
    
    const mongoUsers = await User.find({}).sort({ email: 1 });
    console.log(`Total MongoDB Users: ${mongoUsers.length}`);
    
    let realUsers = [];
    let guestUsers = [];
    
    mongoUsers.forEach((user, index) => {
      const isGuest = user.email.includes('guest_') && user.email.includes('@temp.com');
      const userInfo = {
        index: index + 1,
        email: user.email,
        name: user.name || 'N/A',
        firebaseUID: user.firebaseUID || 'No UID',
        hasFirebaseUID: !!user.firebaseUID,
        createdAt: user.createdAt?.toLocaleDateString() || 'N/A'
      };
      
      if (isGuest) {
        guestUsers.push(userInfo);
      } else {
        realUsers.push(userInfo);
      }
      
      console.log(`${index + 1}. ${isGuest ? '👻' : '👤'} ${user.email}`);
      console.log(`   Name: ${user.name || 'N/A'}`);
      console.log(`   Firebase UID: ${user.firebaseUID || 'No UID'}`);
      console.log(`   Created: ${user.createdAt?.toLocaleDateString() || 'N/A'}`);
      console.log('');
    });
    
    console.log('\n' + '='.repeat(60));
    console.log('🔥 SYSTEM 2: FIREBASE AUTHENTICATION');
    console.log('='.repeat(60));
    
    const firebaseUsers = [];
    let nextPageToken;
    
    do {
      const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
      firebaseUsers.push(...listUsersResult.users);
      nextPageToken = listUsersResult.pageToken;
    } while (nextPageToken);
    
    console.log(`Total Firebase Users: ${firebaseUsers.length}`);
    
    firebaseUsers.forEach((user, index) => {
      console.log(`${index + 1}. 🔥 ${user.email || 'No Email'}`);
      console.log(`   UID: ${user.uid}`);
      console.log(`   Display Name: ${user.displayName || 'N/A'}`);
      console.log(`   Created: ${new Date(user.metadata.creationTime).toLocaleDateString()}`);
      console.log(`   Last Sign In: ${user.metadata.lastSignInTime ? new Date(user.metadata.lastSignInTime).toLocaleDateString() : 'Never'}`);
      console.log('');
    });
    
    console.log('\n' + '='.repeat(60));
    console.log('🏆 SYSTEM 3: LOYALTY ACCOUNTS');
    console.log('='.repeat(60));
    
    const loyaltyAccounts = await LoyaltyAccount.find({}).sort({ userEmail: 1 });
    console.log(`Total Loyalty Accounts: ${loyaltyAccounts.length}`);
    
    loyaltyAccounts.forEach((account, index) => {
      const isGuest = account.userEmail.includes('guest_') && account.userEmail.includes('@temp.com');
      console.log(`${index + 1}. ${isGuest ? '👻' : '🏆'} ${account.userEmail}`);
      console.log(`   Name: ${account.userName || 'N/A'}`);
      console.log(`   Points: ${account.currentBalance}`);
      console.log(`   Tier: ${account.currentTier}`);
      console.log(`   Joined: ${account.joinedAt?.toLocaleDateString() || 'N/A'}`);
      console.log('');
    });
    
    console.log('\n' + '='.repeat(60));
    console.log('🔍 CROSS-SYSTEM ANALYSIS');
    console.log('='.repeat(60));
    
    // Create email maps for comparison
    const mongoEmails = new Set(mongoUsers.map(u => u.email));
    const firebaseEmails = new Set(firebaseUsers.map(u => u.email).filter(Boolean));
    const loyaltyEmails = new Set(loyaltyAccounts.map(a => a.userEmail));
    
    console.log('📊 SUMMARY BY CATEGORY:');
    console.log(`👤 Real Users (MongoDB): ${realUsers.length}`);
    console.log(`👻 Guest Users (MongoDB): ${guestUsers.length}`);
    console.log(`🔥 Firebase Users: ${firebaseUsers.length}`);
    console.log(`🏆 Loyalty Accounts: ${loyaltyAccounts.length}`);
    
    console.log('\n🔍 MISSING FROM SYSTEMS:');
    
    // Users in MongoDB but not in Firebase
    const mongoNotInFirebase = mongoUsers.filter(u => 
      !firebaseUsers.some(f => f.email === u.email)
    );
    if (mongoNotInFirebase.length > 0) {
      console.log(`❌ MongoDB users NOT in Firebase (${mongoNotInFirebase.length}):`);
      mongoNotInFirebase.forEach(u => console.log(`   - ${u.email}`));
    }
    
    // Users in Firebase but not in MongoDB
    const firebaseNotInMongo = firebaseUsers.filter(f => 
      f.email && !mongoUsers.some(u => u.email === f.email)
    );
    if (firebaseNotInMongo.length > 0) {
      console.log(`❌ Firebase users NOT in MongoDB (${firebaseNotInMongo.length}):`);
      firebaseNotInMongo.forEach(u => console.log(`   - ${u.email}`));
    }
    
    // Users in MongoDB but not in Loyalty
    const mongoNotInLoyalty = mongoUsers.filter(u => 
      !loyaltyAccounts.some(l => l.userEmail === u.email)
    );
    if (mongoNotInLoyalty.length > 0) {
      console.log(`❌ MongoDB users WITHOUT loyalty accounts (${mongoNotInLoyalty.length}):`);
      mongoNotInLoyalty.forEach(u => console.log(`   - ${u.email}`));
    }
    
    // Loyalty accounts without MongoDB users
    const loyaltyNotInMongo = loyaltyAccounts.filter(l => 
      !mongoUsers.some(u => u.email === l.userEmail)
    );
    if (loyaltyNotInMongo.length > 0) {
      console.log(`❌ Loyalty accounts WITHOUT MongoDB users (${loyaltyNotInMongo.length}):`);
      loyaltyNotInMongo.forEach(l => console.log(`   - ${l.userEmail}`));
    }
    
    console.log('\n' + '='.repeat(60));
    console.log('🎯 SYNC HEALTH VERDICT');
    console.log('='.repeat(60));
    
    const totalIssues = mongoNotInFirebase.length + firebaseNotInMongo.length + 
                       mongoNotInLoyalty.length + loyaltyNotInMongo.length;
    
    if (totalIssues === 0) {
      console.log('🎉 PERFECT SYNC - All systems are perfectly aligned!');
    } else {
      console.log(`⚠️  SYNC ISSUES DETECTED: ${totalIssues} problems found`);
      console.log('💡 Recommendation: Run sync repair tools to fix inconsistencies');
    }
    
    // Calculate real user sync health (excluding guests)
    const realMongoUsers = mongoUsers.filter(u => !(u.email.includes('guest_') && u.email.includes('@temp.com')));
    const realLoyaltyAccounts = loyaltyAccounts.filter(l => !(l.userEmail.includes('guest_') && l.userEmail.includes('@temp.com')));
    
    console.log('\n📈 REAL USER SYNC HEALTH:');
    console.log(`👤 Real MongoDB Users: ${realMongoUsers.length}`);
    console.log(`🔥 Firebase Users: ${firebaseUsers.length}`);
    console.log(`🏆 Real Loyalty Accounts: ${realLoyaltyAccounts.length}`);
    
    const realUserSyncHealth = realLoyaltyAccounts.length / realMongoUsers.length * 100;
    console.log(`📊 Real User Sync Health: ${realUserSyncHealth.toFixed(1)}%`);
    
  } catch (error) {
    console.error('❌ Deep analysis failed:', error.message);
    console.error(error.stack);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔒 Database connection closed');
  }
};

// Run the analysis
if (require.main === module) {
  deepSyncAnalysis()
    .then(() => {
      console.log('\n✅ Deep sync analysis completed!');
      process.exit(0);
    })
    .catch(error => {
      console.error('\n💥 Analysis failed:', error);
      process.exit(1);
    });
}

module.exports = { deepSyncAnalysis };
