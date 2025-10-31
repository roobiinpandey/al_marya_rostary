const { seedLoyaltyTiers } = require('./seed-loyalty-tiers');
const { seedSubscriptionPlans } = require('./seed-subscription-plans');
const { seedSampleData } = require('./seed-sample-data');
const mongoose = require('mongoose');
require('dotenv').config();

// Database connection
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('📍 MongoDB Connected for complete seeding');
  } catch (err) {
    console.error('❌ Database connection failed:', err.message);
    process.exit(1);
  }
};

// Complete database seeding
const seedAll = async () => {
  try {
    console.log('🚀 Starting Complete Database Seeding Process...\n');
    console.log('This will seed all necessary data for the Al Marya Rostery backend:\n');
    
    await connectDB();
    
    // 1. Seed Loyalty Tiers (required first)
    console.log('📊 Step 1: Seeding Loyalty Tiers...');
    await seedLoyaltyTiers();
    console.log('✅ Loyalty Tiers completed\n');
    
    // 2. Seed Subscription Plans
    console.log('📋 Step 2: Seeding Subscription Plans...');
    await seedSubscriptionPlans();
    console.log('✅ Subscription Plans completed\n');
    
    // 3. Seed Sample Data (reviews, loyalty accounts, referrals, subscriptions)
    console.log('🎭 Step 3: Seeding Sample Data...');
    await seedSampleData();
    console.log('✅ Sample Data completed\n');
    
    console.log('🎉 COMPLETE DATABASE SEEDING FINISHED! 🎉\n');
    console.log('🗃️  Database Summary:');
    console.log('   📈 Loyalty System:');
    console.log('      • 5 Loyalty Tiers (Bronze → Diamond)');
    console.log('      • 10 Loyalty Accounts with transactions');
    console.log('      • Point earning and spending history');
    console.log('');
    console.log('   📝 Reviews System:');
    console.log('      • 25 Sample reviews with ratings');
    console.log('      • Mix of approved and pending reviews');
    console.log('      • Verified purchase indicators');
    console.log('');
    console.log('   🤝 Referral System:');
    console.log('      • 15 Referral codes with tracking');
    console.log('      • Completed referrals with rewards');
    console.log('      • Click and conversion analytics');
    console.log('');
    console.log('   📦 Subscription System:');
    console.log('      • 5 Subscription Plans (daily → custom)');
    console.log('      • 12 Active subscriptions with delivery history');
    console.log('      • Various frequencies and statuses');
    console.log('');
    console.log('🚀 Your backend is now ready for:');
    console.log('   • Flutter app integration testing');
    console.log('   • Admin panel feature demonstration');
    console.log('   • API endpoint validation');
    console.log('   • Real-world usage simulation');
    console.log('');
    console.log('🔗 Next Steps:');
    console.log('   1. Test API endpoints with the new data');
    console.log('   2. Access admin panel to manage features');
    console.log('   3. Connect Flutter app to backend');
    console.log('   4. Validate end-to-end functionality');
    
  } catch (error) {
    console.error('\n❌ Complete database seeding failed:', error);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log('\n📍 Database connection closed');
    process.exit(0);
  }
};

// Run complete seeding if called directly
if (require.main === module) {
  console.log('🌱 Al Marya Rostery - Complete Database Seeding');
  console.log('===============================================\n');
  seedAll();
}

module.exports = { seedAll };
