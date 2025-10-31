#!/usr/bin/env node

/**
 * Manual Loyalty Account Creator
 * 
 * This script manually creates missing loyalty accounts for users
 * who don't have Firebase UIDs (temporary/guest accounts)
 */

const mongoose = require('mongoose');
const User = require('../models/User');
const { LoyaltyAccount } = require('../models/Loyalty');
require('dotenv').config();

const createMissingLoyaltyAccounts = async () => {
  try {
    console.log('🔧 MANUAL LOYALTY ACCOUNT CREATION');
    console.log('===================================');
    
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');
    
    // Find users without loyalty accounts
    const allUsers = await User.find({});
    const loyaltyAccounts = await LoyaltyAccount.find({});
    const loyaltyEmails = new Set(loyaltyAccounts.map(l => l.userEmail));
    
    const usersWithoutLoyalty = allUsers.filter(user => 
      !loyaltyEmails.has(user.email)
    );
    
    console.log(`\n📊 Found ${usersWithoutLoyalty.length} users without loyalty accounts:`);
    
    if (usersWithoutLoyalty.length === 0) {
      console.log('🎉 All users already have loyalty accounts!');
      return;
    }
    
    let created = 0;
    
    for (const user of usersWithoutLoyalty) {
      try {
        console.log(`\n🔨 Creating loyalty account for: ${user.email}`);
        
        const loyaltyAccount = new LoyaltyAccount({
          userId: user.firebaseUID || user._id.toString(), // Use MongoDB _id if no Firebase UID
          userEmail: user.email,
          userName: user.name || 'User',
          currentBalance: 0,
          totalPointsEarned: 0,
          totalPointsSpent: 0,
          currentTier: 'Bronze',
          joinedAt: new Date(),
          lastActivity: new Date()
        });
        
        await loyaltyAccount.save();
        console.log(`   ✅ Created loyalty account with ID: ${loyaltyAccount._id}`);
        created++;
        
      } catch (error) {
        console.log(`   ❌ Failed to create loyalty account for ${user.email}: ${error.message}`);
      }
    }
    
    console.log(`\n🎉 CREATION SUMMARY`);
    console.log(`====================`);
    console.log(`✅ Successfully created: ${created} loyalty accounts`);
    console.log(`❌ Failed to create: ${usersWithoutLoyalty.length - created} accounts`);
    
    // Verify final count
    const finalLoyaltyCount = await LoyaltyAccount.countDocuments();
    const finalUserCount = await User.countDocuments();
    
    console.log(`\n📊 FINAL COUNTS`);
    console.log(`================`);
    console.log(`👥 Total Users: ${finalUserCount}`);
    console.log(`🏆 Total Loyalty Accounts: ${finalLoyaltyCount}`);
    console.log(`📈 Sync Percentage: ${((finalLoyaltyCount / finalUserCount) * 100).toFixed(1)}%`);
    
    if (finalLoyaltyCount === finalUserCount) {
      console.log('🎉 PERFECT SYNC ACHIEVED!');
    } else {
      console.log(`⚠️  Still missing ${finalUserCount - finalLoyaltyCount} loyalty accounts`);
    }
    
  } catch (error) {
    console.error('❌ Manual creation failed:', error.message);
    console.error(error.stack);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔒 Database connection closed');
  }
};

// Run the manual creation
if (require.main === module) {
  createMissingLoyaltyAccounts()
    .then(() => {
      console.log('\n✅ Manual loyalty account creation completed!');
      process.exit(0);
    })
    .catch(error => {
      console.error('\n💥 Manual creation failed:', error);
      process.exit(1);
    });
}

module.exports = { createMissingLoyaltyAccounts };
