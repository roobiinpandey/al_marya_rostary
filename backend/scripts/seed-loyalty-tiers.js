const mongoose = require('mongoose');
const { LoyaltyTier } = require('../models/Loyalty');
require('dotenv').config();

// Database connection
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('📍 MongoDB Connected for seeding');
  } catch (err) {
    console.error('❌ Database connection failed:', err.message);
    process.exit(1);
  }
};

// Loyalty Tiers Seed Data
const loyaltyTiers = [
  {
    name: 'Bronze',
    minPoints: 0,
    maxPoints: 999,
    benefits: [
      'Basic customer support',
      'Order tracking',
      'Newsletter updates',
      '1 point per $1 spent'
    ],
    color: '#cd7f32',
    description: 'Welcome to our loyalty program! Start earning points with every purchase.',
    pointsMultiplier: 1.0,
    isActive: true
  },
  {
    name: 'Silver',
    minPoints: 1000,
    maxPoints: 2999,
    benefits: [
      'Priority customer support',
      'Free shipping on orders over $50',
      'Early access to sales',
      '1.2 points per $1 spent',
      'Birthday discount (10%)'
    ],
    color: '#c0c0c0',
    description: 'Unlock better rewards and enjoy priority support!',
    pointsMultiplier: 1.2,
    isActive: true
  },
  {
    name: 'Gold',
    minPoints: 3000,
    maxPoints: 7999,
    benefits: [
      'Premium customer support',
      'Free shipping on all orders',
      'Exclusive member-only products',
      '1.5 points per $1 spent',
      'Birthday discount (15%)',
      'Quarterly bonus points'
    ],
    color: '#ffd700',
    description: 'Experience premium benefits and exclusive access to special products!',
    pointsMultiplier: 1.5,
    isActive: true
  },
  {
    name: 'Platinum',
    minPoints: 8000,
    maxPoints: 19999,
    benefits: [
      'VIP customer support',
      'Free express shipping',
      'Personal account manager',
      '2.0 points per $1 spent',
      'Birthday discount (20%)',
      'Monthly bonus points',
      'Exclusive events invitations'
    ],
    color: '#e5e4e2',
    description: 'Enjoy VIP treatment with personal service and exclusive events!',
    pointsMultiplier: 2.0,
    isActive: true
  },
  {
    name: 'Diamond',
    minPoints: 20000,
    maxPoints: null,
    benefits: [
      'Concierge-level customer support',
      'Free same-day delivery',
      'Dedicated account manager',
      '2.5 points per $1 spent',
      'Birthday discount (25%)',
      'Weekly bonus points',
      'VIP events and tastings',
      'Custom coffee blends',
      'Annual loyalty gift'
    ],
    color: '#b9f2ff',
    description: 'The ultimate coffee experience with concierge service and custom blends!',
    pointsMultiplier: 2.5,
    isActive: true
  }
];

// Seed Loyalty Tiers
const seedLoyaltyTiers = async () => {
  try {
    console.log('🌱 Seeding Loyalty Tiers...');
    
    // Clear existing tiers
    await LoyaltyTier.deleteMany({});
    console.log('🧹 Cleared existing loyalty tiers');
    
    // Insert new tiers
    const insertedTiers = await LoyaltyTier.insertMany(loyaltyTiers);
    console.log(`✅ Inserted ${insertedTiers.length} loyalty tiers:`);
    
    insertedTiers.forEach(tier => {
      console.log(`   • ${tier.name}: ${tier.minPoints}${tier.maxPoints ? ` - ${tier.maxPoints}` : '+'} points`);
    });
    
    return insertedTiers;
  } catch (error) {
    console.error('❌ Error seeding loyalty tiers:', error);
    throw error;
  }
};

// Main seeding function
const seedDatabase = async () => {
  try {
    console.log('🚀 Starting Database Seeding Process...\n');
    
    await connectDB();
    
    // Seed loyalty tiers
    await seedLoyaltyTiers();
    
    console.log('\n🎉 Database seeding completed successfully!');
    console.log('📊 Summary:');
    console.log('   • 5 Loyalty Tiers created (Bronze → Diamond)');
    console.log('   • Point multipliers configured');
    console.log('   • Benefits and descriptions added');
    
  } catch (error) {
    console.error('\n❌ Database seeding failed:', error);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log('📍 Database connection closed');
    process.exit(0);
  }
};

// Run seeding if called directly
if (require.main === module) {
  seedDatabase();
}

module.exports = { seedDatabase, seedLoyaltyTiers };
