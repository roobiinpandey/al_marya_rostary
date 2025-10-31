#!/usr/bin/env node

/**
 * Firebase Webhook Sync Service
 * 
 * This service can be called whenever Firebase user changes occur
 * to keep MongoDB and Loyalty systems in perfect sync
 */

const mongoose = require('mongoose');
const admin = require('firebase-admin');
const User = require('../models/User');
const { LoyaltyAccount } = require('../models/Loyalty');
require('dotenv').config();

const syncSingleUser = async (firebaseUID) => {
  try {
    console.log(`🔥 Syncing single user: ${firebaseUID}`);
    
    // Get Firebase user
    const firebaseUser = await admin.auth().getUser(firebaseUID);
    
    if (!firebaseUser.email) {
      console.log('❌ Firebase user has no email, skipping sync');
      return { success: false, message: 'No email found' };
    }
    
    // Sync MongoDB User
    let mongoUser = await User.findOne({ email: firebaseUser.email });
    
    if (!mongoUser) {
      console.log(`➕ Creating MongoDB user: ${firebaseUser.email}`);
      mongoUser = new User({
        email: firebaseUser.email,
        name: firebaseUser.displayName || 'User',
        firebaseUID: firebaseUser.uid,
        emailVerified: firebaseUser.emailVerified || false,
        createdAt: new Date(firebaseUser.metadata.creationTime),
        lastLoginAt: firebaseUser.metadata.lastSignInTime ? new Date(firebaseUser.metadata.lastSignInTime) : null
      });
      await mongoUser.save();
    } else {
      console.log(`🔄 Updating MongoDB user: ${firebaseUser.email}`);
      mongoUser.firebaseUID = firebaseUser.uid;
      mongoUser.name = firebaseUser.displayName || 'User';
      mongoUser.emailVerified = firebaseUser.emailVerified || false;
      await mongoUser.save();
    }
    
    // Sync Loyalty Account
    let loyaltyAccount = await LoyaltyAccount.findOne({ userEmail: firebaseUser.email });
    
    if (!loyaltyAccount) {
      console.log(`➕ Creating loyalty account: ${firebaseUser.email}`);
      loyaltyAccount = new LoyaltyAccount({
        userId: firebaseUser.uid,
        userEmail: firebaseUser.email,
        userName: firebaseUser.displayName || 'User',
        currentBalance: 0,
        totalPointsEarned: 0,
        totalPointsSpent: 0,
        currentTier: 'Bronze',
        joinedAt: new Date(firebaseUser.metadata.creationTime),
        lastActivity: new Date()
      });
      await loyaltyAccount.save();
      
      // Award welcome bonus for new users
      if (!firebaseUser.email.includes('guest_')) {
        await loyaltyAccount.addPoints(100, 'earned_signup', '🎉 Welcome to Al Marya Rostery!');
        console.log(`🎁 Awarded 100 welcome points to ${firebaseUser.email}`);
      }
    } else {
      console.log(`🔄 Updating loyalty account: ${firebaseUser.email}`);
      loyaltyAccount.userId = firebaseUser.uid;
      loyaltyAccount.userName = firebaseUser.displayName || 'User';
      await loyaltyAccount.save();
    }
    
    return {
      success: true,
      message: 'User synced successfully',
      user: {
        email: firebaseUser.email,
        name: firebaseUser.displayName || 'User',
        uid: firebaseUser.uid
      }
    };
    
  } catch (error) {
    console.error(`❌ Failed to sync user ${firebaseUID}:`, error.message);
    return { success: false, message: error.message };
  }
};

const removeUserFromSystems = async (email) => {
  try {
    console.log(`🗑️  Removing user from all systems: ${email}`);
    
    // Remove from MongoDB
    const mongoUser = await User.findOneAndDelete({ email });
    if (mongoUser) {
      console.log(`✅ Removed MongoDB user: ${email}`);
    }
    
    // Archive loyalty account (preserve points history)
    const loyaltyAccount = await LoyaltyAccount.findOne({ userEmail: email });
    if (loyaltyAccount) {
      console.log(`💰 Archiving loyalty account: ${email} (${loyaltyAccount.currentBalance} points)`);
      // Instead of deleting, mark as archived
      loyaltyAccount.isActive = false;
      loyaltyAccount.archivedAt = new Date();
      loyaltyAccount.archiveReason = 'Firebase user deleted';
      await loyaltyAccount.save();
    }
    
    return { success: true, message: 'User removed from systems' };
    
  } catch (error) {
    console.error(`❌ Failed to remove user ${email}:`, error.message);
    return { success: false, message: error.message };
  }
};

