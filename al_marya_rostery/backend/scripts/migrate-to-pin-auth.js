/**
 * Migration Script: Convert existing staff to PIN + QR Badge authentication
 * 
 * This script:
 * 1. Finds all existing staff with Firebase authentication
 * 2. Generates Employee IDs based on their roles (BAR001, MNG001, CSH001, etc.)
 * 3. Sets default PIN (1234) with requirePinChange flag
 * 4. Generates QR badge tokens
 * 5. Keeps Firebase credentials for backward compatibility
 */

require('dotenv').config();
const mongoose = require('mongoose');
const Staff = require('../models/Staff');
const qrBadgeService = require('../services/qrBadgeService');

// Connect to MongoDB
async function connectDB() {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('✅ MongoDB connected successfully');
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error.message);
    process.exit(1);
  }
}

// Main migration function
async function migrateStaffToPinAuth() {
  try {
    console.log('\n🔄 Starting Staff Migration to PIN + QR Badge Authentication...\n');

    // Find all staff without Employee IDs (not yet migrated)
    const staffToMigrate = await Staff.find({ 
      employeeId: { $exists: false },
      isDeleted: false 
    });

    console.log(`📊 Found ${staffToMigrate.length} staff members to migrate\n`);

    if (staffToMigrate.length === 0) {
      console.log('✅ All staff already migrated!');
      return;
    }

    let successCount = 0;
    let errorCount = 0;

    for (const staff of staffToMigrate) {
      try {
        console.log(`\n🔧 Migrating: ${staff.name} (${staff.email})`);

        // Generate Employee ID based on role
        const employeeId = await Staff.generateEmployeeId(staff.role);
        console.log(`  📝 Generated Employee ID: ${employeeId}`);

        // Set default PIN: 1234 (will be hashed by pre-save middleware)
        const defaultPin = '1234';
        console.log(`  🔐 Setting default PIN: ${defaultPin}`);

        // Generate QR Badge Token
        const qrToken = qrBadgeService.generateQRToken(employeeId);
        console.log(`  🎫 Generated QR Badge Token`);

        // Calculate QR badge expiry (6 months from now)
        const qrExpiresAt = new Date();
        qrExpiresAt.setMonth(qrExpiresAt.getMonth() + 6);

        // Update staff with new authentication fields
        staff.employeeId = employeeId;
        staff.pin = defaultPin; // Will be hashed by pre-save middleware
        staff.requirePinChange = true; // Force staff to change PIN on first login
        staff.pinAttempts = 0;
        staff.pinLockedUntil = null;
        staff.qrBadgeToken = qrToken;
        staff.qrBadgeGeneratedAt = new Date();
        staff.qrBadgeExpiresAt = qrExpiresAt;

        // Keep Firebase credentials for backward compatibility
        // firebaseUid and email remain unchanged

        await staff.save();

        console.log(`  ✅ Successfully migrated: ${staff.name}`);
        console.log(`  📋 Employee ID: ${employeeId}`);
        console.log(`  🔐 Default PIN: ${defaultPin} (must change on first login)`);
        console.log(`  🎫 QR Badge: Valid until ${qrExpiresAt.toLocaleDateString()}`);

        successCount++;
      } catch (error) {
        console.error(`  ❌ Failed to migrate ${staff.name}:`, error.message);
        errorCount++;
      }
    }

    console.log('\n\n' + '='.repeat(60));
    console.log('📊 Migration Summary');
    console.log('='.repeat(60));
    console.log(`✅ Successfully migrated: ${successCount}`);
    console.log(`❌ Failed: ${errorCount}`);
    console.log(`📝 Total staff processed: ${staffToMigrate.length}`);
    console.log('='.repeat(60));

    if (successCount > 0) {
      console.log('\n📋 Next Steps:');
      console.log('1. Staff can now login using:');
      console.log('   - Employee ID + PIN (1234 - must change on first login)');
      console.log('   - QR Badge Scan (download badges from admin panel)');
      console.log('2. Generate and print QR badges from admin panel');
      console.log('3. Distribute badges to staff members');
      console.log('4. Train staff on new login methods');
      console.log('\n⚠️  Default PIN: 1234 (Staff MUST change this on first login)');
    }

  } catch (error) {
    console.error('\n❌ Migration failed:', error.message);
    console.error(error.stack);
  }
}

// Run migration
(async () => {
  await connectDB();
  await migrateStaffToPinAuth();
  await mongoose.connection.close();
  console.log('\n✅ Database connection closed');
  console.log('🎉 Migration complete!\n');
  process.exit(0);
})();
