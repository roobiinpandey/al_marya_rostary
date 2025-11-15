const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const mongoose = require('mongoose');
const Order = require('./models/Order');

async function checkOrders() {
  try {
    const mongoUri = process.env.MONGODB_URI || process.env.MONGO_URI;
    if (!mongoUri) {
      throw new Error('MONGODB_URI not found in environment variables');
    }
    await mongoose.connect(mongoUri);
    console.log('✅ Connected to MongoDB');

    const totalOrders = await Order.countDocuments();
    console.log(`\n📊 Total orders in database: ${totalOrders}`);

    const ordersByStatus = await Order.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      },
      { $sort: { count: -1 } }
    ]);

    console.log('\n📈 Orders by status:');
    ordersByStatus.forEach(({ _id, count }) => {
      console.log(`  ${_id}: ${count}`);
    });

    // Check recent orders
    const recentOrders = await Order.find()
      .sort({ createdAt: -1 })
      .limit(10)
      .select('orderNumber status assignedStaff createdAt');

    console.log('\n📋 Recent 10 orders:');
    recentOrders.forEach(order => {
      console.log(`  ${order.orderNumber} - Status: ${order.status} - Assigned: ${order.assignedStaff ? 'Yes' : 'No'}`);
    });

    await mongoose.connection.close();
    console.log('\n✅ Done');
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

checkOrders();
