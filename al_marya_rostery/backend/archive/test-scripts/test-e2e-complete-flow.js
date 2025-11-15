#!/usr/bin/env node

/**
 * 🧪 END-TO-END SYSTEM TEST: CUSTOMER → STAFF → DRIVER COMPLETE FLOW
 * 
 * This test simulates a complete order lifecycle through all three apps:
 * 1. Customer App: Creates an order
 * 2. Staff App: Accepts, prepares, and marks order as ready
 * 3. Driver App: Accepts, picks up, and delivers the order
 * 
 * Test validates:
 * ✅ Unified order_number consistency across all apps
 * ✅ Proper status transitions and timestamps
 * ✅ Data synchronization between backend and apps
 * ✅ No missing fields or API inconsistencies
 * 
 * Run: node test-e2e-complete-flow.js
 */

require('dotenv').config();
const mongoose = require('mongoose');
const axios = require('axios');
const Order = require('./models/Order');
const User = require('./models/User');
const Staff = require('./models/Staff');
const Driver = require('./models/Driver');

// ===== CONFIGURATION =====
const BASE_URL = process.env.BASE_URL || 'http://127.0.0.1:5001';
const API_URL = `${BASE_URL}/api`;

// Test user credentials (you should have these in your database)
const TEST_CUSTOMER = {
  email: 'test_customer@almarya.com',
  password: 'TestPass123!',
  name: 'Test Customer'
};

const TEST_STAFF = {
  pin: '1234', // Replace with actual test staff PIN
  name: 'Test Staff'
};

const TEST_DRIVER = {
  pin: '5678', // Replace with actual test driver PIN
  name: 'Test Driver'
};

// Test data storage
let testData = {
  customer: null,
  staff: null,
  driver: null,
  order: null,
  orderNumber: null
};

// ===== UTILITY FUNCTIONS =====

const log = (emoji, message, data = null) => {
  const timestamp = new Date().toLocaleTimeString();
  console.log(`${emoji} [${timestamp}] ${message}`);
  if (data) {
    console.log(JSON.stringify(data, null, 2));
  }
};

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

const makeRequest = async (method, endpoint, data = null, token = null) => {
  const config = {
    method,
    url: `${API_URL}${endpoint}`,
    headers: {
      'Content-Type': 'application/json'
    }
  };

  if (token) {
    config.headers['Authorization'] = `Bearer ${token}`;
  }

  if (data) {
    config.data = data;
  }

  try {
    const response = await axios(config);
    return { success: true, data: response.data };
  } catch (error) {
    return {
      success: false,
      error: error.response?.data || error.message,
      status: error.response?.status
    };
  }
};

// ===== TEST STEPS =====

/**
 * STEP 1: CUSTOMER - Create Order
 */
