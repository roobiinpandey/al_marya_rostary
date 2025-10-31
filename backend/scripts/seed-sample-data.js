const mongoose = require('mongoose');
const { LoyaltyAccount, LoyaltyPoint, LoyaltyTier } = require('../models/Loyalty');
const { Referral, ReferralCode } = require('../models/Referral');
const Review = require('../models/Review');
const Subscription = require('../models/Subscription');
require('dotenv').config();

// Database connection
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('📍 MongoDB Connected for sample data seeding');
  } catch (err) {
    console.error('❌ Database connection failed:', err.message);
    process.exit(1);
  }
};

// Generate random data helpers
const getRandomElement = (array) => array[Math.floor(Math.random() * array.length)];
const getRandomNumber = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const getRandomDate = (start, end) => new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));

// Sample user IDs (you can replace these with actual user IDs from your database)
const sampleUserIds = [
  '507f1f77bcf86cd799439011',
  '507f1f77bcf86cd799439012',
  '507f1f77bcf86cd799439013',
  '507f1f77bcf86cd799439014',
  '507f1f77bcf86cd799439015',
  '507f1f77bcf86cd799439016',
  '507f1f77bcf86cd799439017',
  '507f1f77bcf86cd799439018',
  '507f1f77bcf86cd799439019',
  '507f1f77bcf86cd799439020'
];

// Sample products
const sampleProducts = [
  { id: 'prod_001', name: 'Ethiopian Yirgacheffe', price: 24.99 },
  { id: 'prod_002', name: 'Colombian Supremo', price: 22.99 },
  { id: 'prod_003', name: 'Jamaican Blue Mountain', price: 49.99 },
  { id: 'prod_004', name: 'Hawaiian Kona', price: 39.99 },
  { id: 'prod_005', name: 'Brazilian Santos', price: 19.99 },
  { id: 'prod_006', name: 'Guatemala Antigua', price: 26.99 },
  { id: 'prod_007', name: 'Kenya AA', price: 28.99 },
  { id: 'prod_008', name: 'Costa Rica Tarrazú', price: 25.99 }
];

// Sample reviews
const reviewComments = [
  'Absolutely love this coffee! The flavor is rich and complex with perfect acidity.',
  'Great coffee for the morning. Smooth taste and aromatic.',
  'One of my favorite blends. Highly recommend for coffee enthusiasts.',
  'Good quality coffee, though a bit pricey. Worth it for special occasions.',
  'Excellent roast! Perfect balance between boldness and smoothness.',
  'Not bad, but I expected more complexity in the flavor profile.',
  'Amazing coffee! Will definitely order again.',
  'Perfect for espresso. Great crema and intense flavor.',
  'Light and fruity notes make this perfect for pour-over brewing.',
  'Solid coffee, good value for money. Consistent quality.'
];

// Create sample reviews
const createSampleReviews = async () => {
  try {
    console.log('🌱 Creating sample reviews...');
    
    await Review.deleteMany({});
    
    const reviews = [];
    for (let i = 0; i < 25; i++) {
      const product = getRandomElement(sampleProducts);
      const userId = getRandomElement(sampleUserIds);
      
      reviews.push({
        userId: userId,
        productId: product.id,
        productName: product.name,
        rating: getRandomNumber(3, 5), // Mostly positive reviews
        comment: getRandomElement(reviewComments),
        user: {
          name: `Customer ${i + 1}`,
          email: `customer${i + 1}@example.com`,
          isVerified: Math.random() > 0.3 // 70% verified
        },
        status: getRandomElement(['approved', 'approved', 'approved', 'pending']), // Mostly approved
        helpfulVotes: getRandomNumber(0, 15),
        createdAt: getRandomDate(new Date(2024, 0, 1), new Date()),
        isVerifiedPurchase: Math.random() > 0.2 // 80% verified purchases
      });
    }
    
    const insertedReviews = await Review.insertMany(reviews);
    console.log(`✅ Created ${insertedReviews.length} sample reviews`);
    
    return insertedReviews;
  } catch (error) {
    console.error('❌ Error creating sample reviews:', error);
    throw error;
  }
};

