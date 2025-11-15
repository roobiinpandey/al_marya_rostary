#!/usr/bin/env node

/**
 * 🚀 E2E Test Setup Script
 * 
 * This script creates the necessary test users for running the E2E test:
 * - Test Customer (email/password login)
 * - Test Staff (PIN login)
 * - Test Driver (PIN login)
 * 
 * Run: node setup-e2e-test.js
 */

require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');
const Staff = require('./models/Staff');
const Driver = require('./models/Driver');

// Test user configurations
const TEST_USERS = {
  customer: {
    name: 'Test Customer',
    email: 'test_customer@almarya.com',
    password: 'TestPass123!',
    phone: '+971501234567',
    role: 'customer'
  },
  staff: {
    name: 'Test Staff',
    employeeId: 'TST001', // Required: ABC123 format
    email: 'test_staff@almarya.com',
    phone: '+971501111111',
    pin: '1234',
    role: 'barista',
    status: 'active'
  },
  driver: {
    name: 'Test Driver',
    firebaseUid: 'test_driver_uid_12345', // Required for Driver model
    email: 'test_driver@almarya.com',
    phone: '+971502222222',
    pin: '5678',
    status: 'available',
    vehicleType: 'bike', // Required: bike, car, scooter, bicycle
    vehicleNumber: 'TEST-123'
  }
};

const log = (emoji, message, data = null) => {
  const timestamp = new Date().toLocaleTimeString();
  console.log(`${emoji} [${timestamp}] ${message}`);
  if (data) {
    console.log(JSON.stringify(data, null, 2));
  }
};

async function createTestCustomer() {
  log('👤', 'Creating test customer...');

  try {
    // Check if customer already exists
    const existingCustomer = await User.findOne({ email: TEST_USERS.customer.email });
    
    if (existingCustomer) {
      log('✅', 'Test customer already exists');
      log('📧', `Email: ${existingCustomer.email}`);
      return existingCustomer;
    }

    // Create new customer
    const customer = await User.create({
      name: TEST_USERS.customer.name,
      email: TEST_USERS.customer.email,
      password: TEST_USERS.customer.password, // Will be hashed by pre-save hook
      phone: TEST_USERS.customer.phone,
      role: TEST_USERS.customer.role
    });

    log('✅', 'Test customer created successfully');
    log('📧', `Email: ${customer.email}`);
    log('🔑', `Password: ${TEST_USERS.customer.password}`);
    
    return customer;
  } catch (error) {
    log('❌', 'Failed to create test customer', error.message);
    throw error;
  }
}

async function createTestStaff() {
  log('👨‍🍳', 'Creating test staff member...');

  try {
    // Check if staff already exists
    const existingStaff = await Staff.findOne({ email: TEST_USERS.staff.email });
    
    if (existingStaff) {
      log('✅', 'Test staff already exists');
      log('📧', `Email: ${existingStaff.email}`);
      log('🔢', `PIN: ${TEST_USERS.staff.pin}`);
      return existingStaff;
    }

    // Hash PIN
    const hashedPin = await bcrypt.hash(TEST_USERS.staff.pin, 10);

    // Create new staff
    const staff = await Staff.create({
      name: TEST_USERS.staff.name,
      employeeId: TEST_USERS.staff.employeeId,
      email: TEST_USERS.staff.email,
      phone: TEST_USERS.staff.phone,
      pin: hashedPin,
      role: TEST_USERS.staff.role,
      status: TEST_USERS.staff.status,
      isDeleted: false
    });

    log('✅', 'Test staff created successfully');
    log('📧', `Email: ${staff.email}`);
    log('🔢', `PIN: ${TEST_USERS.staff.pin}`);
    log('👔', `Role: ${staff.role}`);
    
    return staff;
  } catch (error) {
    log('❌', 'Failed to create test staff', error.message);
    throw error;
  }
}