const validateFirebaseSync = async () => {
  try {
    console.log('🔍 Validating Firebase sync status...');
    
    // Get Firebase users
    const firebaseUsers = [];
    let nextPageToken;
    
    do {
      const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
      firebaseUsers.push(...listUsersResult.users);
      nextPageToken = listUsersResult.pageToken;
    } while (nextPageToken);
    
    const firebaseEmails = firebaseUsers.map(u => u.email).filter(Boolean);
    
    // Get MongoDB and Loyalty counts
    const mongoCount = await User.countDocuments({ email: { $in: firebaseEmails } });
    const loyaltyCount = await LoyaltyAccount.countDocuments({ userEmail: { $in: firebaseEmails } });
    
    const syncHealth = {
      firebase: firebaseUsers.length,
      mongo: mongoCount,
      loyalty: loyaltyCount,
      mongoSync: ((mongoCount / firebaseUsers.length) * 100).toFixed(1),
      loyaltySync: ((loyaltyCount / firebaseUsers.length) * 100).toFixed(1)
    };
    
    console.log('📊 SYNC HEALTH REPORT:');
    console.log(`🔥 Firebase Users: ${syncHealth.firebase}`);
    console.log(`📊 MongoDB Users: ${syncHealth.mongo} (${syncHealth.mongoSync}%)`);
    console.log(`🏆 Loyalty Accounts: ${syncHealth.loyalty} (${syncHealth.loyaltySync}%)`);
    
    return syncHealth;
    
  } catch (error) {
    console.error('❌ Sync validation failed:', error.message);
    return null;
  }
};

// Express.js webhook endpoint for Firebase user events
const createWebhookHandler = () => {
  return async (req, res) => {
    try {
      const { eventType, uid, email } = req.body;
      
      console.log(`🔥 Firebase webhook received: ${eventType} for ${email || uid}`);
      
      let result;
      
      switch (eventType) {
        case 'user.created':
        case 'user.updated':
          result = await syncSingleUser(uid);
          break;
          
        case 'user.deleted':
          if (email) {
            result = await removeUserFromSystems(email);
          } else {
            result = { success: false, message: 'No email provided for deletion' };
          }
          break;
          
        default:
          result = { success: false, message: `Unknown event type: ${eventType}` };
      }
      
      res.json(result);
      
    } catch (error) {
      console.error('❌ Webhook handler failed:', error.message);
      res.status(500).json({ success: false, message: error.message });
    }
  };
};

// CLI interface
const runCLI = async () => {
  const command = process.argv[2];
  const target = process.argv[3];
  
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('✅ Connected to MongoDB');
  
  if (!admin.apps.length) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id
    });
  }
  console.log('✅ Firebase Admin initialized');
  
  switch (command) {
    case 'sync':
      if (target) {
        const result = await syncSingleUser(target);
        console.log('Result:', result);
      } else {
        console.log('Usage: node firebase-webhook-sync.js sync <firebase-uid>');
      }
      break;
      
    case 'remove':
      if (target) {
        const result = await removeUserFromSystems(target);
        console.log('Result:', result);
      } else {
        console.log('Usage: node firebase-webhook-sync.js remove <email>');
      }
      break;
      
    case 'validate':
      const health = await validateFirebaseSync();
      if (health) {
        const allSync = health.mongoSync === '100.0' && health.loyaltySync === '100.0';
        console.log(allSync ? '🎉 Perfect sync!' : '⚠️  Sync issues detected');
      }
      break;
      
    default:
      console.log('Available commands:');
      console.log('  sync <firebase-uid>  - Sync single user');
      console.log('  remove <email>       - Remove user from systems');
      console.log('  validate            - Check sync health');
  }
  
  await mongoose.connection.close();
};

// Run CLI if called directly
if (require.main === module) {
  runCLI()
    .then(() => process.exit(0))
    .catch(error => {
      console.error('CLI error:', error);
      process.exit(1);
    });
}

module.exports = {
  syncSingleUser,
  removeUserFromSystems,
  validateFirebaseSync,
  createWebhookHandler
};
