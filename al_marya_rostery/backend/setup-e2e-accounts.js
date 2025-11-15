#!/usr/bin/env node

/**
 * Quick Setup Script for E2E Testing
 * Creates real test accounts: Customer, Staff, Driver
 */

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const ACCOUNTS = {
  customer: {
    name: 'Roobin Pandey',
    email: 'roobiinpandey@gmail.com',
    password: 'Test@1234',
    phone: '+971501234567',
    role: 'customer',
    isVerified: true
  },
  staff: {
    name: 'Staff Member',
    email: 'staff@almaryacoffee.com',
    pin: '1234',
    password: 'Staff@1234', // Fallback if email/password login is used
    phone: '+971502345678',
    role: 'staff',
    isVerified: true
  },
  driver: {
    name: 'Delivery Driver',
    email: 'driver@almaryacoffee.com',
    pin: '1234',
    password: 'Driver@1234', // Fallback if email/password login is used
    phone: '+971503456789',
    role: 'driver',
    isVerified: true
  }
};

async function createAccount(userData) {
  const User = require('./models/User');
  
  // Check if account already exists
  const existing = await User.findOne({ email: userData.email });
  if (existing) {
    console.log(`⏭️  ${userData.role.toUpperCase()}: ${userData.name} already exists (${userData.email})`);
    
    // Update PIN if it's staff or driver and doesn't have one
    if ((userData.role === 'staff' || userData.role === 'driver') && userData.pin && !existing.pin) {
      existing.pin = userData.pin;
      await existing.save();
      console.log(`   ✅ Added PIN: ${userData.pin}`);
    }
    
    return existing;
  }
  
  // Hash password
  const hashedPassword = await bcrypt.hash(userData.password, 10);
  
  // Create new user
  const user = new User({
    ...userData,
    password: hashedPassword
  });
  
  await user.save();
  console.log(`✅ ${userData.role.toUpperCase()}: ${userData.name} created successfully (${userData.email})`);
  if (userData.pin) {
    console.log(`   📌 PIN: ${userData.pin}`);
  }
  return user;
}

async function main() {
  try {
    console.log('🚀 E2E Testing - Account Setup\n');
    console.log('📡 Connecting to MongoDB...');
    
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB connected\n');
    
    console.log('👥 Creating test accounts...\n');
    
    // Create all accounts
    const customer = await createAccount(ACCOUNTS.customer);
    const staff = await createAccount(ACCOUNTS.staff);
    const driver = await createAccount(ACCOUNTS.driver);
    
    console.log('\n📊 ACCOUNT SUMMARY:\n');
    console.log('┌─────────────────────────────────────────────────────────────────┐');
    console.log('│ CUSTOMER ACCOUNT                                                 │');
    console.log('├─────────────────────────────────────────────────────────────────┤');
    console.log(`│ Name:     ${ACCOUNTS.customer.name.padEnd(55)} │`);
    console.log(`│ Email:    ${ACCOUNTS.customer.email.padEnd(55)} │`);
    console.log(`│ Password: ${ACCOUNTS.customer.password.padEnd(55)} │`);
    console.log(`│ Phone:    ${ACCOUNTS.customer.phone.padEnd(55)} │`);
    console.log('└─────────────────────────────────────────────────────────────────┘');
    
    console.log('┌─────────────────────────────────────────────────────────────────┐');
    console.log('│ STAFF ACCOUNT                                                    │');
    console.log('├─────────────────────────────────────────────────────────────────┤');
    console.log(`│ Name:     ${ACCOUNTS.staff.name.padEnd(55)} │`);
    console.log(`│ Email:    ${ACCOUNTS.staff.email.padEnd(55)} │`);
    console.log(`│ Password: ${ACCOUNTS.staff.password.padEnd(55)} │`);
    console.log(`│ Phone:    ${ACCOUNTS.staff.phone.padEnd(55)} │`);
    console.log('└─────────────────────────────────────────────────────────────────┘');
    
    console.log('┌─────────────────────────────────────────────────────────────────┐');
    console.log('│ DRIVER ACCOUNT                                                   │');
    console.log('├─────────────────────────────────────────────────────────────────┤');
    console.log(`│ Name:     ${ACCOUNTS.driver.name.padEnd(55)} │`);
    console.log(`│ Email:    ${ACCOUNTS.driver.email.padEnd(55)} │`);
    console.log(`│ Password: ${ACCOUNTS.driver.password.padEnd(55)} │`);
    console.log(`│ Phone:    ${ACCOUNTS.driver.phone.padEnd(55)} │`);
    console.log('└─────────────────────────────────────────────────────────────────┘');
    
    console.log('\n✅ All accounts ready for E2E testing!');
    console.log('\n📱 NEXT STEPS:');
    console.log('1. Start backend server: npm start');
    console.log('2. Login to Customer App with customer credentials');
    console.log('3. Login to Staff App with staff credentials');
    console.log('4. Login to Driver App with driver credentials');
    console.log('5. Follow E2E_TESTING_GUIDE.md for complete flow\n');
    
    await mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

main();