async function step1_CustomerCreateOrder() {
  log('🛍️', 'STEP 1: Customer creates an order...');

  // Login as customer
  log('🔐', 'Logging in as customer...');
  log('🔍', `API URL: ${API_URL}/auth/login`);
  log('📧', `Email: ${TEST_CUSTOMER.email}`);
  const loginResult = await makeRequest('POST', '/auth/login', {
    email: TEST_CUSTOMER.email,
    password: TEST_CUSTOMER.password
  });

  if (!loginResult.success) {
    log('❌', 'Customer login failed', loginResult.error);
    log('🔍', 'Full error:', JSON.stringify(loginResult, null, 2));
    
    // Try to create test customer if login fails
    log('👤', 'Creating test customer account...');
    const signupResult = await makeRequest('POST', '/auth/register', {
      name: TEST_CUSTOMER.name,
      email: TEST_CUSTOMER.email,
      password: TEST_CUSTOMER.password,
      phone: '+971501234567'
    });

    if (!signupResult.success) {
      throw new Error('Failed to create test customer: ' + JSON.stringify(signupResult.error));
    }

    log('✅', 'Test customer created successfully');
    // API returns { success, message, data: { user, token } }
    // makeRequest wraps it again: { success, data: {...} }
    testData.customer = signupResult.data.data;
  } else {
    log('✅', 'Customer logged in successfully');
    // API returns { success, message, data: { user, token } }
    // makeRequest wraps it again: { success, data: {...} }
    testData.customer = loginResult.data.data;
  }

  // Get a coffee product for the order
  log('☕', 'Fetching a coffee product...');
  const Coffee = require('./models/Coffee');
  const coffees = await Coffee.find({ isActive: true }).limit(2).lean();
  
  if (coffees.length === 0) {
    throw new Error('No active coffee products found in database');
  }
  
  log('✅', `Found ${coffees.length} coffee product(s)`);

  // Create order
  log('📦', 'Creating order...');
  
  // Helper to get localized name
  const getName = (coffee) => {
    return typeof coffee.name === 'string' ? coffee.name : 
           (coffee.name?.en || coffee.name?.ar || 'Coffee');
  };
  
  const orderData = {
    items: [
      {
        productId: coffees[0]._id,
        productName: getName(coffees[0]),
        quantity: 2,
        price: coffees[0].price,
        selectedSize: '250g'
      }
    ].concat(coffees.length > 1 ? [{
        productId: coffees[1]._id,
        productName: getName(coffees[1]),
        quantity: 1,
        price: coffees[1].price,
        selectedSize: '500g'
      }] : []),
    totalAmount: (coffees[0].price * 2) + (coffees.length > 1 ? coffees[1].price : 0),
    shippingAddress: {
      street: '123 Test Street',
      city: 'Dubai',
      state: 'Dubai',
      zipCode: '12345',
      country: 'UAE'
    },
    paymentMethod: 'card',
    paymentStatus: 'paid',
    deliveryMethod: 'delivery',
    specialInstructions: 'E2E Test Order - Please handle with care'
  };

  const createOrderResult = await makeRequest(
    'POST',
    '/orders',
    orderData,
    testData.customer.token
  );

  if (!createOrderResult.success) {
    throw new Error('Failed to create order: ' + JSON.stringify(createOrderResult.error));
  }

  // API returns { success, message, order }
  // makeRequest wraps it: { success, data: {...} }
  const orderDoc = createOrderResult.data.order;
  // If it's a Mongoose document, extract the plain object from _doc
  testData.order = orderDoc._doc || (typeof orderDoc.toObject === 'function' ? orderDoc.toObject() : orderDoc);
  testData.orderNumber = testData.order.orderNumber;

  log('✅', `Order created successfully!`);
  log('�📋', `Order Number: ${testData.orderNumber}`);
  log('💰', `Total Amount: AED ${testData.order.totalAmount}`);
  log('📊', `Status: ${testData.order.status}`);
  log('💳', `Payment Status: ${testData.order.paymentStatus}`);

  // Validate order number format
  const orderNumberPattern = /^ALM-\d{8}-\d{6}$/;
  if (!orderNumberPattern.test(testData.orderNumber)) {
    throw new Error(`Invalid order number format: ${testData.orderNumber}`);
  }
  log('✅', 'Order number format validated: ALM-YYYYMMDD-XXXXXX');

  await sleep(1000);
}

/**
 * STEP 2: BACKEND - Verify Order in Database
 */
async function step2_BackendVerifyOrder() {
  log('🔍', 'STEP 2: Verifying order in database...');

  const order = await Order.findOne({ orderNumber: testData.orderNumber })
    .populate('user', 'name email')
    .populate('items.coffee', 'name');

  if (!order) {
    throw new Error(`Order not found in database: ${testData.orderNumber}`);
  }

  log('✅', 'Order found in database');
  log('📊', `Order ID: ${order._id}`);
  log('👤', `Customer: ${order.user ? order.user.name : 'Guest'}`);
  log('📦', `Items Count: ${order.items.length}`);
  log('📍', `Delivery Address: ${order.deliveryAddress.city}, ${order.deliveryAddress.country}`);
  log('⏰', `Created At: ${order.createdAt}`);

  // Validate mandatory fields
  const requiredFields = ['orderNumber', 'totalAmount', 'items', 'status', 'paymentStatus'];
  for (const field of requiredFields) {
    if (!order[field]) {
      throw new Error(`Missing required field: ${field}`);
    }
  }
  log('✅', 'All mandatory fields present');

  await sleep(1000);
}

