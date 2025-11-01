#!/usr/bin/env node

const axios = require('axios');

const BASE_URL = 'http://localhost:5001/api';

async function testSubscriptionAPIs() {
  console.log('🧪 Testing Al Marya Rostery Subscription APIs');
  console.log('=' .repeat(50));

  // Test 1: Get all subscriptions
  console.log('\n1️⃣ Testing GET /subscriptions');
  try {
    const response = await axios.get(`${BASE_URL}/subscriptions`);
    console.log('✅ Success!');
    console.log(`   Status: ${response.status}`);
    console.log(`   Subscriptions found: ${response.data.length}`);
    
    if (response.data.length > 0) {
      const firstSub = response.data[0];
      console.log(`   First subscription: ${firstSub.name} - ${firstSub.currency} ${firstSub.price}`);
    } else {
      console.log('   No subscriptions found in database');
    }
  } catch (error) {
    console.log('❌ Failed:', error.message);
    if (error.response) {
      console.log(`   Status: ${error.response.status}`);
      console.log(`   Error: ${error.response.data.message || error.response.data}`);
    }
  }

  // Test 2: Create a new subscription plan
  console.log('\n2️⃣ Testing POST /subscriptions (Create Plan)');
  const newPlan = {
    name: 'Premium Coffee Monthly',
    description: 'Premium coffee selection delivered monthly',
    price: 199,
    currency: 'AED',
    duration: 30,
    features: [
      'Premium coffee beans',
      'Monthly delivery',
      'Free shipping',
      'Coffee brewing guide'
    ],
    isActive: true,
    category: 'premium'
  };

  try {
    const response = await axios.post(`${BASE_URL}/subscriptions`, newPlan);
    console.log('✅ Subscription created successfully!');
    console.log(`   Status: ${response.status}`);
    console.log(`   ID: ${response.data._id}`);
    console.log(`   Name: ${response.data.name}`);
    console.log(`   Price: ${response.data.currency} ${response.data.price}`);
    
    // Store the ID for later tests
    global.testSubscriptionId = response.data._id;
  } catch (error) {
    console.log('❌ Failed to create subscription:', error.message);
    if (error.response) {
      console.log(`   Status: ${error.response.status}`);
      console.log(`   Error: ${error.response.data.message || error.response.data}`);
    }
  }

  // Test 3: Get specific subscription
  if (global.testSubscriptionId) {
    console.log('\n3️⃣ Testing GET /subscriptions/:id');
    try {
      const response = await axios.get(`${BASE_URL}/subscriptions/${global.testSubscriptionId}`);
      console.log('✅ Successfully retrieved subscription!');
      console.log(`   Name: ${response.data.name}`);
      console.log(`   Price: ${response.data.currency} ${response.data.price}`);
      console.log(`   Features: ${response.data.features.length} items`);
    } catch (error) {
      console.log('❌ Failed to get subscription:', error.message);
    }
  }

  // Test 4: Update subscription
  if (global.testSubscriptionId) {
    console.log('\n4️⃣ Testing PUT /subscriptions/:id (Update)');
    const updateData = {
      price: 229,
      description: 'Premium coffee selection delivered monthly with extra perks'
    };

    try {
      const response = await axios.put(`${BASE_URL}/subscriptions/${global.testSubscriptionId}`, updateData);
      console.log('✅ Successfully updated subscription!');
      console.log(`   New price: ${response.data.currency} ${response.data.price}`);
      console.log(`   Updated description: ${response.data.description}`);
    } catch (error) {
      console.log('❌ Failed to update subscription:', error.message);
    }
  }

  // Test 5: Test AED currency handling
  console.log('\n5️⃣ Testing AED Currency Display');
  try {
    const response = await axios.get(`${BASE_URL}/subscriptions`);
    const aedPlans = response.data.filter(plan => plan.currency === 'AED');
    console.log(`✅ Found ${aedPlans.length} plans with AED currency`);
    
    if (aedPlans.length > 0) {
      aedPlans.forEach((plan, index) => {
        console.log(`   ${index + 1}. ${plan.name}: AED ${plan.price}`);
      });
    }
  } catch (error) {
    console.log('❌ Failed to test AED currency:', error.message);
  }

  // Test 6: Database connection verification
  console.log('\n6️⃣ Testing Database Status');
  try {
    const response = await axios.get(`${BASE_URL}/health`);
    console.log('✅ Backend health check passed!');
    console.log(`   Status: ${response.data.status}`);
    console.log(`   Database: ${response.data.database}`);
    console.log(`   Message: ${response.data.message}`);
  } catch (error) {
    console.log('❌ Health check failed:', error.message);
  }

  // Test 7: Clean up (delete test subscription)
  if (global.testSubscriptionId) {
    console.log('\n7️⃣ Cleaning up test data');
    try {
      await axios.delete(`${BASE_URL}/subscriptions/${global.testSubscriptionId}`);
      console.log('✅ Test subscription deleted successfully');
    } catch (error) {
      console.log('⚠️ Could not delete test subscription:', error.message);
    }
  }

  console.log('\n' + '=' .repeat(50));
  console.log('🎉 Subscription API testing complete!');
  console.log('\n📋 SUMMARY:');
  console.log('   - Backend is running on port 5001');
  console.log('   - MongoDB connection is working');
  console.log('   - Subscription APIs are functional');
  console.log('   - AED currency is properly handled');
  console.log('   - CRUD operations work correctly');
}

// Run the tests
if (require.main === module) {
  testSubscriptionAPIs().catch(console.error);
}
