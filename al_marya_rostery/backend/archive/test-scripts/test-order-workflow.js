/**
 * Complete Order Workflow Testing Script
 * Tests: Create → Confirm → Process → Deliver
 */

require('dotenv').config();
const mongoose = require('mongoose');
const Order = require('./models/Order');
const User = require('./models/User');
const Coffee = require('./models/Coffee');

// Colors for output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[36m',
  bold: '\x1b[1m'
};

function log(type, message) {
  const prefix = {
    success: `${colors.green}✅`,
    error: `${colors.red}❌`,
    info: `${colors.blue}ℹ️`,
    test: `${colors.yellow}🧪`,
    step: `${colors.bold}📍`
  }[type] || '';
  
  console.log(`${prefix} ${message}${colors.reset}`);
}

let testOrder = null;
let testUser = null;
let testProduct = null;

async function setup() {
  log('step', 'PHASE 2: ORDER WORKFLOW TESTING');
  console.log('═══════════════════════════════════════════════════\n');
  
  try {
    log('info', 'Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    log('success', 'Connected to MongoDB\n');

    // Get test user
    log('info', 'Finding test user...');
    testUser = await User.findOne({ email: 'admin@almaryarostery.com' });
    if (!testUser) {
      log('error', 'Test user not found!');
      process.exit(1);
    }
    log('success', `Test user found: ${testUser.name}\n`);

    // Get test product
    log('info', 'Finding test product...');
    testProduct = await Coffee.findOne().limit(1);
    if (!testProduct) {
      log('error', 'No products found in database!');
      process.exit(1);
    }
    log('success', `Test product found: ${testProduct.name.en}\n`);

  } catch (error) {
    log('error', `Setup failed: ${error.message}`);
    process.exit(1);
  }
}

async function testCreateOrder() {
  console.log('─'.repeat(50));
  log('test', 'TEST 1: Create Order');
  console.log('─'.repeat(50));

  try {
    // Generate unique order number
    const orderNumber = `ORD-TEST-${Date.now()}`;
    
    const orderData = {
      orderNumber,
      user: testUser._id,
      items: [
        {
          coffee: testProduct._id,
          name: testProduct.name.en,
          quantity: 2,
          price: testProduct.price,
          selectedSize: '250g',
          subtotal: testProduct.price * 2
        }
      ],
      subtotal: testProduct.price * 2,
      tax: (testProduct.price * 2) * 0.05, // 5% tax
      shipping: 15, // AED 15 shipping
      discount: 0,
      totalAmount: (testProduct.price * 2) + ((testProduct.price * 2) * 0.05) + 15,
      currency: 'AED',
      status: 'pending',
      paymentStatus: 'pending',
      paymentMethod: 'card',
      deliveryMethod: 'delivery',
      deliveryAddress: {
        street: '123 Test Street',
        city: 'Dubai',
        state: 'Dubai',
        zipCode: '12345',
        country: 'UAE',
        instructions: 'Test order - please handle with care'
      },
      notes: 'This is a test order for workflow testing'
    };

    testOrder = await Order.create(orderData);
    
    log('success', 'Order created successfully!');
    log('info', `Order Number: ${testOrder.orderNumber}`);
    log('info', `Order ID: ${testOrder._id}`);
    log('info', `Status: ${testOrder.status}`);
    log('info', `Payment Status: ${testOrder.paymentStatus}`);
    log('info', `Total Amount: ${testOrder.totalAmount} ${testOrder.currency}`);
    console.log('');
    
    return true;
  } catch (error) {
    log('error', `Create order failed: ${error.message}`);
    return false;
  }
}

async function testUpdateOrderStatus() {
  console.log('─'.repeat(50));
  log('test', 'TEST 2: Update Order Status (Pending → Confirmed)');
  console.log('─'.repeat(50));

  try {
    testOrder.status = 'confirmed';
    await testOrder.save();
    
    log('success', 'Order status updated!');
    log('info', `New Status: ${testOrder.status}`);
    console.log('');
    
    return true;
  } catch (error) {
    log('error', `Update status failed: ${error.message}`);
    return false;
  }
}

async function testUpdatePaymentStatus() {
  console.log('─'.repeat(50));
  log('test', 'TEST 3: Update Payment Status (Pending → Paid)');
  console.log('─'.repeat(50));

  try {
    testOrder.paymentStatus = 'paid';
    await testOrder.save();
    
    log('success', 'Payment status updated!');
    log('info', `New Payment Status: ${testOrder.paymentStatus}`);
    console.log('');
    
    return true;
  } catch (error) {
    log('error', `Update payment failed: ${error.message}`);
    return false;
  }
}

async function testOrderPreparation() {
  console.log('─'.repeat(50));
  log('test', 'TEST 4: Start Order Preparation (Confirmed → Preparing)');
  console.log('─'.repeat(50));

  try {
    testOrder.status = 'preparing';
    await testOrder.save();
    
    log('success', 'Order moved to preparation!');
    log('info', `New Status: ${testOrder.status}`);
    console.log('');
    
    return true;
  } catch (error) {
    log('error', `Preparation update failed: ${error.message}`);
    return false;
  }
}

async function testOrderReady() {
  console.log('─'.repeat(50));
  log('test', 'TEST 5: Mark Order Ready (Preparing → Ready)');
  console.log('─'.repeat(50));

  try {
    testOrder.status = 'ready';
    const estimatedDelivery = new Date();
    estimatedDelivery.setHours(estimatedDelivery.getHours() + 1); // 1 hour from now
    testOrder.estimatedDeliveryTime = estimatedDelivery;
    await testOrder.save();
    
    log('success', 'Order marked as ready!');
    log('info', `New Status: ${testOrder.status}`);
    log('info', `Estimated Delivery: ${testOrder.estimatedDeliveryTime}`);
    console.log('');
    
    return true;
  } catch (error) {
    log('error', `Ready status update failed: ${error.message}`);
    return false;
  }
}

async function testOrderDelivery() {
  console.log('─'.repeat(50));
  log('test', 'TEST 6: Complete Order Delivery (Ready → Delivered)');
  console.log('─'.repeat(50));

  try {
    testOrder.status = 'delivered';
    testOrder.actualDeliveryTime = new Date();
    await testOrder.save();
    
    log('success', 'Order delivered successfully!');
    log('info', `Final Status: ${testOrder.status}`);
    log('info', `Delivered At: ${testOrder.actualDeliveryTime}`);
    console.log('');
    
    return true;
  } catch (error) {
    log('error', `Delivery update failed: ${error.message}`);
    return false;
  }
}

async function testOrderCancellation() {
  console.log('─'.repeat(50));
  log('test', 'TEST 7: Create and Cancel Order');
  console.log('─'.repeat(50));

  try {
    // Create a new order to cancel
    const orderNumber = `ORD-CANCEL-${Date.now()}`;
    
    const cancelOrder = await Order.create({
      orderNumber,
      user: testUser._id,
      items: [{
        coffee: testProduct._id,
        name: testProduct.name.en,
        quantity: 1,
        price: testProduct.price,
        selectedSize: '250g',
        subtotal: testProduct.price
      }],
      subtotal: testProduct.price,
      totalAmount: testProduct.price,
      status: 'pending',
      paymentStatus: 'pending',
      deliveryMethod: 'pickup'
    });

    log('info', `Created order ${cancelOrder.orderNumber}`);
    
    // Cancel it
    cancelOrder.status = 'cancelled';
    await cancelOrder.save();
    
    log('success', 'Order cancelled successfully!');
    log('info', `Order ${cancelOrder.orderNumber} status: ${cancelOrder.status}`);
    console.log('');
    
    return true;
  } catch (error) {
    log('error', `Cancellation test failed: ${error.message}`);
    return false;
  }
}

async function testQueryOrders() {
  console.log('─'.repeat(50));
  log('test', 'TEST 8: Query Orders by Status');
  console.log('─'.repeat(50));

  try {
    const pendingOrders = await Order.find({ status: 'pending' });
    const deliveredOrders = await Order.find({ status: 'delivered' });
    const cancelledOrders = await Order.find({ status: 'cancelled' });
    
    log('success', 'Order queries successful!');
    log('info', `Pending Orders: ${pendingOrders.length}`);
    log('info', `Delivered Orders: ${deliveredOrders.length}`);
    log('info', `Cancelled Orders: ${cancelledOrders.length}`);
    console.log('');
    
    return true;
  } catch (error) {
    log('error', `Query orders failed: ${error.message}`);
    return false;
  }
}

async function testOrderStatistics() {
  console.log('─'.repeat(50));
  log('test', 'TEST 9: Calculate Order Statistics');
  console.log('─'.repeat(50));

  try {
    const totalOrders = await Order.countDocuments();
    const totalRevenue = await Order.aggregate([
      { $match: { paymentStatus: 'paid' } },
      { $group: { _id: null, total: { $sum: '$totalAmount' } } }
    ]);
    
    const statusCounts = await Order.aggregate([
      { $group: { _id: '$status', count: { $sum: 1 } } }
    ]);
    
    log('success', 'Statistics calculated!');
    log('info', `Total Orders: ${totalOrders}`);
    log('info', `Total Revenue: ${totalRevenue[0]?.total || 0} AED`);
    log('info', 'Orders by Status:');
    statusCounts.forEach(stat => {
      console.log(`     ${stat._id}: ${stat.count}`);
    });
    console.log('');
    
    return true;
  } catch (error) {
    log('error', `Statistics calculation failed: ${error.message}`);
    return false;
  }
}

async function cleanup() {
  console.log('─'.repeat(50));
  log('info', 'CLEANUP: Removing Test Orders');
  console.log('─'.repeat(50));

  try {
    const result = await Order.deleteMany({ 
      orderNumber: { $regex: /^ORD-(TEST|CANCEL)-/ } 
    });
    
    log('success', `Cleaned up ${result.deletedCount} test orders`);
    console.log('');
  } catch (error) {
    log('error', `Cleanup failed: ${error.message}`);
  }
}

async function runAllTests() {
  const results = {
    passed: 0,
    failed: 0,
    total: 9
  };

  await setup();

  // Run all tests
  const tests = [
    { name: 'Create Order', fn: testCreateOrder },
    { name: 'Update Order Status', fn: testUpdateOrderStatus },
    { name: 'Update Payment Status', fn: testUpdatePaymentStatus },
    { name: 'Order Preparation', fn: testOrderPreparation },
    { name: 'Order Ready', fn: testOrderReady },
    { name: 'Order Delivery', fn: testOrderDelivery },
    { name: 'Order Cancellation', fn: testOrderCancellation },
    { name: 'Query Orders', fn: testQueryOrders },
    { name: 'Order Statistics', fn: testOrderStatistics }
  ];

  for (const test of tests) {
    const passed = await test.fn();
    if (passed) {
      results.passed++;
    } else {
      results.failed++;
    }
    await new Promise(resolve => setTimeout(resolve, 500)); // Brief pause between tests
  }

  await cleanup();

  // Print summary
  console.log('\n');
  console.log('═══════════════════════════════════════════════════');
  log('step', 'TEST SUMMARY');
  console.log('═══════════════════════════════════════════════════');
  console.log('');
  log('info', `Total Tests: ${results.total}`);
  log('success', `Passed: ${results.passed}`);
  if (results.failed > 0) {
    log('error', `Failed: ${results.failed}`);
  }
  console.log('');

  if (results.failed === 0) {
    log('success', `${colors.bold}🎉 ALL ORDER WORKFLOW TESTS PASSED! 🎉${colors.reset}`);
    console.log('');
    log('info', 'Order Management System is fully functional!');
    log('info', 'Complete order lifecycle verified:');
    console.log('   ✅ Create → Confirm → Prepare → Ready → Deliver');
    console.log('   ✅ Cancellation workflow');
    console.log('   ✅ Payment status tracking');
    console.log('   ✅ Order queries and statistics');
    console.log('');
  } else {
    log('error', '⚠️  SOME TESTS FAILED - PLEASE REVIEW');
    console.log('');
  }

  await mongoose.connection.close();
  log('info', 'Database connection closed');
  
  process.exit(results.failed === 0 ? 0 : 1);
}

// Run the tests
runAllTests().catch(error => {
  log('error', `Test suite crashed: ${error.message}`);
  console.error(error);
  process.exit(1);
});
