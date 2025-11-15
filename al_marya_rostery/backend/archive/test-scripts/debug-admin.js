/**
 * Debug Admin User Script
 */

require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const bcrypt = require('bcryptjs');

async function debugAdmin() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Find admin user WITH password field
    const admin = await User.findOne({ email: 'admin@almarya.com' }).select('+password');
    
    if (!admin) {
      console.log('❌ Admin user not found!');
      await mongoose.connection.close();
      return;
    }

    console.log('📋 Admin User Details:');
    console.log('   ID:', admin._id);
    console.log('   Name:', admin.name);
    console.log('   Email:', admin.email);
    console.log('   Roles:', admin.roles);
    console.log('   Role (single):', admin.role);
    console.log('   Is Active:', admin.isActive);
    console.log('   Email Verified:', admin.isEmailVerified);
    console.log('   Password Hash:', admin.password ? `${admin.password.substring(0, 20)}...` : 'MISSING');
    console.log('   Password Length:', admin.password ? admin.password.length : 0);
    
    // Test password comparison
    console.log('\n🔐 Testing Password:');
    const testPassword = 'almarya2024';
    const isMatch = await bcrypt.compare(testPassword, admin.password);
    console.log(`   Password "${testPassword}":`, isMatch ? '✅ MATCHES' : '❌ NO MATCH');
    
    // Try the method
    const isMatch2 = await admin.comparePassword(testPassword);
    console.log(`   Method comparePassword:`, isMatch2 ? '✅ MATCHES' : '❌ NO MATCH');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔌 Database connection closed');
  }
}

debugAdmin();
