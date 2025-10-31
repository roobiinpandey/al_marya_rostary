#!/usr/bin/env node

/**
 * Welcome Bonus for New Loyalty Accounts
 * 
 * This script awards welcome bonuses to loyalty accounts that were just created
 * during the sync process.
 */

const mongoose = require('mongoose');
const { LoyaltyAccount, LoyaltyPoint } = require('../models/Loyalty');
require('dotenv').config();

const awardWelcomeBonuses = async () => {
  try {
    console.log('🎁 Al Marya Rostery - Welcome Bonus Awards');
    console.log('==========================================');
    
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');
    
    // Find loyalty accounts created today (just synced)
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const newLoyaltyAccounts = await LoyaltyAccount.find({
      joinedAt: { $gte: today },
      currentBalance: 0 // Only accounts with no points yet
    });
    
    console.log(`\n🔍 Found ${newLoyaltyAccounts.length} new loyalty accounts eligible for welcome bonus`);
    
    if (newLoyaltyAccounts.length === 0) {
      console.log('ℹ️  No new accounts found. Welcome bonuses may have already been awarded.');
      return;
    }
    
    const welcomeBonus = 100; // 100 points welcome bonus
    let awarded = 0;
    let skipped = 0;
    
    for (const account of newLoyaltyAccounts) {
      try {
        // Skip guest accounts for welcome bonus (optional)
        if (account.userEmail.includes('guest_') && account.userEmail.includes('@temp.com')) {
          console.log(`   ⏭️  Skipped guest account: ${account.userEmail}`);
          skipped++;
          continue;
        }
        
        // Award welcome bonus
        await account.addPoints(
          welcomeBonus,
          'earned_signup',
          '🎉 Welcome to Al Marya Rostery Loyalty Program! Enjoy your bonus points.',
          { welcomeBonus: true }
        );
        
        console.log(`   🎁 Awarded ${welcomeBonus} points to: ${account.userName || account.userEmail}`);
        awarded++;
        
      } catch (error) {
        console.log(`   ❌ Failed to award bonus to ${account.userEmail}: ${error.message}`);
      }
    }
    
    console.log('\n📊 WELCOME BONUS SUMMARY');
    console.log('========================');
    console.log(`🎁 Bonuses Awarded: ${awarded}`);
    console.log(`⏭️  Guest Accounts Skipped: ${skipped}`);
    console.log(`💰 Total Points Awarded: ${awarded * welcomeBonus}`);
    
    if (awarded > 0) {
      console.log('\n🎉 Welcome bonuses have been successfully awarded!');
      console.log('💡 Your loyalty members now have points to start their journey.');
    }
    
    // Show updated loyalty summary
    const totalAccounts = await LoyaltyAccount.countDocuments();
    const totalPoints = await LoyaltyAccount.aggregate([
      { $group: { _id: null, total: { $sum: '$currentBalance' } } }
    ]);
    
    console.log('\n📈 UPDATED LOYALTY PROGRAM STATS');
    console.log('=================================');
    console.log(`👥 Total Loyalty Members: ${totalAccounts}`);
    console.log(`💰 Total Points in Circulation: ${totalPoints[0]?.total || 0}`);
    console.log(`🎯 Average Points per Member: ${((totalPoints[0]?.total || 0) / totalAccounts).toFixed(1)}`);
    
  } catch (error) {
    console.error('❌ Welcome bonus process failed:', error.message);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log('🔒 Database connection closed');
  }
};

// Run the welcome bonus script
if (require.main === module) {
  awardWelcomeBonuses()
    .then(() => {
      console.log('\n✅ Welcome bonus process completed!');
      process.exit(0);
    })
    .catch(error => {
      console.error('\n💥 Welcome bonus failed:', error);
      process.exit(1);
    });
}

module.exports = { awardWelcomeBonuses };