// Create sample loyalty accounts
const createSampleLoyaltyAccounts = async () => {
  try {
    console.log('🌱 Creating sample loyalty accounts...');
    
    await LoyaltyAccount.deleteMany({});
    await LoyaltyPoint.deleteMany({});
    
    // Get available tiers
    const tiers = await LoyaltyTier.find().sort({ minPoints: 1 });
    
    const accounts = [];
    const pointTransactions = [];
    
    for (let i = 0; i < sampleUserIds.length; i++) {
      const userId = sampleUserIds[i];
      const totalPoints = getRandomNumber(0, 25000);
      
      // Determine tier based on points
      let currentTier = tiers[0]; // Default to Bronze
      for (const tier of tiers) {
        if (totalPoints >= tier.minPoints && (!tier.maxPoints || totalPoints <= tier.maxPoints)) {
          currentTier = tier;
        }
      }
      
      const account = {
        userId: userId,
        user: {
          name: `Customer ${i + 1}`,
          email: `customer${i + 1}@example.com`
        },
        totalPoints: totalPoints,
        availablePoints: Math.floor(totalPoints * 0.8), // 80% available
        currentTier: currentTier.name,
        tierProgress: {
          currentPoints: totalPoints,
          nextTierPoints: currentTier.maxPoints,
          progressPercentage: currentTier.maxPoints ? 
            Math.min((totalPoints / currentTier.maxPoints) * 100, 100) : 100
        },
        joinedAt: getRandomDate(new Date(2023, 0, 1), new Date()),
        lastActivity: getRandomDate(new Date(2024, 0, 1), new Date())
      };
      
      accounts.push(account);
      
      // Create some point transactions for this user
      const numTransactions = getRandomNumber(3, 10);
      for (let j = 0; j < numTransactions; j++) {
        pointTransactions.push({
          userId: userId,
          points: getRandomNumber(50, 500),
          type: getRandomElement(['earned', 'earned', 'earned', 'spent']), // Mostly earned
          source: getRandomElement(['purchase', 'review', 'referral', 'bonus', 'redemption']),
          description: `${getRandomElement(['Purchase reward', 'Review bonus', 'Referral reward', 'Monthly bonus', 'Points redemption'])}`,
          orderId: `order_${getRandomNumber(1000, 9999)}`,
          createdAt: getRandomDate(new Date(2024, 0, 1), new Date())
        });
      }
    }
    
    const insertedAccounts = await LoyaltyAccount.insertMany(accounts);
    const insertedTransactions = await LoyaltyPoint.insertMany(pointTransactions);
    
    console.log(`✅ Created ${insertedAccounts.length} loyalty accounts`);
    console.log(`✅ Created ${insertedTransactions.length} point transactions`);
    
    return { accounts: insertedAccounts, transactions: insertedTransactions };
  } catch (error) {
    console.error('❌ Error creating sample loyalty accounts:', error);
    throw error;
  }
};

// Create sample referrals
const createSampleReferrals = async () => {
  try {
    console.log('🌱 Creating sample referrals...');
    
    await Referral.deleteMany({});
    await ReferralCode.deleteMany({});
    
    const referrals = [];
    const referralCodes = [];
    
    for (let i = 0; i < 15; i++) {
      const referrerId = getRandomElement(sampleUserIds);
      const code = `REF${getRandomNumber(1000, 9999)}`;
      
      // Create referral code
      referralCodes.push({
        code: code,
        userId: referrerId,
        user: {
          name: `Customer ${sampleUserIds.indexOf(referrerId) + 1}`,
          email: `customer${sampleUserIds.indexOf(referrerId) + 1}@example.com`
        },
        isActive: true,
        clickCount: getRandomNumber(5, 50),
        conversionCount: getRandomNumber(0, 10),
        createdAt: getRandomDate(new Date(2024, 0, 1), new Date())
      });
      
      // Create some successful referrals
      const successfulReferrals = getRandomNumber(0, 5);
      for (let j = 0; j < successfulReferrals; j++) {
        const refereeId = getRandomElement(sampleUserIds.filter(id => id !== referrerId));
        
        referrals.push({
          referrerId: referrerId,
          refereeId: refereeId,
          referralCode: code,
          referrer: {
            name: `Customer ${sampleUserIds.indexOf(referrerId) + 1}`,
            email: `customer${sampleUserIds.indexOf(referrerId) + 1}@example.com`
          },
          referee: {
            name: `Customer ${sampleUserIds.indexOf(refereeId) + 1}`,
            email: `customer${sampleUserIds.indexOf(refereeId) + 1}@example.com`
          },
          status: 'completed',
          rewards: {
            referrerReward: { points: 500, discount: 10 },
            refereeReward: { points: 250, discount: 10 }
          },
          clickedAt: getRandomDate(new Date(2024, 0, 1), new Date()),
          registeredAt: getRandomDate(new Date(2024, 0, 1), new Date()),
          completedAt: getRandomDate(new Date(2024, 0, 1), new Date())
        });
      }
    }
    
    const insertedCodes = await ReferralCode.insertMany(referralCodes);
    const insertedReferrals = await Referral.insertMany(referrals);
    
    console.log(`✅ Created ${insertedCodes.length} referral codes`);
    console.log(`✅ Created ${insertedReferrals.length} completed referrals`);
    
    return { codes: insertedCodes, referrals: insertedReferrals };
  } catch (error) {
    console.error('❌ Error creating sample referrals:', error);
    throw error;
  }
};

