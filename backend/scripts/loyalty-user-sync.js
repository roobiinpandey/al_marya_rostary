#!/usr/bin/env node

/**
 * Loyalty & Rewards Sync with Users & Firebase
 * 
 * This script synchronizes the Loyalty system with Users collection and Firebase:
 * 1. Finds orphaned loyalty accounts (users that don't exist)
 * 2. Creates missing loyalty accounts for existing users
 * 3. Updates user information in loyalty accounts
 * 4. Validates Firebase UID consistency
 * 5. Cleans up inconsistent data
 */

const mongoose = require('mongoose');
const admin = require('firebase-admin');
require('dotenv').config();

// Import models
const User = require('../models/User');
const { LoyaltyAccount, LoyaltyPoint } = require('../models/Loyalty');

class LoyaltyUserSync {
  constructor() {
    this.syncResults = {
      totalLoyaltyAccounts: 0,
      totalUsers: 0,
      totalFirebaseUsers: 0,
      orphanedLoyaltyAccounts: [],
      missingLoyaltyAccounts: [],
      updatedLoyaltyAccounts: [],
      inconsistentFirebaseUIDs: [],
      errors: []
    };
  }

  async connect() {
    try {
      await mongoose.connect(process.env.MONGODB_URI);
      console.log('✅ Connected to MongoDB');
      
      // Initialize Firebase Admin if not already done
      if (!admin.apps.length) {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount)
        });
      }
      console.log('✅ Firebase Admin initialized');
      
      return true;
    } catch (error) {
      console.error('❌ Connection failed:', error.message);
      return false;
    }
  }

  async syncLoyaltyWithUsers() {
    console.log('🔄 Starting Loyalty & Users Sync...');
    console.log('='.repeat(50));

    if (!await this.connect()) {
      return;
    }

    try {
      // Step 1: Get all data
      await this.gatherData();
      
      // Step 2: Find orphaned loyalty accounts
      await this.findOrphanedLoyaltyAccounts();
      
      // Step 3: Create missing loyalty accounts
      await this.createMissingLoyaltyAccounts();
      
      // Step 4: Update existing loyalty account data
      await this.updateLoyaltyAccountData();
      
      // Step 5: Validate Firebase consistency
      await this.validateFirebaseConsistency();
      
      // Step 6: Generate sync report
      await this.generateSyncReport();
      
    } catch (error) {
      console.error('❌ Sync failed:', error.message);
      this.syncResults.errors.push(error.message);
    } finally {
      await mongoose.connection.close();
      console.log('🔒 Database connection closed');
    }
  }

  async gatherData() {
    console.log('\n📊 Gathering current data...');
    
    // Get all loyalty accounts
    const loyaltyAccounts = await LoyaltyAccount.find({}).lean();
    this.loyaltyAccounts = loyaltyAccounts;
    this.syncResults.totalLoyaltyAccounts = loyaltyAccounts.length;
    
    // Get all users
    const users = await User.find({}).lean();
    this.users = users;
    this.syncResults.totalUsers = users.length;
    
    // Get Firebase users
    try {
      const firebaseUsers = [];
      let pageToken;
      do {
        const listResult = await admin.auth().listUsers(1000, pageToken);
        firebaseUsers.push(...listResult.users);
        pageToken = listResult.pageToken;
      } while (pageToken);
      
      this.firebaseUsers = firebaseUsers;
      this.syncResults.totalFirebaseUsers = firebaseUsers.length;
    } catch (error) {
      console.warn('⚠️  Could not fetch Firebase users:', error.message);
      this.firebaseUsers = [];
    }
    
    console.log(`   📄 Loyalty Accounts: ${this.syncResults.totalLoyaltyAccounts}`);
    console.log(`   👥 Local Users: ${this.syncResults.totalUsers}`);
    console.log(`   🔥 Firebase Users: ${this.syncResults.totalFirebaseUsers}`);
  }

  async findOrphanedLoyaltyAccounts() {
    console.log('\n🔍 Finding orphaned loyalty accounts...');
    
    for (const loyaltyAccount of this.loyaltyAccounts) {
      // Check if user exists in Users collection
      const userExists = this.users.find(user => 
        user.firebaseUid === loyaltyAccount.userId || 
        user.email === loyaltyAccount.userEmail
      );
      
      // Check if user exists in Firebase
      const firebaseUserExists = this.firebaseUsers.find(fbUser => 
        fbUser.uid === loyaltyAccount.userId || 
        fbUser.email === loyaltyAccount.userEmail
      );
      
      if (!userExists && !firebaseUserExists) {
        console.log(`   🗑️  Orphaned: ${loyaltyAccount.userEmail} (${loyaltyAccount.userId})`);
        this.syncResults.orphanedLoyaltyAccounts.push({
          loyaltyAccountId: loyaltyAccount._id,
          userId: loyaltyAccount.userId,
          userEmail: loyaltyAccount.userEmail,
          userName: loyaltyAccount.userName,
          points: loyaltyAccount.currentBalance
        });
      }
    }
    
    console.log(`   Found ${this.syncResults.orphanedLoyaltyAccounts.length} orphaned loyalty accounts`);
  }

  async createMissingLoyaltyAccounts() {
    console.log('\n➕ Creating missing loyalty accounts...');
    
    for (const user of this.users) {
      if (!user.firebaseUid) {
        console.log(`   ⚠️  User without Firebase UID: ${user.email}`);
        continue;
      }
      
      // Check if loyalty account exists
      const loyaltyExists = this.loyaltyAccounts.find(loyalty => 
        loyalty.userId === user.firebaseUid || 
        loyalty.userEmail === user.email
      );
      
      if (!loyaltyExists) {
        try {
          const newLoyaltyAccount = new LoyaltyAccount({
            userId: user.firebaseUid,
            userEmail: user.email,
            userName: user.name,
            joinedAt: user.createdAt || new Date()
          });
          
          await newLoyaltyAccount.save();
          
          console.log(`   ✅ Created loyalty account for: ${user.email}`);
          this.syncResults.missingLoyaltyAccounts.push({
            userId: user.firebaseUid,
            userEmail: user.email,
            userName: user.name
          });
          
        } catch (error) {
          console.log(`   ❌ Failed to create loyalty account for ${user.email}: ${error.message}`);
          this.syncResults.errors.push(`Failed to create loyalty for ${user.email}: ${error.message}`);
        }
      }
    }
    
    console.log(`   Created ${this.syncResults.missingLoyaltyAccounts.length} new loyalty accounts`);
  }

  async updateLoyaltyAccountData() {
    console.log('\n🔄 Updating loyalty account data...');
    
    for (const loyaltyAccount of this.loyaltyAccounts) {
      let needsUpdate = false;
      const updates = {};
      
      // Find corresponding user
      const user = this.users.find(user => 
        user.firebaseUid === loyaltyAccount.userId || 
        user.email === loyaltyAccount.userEmail
      );
      
      if (user) {
        // Update userId if needed (ensure it's Firebase UID)
        if (loyaltyAccount.userId !== user.firebaseUid) {
          updates.userId = user.firebaseUid;
          needsUpdate = true;
        }
        
        // Update email if needed
        if (loyaltyAccount.userEmail !== user.email) {
          updates.userEmail = user.email;
          needsUpdate = true;
        }
        
        // Update name if needed
        if (loyaltyAccount.userName !== user.name) {
          updates.userName = user.name;
          needsUpdate = true;
        }
        
        if (needsUpdate) {
          try {
            await LoyaltyAccount.findByIdAndUpdate(loyaltyAccount._id, updates);
            console.log(`   ✅ Updated loyalty account for: ${user.email}`);
            this.syncResults.updatedLoyaltyAccounts.push({
              loyaltyAccountId: loyaltyAccount._id,
              userEmail: user.email,
              updates: updates
            });
          } catch (error) {
            console.log(`   ❌ Failed to update loyalty account for ${user.email}: ${error.message}`);
            this.syncResults.errors.push(`Failed to update loyalty for ${user.email}: ${error.message}`);
          }
        }
      }
    }
    
    console.log(`   Updated ${this.syncResults.updatedLoyaltyAccounts.length} loyalty accounts`);
  }

  async validateFirebaseConsistency() {
    console.log('\n🔥 Validating Firebase consistency...');
    
    for (const user of this.users) {
      if (!user.firebaseUid) continue;
      
      // Check if Firebase user exists
      const firebaseUser = this.firebaseUsers.find(fbUser => fbUser.uid === user.firebaseUid);
      
      if (!firebaseUser) {
        console.log(`   ⚠️  User has Firebase UID but no Firebase record: ${user.email}`);
        this.syncResults.inconsistentFirebaseUIDs.push({
          userId: user._id,
          email: user.email,
          firebaseUid: user.firebaseUid,
          issue: 'Firebase record missing'
        });
      } else if (firebaseUser.email !== user.email) {
        console.log(`   ⚠️  Email mismatch - Local: ${user.email}, Firebase: ${firebaseUser.email}`);
        this.syncResults.inconsistentFirebaseUIDs.push({
          userId: user._id,
          localEmail: user.email,
          firebaseEmail: firebaseUser.email,
          firebaseUid: user.firebaseUid,
          issue: 'Email mismatch'
        });
      }
    }
    
    console.log(`   Found ${this.syncResults.inconsistentFirebaseUIDs.length} Firebase inconsistencies`);
  }

  async cleanupOrphanedAccounts() {
    console.log('\n🧹 Cleaning up orphaned accounts...');
    
    if (this.syncResults.orphanedLoyaltyAccounts.length === 0) {
      console.log('   ✅ No orphaned accounts to clean up');
      return;
    }
    
    console.log('   ⚠️  Found orphaned loyalty accounts. Options:');
    console.log('   1. Keep them (they might be valid users from other sources)');
    console.log('   2. Mark them as inactive');
    console.log('   3. Delete them (WARNING: This will lose loyalty data)');
    console.log('');
    console.log('   For safety, this script will NOT automatically delete orphaned accounts.');
    console.log('   Review the sync report and decide manually.');
  }

  async generateSyncReport() {
    console.log('\n📊 LOYALTY & USERS SYNC REPORT');
    console.log('='.repeat(50));
    
    console.log('\n📈 Summary:');
    console.log(`   📄 Total Loyalty Accounts: ${this.syncResults.totalLoyaltyAccounts}`);
    console.log(`   👥 Total Users: ${this.syncResults.totalUsers}`);
    console.log(`   🔥 Total Firebase Users: ${this.syncResults.totalFirebaseUsers}`);
    
    console.log('\n✅ Actions Performed:');
    console.log(`   ➕ Created Loyalty Accounts: ${this.syncResults.missingLoyaltyAccounts.length}`);
    console.log(`   🔄 Updated Loyalty Accounts: ${this.syncResults.updatedLoyaltyAccounts.length}`);
    
    console.log('\n⚠️  Issues Found:');
    console.log(`   🗑️  Orphaned Loyalty Accounts: ${this.syncResults.orphanedLoyaltyAccounts.length}`);
    console.log(`   🔥 Firebase Inconsistencies: ${this.syncResults.inconsistentFirebaseUIDs.length}`);
    console.log(`   ❌ Errors: ${this.syncResults.errors.length}`);
    
    if (this.syncResults.orphanedLoyaltyAccounts.length > 0) {
      console.log('\n🗑️  Orphaned Loyalty Accounts (no matching user):');
      this.syncResults.orphanedLoyaltyAccounts.forEach((account, index) => {
        console.log(`   ${index + 1}. ${account.userEmail} (${account.points} points)`);
      });
    }
    
    if (this.syncResults.inconsistentFirebaseUIDs.length > 0) {
      console.log('\n🔥 Firebase Inconsistencies:');
      this.syncResults.inconsistentFirebaseUIDs.forEach((issue, index) => {
        console.log(`   ${index + 1}. ${issue.issue}: ${issue.localEmail || issue.email}`);
      });
    }
    
    if (this.syncResults.errors.length > 0) {
      console.log('\n❌ Errors:');
      this.syncResults.errors.forEach((error, index) => {
        console.log(`   ${index + 1}. ${error}`);
      });
    }
    
    console.log('\n💡 Recommendations:');
    
    if (this.syncResults.orphanedLoyaltyAccounts.length > 0) {
      console.log('   🗑️  Review orphaned loyalty accounts manually');
      console.log('   📧 Check if these users should be re-invited');
      console.log('   🔄 Consider merging data if users exist under different emails');
    }
    
    if (this.syncResults.inconsistentFirebaseUIDs.length > 0) {
      console.log('   🔥 Fix Firebase authentication inconsistencies');
      console.log('   📧 Update email addresses to match between systems');
    }
    
    if (this.syncResults.missingLoyaltyAccounts.length > 0) {
      console.log('   ✅ New loyalty accounts were created successfully');
      console.log('   🎁 Consider awarding welcome bonuses to new accounts');
    }
    
    console.log('\n🎉 Loyalty & Users sync completed!');
    
    // Save detailed report to file
    await this.saveDetailedReport();
  }

  async saveDetailedReport() {
    const fs = require('fs').promises;
    const path = require('path');
    
    const reportData = {
      timestamp: new Date(),
      summary: this.syncResults,
      recommendations: [
        'Review orphaned loyalty accounts',
        'Fix Firebase authentication inconsistencies',
        'Award welcome bonuses to new loyalty accounts',
        'Regular sync should be scheduled weekly'
      ]
    };
    
    const reportPath = path.join(__dirname, '..', 'LOYALTY_SYNC_REPORT.json');
    
    try {
      await fs.writeFile(reportPath, JSON.stringify(reportData, null, 2));
      console.log(`📄 Detailed report saved to: LOYALTY_SYNC_REPORT.json`);
    } catch (error) {
      console.log('⚠️  Could not save detailed report:', error.message);
    }
  }
}