/**
 * STEP 3: STAFF - Accept and Process Order
 */
async function step3_StaffAcceptOrder() {
  log('👨‍🍳', 'STEP 3: Staff accepts and processes order...');

  // Staff PIN login
  log('🔐', 'Staff logging in with PIN...');
  const staffLoginResult = await makeRequest('POST', '/staff/auth/login-pin', {
    pin: TEST_STAFF.pin
  });

  if (!staffLoginResult.success) {
    throw new Error('Staff login failed: ' + JSON.stringify(staffLoginResult.error));
  }

  log('✅', 'Staff logged in successfully');
  // API returns { success, message, token, staff }
  // makeRequest wraps it: { success, data: {...} }
  log('🔍', 'Staff login response keys:', Object.keys(staffLoginResult.data));
  testData.staff = staffLoginResult.data;
  log('🔍', 'Staff token:', testData.staff.token ? 'present' : 'MISSING');

  // Get pending orders
  log('📋', 'Fetching pending orders...');
  const pendingOrdersResult = await makeRequest(
    'GET',
    '/staff/orders?status=pending',
    null,
    testData.staff.token
  );

  if (!pendingOrdersResult.success) {
    throw new Error('Failed to fetch pending orders: ' + JSON.stringify(pendingOrdersResult.error));
  }

  const pendingOrders = pendingOrdersResult.data.orders || [];
  log('📊', `Found ${pendingOrders.length} pending orders`);

  // Find our test order
  const ourOrder = pendingOrders.find(o => o.orderNumber === testData.orderNumber);
  if (!ourOrder) {
    log('⚠️', `Test order ${testData.orderNumber} not in pending list (status: ${testData.order.status})`);
  } else {
    log('✅', `Test order found in pending orders`);
  }

  // Accept order
  log('✋', 'Staff accepting order...');
  const acceptResult = await makeRequest(
    'POST',
    `/staff/orders/${testData.order._id}/accept`,
    {},
    testData.staff.token
  );

  if (!acceptResult.success) {
    throw new Error('Failed to accept order: ' + JSON.stringify(acceptResult.error));
  }

  log('✅', 'Order accepted by staff');
  log('📊', `New Status: ${acceptResult.data.order.status}`);
  log('ℹ️', 'Order automatically moved to "preparing" status');

  // Simulate preparation time
  await sleep(3000);

  // Mark as ready
  log('✅', 'Staff marking order as ready...');
  const readyResult = await makeRequest(
    'POST',
    `/staff/orders/${testData.order._id}/ready`,
    {},
    testData.staff.token
  );

  if (!readyResult.success) {
    throw new Error('Failed to mark as ready: ' + JSON.stringify(readyResult.error));
  }

  log('✅', 'Order marked as ready for delivery');
  log('📊', `New Status: ${readyResult.data.order.status}`);

  // Update test data with latest order info
  testData.order = readyResult.data.order;

  await sleep(1000);
}

/**
 * STEP 4: DRIVER - Accept and Deliver Order
 */
