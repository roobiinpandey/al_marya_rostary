#!/usr/bin/env node

/**
 * Automated Loyalty Sync Service
 * 
 * This script provides automated synchronization between Loyalty & Rewards
 * and Users & Firebase. It can be run manually or scheduled to run periodically.
 */

const LoyaltyUserSync = require('./loyalty-user-sync');

class AutomatedLoyaltySync {
  constructor() {
    this.syncInterval = 24 * 60 * 60 * 1000; // 24 hours
    this.isRunning = false;
  }

  async runQuickSync() {
    console.log('⚡ Running Quick Loyalty Sync...');
    console.log('===============================');
    
    const sync = new LoyaltyUserSync();
    
    try {
      await sync.syncLoyaltyWithUsers();
      return true;
    } catch (error) {
      console.error('❌ Quick sync failed:', error.message);
      return false;
    }
  }

  async runValidationOnly() {
    console.log('🔍 Running Loyalty Validation (Read-Only)...');
    console.log('=============================================');
    
    const mongoose = require('mongoose');
    const User = require('../models/User');
    const { LoyaltyAccount } = require('../models/Loyalty');
    
    try {
      await mongoose.connect(process.env.MONGODB_URI);
      
      // Get counts
      const loyaltyCount = await LoyaltyAccount.countDocuments();
      const userCount = await User.countDocuments();
      
      // Find mismatches
      const loyaltyAccounts = await LoyaltyAccount.find({}, 'userId userEmail').lean();
      const users = await User.find({}, 'firebaseUid email').lean();
      
      let orphaned = 0;
      let missing = 0;
      let synced = 0;
      
      // Check each loyalty account
      for (const loyalty of loyaltyAccounts) {
        const userExists = users.find(user => 
          user.firebaseUid === loyalty.userId || 
          user.email === loyalty.userEmail
        );
        
        if (userExists) {
          synced++;
        } else {
          orphaned++;
        }
      }
      
      // Check for missing loyalty accounts
      for (const user of users) {
        if (user.firebaseUid) {
          const loyaltyExists = loyaltyAccounts.find(loyalty => 
            loyalty.userId === user.firebaseUid || 
            loyalty.userEmail === user.email
          );
          
          if (!loyaltyExists) {
            missing++;
          }
        }
      }
      
      console.log('\n📊 Loyalty Sync Status:');
      console.log(`   👥 Total Users: ${userCount}`);
      console.log(`   🏆 Total Loyalty Accounts: ${loyaltyCount}`);
      console.log(`   ✅ Properly Synced: ${synced}`);
      console.log(`   🗑️  Orphaned Loyalty Accounts: ${orphaned}`);
      console.log(`   ❓ Missing Loyalty Accounts: ${missing}`);
      
      const syncHealth = ((synced / Math.max(loyaltyCount, 1)) * 100).toFixed(1);
      console.log(`   📈 Sync Health: ${syncHealth}%`);
      
      if (syncHealth < 90) {
        console.log('\n⚠️  Sync health is below 90%. Consider running full sync.');
        console.log('   Run: npm run loyalty:sync');
      } else {
        console.log('\n✅ Loyalty sync is healthy!');
      }
      
      await mongoose.connection.close();
      return true;
      
    } catch (error) {
      console.error('❌ Validation failed:', error.message);
      await mongoose.connection.close();
      return false;
    }
  }

