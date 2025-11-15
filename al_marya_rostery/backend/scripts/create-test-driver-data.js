/**
 * Create Test Driver Account and Sample Orders
 * 
 * This script creates:
 * 1. A test driver account with PIN: 1234
 * 2. Sample orders with "ready" status for testing
 */

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// MongoDB connection
const MONGODB_URI = process.env.MONGODB_URI;

// Models
const driverSchema = new mongoose.Schema({
  driverId: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String, required: true },
  pin: { type: String, required: true },
  qrBadgeToken: { type: String, unique: true, sparse: true },
  status: { 
    type: String, 
    enum: ['available', 'on_delivery', 'offline', 'on_break'],
    default: 'offline' 
  },
  location: {
    latitude: Number,
    longitude: Number,
    lastUpdated: Date
  },
  vehicleInfo: {
    type: { type: String },
    plateNumber: String,
    color: String
  },
  stats: {
    totalDeliveries: { type: Number, default: 0 },
    completedDeliveries: { type: Number, default: 0 },
    cancelledDeliveries: { type: Number, default: 0 }
  },
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

const orderSchema = new mongoose.Schema({
  orderNumber: { type: String, required: true, unique: true },
  userId: { type: String, required: true },
  customerName: { type: String, required: true },
  customerPhone: { type: String, required: true },
  customerEmail: String,
  deliveryAddress: {
    fullAddress: { type: String, required: true },
    area: String,
    building: String,
    floor: String,
    apartment: String,
    instructions: String,
    coordinates: {
      latitude: Number,
      longitude: Number
    }
  },
  items: [{
    productId: String,
    name: { type: String, required: true },
    arabicName: String,
    quantity: { type: Number, required: true },
    size: String,
    roastLevel: String,
    addOns: [String],
    specialNotes: String,
    price: { type: Number, required: true },
    subtotal: { type: Number, required: true }
  }],
  totalAmount: { type: Number, required: true },
  deliveryFee: { type: Number, default: 0 },
  status: { 
    type: String, 
    enum: ['pending', 'confirmed', 'ready', 'assigned', 'out-for-delivery', 'delivered', 'cancelled'],
    default: 'pending' 
  },
  paymentMethod: {
    type: String,
    enum: ['cash', 'card', 'digital-wallet'],
    required: true
  },
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'failed', 'refunded'],
    default: 'pending'
  },
  driverId: String,
  assignedAt: Date,
  startedAt: Date,
  deliveredAt: Date,
  estimatedDeliveryTime: Date,
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

const Driver = mongoose.model('Driver', driverSchema);
const Order = mongoose.model('Order', orderSchema);

async function createTestData() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // 1. Create Test Driver
    console.log('👤 Creating test driver account...');
    
    // Check if driver already exists
    const existingDriver = await Driver.findOne({ email: 'testdriver@almarya.com' });
    
    if (existingDriver) {
      console.log('⚠️  Test driver already exists!');
      console.log('📧 Email: testdriver@almarya.com');
      console.log('📱 Phone: +971501234567');
      console.log('🔐 PIN: 1234');
      console.log(`🆔 Driver ID: ${existingDriver.driverId}\n`);
    } else {
      // Hash PIN
      const hashedPin = await bcrypt.hash('1234', 10);
      
      const testDriver = new Driver({
        driverId: `DRV${Date.now()}`,
        name: 'Test Driver',
        email: 'testdriver@almarya.com',
        phone: '+971501234567',
        pin: hashedPin,
        qrBadgeToken: `QR_TEST_${Date.now()}`,
        status: 'offline',
        vehicleInfo: {
          type: 'sedan',
          plateNumber: 'DXB-12345',
          color: 'White'
        },
        stats: {
          totalDeliveries: 0,
          completedDeliveries: 0,
          cancelledDeliveries: 0
        },
        isActive: true
      });

      await testDriver.save();
      console.log('✅ Test driver created successfully!');
      console.log('📧 Email: testdriver@almarya.com');
      console.log('📱 Phone: +971501234567');
      console.log('🔐 PIN: 1234');
      console.log(`🆔 Driver ID: ${testDriver.driverId}\n`);
    }

    // 2. Create Test Orders
    console.log('📦 Creating test orders...');
    
    const testOrders = [
      {
        orderNumber: `ORD${Date.now()}_1`,
        userId: 'test_user_1',
        customerName: 'Ahmed Al Mansoori',
        customerPhone: '+971501111111',
        customerEmail: 'ahmed@example.com',
        deliveryAddress: {
          fullAddress: 'Villa 123, Al Wasl Road, Jumeirah 1, Dubai',
          area: 'Jumeirah 1',
          building: 'Villa 123',
          floor: 'Ground Floor',
          instructions: 'Ring the doorbell twice',
          coordinates: {
            latitude: 25.2324,
            longitude: 55.2581
          }
        },
        items: [
          {
            productId: 'prod_001',
            name: 'Arabic Coffee (Gahwa)',
            arabicName: 'قهوة عربية',
            quantity: 2,
            size: '250g',
            roastLevel: 'Light',
            addOns: ['Cardamom', 'Saffron'],
            specialNotes: 'Extra cardamom please',
            price: 45.00,
            subtotal: 90.00
          },
          {
            productId: 'prod_002',
            name: 'Turkish Coffee',
            arabicName: 'قهوة تركية',
            quantity: 1,
            size: '200g',
            roastLevel: 'Medium',
            addOns: [],
            price: 35.00,
            subtotal: 35.00
          }
        ],
        totalAmount: 125.00,
        deliveryFee: 10.00,
        status: 'ready',
        paymentMethod: 'cash',
        paymentStatus: 'pending',
        estimatedDeliveryTime: new Date(Date.now() + 60 * 60 * 1000) // 1 hour from now
      },
      {
        orderNumber: `ORD${Date.now()}_2`,
        userId: 'test_user_2',
        customerName: 'Fatima Mohammed',
        customerPhone: '+971502222222',
        customerEmail: 'fatima@example.com',
        deliveryAddress: {
          fullAddress: 'Burj Khalifa Tower, Downtown Dubai',
          area: 'Downtown Dubai',
          building: 'Burj Khalifa',
          floor: '45',
          apartment: '4502',
          instructions: 'Call when you arrive at reception',
          coordinates: {
            latitude: 25.1972,
            longitude: 55.2744
          }
        },
        items: [
          {
            productId: 'prod_003',
            name: 'Espresso Blend',
            arabicName: 'خليط اسبريسو',
            quantity: 3,
            size: '500g',
            roastLevel: 'Dark',
            addOns: ['Grind Service'],
            price: 65.00,
            subtotal: 195.00
          }
        ],
        totalAmount: 205.00,
        deliveryFee: 10.00,
        status: 'ready',
        paymentMethod: 'card',
        paymentStatus: 'paid',
        estimatedDeliveryTime: new Date(Date.now() + 45 * 60 * 1000) // 45 minutes
      },
      {
        orderNumber: `ORD${Date.now()}_3`,
        userId: 'test_user_3',
        customerName: 'Khalid Hassan',
        customerPhone: '+971503333333',
        deliveryAddress: {
          fullAddress: 'The Dubai Mall, Sheikh Mohammed bin Rashid Boulevard',
          area: 'Downtown Dubai',
          building: 'Dubai Mall',
          instructions: 'Meet at main entrance',
          coordinates: {
            latitude: 25.1981,
            longitude: 55.2796
          }
        },
        items: [
          {
            productId: 'prod_004',
            name: 'Colombian Coffee',
            quantity: 1,
            size: '1kg',
            roastLevel: 'Medium',
            addOns: [],
            price: 120.00,
            subtotal: 120.00
          },
          {
            productId: 'prod_005',
            name: 'Coffee Maker Set',
            quantity: 1,
            price: 250.00,
            subtotal: 250.00
          }
        ],
        totalAmount: 370.00,
        deliveryFee: 15.00,
        status: 'ready',
        paymentMethod: 'digital-wallet',
        paymentStatus: 'paid',
        estimatedDeliveryTime: new Date(Date.now() + 30 * 60 * 1000) // 30 minutes
      }
    ];

    let createdCount = 0;
    for (const orderData of testOrders) {
      const existingOrder = await Order.findOne({ orderNumber: orderData.orderNumber });
      if (!existingOrder) {
        const order = new Order(orderData);
        await order.save();
        createdCount++;
        console.log(`✅ Created order: ${orderData.orderNumber} - ${orderData.customerName}`);
      } else {
        console.log(`⚠️  Order already exists: ${orderData.orderNumber}`);
      }
    }

    console.log(`\n✅ Created ${createdCount} new test orders\n`);

    // 3. Summary
    console.log('📊 TEST DATA SUMMARY:');
    console.log('═'.repeat(50));
    console.log('👤 Driver Account:');
    console.log('   Email: testdriver@almarya.com');
    console.log('   PIN: 1234');
    console.log('   Phone: +971501234567');
    console.log('');
    console.log('📦 Test Orders:');
    const orders = await Order.find({ status: 'ready' }).sort({ createdAt: -1 }).limit(3);
    orders.forEach((order, index) => {
      console.log(`   ${index + 1}. ${order.orderNumber}`);
      console.log(`      Customer: ${order.customerName}`);
      console.log(`      Amount: AED ${order.totalAmount.toFixed(2)}`);
      console.log(`      Status: ${order.status}`);
    });
    console.log('═'.repeat(50));
    console.log('');
    console.log('🚀 Ready for testing!');
    console.log('');
    console.log('📱 Next Steps:');
    console.log('   1. Open the Driver App');
    console.log('   2. Login with PIN: 1234');
    console.log('   3. Grant location permissions');
    console.log('   4. Go to "Available" tab');
    console.log('   5. Accept an order');
    console.log('   6. Start delivery');
    console.log('   7. Navigate to address');
    console.log('   8. Complete delivery');
    console.log('');

  } catch (error) {
    console.error('❌ Error creating test data:', error);
  } finally {
    await mongoose.disconnect();
    console.log('👋 Disconnected from MongoDB');
  }
}

// Run the script
createTestData();