async function step4_DriverDeliverOrder() {
  log('🚗', 'STEP 4: Driver accepts and delivers order...');

  // Driver PIN login
  log('🔐', 'Driver logging in with PIN...');
  const driverLoginResult = await makeRequest('POST', '/driver/auth/pin-login', {
    pin: TEST_DRIVER.pin
  });

  if (!driverLoginResult.success) {
    throw new Error('Driver login failed: ' + JSON.stringify(driverLoginResult.error));
  }

  log('✅', 'Driver logged in successfully');
  // API returns { success, message, token, driver }
  // makeRequest wraps it: { success, data: {...} }
  testData.driver = driverLoginResult.data;
  log('🔍', 'Driver data keys:', Object.keys(testData.driver));
  log('🔍', 'Driver ID:', testData.driver.driver?.driverId);
  log('🔍', 'Token exists:', testData.driver.token ? 'YES' : 'NO');

  // Get available deliveries
  log('📋', 'Fetching available deliveries...');
  const availableResult = await makeRequest(
    'GET',
    '/driver/orders/available',
    null,
    testData.driver.token
  );

  if (!availableResult.success) {
    throw new Error('Failed to fetch available deliveries: ' + JSON.stringify(availableResult.error));
  }

  const availableOrders = availableResult.data.orders || [];
  log('📊', `Found ${availableOrders.length} available deliveries`);

  // Find our test order
  const ourOrder = availableOrders.find(o => o.orderNumber === testData.orderNumber);
  if (!ourOrder) {
    log('⚠️', `Test order ${testData.orderNumber} not in available list`);
    log('🔍', 'Available order numbers:', availableOrders.map(o => o.orderNumber).slice(0, 5).join(', '));
    log('🔍', 'Our order ID:', testData.order._id);
    // It might be in a different status, continue anyway
  } else {
    log('✅', `Test order found in available deliveries`);
    log('🔍', 'Using order ID from available list:', ourOrder._id);
    // Use the ID from the available list to ensure it matches what driver API expects
    testData.order._id = ourOrder._id;
  }

  // Accept delivery
  log('✋', 'Driver accepting delivery...');
  log('🔍', 'Attempting to accept order ID:', testData.order._id);
  const acceptResult = await makeRequest(
    'POST',
    `/driver/orders/${testData.order._id}/accept`,
    {},
    testData.driver.token
  );

  if (!acceptResult.success) {
    throw new Error('Failed to accept delivery: ' + JSON.stringify(acceptResult.error));
  }

  log('✅', 'Delivery accepted by driver');
  log('📊', `New Status: ${acceptResult.data.order.status}`);

  await sleep(2000);

  // Start delivery (pickup + go out for delivery)
  log('📦', 'Driver starting delivery...');
  const startResult = await makeRequest(
    'POST',
    `/driver/orders/${testData.order._id}/start`,
    {},
    testData.driver.token
  );

  if (!startResult.success) {
    throw new Error('Failed to start delivery: ' + JSON.stringify(startResult.error));
  }

  log('✅', 'Delivery started (out for delivery)');
  log('📊', `New Status: ${startResult.data.order.status}`);

  await sleep(2000);

  // Update location (simulate driving)
  log('📍', 'Driver updating location...');
  const locationResult = await makeRequest(
    'POST',
    '/driver/location',
    {
      latitude: 25.2048,
      longitude: 55.2708,
      accuracy: 10,
      heading: 180,
      speed: 45
    },
    testData.driver.token
  );

  if (locationResult.success) {
    log('✅', 'Location updated');
  }

  await sleep(3000);

  // Complete delivery
  log('✅', 'Driver completing delivery...');
  const deliverResult = await makeRequest(
    'POST',
    `/driver/orders/${testData.order._id}/complete`,
    {
      notes: 'E2E Test: Delivered successfully at doorstep'
    },
    testData.driver.token
  );

  if (!deliverResult.success) {
    throw new Error('Failed to complete delivery: ' + JSON.stringify(deliverResult.error));
  }

  log('✅', 'Delivery completed!');
  log('📊', `Final Status: ${deliverResult.data.order.status}`);

  // Update test data with final order info
  testData.order = deliverResult.data.order;

  await sleep(1000);
}

