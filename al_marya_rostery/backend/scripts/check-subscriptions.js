require('dotenv').config();
const mongoose = require('mongoose');

// SECURITY: MongoDB URI must be provided via environment variable
const MONGODB_URI = process.env.MONGODB_URI;
if (!MONGODB_URI) {
  console.error('❌ MONGODB_URI environment variable is required');
  process.exit(1);
}

async function checkSubscriptions() {
  try {
    console.log('📊 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const db = mongoose.connection.db;
    
    // Check subscription plans
    const plans = await db.collection('subscriptionplans').find().toArray();
    console.log(`\n📦 Subscription Plans Found: ${plans.length}`);
    
    if (plans.length > 0) {
      console.log('\n📋 Plans:');
      plans.forEach(plan => {
        console.log(`  - ${plan.name?.en || plan.name} - $${plan.price}/${plan.duration} days`);
        console.log(`    Features: ${plan.features?.length || 0} items`);
      });
    } else {
      console.log('\n⚠️  NO SUBSCRIPTION PLANS FOUND!');
      console.log('💡 Need to seed the database with subscription plans');
    }

    // Check subscriptions
    const subscriptions = await db.collection('subscriptions').find().toArray();
    console.log(`\n👥 Active Subscriptions Found: ${subscriptions.length}`);
    
    if (subscriptions.length > 0) {
      subscriptions.forEach(sub => {
        console.log(`  - User: ${sub.userId}, Plan: ${sub.planId}, Status: ${sub.status}`);
      });
    }

    await mongoose.connection.close();
    console.log('\n✅ Done!');
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

checkSubscriptions();