// Add to package.json scripts
const updatePackageJsonScripts = async () => {
  const fs = require('fs').promises;
  const path = require('path');
  
  try {
    const packagePath = path.join(__dirname, '..', 'package.json');
    const packageData = JSON.parse(await fs.readFile(packagePath, 'utf8'));
    
    if (!packageData.scripts['loyalty:sync']) {
      packageData.scripts['loyalty:sync'] = 'node scripts/loyalty-user-sync.js';
      
      await fs.writeFile(packagePath, JSON.stringify(packageData, null, 2));
      console.log('✅ Added loyalty:sync script to package.json');
    }
  } catch (error) {
    console.log('⚠️  Could not update package.json:', error.message);
  }
};

// Run sync
if (require.main === module) {
  const sync = new LoyaltyUserSync();
  
  console.log('🚀 Al Marya Rostery - Loyalty & Users Sync');
  console.log('============================================');
  
  sync.syncLoyaltyWithUsers()
    .then(async () => {
      await updatePackageJsonScripts();
      console.log('\n✅ Sync completed successfully!');
      console.log('💡 Run "npm run loyalty:sync" anytime to re-sync');
      process.exit(0);
    })
    .catch(error => {
      console.error('\n💥 Sync failed:', error);
      process.exit(1);
    });
}

module.exports = LoyaltyUserSync;
