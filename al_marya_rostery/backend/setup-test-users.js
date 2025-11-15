#!/usr/bin/env node

/**
 * Setup Test Users for API Connectivity Testing
 * Creates test accounts for Customer, Staff, and Driver roles
 */

const axios = require('axios');

// Console colors (simple version for compatibility)
const colors = {
  cyan: (text) => `\x1b[36m${text}\x1b[0m`,
  green: (text) => `\x1b[32m${text}\x1b[0m`,
  yellow: (text) => `\x1b[33m${text}\x1b[0m`,
  red: (text) => `\x1b[31m${text}\x1b[0m`,
  gray: (text) => `\x1b[90m${text}\x1b[0m`,
  bold: {
    cyan: (text) => `\x1b[1m\x1b[36m${text}\x1b[0m`
  }
};

const BASE_URL = process.env.BASE_URL || 'http://localhost:5001';

const TEST_USERS = [
  {
    email: 'test.customer@almarya.com',
    password: 'TestCustomer123!',
    name: 'Test Customer',
    phone: '+971501234567',
    role: 'customer'
  },
  {
    email: 'test.staff@almarya.com',
    password: 'TestStaff123!',
    name: 'Test Staff',
    phone: '+971501234568',
    role: 'staff'
  },
  {
    email: 'test.driver@almarya.com',
    password: 'TestDriver123!',
    name: 'Test Driver',
    phone: '+971501234569',
    role: 'driver'
  }
];

async function createTestUser(user) {
  try {
    console.log(colors.cyan(`Creating ${user.role} user: ${user.email}`));
    
    const response = await axios.post(`${BASE_URL}/api/auth/register`, user, {
      timeout: 10000
    });
    
    console.log(colors.green(`  ✅ ${user.role} user created successfully`));
    return response.data;
  } catch (error) {
    if (error.response?.status === 400 && error.response?.data?.message?.includes('already exists')) {
      console.log(colors.yellow(`  ⚠️ ${user.role} user already exists`));
      return { exists: true };
    }
    console.error(colors.red(`  ❌ Failed to create ${user.role} user:`), error.response?.data || error.message);
    throw error;
  }
}

async function main() {
  console.log(colors.bold.cyan('\n🔧 Setting Up Test Users'));
  console.log(colors.cyan('═'.repeat(60)));
  console.log(colors.gray(`Base URL: ${BASE_URL}\n`));
  
  for (const user of TEST_USERS) {
    await createTestUser(user);
  }
  
  console.log(colors.green('\n✅ Test user setup complete!'));
  console.log(colors.gray('\nYou can now run: npm test\n'));
}

main().catch((error) => {
  console.error(colors.red('\n❌ Setup failed:'), error.message);
  process.exit(1);
});
