#!/usr/bin/env node

/**
 * Sync MongoDB Users to New Firebase Project
 * Syncs all users from MongoDB to almaryah-rostery Firebase project
 * and creates loyalty accounts
 */

const mongoose = require('mongoose');
const admin = require('firebase-admin');
const User = require('../models/User');
const { LoyaltyAccount } = require('../models/Loyalty');
require('dotenv').config();

async function syncToNewFirebase() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB connected');
    
    // Initialize NEW Firebase
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id
    });
    console.log('✅ Firebase Admin initialized:', serviceAccount.project_id);
    console.log('');
    
    const users = await User.find({});
    console.log(`📋 Found ${users.length} MongoDB users to sync\n`);
    
    let synced = 0;
    let skipped = 0;
    let errors = 0;
    
    for (const user of users) {
      try {
        // Check if already in Firebase
        let firebaseUser;
        try {
          firebaseUser = await admin.auth().getUserByEmail(user.email);
          console.log(`⏭️  ${user.email} - Already in Firebase (UID: ${firebaseUser.uid})`);
          
          // Update MongoDB with Firebase UID
          if (user.firebaseUid !== firebaseUser.uid) {
            user.firebaseUid = firebaseUser.uid;
            await user.save();
            console.log(`   ✅ Updated firebaseUid in MongoDB`);
          }
          skipped++;
        } catch (err) {
          if (err.code === 'auth/user-not-found') {
            // Create in Firebase
            const createData = {
              email: user.email,
              displayName: user.name,
              emailVerified: user.emailVerified || false,
              disabled: user.isActive === false
            };
            
            firebaseUser = await admin.auth().createUser(createData);
            console.log(`➕ ${user.email} - Created in Firebase (UID: ${firebaseUser.uid})`);
            
            // Update MongoDB
            user.firebaseUid = firebaseUser.uid;
            await user.save();
            console.log(`   ✅ Updated MongoDB with firebaseUid`);
            synced++;
          } else {
            throw err;
          }
        }
        
        // Create/Update Loyalty Account (use Firebase UID as userId)
        let loyalty = await LoyaltyAccount.findOne({ userId: firebaseUser.uid });
        if (!loyalty) {
          loyalty = await LoyaltyAccount.create({
            userId: firebaseUser.uid,  // Firebase UID
            userEmail: user.email,     // Required field
            userName: user.name,       // Optional
            currentBalance: 0,
            totalPointsEarned: 0,
            totalPointsSpent: 0,
            currentTier: 'Bronze'
          });
          console.log(`   🏆 Created loyalty account`);
        } else {
          console.log(`   🏆 Loyalty account exists`);
        }
        console.log('');
        
      } catch (error) {
        console.error(`❌ Error with ${user.email}:`, error.message);
        errors++;
      }
    }
    
    console.log('\n' + '='.repeat(60));
    console.log('📊 SYNC SUMMARY:');
    console.log(`✅ Created in Firebase: ${synced}`);
    console.log(`⏭️  Already existed: ${skipped}`);
    console.log(`❌ Errors: ${errors}`);
    console.log(`📊 Total processed: ${users.length}`);
    console.log('='.repeat(60));
    
    await mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    console.error('Fatal error:', error);
    process.exit(1);
  }
}

syncToNewFirebase();
