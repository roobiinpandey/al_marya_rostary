require('dotenv').config();
const mongoose = require('mongoose');
const { SubscriptionPlan } = require('../models/Subscription');

// SECURITY: MongoDB URI must be provided via environment variable
const MONGODB_URI = process.env.MONGODB_URI;
if (!MONGODB_URI) {
  console.error('❌ MONGODB_URI environment variable is required');
  process.exit(1);
}

// Subscription Plans Seed Data matching the actual SubscriptionPlan schema
const subscriptionPlans = [
  {
    planId: 'WEEKLY_BASIC',
    name: 'Weekly Basic Plan',
    description: 'Perfect for coffee lovers who want fresh coffee every week. Get consistent delivery of your favorite coffee with 10% savings.',
    frequency: 'weekly',
    discountPercentage: 10,
    minCommitmentMonths: 1,
    benefits: [
      'Weekly delivery of fresh coffee',
      '10% discount on all orders',
      'Free delivery',
      'Flexible pause and skip options',
      'Cancel anytime after 1 month'
    ],
    isActive: true,
    sortOrder: 1
  },
  {
    planId: 'BIWEEKLY_STANDARD',
    name: 'Bi-Weekly Standard Plan',
    description: 'Great balance of convenience and value. Receive your coffee every two weeks with 15% savings on every order.',
    frequency: 'bi-weekly',
    discountPercentage: 15,
    minCommitmentMonths: 1,
    benefits: [
      'Bi-weekly delivery (every 2 weeks)',
      '15% discount on all orders',
      'Free priority delivery',
      'Skip or reschedule deliveries easily',
      'Exclusive access to new releases',
      'Cancel anytime after 1 month'
    ],
    isActive: true,
    sortOrder: 2
  },
  {
    planId: 'MONTHLY_PREMIUM',
    name: 'Monthly Premium Plan',
    description: 'Best value for coffee enthusiasts. Get monthly deliveries with the highest discount and exclusive perks.',
    frequency: 'monthly',
    discountPercentage: 20,
    minCommitmentMonths: 1,
    benefits: [
      'Monthly delivery on your chosen date',
      '20% discount on all orders',
      'Free express delivery',
      'Exclusive limited edition coffees',
      'Personal coffee consultation',
      'Birthday gift included',
      'Priority customer support',
      'Cancel anytime after 1 month'
    ],
    isActive: true,
    sortOrder: 3
  },
  {
    planId: 'QUARTERLY_VIP',
    name: 'Quarterly VIP Plan',
    description: 'Premium experience for serious coffee connoisseurs. Quarterly deliveries with maximum savings and VIP benefits.',
    frequency: 'quarterly',
    discountPercentage: 25,
    minCommitmentMonths: 3,
    benefits: [
      'Quarterly delivery (every 3 months)',
      '25% discount on all orders',
      'Free express delivery worldwide',
      'Exclusive VIP-only coffee releases',
      'Personal barista consultation',
      'Coffee accessories gift set',
      'Invitation to exclusive tasting events',
      'Dedicated VIP support line',
      'Free coffee grinder after 1 year',
      'Cancel anytime after 3 months'
    ],
    isActive: true,
    sortOrder: 4
  }
];

// Main seeding function
async function seedSubscriptionPlans() {
  try {
    console.log('🌱 Starting subscription plans seeding...');
    console.log('� Connecting to MongoDB...');
    
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Check existing plans
    const existingCount = await SubscriptionPlan.countDocuments();
    console.log(`\n📦 Found ${existingCount} existing subscription plans`);
    
    if (existingCount > 0) {
      console.log('🗑️  Clearing existing plans...');
      await SubscriptionPlan.deleteMany({});
      console.log('✅ Cleared existing plans');
    }

    // Insert new plans
    console.log(`\n🌱 Inserting ${subscriptionPlans.length} subscription plans...`);
    const inserted = await SubscriptionPlan.insertMany(subscriptionPlans);
    console.log(`✅ Successfully inserted ${inserted.length} subscription plans`);

    // Display summary
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📋 Subscription Plans Created:');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    for (const plan of inserted) {
      console.log(`\n📦 ${plan.name}`);
      console.log(`   🆔 Plan ID: ${plan.planId}`);
      console.log(`   📅 Frequency: ${plan.frequency}`);
      console.log(`   💰 Discount: ${plan.discountPercentage}%`);
      console.log(`   📝 Min Commitment: ${plan.minCommitmentMonths} month(s)`);
      console.log(`   ✨ Benefits: ${plan.benefits.length} items`);
      console.log(`   🎯 Sort Order: ${plan.sortOrder}`);
      console.log(`   ✅ Active: ${plan.isActive}`);
    }

    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('✅ Seeding completed successfully!');
    console.log('\n💡 Next steps:');
    console.log('   1. Test the API: GET /api/subscriptions/plans');
    console.log('   2. Open your Flutter app and navigate to subscriptions');
    console.log('   3. Users can now see and create subscriptions!');
    console.log('\n📱 API Endpoints:');
    console.log('   • GET    /api/subscriptions/plans - List all plans');
    console.log('   • POST   /api/subscriptions       - Create subscription');
    console.log('   • GET    /api/subscriptions       - Get user subscriptions');
    console.log('   • PATCH  /api/subscriptions/:id   - Update subscription');
    console.log('   • POST   /api/subscriptions/:id/pause   - Pause subscription');
    console.log('   • POST   /api/subscriptions/:id/resume  - Resume subscription');
    console.log('   • POST   /api/subscriptions/:id/cancel  - Cancel subscription');

    await mongoose.connection.close();
    console.log('\n👋 Database connection closed');
    process.exit(0);

  } catch (error) {
    console.error('\n❌ Error seeding subscription plans:', error.message);
    console.error('Stack trace:', error.stack);
    process.exit(1);
  }
}

// Run the seeding
if (require.main === module) {
  seedSubscriptionPlans();
}

module.exports = { seedSubscriptionPlans };
