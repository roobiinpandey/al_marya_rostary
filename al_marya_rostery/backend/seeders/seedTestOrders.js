const mongoose = require('mongoose');
const Order = require('../models/Order');
const User = require('../models/User');
const Coffee = require('../models/Coffee');
require('dotenv').config();

// MongoDB connection
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/al_marya_rostery');
    console.log('✅ MongoDB connected successfully');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
};

// Function to generate order number
function generateOrderNumber() {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
  return `ORD-${timestamp}-${random}`;
}

// Seed function
const seedTestOrders = async () => {
  try {
    console.log('🌱 Starting Test Orders seeding...\n');

    // Find a test user (you can modify this to use your actual user)
    const testUser = await User.findOne({ email: { $exists: true } }).sort({ createdAt: -1 });
    
    if (!testUser) {
      console.log('⚠️  No users found in database. Please create a user first.');
      console.log('   You can sign up in the app, then run this script again.');
      return;
    }

    console.log(`✅ Found test user: ${testUser.email} (${testUser._id})\n`);

    // Find some coffees to use in orders
    const coffees = await Coffee.find({ isActive: true }).limit(5);
    
    if (coffees.length === 0) {
      console.log('⚠️  No active coffees found. Please seed coffees first.');
      return;
    }

    console.log(`✅ Found ${coffees.length} active coffees\n`);

    // Clear existing test orders for this user (optional)
    const deleteResult = await Order.deleteMany({ user: testUser._id });
    console.log(`🗑️  Cleared ${deleteResult.deletedCount} existing orders for ${testUser.email}\n`);

    // Create test orders with different statuses
    const testOrders = [
      {
        orderNumber: generateOrderNumber(),
        user: testUser._id,
        items: [
          {
            coffee: coffees[0]._id,
            name: coffees[0].name.en,
            quantity: 2,
            price: coffees[0].price,
            selectedSize: '250g',
            subtotal: coffees[0].price * 2
          }
        ],
        subtotal: coffees[0].price * 2,
        tax: 0,
        shipping: 15,
        discount: 0,
        totalAmount: (coffees[0].price * 2) + 15,
        currency: 'AED',
        status: 'delivered',
        paymentMethod: 'card',
        paymentStatus: 'paid',
        deliveryAddress: {
          street: '123 Sheikh Zayed Road',
          city: 'Dubai',
          state: 'Dubai',
          zipCode: '12345',
          country: 'UAE',
          coordinates: {
            latitude: 25.2048,
            longitude: 55.2708
          }
        },
        deliveryMethod: 'delivery',
        actualDelivery: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // 7 days ago
        createdAt: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000) // 8 days ago
      },
      {
        orderNumber: generateOrderNumber(),
        user: testUser._id,
        items: [
          {
            coffee: coffees[1]._id,
            name: coffees[1].name.en,
            quantity: 1,
            price: coffees[1].price,
            selectedSize: '500g',
            subtotal: coffees[1].price
          },
          {
            coffee: coffees[2]._id,
            name: coffees[2].name.en,
            quantity: 3,
            price: coffees[2].price,
            selectedSize: '250g',
            subtotal: coffees[2].price * 3
          }
        ],
        subtotal: coffees[1].price + (coffees[2].price * 3),
        tax: 0,
        shipping: 15,
        discount: 20,
        totalAmount: coffees[1].price + (coffees[2].price * 3) + 15 - 20,
        currency: 'AED',
        status: 'out-for-delivery',
        paymentMethod: 'card',
        paymentStatus: 'paid',
        deliveryAddress: {
          street: '456 Al Wasl Road',
          city: 'Dubai',
          state: 'Dubai',
          zipCode: '12346',
          country: 'UAE',
          coordinates: {
            latitude: 25.2148,
            longitude: 55.2808
          }
        },
        deliveryMethod: 'delivery',
        trackingInfo: {
          trackingNumber: 'TRK' + Date.now(),
          carrier: 'Al Marya Express',
          currentStatus: 'Out for delivery',
          lastUpdate: new Date()
        },
        estimatedDelivery: new Date(Date.now() + 2 * 60 * 60 * 1000), // 2 hours from now
        createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000) // 1 day ago
      },
      {
        orderNumber: generateOrderNumber(),
        user: testUser._id,
        items: [
          {
            coffee: coffees[3]._id,
            name: coffees[3].name.en,
            quantity: 1,
            price: coffees[3].price,
            selectedSize: '1kg',
            subtotal: coffees[3].price
          }
        ],
        subtotal: coffees[3].price,
        tax: 0,
        shipping: 0, // Free shipping
        discount: 0,
        totalAmount: coffees[3].price,
        currency: 'AED',
        status: 'preparing',
        paymentMethod: 'apple_pay',
        paymentStatus: 'paid',
        deliveryAddress: {
          street: '789 Jumeirah Beach Road',
          city: 'Dubai',
          state: 'Dubai',
          zipCode: '12347',
          country: 'UAE',
          coordinates: {
            latitude: 25.2248,
            longitude: 55.2908
          }
        },
        deliveryMethod: 'delivery',
        estimatedDelivery: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // 3 days from now
        createdAt: new Date(Date.now() - 5 * 60 * 60 * 1000) // 5 hours ago
      },
      {
        orderNumber: generateOrderNumber(),
        user: testUser._id,
        items: [
          {
            coffee: coffees[4]._id,
            name: coffees[4].name.en,
            quantity: 2,
            price: coffees[4].price,
            selectedSize: '250g',
            subtotal: coffees[4].price * 2
          }
        ],
        subtotal: coffees[4].price * 2,
        tax: 0,
        shipping: 15,
        discount: 0,
        totalAmount: (coffees[4].price * 2) + 15,
        currency: 'AED',
        status: 'pending',
        paymentMethod: 'card',
        paymentStatus: 'pending',
        deliveryAddress: {
          street: '321 Downtown Boulevard',
          city: 'Dubai',
          state: 'Dubai',
          zipCode: '12348',
          country: 'UAE',
          coordinates: {
            latitude: 25.1948,
            longitude: 55.2608
          }
        },
        deliveryMethod: 'delivery',
        estimatedDelivery: new Date(Date.now() + 4 * 24 * 60 * 60 * 1000), // 4 days from now
        createdAt: new Date(Date.now() - 30 * 60 * 1000) // 30 minutes ago
      }
    ];

    // Insert test orders
    const insertedOrders = await Order.insertMany(testOrders);
    console.log(`✅ Successfully seeded ${insertedOrders.length} test orders:\n`);

    insertedOrders.forEach((order, index) => {
      console.log(`${index + 1}. Order ${order.orderNumber}`);
      console.log(`   - Status: ${order.status}`);
      console.log(`   - Total: ${order.totalAmount} ${order.currency}`);
      console.log(`   - Items: ${order.items.length}`);
      console.log(`   - Payment: ${order.paymentMethod} (${order.paymentStatus})`);
      console.log(`   - Created: ${order.createdAt.toLocaleString()}`);
      console.log('');
    });

    console.log('\n🎉 Test Orders seeding completed successfully!');
    console.log(`\n📊 Summary:`);
    console.log(`   - User: ${testUser.email}`);
    console.log(`   - Total orders: ${insertedOrders.length}`);
    console.log(`   - Pending: ${insertedOrders.filter(o => o.status === 'pending').length}`);
    console.log(`   - Processing: ${insertedOrders.filter(o => o.status === 'processing').length}`);
    console.log(`   - In Transit: ${insertedOrders.filter(o => o.status === 'in_transit').length}`);
    console.log(`   - Delivered: ${insertedOrders.filter(o => o.status === 'delivered').length}`);

  } catch (error) {
    console.error('❌ Error seeding test orders:', error);
    throw error;
  }
};

// Run seeder
const runSeeder = async () => {
  try {
    await connectDB();
    await seedTestOrders();
    console.log('\n✅ Seeding process completed. Closing connection...');
    await mongoose.connection.close();
    console.log('👋 Database connection closed');
    process.exit(0);
  } catch (error) {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  }
};

// Execute if run directly
if (require.main === module) {
  runSeeder();
}

module.exports = { seedTestOrders };