// Create sample subscriptions
const createSampleSubscriptions = async () => {
  try {
    console.log('🌱 Creating sample subscriptions...');
    
    await Subscription.deleteMany({});
    
    const subscriptions = [];
    const frequencies = ['daily', 'weekly', 'bi-weekly', 'monthly'];
    const statuses = ['active', 'active', 'active', 'paused', 'cancelled'];
    
    for (let i = 0; i < 12; i++) {
      const userId = getRandomElement(sampleUserIds);
      const frequency = getRandomElement(frequencies);
      const status = getRandomElement(statuses);
      
      const subscription = {
        userId: userId,
        user: {
          name: `Customer ${sampleUserIds.indexOf(userId) + 1}`,
          email: `customer${sampleUserIds.indexOf(userId) + 1}@example.com`,
          phone: `+1-555-${getRandomNumber(1000, 9999)}`
        },
        products: [
          {
            productId: getRandomElement(sampleProducts).id,
            name: getRandomElement(sampleProducts).name,
            quantity: getRandomNumber(1, 3),
            price: getRandomNumber(15, 45)
          }
        ],
        frequency: frequency,
        deliveryAddress: {
          street: `${getRandomNumber(100, 9999)} Main Street`,
          city: getRandomElement(['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix']),
          state: getRandomElement(['NY', 'CA', 'IL', 'TX', 'AZ']),
          zipCode: `${getRandomNumber(10000, 99999)}`,
          country: 'USA'
        },
        deliveryInstructions: getRandomElement([
          'Leave at front door',
          'Ring doorbell',
          'Leave with concierge',
          'Call upon arrival',
          'Leave in safe location'
        ]),
        nextDeliveryDate: new Date(Date.now() + getRandomNumber(1, 14) * 24 * 60 * 60 * 1000),
        totalAmount: getRandomNumber(25, 150),
        paymentMethod: getRandomElement(['credit_card', 'debit_card', 'paypal']),
        status: status,
        createdAt: getRandomDate(new Date(2024, 0, 1), new Date()),
        deliveries: []
      };
      
      // Add some delivery history for active/paused subscriptions
      if (status !== 'cancelled') {
        const numDeliveries = getRandomNumber(2, 8);
        for (let j = 0; j < numDeliveries; j++) {
          subscription.deliveries.push({
            date: getRandomDate(new Date(2024, 0, 1), new Date()),
            status: getRandomElement(['delivered', 'delivered', 'delivered', 'pending']),
            trackingNumber: `TRK${getRandomNumber(100000, 999999)}`,
            deliveryAddress: subscription.deliveryAddress,
            notes: j === 0 ? 'First delivery - welcome package included' : '',
            deliveredAt: getRandomDate(new Date(2024, 0, 1), new Date())
          });
        }
      }
      
      subscriptions.push(subscription);
    }
    
    const insertedSubscriptions = await Subscription.insertMany(subscriptions);
    console.log(`✅ Created ${insertedSubscriptions.length} sample subscriptions`);
    
    return insertedSubscriptions;
  } catch (error) {
    console.error('❌ Error creating sample subscriptions:', error);
    throw error;
  }
};

// Main seeding function
const seedSampleData = async () => {
  try {
    console.log('🚀 Starting Sample Data Seeding Process...\n');
    
    await connectDB();
    
    // Check if loyalty tiers exist (required for loyalty accounts)
    const tierCount = await LoyaltyTier.countDocuments();
    if (tierCount === 0) {
      console.log('⚠️  No loyalty tiers found. Please run seed-loyalty-tiers.js first.');
      console.log('   Running: npm run seed:tiers');
      process.exit(1);
    }
    
    // Seed all sample data
    await createSampleReviews();
    await createSampleLoyaltyAccounts();
    await createSampleReferrals();
    await createSampleSubscriptions();
    
    console.log('\n🎉 Sample data seeding completed successfully!');
    console.log('📊 Summary:');
    console.log('   • Sample reviews with ratings and comments');
    console.log('   • Loyalty accounts with point transactions');
    console.log('   • Referral codes and completed referrals');
    console.log('   • Active subscriptions with delivery history');
    console.log('\n💡 Your backend now has realistic test data for frontend development!');
    
  } catch (error) {
    console.error('\n❌ Sample data seeding failed:', error);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log('📍 Database connection closed');
    process.exit(0);
  }
};

// Run seeding if called directly
if (require.main === module) {
  seedSampleData();
}

module.exports = { 
  seedSampleData,
  createSampleReviews,
  createSampleLoyaltyAccounts,
  createSampleReferrals,
  createSampleSubscriptions
};
