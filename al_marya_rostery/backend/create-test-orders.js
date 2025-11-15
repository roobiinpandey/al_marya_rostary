/**
 * Create Test Order for Staff App Testing
 * 
 * This script creates sample orders that can be viewed and managed
 * by staff members in the staff app.
 */

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const mongoose = require('mongoose');

// Connect to MongoDB
const mongoUri = process.env.MONGODB_URI;
if (!mongoUri) {
  console.error('❌ MONGODB_URI not found in environment variables');
  process.exit(1);
}

mongoose.connect(mongoUri)
  .then(() => console.log('✅ MongoDB Connected'))
  .catch(err => {
    console.error('❌ MongoDB connection error:', err);
    process.exit(1);
  });

// Import models
const Order = require('./models/Order');
const User = require('./models/User');
const Coffee = require('./models/Coffee');

async function createTestOrders() {
  try {
    console.log('\n🧪 Creating test orders for staff app...\n');

    // Find a user
    let user = await User.findOne();
    if (!user) {
      console.log('❌ No users found. Please create a user first.');
      console.log('   You can use the main app to register a user.');
      process.exit(1);
    }
    console.log('✅ Using existing user:', user.email || user.name);

    // Find some coffees
    const coffees = await Coffee.find().limit(3);
    if (coffees.length === 0) {
      console.log('❌ No coffee products found. Please seed coffee data first.');
      process.exit(1);
    }
    console.log(`✅ Found ${coffees.length} coffee products`);

    // Generate order number
    const orderCount = await Order.countDocuments();
    const orderNumber = `ORD${String(orderCount + 1).padStart(6, '0')}`;

    // Create test orders
    const testOrders = [
      {
        orderNumber: orderNumber,
        userId: user._id,
        user: {
          name: user.name,
          email: user.email,
          phone: user.phone
        },
        items: [
          {
            coffee: coffees[0]._id,
            quantity: 2,
            price: 25.00,
            customizations: {
              size: 'medium',
              temperature: 'hot',
              sugar: 'normal'
            }
          }
        ],
        totalAmount: 50.00,
        status: 'pending',
        deliveryMethod: 'pickup',
        statusTimestamps: {
          pending: new Date()
        },
        preparationTime: 15,
        notes: 'Test order - Please prepare carefully'
      }
    ];

    // Create additional orders if we have more coffees
    if (coffees.length >= 2) {
      testOrders.push({
        orderNumber: `ORD${String(orderCount + 2).padStart(6, '0')}`,
        userId: user._id,
        user: {
          name: user.name,
          email: user.email,
          phone: user.phone
        },
        items: [
          {
            coffee: coffees[1]._id,
            quantity: 1,
            price: 30.00,
            customizations: {
              size: 'large',
              temperature: 'iced',
              sugar: 'less'
            }
          },
          {
            coffee: coffees[0]._id,
            quantity: 1,
            price: 25.00,
            customizations: {
              size: 'small',
              temperature: 'hot',
              sugar: 'extra'
            }
          }
        ],
        totalAmount: 55.00,
        status: 'pending',
        deliveryMethod: 'delivery',
        deliveryAddress: {
          street: 'Sheikh Zayed Road',
          building: 'Building 123',
          apartment: '456',
          city: 'Dubai',
          emirate: 'Dubai'
        },
        statusTimestamps: {
          pending: new Date()
        },
        preparationTime: 20,
        notes: 'Test delivery order'
      });
    }

    // Insert orders
    const createdOrders = await Order.insertMany(testOrders);
    
    console.log(`\n✅ Successfully created ${createdOrders.length} test orders:\n`);
    createdOrders.forEach(order => {
      console.log(`   📦 Order #${order.orderNumber}`);
      console.log(`      Status: ${order.status}`);
      console.log(`      Items: ${order.items.length}`);
      console.log(`      Total: AED ${order.totalAmount}`);
      console.log(`      Delivery: ${order.deliveryMethod}`);
      console.log(`      Created: ${order.createdAt.toLocaleString()}\n`);
    });

    console.log('🎉 Test orders ready for staff app testing!');
    console.log('\n📱 You can now:');
    console.log('   1. Open the staff app');
    console.log('   2. Login with BAR001 / 1234');
    console.log('   3. View and manage these orders');
    console.log('   4. Test accept, preparing, ready status updates\n');

  } catch (error) {
    console.error('❌ Error creating test orders:', error);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log('✅ Database connection closed');
  }
}

// Run the script
createTestOrders();