/**
 * STEP 5: CUSTOMER - Verify Order History
 */
async function step5_CustomerVerifyHistory() {
  log('📚', 'STEP 5: Customer verifying order history...');

  // Debug: Check customer token
  log('🔍', 'Customer data keys:', Object.keys(testData.customer));
  log('🔍', 'Customer token type:', typeof testData.customer.token);
  log('🔍', 'Customer token length:', testData.customer.token?.length);

  // Get customer order history (uses standard JWT auth)
  const historyResult = await makeRequest(
    'GET',
    '/orders',
    null,
    testData.customer.token
  );

  if (!historyResult.success) {
    throw new Error('Failed to fetch order history: ' + JSON.stringify(historyResult.error));
  }

  // API returns { success, data: { orders, pagination } }
  // makeRequest wraps it: { success, data: { success, data: {...} } }
  const ordersData = historyResult.data.data || historyResult.data;
  const orders = ordersData.orders || [];
  log('📊', `Found ${orders.length} orders in history`);

  // Find our test order
  const ourOrder = orders.find(o => o.orderNumber === testData.orderNumber);
  if (!ourOrder) {
    throw new Error(`Test order ${testData.orderNumber} not found in customer history`);
  }

  log('✅', 'Test order found in customer history');
  log('📋', `Order Number: ${ourOrder.orderNumber}`);
  log('📊', `Final Status: ${ourOrder.status}`);
  log('💳', `Payment Status: ${ourOrder.paymentStatus}`);

  // Verify final status
  if (ourOrder.status !== 'delivered') {
    throw new Error(`Expected status 'delivered', got '${ourOrder.status}'`);
  }

  log('✅', 'Order status verified: delivered');

  await sleep(1000);
}

/**
 * STEP 6: FINAL VALIDATION
 */
async function step6_FinalValidation() {
  log('🎯', 'STEP 6: Final validation and assertions...');

  // Fetch final order from database
  const finalOrder = await Order.findOne({ orderNumber: testData.orderNumber })
    .populate('user', 'name email')
    .populate('assignedStaff', 'name email')
    .populate('assignedDriver', 'name phone');

  if (!finalOrder) {
    throw new Error('Final order not found in database');
  }

  log('📊', 'Final Order State:');
  log('  ', `Order Number: ${finalOrder.orderNumber}`);
  log('  ', `Status: ${finalOrder.status}`);
  log('  ', `Payment Status: ${finalOrder.paymentStatus}`);
  log('  ', `Assigned Staff: ${finalOrder.assignedStaff ? finalOrder.assignedStaff.name : 'None'}`);
  log('  ', `Assigned Driver: ${finalOrder.assignedDriver ? finalOrder.assignedDriver.name : 'None'}`);

  // Assertions
  const assertions = [
    {
      name: 'Order number consistency',
      test: () => finalOrder.orderNumber === testData.orderNumber,
      message: 'Order number must remain consistent throughout flow'
    },
    {
      name: 'Final status is delivered',
      test: () => finalOrder.status === 'delivered',
      message: 'Final order status must be "delivered"'
    },
    {
      name: 'Payment is completed',
      test: () => finalOrder.paymentStatus === 'paid',
      message: 'Payment status must be "paid"'
    },
    {
      name: 'Staff assignment exists',
      test: () => finalOrder.assignedStaff !== null,
      message: 'Order must be assigned to a staff member'
    },
    {
      name: 'Driver assignment exists',
      test: () => finalOrder.assignedDriver !== null,
      message: 'Order must be assigned to a driver'
    },
    {
      name: 'Status timestamps exist',
      test: () => {
        // Check that key timestamps exist (not all are required)
        const timestamps = finalOrder.statusTimestamps || {};
        return timestamps.placed &&  // Order created
               (timestamps.acceptedByStaff || timestamps.preparationStarted) && // Staff accepted
               timestamps.markedReady && // Ready for delivery
               timestamps.delivered;  // Delivered
      },
      message: 'Key status timestamps must be recorded'
    },
    {
      name: 'Delivery time calculated',
      test: () => finalOrder.actualDeliveryTime !== null,
      message: 'Actual delivery time must be recorded'
    },
    {
      name: 'Items preserved',
      test: () => finalOrder.items.length === 2,
      message: 'All order items must be preserved'
    }
  ];

  let passed = 0;
  let failed = 0;

  for (const assertion of assertions) {
    try {
      if (assertion.test()) {
        log('✅', `PASS: ${assertion.name}`);
        passed++;
      } else {
        log('❌', `FAIL: ${assertion.name} - ${assertion.message}`);
        failed++;
      }
    } catch (error) {
      log('❌', `ERROR: ${assertion.name} - ${error.message}`);
      failed++;
    }
  }

  log('📊', '='.repeat(60));
  log('📊', `Test Results: ${passed} passed, ${failed} failed`);
  log('📊', '='.repeat(60));

  if (failed > 0) {
    throw new Error(`${failed} assertions failed`);
  }

  log('✅', 'All assertions passed!');
}