  async fixCommonIssues() {
    console.log('🛠️  Fixing Common Loyalty Sync Issues...');
    console.log('=========================================');
    
    const mongoose = require('mongoose');
    const User = require('../models/User');
    const { LoyaltyAccount } = require('../models/Loyalty');
    
    try {
      await mongoose.connect(process.env.MONGODB_URI);
      
      let fixed = 0;
      
      // Fix 1: Update loyalty accounts with missing user names
      console.log('\n🔧 Fixing missing user names in loyalty accounts...');
      const loyaltyWithoutNames = await LoyaltyAccount.find({
        $or: [
          { userName: { $exists: false } },
          { userName: null },
          { userName: '' }
        ]
      });
      
      for (const loyalty of loyaltyWithoutNames) {
        const user = await User.findOne({
          $or: [
            { firebaseUid: loyalty.userId },
            { email: loyalty.userEmail }
          ]
        });
        
        if (user && user.name) {
          await LoyaltyAccount.findByIdAndUpdate(loyalty._id, {
            userName: user.name
          });
          console.log(`   ✅ Updated name for ${loyalty.userEmail}: ${user.name}`);
          fixed++;
        }
      }
      
      // Fix 2: Create loyalty accounts for users without them
      console.log('\n🔧 Creating missing loyalty accounts...');
      const usersWithoutLoyalty = await User.find({ firebaseUid: { $exists: true, $ne: null } });
      
      for (const user of usersWithoutLoyalty) {
        const loyaltyExists = await LoyaltyAccount.findOne({
          $or: [
            { userId: user.firebaseUid },
            { userEmail: user.email }
          ]
        });
        
        if (!loyaltyExists) {
          const newLoyalty = new LoyaltyAccount({
            userId: user.firebaseUid,
            userEmail: user.email,
            userName: user.name,
            joinedAt: user.createdAt || new Date()
          });
          
          await newLoyalty.save();
          console.log(`   ✅ Created loyalty account for ${user.email}`);
          fixed++;
        }
      }
      
      // Fix 3: Update incorrect Firebase UIDs in loyalty accounts
      console.log('\n🔧 Fixing incorrect Firebase UIDs...');
      const loyaltyAccounts = await LoyaltyAccount.find({});
      
      for (const loyalty of loyaltyAccounts) {
        const user = await User.findOne({ email: loyalty.userEmail });
        
        if (user && user.firebaseUid && user.firebaseUid !== loyalty.userId) {
          await LoyaltyAccount.findByIdAndUpdate(loyalty._id, {
            userId: user.firebaseUid
          });
          console.log(`   ✅ Updated Firebase UID for ${loyalty.userEmail}`);
          fixed++;
        }
      }
      
      console.log(`\n🎉 Fixed ${fixed} issues!`);
      
      await mongoose.connection.close();
      return true;
      
    } catch (error) {
      console.error('❌ Fix failed:', error.message);
      await mongoose.connection.close();
      return false;
    }
  }

  startAutoSync() {
    if (this.isRunning) {
      console.log('⚠️  Auto sync is already running');
      return;
    }
    
    console.log('🔄 Starting automated loyalty sync...');
    console.log(`   Interval: ${this.syncInterval / (60 * 60 * 1000)} hours`);
    
    this.isRunning = true;
    
    // Run initial sync
    this.runQuickSync();
    
    // Schedule periodic syncs
    this.syncTimer = setInterval(async () => {
      console.log('\n⏰ Running scheduled loyalty sync...');
      await this.runQuickSync();
    }, this.syncInterval);
    
    console.log('✅ Automated sync started');
    console.log('Press Ctrl+C to stop');
  }

  stopAutoSync() {
    if (this.syncTimer) {
      clearInterval(this.syncTimer);
      this.syncTimer = null;
    }
    this.isRunning = false;
    console.log('⏹️  Automated sync stopped');
  }
}

// CLI interface
if (require.main === module) {
  const autoSync = new AutomatedLoyaltySync();
  
  const args = process.argv.slice(2);
  const command = args[0];
  
  console.log('🚀 Al Marya Rostery - Automated Loyalty Sync');
  console.log('==============================================');
  
  // Handle graceful shutdown
  process.on('SIGINT', () => {
    autoSync.stopAutoSync();
    process.exit(0);
  });
  
  switch (command) {
    case 'validate':
    case 'check':
      autoSync.runValidationOnly()
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    case 'fix':
    case 'repair':
      autoSync.fixCommonIssues()
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    case 'auto':
    case 'daemon':
      autoSync.startAutoSync();
      break;
      
    case 'sync':
    case 'full':
    default:
      autoSync.runQuickSync()
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
  }
}

module.exports = AutomatedLoyaltySync;
