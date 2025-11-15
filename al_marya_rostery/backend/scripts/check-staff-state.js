/**
 * Check Staff Database State
 * Shows current staff records and their authentication status
 */

require('dotenv').config();
const mongoose = require('mongoose');
const Staff = require('../models/Staff');

// Connect to MongoDB
async function connectDB() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB connected successfully\n');
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error.message);
    process.exit(1);
  }
}

// Check staff state
async function checkStaffState() {
  try {
    const allStaff = await Staff.find({ isDeleted: false }).select('+pin');
    
    console.log('📊 Current Staff Database State\n');
    console.log('='.repeat(80));
    console.log(`Total Active Staff: ${allStaff.length}\n`);
    
    for (const staff of allStaff) {
      console.log(`👤 Name: ${staff.name}`);
      console.log(`   Email: ${staff.email}`);
      console.log(`   Role: ${staff.role}`);
      console.log(`   Status: ${staff.status}`);
      console.log(`   Employee ID: ${staff.employeeId || '❌ NOT SET'}`);
      console.log(`   PIN: ${staff.pin ? '✅ SET (hashed)' : '❌ NOT SET'}`);
      console.log(`   PIN Locked: ${staff.isPinLocked ? '🔒 YES' : '✅ NO'}`);
      console.log(`   QR Badge: ${staff.qrBadgeToken ? '✅ SET' : '❌ NOT SET'}`);
      console.log(`   Firebase UID: ${staff.firebaseUid || '❌ NOT SET'}`);
      console.log(`   Require PIN Change: ${staff.requirePinChange ? 'YES' : 'NO'}`);
      console.log('   ' + '-'.repeat(76));
    }
    
    console.log('='.repeat(80));
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

// Run check
(async () => {
  await connectDB();
  await checkStaffState();
  await mongoose.connection.close();
  console.log('\n✅ Database connection closed\n');
  process.exit(0);
})();
