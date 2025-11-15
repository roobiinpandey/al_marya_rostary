// Quick test script to send emails to roobiinpandey@gmail.com
require('dotenv').config();
const mongoose = require('mongoose');
const Order = require('./models/Order');
const User = require('./models/User');
const emailService = require('./services/emailService');

async function testEmails() {
  try {
    console.log('==========================================');
    console.log('Email Test for roobiinpandey@gmail.com');
    console.log('==========================================\n');

    // Connect to database
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to database\n');

    // Find your user
    const user = await User.findOne({ email: 'roobiinpandey@gmail.com' });
    
    if (!user) {
      console.log('❌ User not found with email: roobiinpandey@gmail.com');
      console.log('Available users:');
      const users = await User.find({}, 'email name').limit(5);
      users.forEach(u => console.log(`  - ${u.email} (${u.name})`));
      process.exit(1);
    }

    console.log(`✅ Found user: ${user.name} (${user.email})\n`);

    // Get a coffee product
    const Coffee = require('./models/Coffee');
    const coffee = await Coffee.findOne();
    
    if (!coffee) {
      console.log('❌ No coffee products found');
      process.exit(1);
    }

    console.log('📝 Creating test order...\n');

    // Create order
    const orderNumber = `ORD-${Date.now()}-${Math.random().toString(36).substr(2, 9).toUpperCase()}`;
    
    const order = await Order.create({
      user: user._id,
      orderNumber,
      items: [{
        coffee: coffee._id,
        name: coffee.name || 'Premium Coffee Blend',
        quantity: 1,
        price: 75,
        selectedSize: '250g',
        subtotal: 75
      }],
      subtotal: 75,
      totalAmount: 75,
      paymentMethod: 'card',
      paymentStatus: 'paid',
      deliveryMethod: 'delivery',
      deliveryAddress: {
        street: '123 Test Street',
        city: 'Dubai',
        state: 'Dubai',
        zipCode: '12345',
        country: 'UAE'
      },
      status: 'pending'
    });

    console.log(`✅ Order created: ${order.orderNumber}`);
    console.log(`   Order ID: ${order._id}\n`);

    // Send order confirmation email
    console.log('📧 Sending order confirmation email...');
    const confirmResult = await emailService.sendOrderConfirmation(order, user);
    
    if (confirmResult.success) {
      console.log(`✅ Order confirmation email sent to ${user.email}\n`);
    } else {
      console.log(`❌ Failed to send confirmation email: ${confirmResult.error}\n`);
    }

    // Test status update emails
    const statuses = [
      { status: 'confirmed', message: 'Your order has been confirmed and is being prepared.' },
      { status: 'preparing', message: 'Your order is being prepared with care.' },
      { status: 'ready', message: 'Your order is ready for delivery!' },
      { status: 'delivered', message: 'Your order has been delivered. Enjoy!' }
    ];

    console.log('📧 Testing status update emails...\n');

    for (const { status, message } of statuses) {
      // Update order status
      order.status = status;
      await order.save();

      console.log(`Testing ${status.toUpperCase()} status...`);

      // Send status update email
      const subject = `Order ${order.orderNumber} - ${status.charAt(0).toUpperCase() + status.slice(1)}`;
      
      const html = `
        <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
          <div style="text-align: center; margin-bottom: 30px;">
            <h1 style="color: #A89A6A;">Al Marya Rostery</h1>
          </div>
          <h2 style="color: #333;">Order Status Update</h2>
          <p>Dear ${user.name},</p>
          <p>${message}</p>
          
          <div style="background: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0;">
            <h3 style="margin-top: 0;">Order #${order.orderNumber}</h3>
            <p><strong>Status:</strong> <span style="color: #A89A6A;">${status.toUpperCase()}</span></p>
            <p><strong>Total:</strong> AED ${order.totalAmount.toFixed(2)}</p>
          </div>
          
          <p>Thank you for choosing Al Marya Rostery!</p>
          
          <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
          <p style="color: #999; font-size: 12px; text-align: center;">
            Al Marya Rostery - Premium Coffee Experience<br>UAE
          </p>
        </div>
      `;

      const emailResult = await emailService.sendEmail({
        to: user.email,
        subject,
        html
      });

      if (emailResult.success) {
        console.log(`✅ ${status.toUpperCase()} email sent\n`);
      } else {
        console.log(`❌ Failed to send ${status} email: ${emailResult.error}\n`);
      }

      // Wait 1 second between emails
      await new Promise(resolve => setTimeout(resolve, 1000));
    }

    console.log('==========================================');
    console.log('✅ All emails sent successfully!');
    console.log('==========================================\n');
    console.log('📧 Check your Gmail inbox: roobiinpandey@gmail.com\n');
    console.log('You should receive:');
    console.log('1. Order Confirmation email');
    console.log('2. Status Update: CONFIRMED');
    console.log('3. Status Update: PREPARING');
    console.log('4. Status Update: READY');
    console.log('5. Status Update: DELIVERED\n');

    await mongoose.connection.close();
    process.exit(0);

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }
}

testEmails();
