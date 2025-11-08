/**
 * Admin Password Reset Script
 * Resets password for existing admin user
 * Run with: node reset-admin-password.js <email> <new-password>
 * Example: node reset-admin-password.js admin@almarya.com myNewPassword123
 */

require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const bcrypt = require('bcryptjs');

// Get email and password from command line arguments
const args = process.argv.slice(2);
const ADMIN_EMAIL = args[0]; // Email from command line
const NEW_PASSWORD = args[1]; // Password from command line

if (!ADMIN_EMAIL || !NEW_PASSWORD) {
  console.error('❌ Usage: node reset-admin-password.js <email> <new-password>');
  console.error('   Example: node reset-admin-password.js admin@almarya.com myNewPassword123');
  process.exit(1);
}

async function resetAdminPassword() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Find admin user
    console.log(`🔍 Finding admin user: ${ADMIN_EMAIL}...`);
    const admin = await User.findOne({ email: ADMIN_EMAIL });
    
    if (!admin) {
      console.log('❌ Admin user not found!');
      console.log('\n📋 Available admin emails:');
      const admins = await User.find({ roles: 'admin' }).select('email');
      admins.forEach(a => console.log(`   - ${a.email}`));
      await mongoose.connection.close();
      return;
    }

    console.log(`✅ Found admin: ${admin.name}`);
    console.log(`📧 Email: ${admin.email}`);
    console.log(`🎭 Roles: ${admin.roles.join(', ')}\n`);

    // Hash new password
    console.log('🔐 Hashing new password...');
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(NEW_PASSWORD, salt);

    // Update password directly
    admin.password = hashedPassword;
    admin.isActive = true;
    admin.isEmailVerified = true;
    
    await admin.save({ validateBeforeSave: false });
    
    console.log('✅ Password updated successfully!\n');
    console.log('═══════════════════════════════════════════════════');
    console.log('📋 UPDATED ADMIN CREDENTIALS');
    console.log('═══════════════════════════════════════════════════');
    console.log(`📧 Email:    ${ADMIN_EMAIL}`);
    console.log(`🔑 Password: ${NEW_PASSWORD}`);
    console.log('═══════════════════════════════════════════════════');
    console.log('\n🧪 Test login at:');
    console.log('   Production: https://almaryarostary.onrender.com\n');
    
    console.log('📝 Test with cURL:');
    console.log(`   curl -X POST https://almaryarostary.onrender.com/api/auth/admin-login \\`);
    console.log(`     -H "Content-Type: application/json" \\`);
    console.log(`     -d '{"email":"${ADMIN_EMAIL}","password":"${NEW_PASSWORD}"}'\n`);

  } catch (error) {
    console.error('❌ Error resetting password:', error.message);
    console.error(error);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Database connection closed');
  }
}

resetAdminPassword();