async function createTestDriver() {
  log('🚗', 'Creating test driver...');

  try {
    // Check if driver already exists
    const existingDriver = await Driver.findOne({ email: TEST_USERS.driver.email });
    
    if (existingDriver) {
      log('✅', 'Test driver already exists');
      log('📧', `Email: ${existingDriver.email}`);
      log('🔢', `PIN: ${TEST_USERS.driver.pin}`);
      return existingDriver;
    }

    // Hash PIN
    const hashedPin = await bcrypt.hash(TEST_USERS.driver.pin, 10);

    // Create PinDriver schema matching driverAuth.js
    const PinDriverSchema = new mongoose.Schema({
      driverId: String,
      name: String,
      email: String,
      phone: String,
      pin: String,
      status: {
        type: String,
        enum: ['available', 'on_delivery', 'offline', 'on_break'],
        default: 'offline'
      },
      vehicleInfo: {
        type: { type: String },  // Nested type field
        plateNumber: String,
        color: String
      },
      isActive: Boolean,
      createdAt: { type: Date, default: Date.now },
      updatedAt: { type: Date, default: Date.now }
    });
    const PinDriver = mongoose.models.PinDriver || mongoose.model('PinDriver', PinDriverSchema, 'drivers');

    // Create driver with PinDriver schema for PIN authentication
    const driver = await PinDriver.create({
      driverId: `DRV-${Date.now()}`,
      name: TEST_USERS.driver.name,
      email: TEST_USERS.driver.email,
      phone: TEST_USERS.driver.phone,
      pin: hashedPin,
      status: 'available',
      vehicleInfo: {
        type: TEST_USERS.driver.vehicleType,
        plateNumber: TEST_USERS.driver.vehicleNumber,
        color: 'White'
      },
      isActive: true
    });

    log('✅', 'Test driver created successfully');
    log('📧', `Email: ${driver.email}`);
    log('🔢', `PIN: ${TEST_USERS.driver.pin}`);
    log('🚙', `Vehicle: ${driver.vehicleType} (${driver.vehicleNumber})`);
    
    return driver;
  } catch (error) {
    log('❌', 'Failed to create test driver', error.message);
    throw error;
  }
}

async function displaySummary(customer, staff, driver) {
  console.log('\n');
  log('📋', '='.repeat(60));
  log('📋', 'TEST USERS SETUP COMPLETE');
  log('📋', '='.repeat(60));
  console.log('\n');

  console.log('🎯 Use these credentials for E2E testing:\n');

  console.log('👤 TEST CUSTOMER:');
  console.log(`   Email:    ${TEST_USERS.customer.email}`);
  console.log(`   Password: ${TEST_USERS.customer.password}`);
  console.log(`   ID:       ${customer._id}`);
  console.log('');

  console.log('👨‍🍳 TEST STAFF:');
  console.log(`   Name:     ${TEST_USERS.staff.name}`);
  console.log(`   Employee: ${TEST_USERS.staff.employeeId}`);
  console.log(`   Email:    ${TEST_USERS.staff.email}`);
  console.log(`   PIN:      ${TEST_USERS.staff.pin}`);
  console.log(`   ID:       ${staff._id}`);
  console.log('');

  console.log('🚗 TEST DRIVER:');
  console.log(`   Name:     ${TEST_USERS.driver.name}`);
  console.log(`   Email:    ${TEST_USERS.driver.email}`);
  console.log(`   PIN:      ${TEST_USERS.driver.pin}`);
  console.log(`   Vehicle:  ${TEST_USERS.driver.vehicleType}`);
  console.log(`   Plate:    ${TEST_USERS.driver.vehicleNumber}`);
  console.log(`   ID:       ${driver._id}`);
  console.log('');

  log('✅', 'You can now run the E2E test:');
  console.log('   node test-e2e-complete-flow.js\n');
}

async function main() {
  console.log('\n');
  log('🚀', '='.repeat(60));
  log('🚀', 'E2E TEST SETUP - Creating Test Users');
  log('🚀', '='.repeat(60));
  console.log('\n');

  try {
    // Connect to MongoDB
    log('🔌', 'Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    log('✅', 'Connected to MongoDB');
    console.log('\n');

    // Create test users
    const customer = await createTestCustomer();
    console.log('\n');

    const staff = await createTestStaff();
    console.log('\n');

    const driver = await createTestDriver();
    console.log('\n');

    // Display summary
    await displaySummary(customer, staff, driver);

  } catch (error) {
    console.log('\n');
    log('❌', '='.repeat(60));
    log('❌', 'SETUP FAILED');
    log('❌', error.message);
    log('❌', '='.repeat(60));
    console.error(error);
    process.exit(1);
  } finally {
    // Close MongoDB connection
    await mongoose.connection.close();
    log('👋', 'MongoDB connection closed');
  }
}

// Run setup
main()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error('Unhandled error:', error);
    process.exit(1);
  });
