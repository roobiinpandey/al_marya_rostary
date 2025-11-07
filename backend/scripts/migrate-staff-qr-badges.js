#!/usr/bin/env node
/**
 * QR Badge Migration Script
 * Generates QR badges for all staff members who don't have one
 * Run: node scripts/migrate-staff-qr-badges.js
 */

require('dotenv').config();
const mongoose = require('mongoose');
const Staff = require('../models/Staff');
const qrBadgeService = require('../services/qrBadgeService');

async function migrateQRBadges() {
  try {
    console.log('🚀 Starting QR Badge Migration...\n');
    console.log('🔗 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Find all staff without QR badges
    const staffWithoutBadges = await Staff.find({
      isDeleted: false,
      $or: [
        { qrBadgeToken: { $exists: false } },
        { qrBadgeToken: null },
        { qrBadgeToken: '' }
      ]
    });

    const totalStaff = await Staff.countDocuments({ isDeleted: false });
    const staffNeedingBadges = staffWithoutBadges.length;

    console.log('📊 Migration Status:');
    console.log(`   Total Staff: ${totalStaff}`);
    console.log(`   Need Badges: ${staffNeedingBadges}`);
    console.log(`   Have Badges: ${totalStaff - staffNeedingBadges}\n`);

    if (staffNeedingBadges === 0) {
      console.log('✅ All staff already have QR badges!');
      await mongoose.disconnect();
      process.exit(0);
    }

    console.log('🔧 Generating QR badges...\n');

    let successCount = 0;
    let errorCount = 0;
    const errors = [];

    for (const staff of staffWithoutBadges) {
      try {
        // Generate QR badge token
        const qrToken = qrBadgeService.generateQRToken(staff.employeeId);
        const qrExpiresAt = new Date();
        qrExpiresAt.setMonth(qrExpiresAt.getMonth() + 6); // 6 months expiry

        staff.qrBadgeToken = qrToken;
        staff.qrBadgeGeneratedAt = new Date();
        staff.qrBadgeExpiresAt = qrExpiresAt;
        await staff.save();

        console.log(`✅ ${staff.employeeId} - ${staff.name}`);
        successCount++;
      } catch (error) {
        console.error(`❌ ${staff.employeeId} - ${staff.name}: ${error.message}`);
        errorCount++;
        errors.push({
          employeeId: staff.employeeId,
          name: staff.name,
          error: error.message
        });
      }
    }

    console.log('\n═══════════════════════════════════════════════════════════');
    console.log('📊 Migration Complete!');
    console.log('═══════════════════════════════════════════════════════════\n');
    console.log(`✅ Success: ${successCount} badges generated`);
    console.log(`❌ Failed: ${errorCount} errors\n`);

    if (errors.length > 0) {
      console.log('❌ Errors:');
      errors.forEach(err => {
        console.log(`   ${err.employeeId} - ${err.name}: ${err.error}`);
      });
      console.log('');
    }

    await mongoose.disconnect();
    process.exit(errorCount > 0 ? 1 : 0);

  } catch (error) {
    console.error('❌ Migration failed:', error);
    await mongoose.disconnect();
    process.exit(1);
  }
}

// Run migration
migrateQRBadges();