/**
 * CLEANUP: Remove test data
 */
async function cleanup() {
  log('🧹', 'Cleaning up test data...');

  try {
    // Delete test order
    if (testData.order) {
      await Order.findByIdAndDelete(testData.order._id);
      log('✅', 'Test order deleted');
    }

    // Note: We keep test users/staff/drivers for future tests
    // To delete them, uncomment below:
    // await User.findOneAndDelete({ email: TEST_CUSTOMER.email });
    // await Staff.findOneAndDelete({ pin: TEST_STAFF.pin });
    // await Driver.findOneAndDelete({ pin: TEST_DRIVER.pin });

    log('✅', 'Cleanup completed');
  } catch (error) {
    log('⚠️', 'Cleanup error:', error.message);
  }
}

// ===== MAIN TEST RUNNER =====

async function runE2ETest() {
  const startTime = Date.now();

  console.log('\n');
  log('🧪', '='.repeat(60));
  log('🧪', 'STARTING END-TO-END SYSTEM TEST');
  log('🧪', 'Customer → Staff → Driver Complete Flow');
  log('🧪', '='.repeat(60));
  console.log('\n');

  try {
    // Connect to MongoDB
    log('🔌', 'Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    log('✅', 'Connected to MongoDB');
    console.log('\n');

    // Run test steps
    await step1_CustomerCreateOrder();
    console.log('\n');

    await step2_BackendVerifyOrder();
    console.log('\n');

    await step3_StaffAcceptOrder();
    console.log('\n');

    await step4_DriverDeliverOrder();
    console.log('\n');

    await step5_CustomerVerifyHistory();
    console.log('\n');

    await step6_FinalValidation();
    console.log('\n');

    // Calculate duration
    const duration = ((Date.now() - startTime) / 1000).toFixed(2);

    log('🎉', '='.repeat(60));
    log('🎉', '✅ END-TO-END TEST PASSED!');
    log('🎉', `Duration: ${duration}s`);
    log('🎉', `Order Number: ${testData.orderNumber}`);
    log('🎉', '='.repeat(60));

  } catch (error) {
    console.log('\n');
    log('❌', '='.repeat(60));
    log('❌', '❌ END-TO-END TEST FAILED!');
    log('❌', error.message);
    log('❌', '='.repeat(60));
    console.error(error);

    process.exit(1);
  } finally {
    // Cleanup
    await cleanup();

    // Close MongoDB connection
    await mongoose.connection.close();
    log('👋', 'MongoDB connection closed');
  }
}

// Run test if called directly
if (require.main === module) {
  runE2ETest()
    .then(() => {
      process.exit(0);
    })
    .catch((error) => {
      console.error('Unhandled error:', error);
      process.exit(1);
    });
}

module.exports = { runE2ETest };
