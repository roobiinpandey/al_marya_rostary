const mongoose = require('mongoose');
require('dotenv').config();

// Subscription Plans Seed Data (stored as documents in a SubscriptionPlan collection)
const subscriptionPlans = [
  {
    name: 'Daily Morning Brew',
    frequency: 'daily',
    description: 'Start every morning with freshly roasted coffee delivered to your door',
    features: [
      'Daily delivery Monday-Friday',
      'Weekend delivery optional',
      'Choose from 5+ coffee varieties',
      'Free delivery',
      '10% discount on all products'
    ],
    pricing: {
      basePrice: 15.99,
      discountPercentage: 10,
      minimumOrder: 1,
      freeShipping: true
    },
    deliveryOptions: {
      timeSlots: ['6:00-8:00 AM', '8:00-10:00 AM', '10:00-12:00 PM'],
      instructions: 'Perfect for early risers who need their daily coffee fix'
    },
    isActive: true,
    popularityRank: 1
  },
  {
    name: 'Weekly Coffee Discovery',
    frequency: 'weekly',
    description: 'Explore new coffee flavors with our curated weekly selection',
    features: [
      'Weekly delivery (choose your day)',
      'Curated selection of premium coffees',
      'Tasting notes included',
      'Free delivery on orders over $50',
      '15% discount on additional purchases'
    ],
    pricing: {
      basePrice: 29.99,
      discountPercentage: 15,
      minimumOrder: 2,
      freeShipping: true
    },
    deliveryOptions: {
      timeSlots: ['Morning (8:00-12:00)', 'Afternoon (12:00-17:00)', 'Evening (17:00-20:00)'],
      instructions: 'Great for coffee enthusiasts who want variety'
    },
    isActive: true,
    popularityRank: 2
  },
  {
    name: 'Bi-Weekly Office Supply',
    frequency: 'bi-weekly',
    description: 'Keep your office stocked with premium coffee every two weeks',
    features: [
      'Bi-weekly delivery',
      'Bulk ordering options',
      'Perfect for office environments',
      'Free delivery on all orders',
      '20% discount on bulk purchases',
      'Flexible quantity adjustments'
    ],
    pricing: {
      basePrice: 89.99,
      discountPercentage: 20,
      minimumOrder: 5,
      freeShipping: true
    },
    deliveryOptions: {
      timeSlots: ['Business Hours (9:00-17:00)', 'After Hours (17:00-19:00)'],
      instructions: 'Ideal for offices and teams of 5-20 people'
    },
    isActive: true,
    popularityRank: 3
  },
  {
    name: 'Monthly Premium Selection',
    frequency: 'monthly',
    description: 'Monthly delivery of our finest coffee selections and exclusive blends',
    features: [
      'Monthly delivery of premium coffees',
      'Exclusive and limited edition blends',
      'Coffee education materials',
      'Free delivery worldwide',
      '25% discount on all products',
      'Priority customer support'
    ],
    pricing: {
      basePrice: 119.99,
      discountPercentage: 25,
      minimumOrder: 3,
      freeShipping: true
    },
    deliveryOptions: {
      timeSlots: ['Flexible (arrange with customer)', 'Standard (10:00-16:00)'],
      instructions: 'Perfect for serious coffee connoisseurs'
    },
    isActive: true,
    popularityRank: 4
  },
  {
    name: 'Custom Business Plan',
    frequency: 'custom',
    description: 'Tailored subscription for businesses with specific requirements',
    features: [
      'Custom delivery schedule',
      'Volume pricing available',
      'Dedicated account manager',
      'Custom blending options',
      'Invoice billing available',
      'Training and support included'
    ],
    pricing: {
      basePrice: 0, // Custom pricing
      discountPercentage: 30,
      minimumOrder: 10,
      freeShipping: true
    },
    deliveryOptions: {
      timeSlots: ['Custom arrangement'],
      instructions: 'Contact sales team for custom pricing and setup'
    },
    isActive: true,
    popularityRank: 5
  }
];

// Database connection
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('📍 MongoDB Connected for subscription seeding');
  } catch (err) {
    console.error('❌ Database connection failed:', err.message);
    process.exit(1);
  }
};

// Create SubscriptionPlan schema (if not exists)
const subscriptionPlanSchema = new mongoose.Schema({
  name: { type: String, required: true, unique: true },
  frequency: { 
    type: String, 
    enum: ['daily', 'weekly', 'bi-weekly', 'monthly', 'custom'], 
    required: true 
  },
  description: { type: String, required: true },
  features: [{ type: String }],
  pricing: {
    basePrice: { type: Number, default: 0 },
    discountPercentage: { type: Number, default: 0 },
    minimumOrder: { type: Number, default: 1 },
    freeShipping: { type: Boolean, default: false }
  },
  deliveryOptions: {
    timeSlots: [{ type: String }],
    instructions: { type: String }
  },
  isActive: { type: Boolean, default: true },
  popularityRank: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

const SubscriptionPlan = mongoose.model('SubscriptionPlan', subscriptionPlanSchema);

// Seed Subscription Plans
const seedSubscriptionPlans = async () => {
  try {
    console.log('🌱 Seeding Subscription Plans...');
    
    // Clear existing plans
    await SubscriptionPlan.deleteMany({});
    console.log('🧹 Cleared existing subscription plans');
    
    // Insert new plans
    const insertedPlans = await SubscriptionPlan.insertMany(subscriptionPlans);
    console.log(`✅ Inserted ${insertedPlans.length} subscription plans:`);
    
    insertedPlans.forEach(plan => {
      console.log(`   • ${plan.name} (${plan.frequency}): $${plan.pricing.basePrice}`);
    });
    
    return insertedPlans;
  } catch (error) {
    console.error('❌ Error seeding subscription plans:', error);
    throw error;
  }
};

// Main seeding function
const seedDatabase = async () => {
  try {
    console.log('🚀 Starting Subscription Plans Seeding Process...\n');
    
    await connectDB();
    
    // Seed subscription plans
    await seedSubscriptionPlans();
    
    console.log('\n🎉 Subscription plans seeding completed successfully!');
    console.log('📊 Summary:');
    console.log('   • 5 Subscription Plans created');
    console.log('   • Different frequencies: daily, weekly, bi-weekly, monthly, custom');
    console.log('   • Pricing and features configured');
    console.log('   • Delivery options and instructions added');
    
  } catch (error) {
    console.error('\n❌ Subscription plans seeding failed:', error);
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

module.exports = { seedDatabase, seedSubscriptionPlans, SubscriptionPlan };
