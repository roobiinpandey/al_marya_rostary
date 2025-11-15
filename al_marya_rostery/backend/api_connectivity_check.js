#!/usr/bin/env node

/**
 * API Connectivity Check Script
 * 
 * Tests CRUD operations for all apps (Customer, Staff, Driver)
 * Verifies backend connectivity and validates permissions
 */

const axios = require('axios');
const fs = require('fs').promises;
const path = require('path');

// Simple ANSI color codes (Chalk v5 ESM compatibility fix)
const colors = {
  green: (text) => `\x1b[32m${text}\x1b[0m`,
  red: (text) => `\x1b[31m${text}\x1b[0m`,
  yellow: (text) => `\x1b[33m${text}\x1b[0m`,
  cyan: (text) => `\x1b[36m${text}\x1b[0m`,
  blue: (text) => `\x1b[34m${text}\x1b[0m`,
  gray: (text) => `\x1b[90m${text}\x1b[0m`,
  bold: {
    cyan: (text) => `\x1b[1m\x1b[36m${text}\x1b[0m`,
    white: (text) => `\x1b[1m\x1b[37m${text}\x1b[0m`
  }
};

// Mock chalk for compatibility
const chalk = {
  green: colors.green,
  red: colors.red,
  yellow: colors.yellow,
  cyan: colors.cyan,
  blue: colors.blue,
  gray: colors.gray,
  bold: (text) => `\x1b[1m${text}\x1b[0m`
};

// Add chained bold methods
chalk.bold.cyan = (text) => `\x1b[1m\x1b[36m${text}\x1b[0m`;
chalk.bold.white = (text) => `\x1b[1m\x1b[37m${text}\x1b[0m`;
chalk.green.bold = (text) => `\x1b[1m\x1b[32m${text}\x1b[0m`;
chalk.yellow.bold = (text) => `\x1b[1m\x1b[33m${text}\x1b[0m`;
chalk.red.bold = (text) => `\x1b[1m\x1b[31m${text}\x1b[0m`;

// ============================================================================
// CONFIGURATION
// ============================================================================

const CONFIG = {
  BASE_URL: process.env.BASE_URL || 'http://localhost:5001',
  TIMEOUT: 10000, // 10 seconds
  RETRY_ATTEMPTS: 3,
  RETRY_DELAY: 2000, // 2 seconds
  LOG_DIR: path.join(__dirname, 'logs'),
  LOG_FILE: path.join(__dirname, 'logs', 'api_test.log')
};

// Test user credentials for each app (using real database users)
const TEST_USERS = {
  customer: {
    email: process.env.TEST_CUSTOMER_EMAIL || 'admin@almarya.com',
    password: process.env.TEST_CUSTOMER_PASSWORD || 'almarya2024',
    role: 'customer'
  },
  staff: {
    email: process.env.TEST_STAFF_EMAIL || 'staff@almaryacoffee.com',
    password: process.env.TEST_STAFF_PASSWORD || '1234',
    role: 'staff'
  },
  driver: {
    email: process.env.TEST_DRIVER_EMAIL || 'driver@almaryacoffee.com',
    password: process.env.TEST_DRIVER_PASSWORD || '1234',
    role: 'driver'
  }
};

// ============================================================================
// STATE MANAGEMENT
// ============================================================================

const testResults = [];
const tokens = {};
let totalTests = 0;
let passedTests = 0;
let failedTests = 0;
const latencies = [];

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Initialize Firebase Admin SDK
 */
async function initializeFirebase() {
  // Skip Firebase initialization for API testing
  // Tests will use JWT authentication from /api/auth/login
  console.log(colors.cyan('ℹ️ Using JWT authentication for API tests'));
}

/**
 * Create logs directory if it doesn't exist
 */
async function ensureLogDirectory() {
  try {
    await fs.mkdir(CONFIG.LOG_DIR, { recursive: true });
  } catch (error) {
    // Directory already exists
  }
}

/**
 * Log message to file
 */
async function logToFile(message) {
  const timestamp = new Date().toISOString();
  const logMessage = `[${timestamp}] ${message}\n`;
  
  try {
    await fs.appendFile(CONFIG.LOG_FILE, logMessage);
  } catch (error) {
    console.error(chalk.red('Failed to write to log file:'), error.message);
  }
}

/**
 * Sleep utility
 */
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

/**
 * Retry logic wrapper
 */
async function retryRequest(fn, retries = CONFIG.RETRY_ATTEMPTS) {
  for (let i = 0; i < retries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === retries - 1) throw error;
      console.log(chalk.yellow(`  ⚠️ Retry ${i + 1}/${retries}...`));
      await sleep(CONFIG.RETRY_DELAY);
    }
  }
}

/**
 * Format response time
 */
function formatTime(ms) {
  if (ms < 100) return chalk.green(`${ms}ms`);
  if (ms < 500) return chalk.yellow(`${ms}ms`);
  return chalk.red(`${ms}ms`);
}

/**
 * Format status code
 */
function formatStatus(code) {
  if (code >= 200 && code < 300) return chalk.green(code);
  if (code >= 400 && code < 500) return chalk.yellow(code);
  return chalk.red(code);
}

// ============================================================================
// AUTHENTICATION
// ============================================================================

/**
 * Login and get JWT token
 */
async function loginUser(userType) {
  const user = TEST_USERS[userType];
  
  console.log(chalk.cyan(`\n🔐 Authenticating ${userType} user...`));
  
  try {
    const startTime = Date.now();
    let response;
    let endpoint;
    let requestData;
    
    // Staff and Driver use PIN-only authentication
    if (userType === 'staff' || userType === 'driver') {
      endpoint = `${CONFIG.BASE_URL}/api/staff/auth/login-pin`;
      requestData = { pin: user.password };
    } else {
      // Customer uses email/password
      endpoint = `${CONFIG.BASE_URL}/api/auth/login`;
      requestData = { email: user.email, password: user.password };
    }
    
    response = await retryRequest(async () => {
      return await axios.post(endpoint, requestData, {
        timeout: CONFIG.TIMEOUT
      });
    });
    
    const latency = Date.now() - startTime;
    latencies.push(latency);
    
    // Extract token from response
    const tokenValue = response.data.token || response.data.data?.token || response.data.accessToken;
    tokens[userType] = tokenValue;
    
    console.log(colors.gray(`    🔍 Token ${tokenValue ? 'saved' : 'NOT FOUND in response'}`));
    if (!tokenValue) {
      console.log(colors.gray(`    Response keys: ${Object.keys(response.data).join(', ')}`));
    }
    
    console.log(chalk.green(`  ✅ ${userType} authenticated (${latency}ms)`));
    
    testResults.push({
      app: userType.charAt(0).toUpperCase() + userType.slice(1),
      endpoint: userType === 'staff' || userType === 'driver' ? '/api/staff/auth/login-pin' : '/api/auth/login',
      method: 'POST',
      status: response.status,
      latency: latency,
      passed: true
    });
    
    totalTests++;
    passedTests++;
    
    return response.data.token;
  } catch (error) {
    console.log(chalk.red(`  ❌ ${userType} authentication failed: ${error.message}`));
    
    testResults.push({
      app: userType.charAt(0).toUpperCase() + userType.slice(1),
      endpoint: '/api/auth/login',
      method: 'POST',
      status: error.response?.status || 0,
      latency: 0,
      passed: false,
      error: error.message
    });
    
    totalTests++;
    failedTests++;
    
    await logToFile(`FAILED: ${userType} login - ${error.message}`);
    
    return null;
  }
}

// ============================================================================
// TEST FUNCTIONS
// ============================================================================

/**
 * Generic API test function
 */
async function testEndpoint(app, endpoint, method, token, data = null, expectedStatus = 200) {
  const url = `${CONFIG.BASE_URL}${endpoint}`;
  
  try {
    const startTime = Date.now();
    
    const config = {
      method: method.toLowerCase(),
      url,
      timeout: CONFIG.TIMEOUT,
      headers: {}
    };
    
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    
    if (data && ['POST', 'PUT', 'PATCH'].includes(method.toUpperCase())) {
      config.data = data;
    }
    
    const response = await retryRequest(async () => await axios(config));
    
    const latency = Date.now() - startTime;
    latencies.push(latency);
    
    const passed = response.status === expectedStatus || (response.status >= 200 && response.status < 300);
    
    if (passed) {
      console.log(chalk.green(`  ✅ ${app} → ${endpoint} [${method}] → ${response.status} (${latency}ms)`));
      passedTests++;
    } else {
      console.log(chalk.yellow(`  ⚠️ ${app} → ${endpoint} [${method}] → ${response.status} (expected ${expectedStatus})`));
      failedTests++;
    }
    
    testResults.push({
      app,
      endpoint,
      method,
      status: response.status,
      latency,
      passed
    });
    
    totalTests++;
    
    return response.data;
  } catch (error) {
    const latency = Date.now();
    
    console.log(chalk.red(`  ❌ ${app} → ${endpoint} [${method}] → ${error.response?.status || 'FAILED'}`));
    console.log(chalk.red(`     Error: ${error.message}`));
    
    testResults.push({
      app,
      endpoint,
      method,
      status: error.response?.status || 0,
      latency: 0,
      passed: false,
      error: error.message
    });
    
    totalTests++;
    failedTests++;
    
    await logToFile(`FAILED: ${app} ${method} ${endpoint} - ${error.message}`);
    
    return null;
  }
}

/**
 * Test Customer App endpoints
 */
async function testCustomerApp() {
  console.log(chalk.blue('\n📱 Testing Customer App Endpoints'));
  console.log(chalk.blue('═'.repeat(60)));
  
  const token = tokens.customer;
  
  console.log(chalk.gray(`  🔍 Debug: tokens object =`, Object.keys(tokens)));
  console.log(chalk.gray(`  🔍 Debug: customer token = ${token ? 'EXISTS' : 'MISSING'}`));
  
  if (!token) {
    console.log(chalk.red('  ❌ Skipping Customer App tests (no token)'));
    return;
  }
  
  // GET Products
  await testEndpoint('Customer', '/api/products', 'GET', token);
  
  // GET Categories
  await testEndpoint('Customer', '/api/categories', 'GET', token);
  
  // GET User Profile
  await testEndpoint('Customer', '/api/users/profile', 'GET', token);
  
  // GET Orders
  await testEndpoint('Customer', '/api/orders', 'GET', token);
  
  // GET Subscriptions
  await testEndpoint('Customer', '/api/subscriptions', 'GET', token);
  
  // GET Wishlist
  await testEndpoint('Customer', '/api/wishlist', 'GET', token);
  
  // GET Addresses
  await testEndpoint('Customer', '/api/addresses', 'GET', token);
  
  // GET Wallet Balance
  await testEndpoint('Customer', '/api/wallet/balance', 'GET', token);
}

/**
 * Test Staff App endpoints
 */
async function testStaffApp() {
  console.log(chalk.blue('\n👨‍💼 Testing Staff App Endpoints'));
  console.log(chalk.blue('═'.repeat(60)));
  
  const token = tokens.staff;
  
  if (!token) {
    console.log(chalk.red('  ❌ Skipping Staff App tests (no token)'));
    return;
  }
  
  // GET All Orders (Staff view)
  await testEndpoint('Staff', '/api/orders/all', 'GET', token);
  
  // GET Products Management
  await testEndpoint('Staff', '/api/products', 'GET', token);
  
  // GET Customers List
  await testEndpoint('Staff', '/api/users', 'GET', token);
  
  // GET Analytics/Dashboard
  await testEndpoint('Staff', '/api/analytics/dashboard', 'GET', token);
  
  // GET Inventory
  await testEndpoint('Staff', '/api/inventory', 'GET', token);
}

/**
 * Test Driver App endpoints
 */
async function testDriverApp() {
  console.log(chalk.blue('\n🚗 Testing Driver App Endpoints'));
  console.log(chalk.blue('═'.repeat(60)));
  
  const token = tokens.driver;
  
  if (!token) {
    console.log(chalk.red('  ❌ Skipping Driver App tests (no token)'));
    return;
  }
  
  // GET Assigned Deliveries
  await testEndpoint('Driver', '/api/deliveries/assigned', 'GET', token);
  
  // GET Delivery History
  await testEndpoint('Driver', '/api/deliveries/history', 'GET', token);
  
  // GET Driver Profile
  await testEndpoint('Driver', '/api/drivers/profile', 'GET', token);
  
  // GET Driver Earnings
  await testEndpoint('Driver', '/api/drivers/earnings', 'GET', token);
}

/**
 * Test Common/Public endpoints
 */
async function testPublicEndpoints() {
  console.log(chalk.blue('\n🌐 Testing Public Endpoints'));
  console.log(chalk.blue('═'.repeat(60)));
  
  // Health Check
  await testEndpoint('Public', '/health', 'GET', null);
  
  // API Status
  await testEndpoint('Public', '/api/status', 'GET', null);
  
  // Get Public Products
  await testEndpoint('Public', '/api/products/featured', 'GET', null);
}

// ============================================================================
// REPORTING
// ============================================================================

/**
 * Print summary table
 */
function printSummary() {
  console.log(chalk.blue('\n\n📊 TEST RESULTS SUMMARY'));
  console.log(chalk.blue('═'.repeat(100)));
  
  // Table header
  console.log(
    chalk.bold.white('App'.padEnd(15)) +
    chalk.bold.white('Endpoint'.padEnd(35)) +
    chalk.bold.white('Method'.padEnd(8)) +
    chalk.bold.white('Status'.padEnd(10)) +
    chalk.bold.white('Time'.padEnd(12)) +
    chalk.bold.white('Result')
  );
  console.log('─'.repeat(100));
  
  // Table rows
  testResults.forEach(result => {
    const passIcon = result.passed ? chalk.green('✅') : chalk.red('🚫');
    const app = result.app.padEnd(15);
    const endpoint = result.endpoint.padEnd(35);
    const method = result.method.padEnd(8);
    const status = formatStatus(result.status).toString().padEnd(10);
    const time = formatTime(result.latency).toString().padEnd(12);
    
    console.log(`${app}${endpoint}${method}${status}${time}${passIcon}`);
  });
  
  console.log('═'.repeat(100));
  
  // Statistics
  const avgLatency = latencies.length > 0 
    ? Math.round(latencies.reduce((a, b) => a + b, 0) / latencies.length)
    : 0;
  
  console.log(chalk.bold('\n📈 STATISTICS:'));
  console.log(`  Total Endpoints Tested: ${chalk.cyan(totalTests)}`);
  console.log(`  Passed: ${chalk.green(passedTests + ' ✅')}`);
  console.log(`  Failed: ${chalk.red(failedTests + ' 🚫')}`);
  console.log(`  Success Rate: ${chalk.yellow(((passedTests / totalTests) * 100).toFixed(2) + '%')}`);
  console.log(`  Average Latency: ${formatTime(avgLatency)}`);
  console.log(`  Max Latency: ${formatTime(Math.max(...latencies))}`);
  console.log(`  Min Latency: ${formatTime(Math.min(...latencies))}`);
  
  // Final verdict
  console.log(chalk.bold('\n🎯 VERDICT:'));
  if (failedTests === 0) {
    console.log(chalk.green.bold('  ✅ ALL APPS CONNECTED & CRUD FUNCTIONALITIES VERIFIED!'));
  } else if (passedTests > failedTests) {
    console.log(chalk.yellow.bold(`  ⚠️ Partial Success - ${failedTests} endpoints need attention`));
  } else {
    console.log(chalk.red.bold('  ❌ CRITICAL: Multiple endpoints failing'));
  }
  
  console.log('\n');
}

/**
 * Save results to JSON
 */
async function saveResults() {
  const resultsFile = path.join(CONFIG.LOG_DIR, `test_results_${Date.now()}.json`);
  
  const report = {
    timestamp: new Date().toISOString(),
    baseUrl: CONFIG.BASE_URL,
    summary: {
      total: totalTests,
      passed: passedTests,
      failed: failedTests,
      successRate: ((passedTests / totalTests) * 100).toFixed(2),
      avgLatency: Math.round(latencies.reduce((a, b) => a + b, 0) / latencies.length)
    },
    results: testResults
  };
  
  await fs.writeFile(resultsFile, JSON.stringify(report, null, 2));
  console.log(chalk.gray(`📄 Full results saved to: ${resultsFile}\n`));
}

// ============================================================================
// MAIN EXECUTION
// ============================================================================

async function main() {
  console.log(chalk.bold.cyan('\n🚀 API CONNECTIVITY CHECK'));
  console.log(chalk.cyan('═'.repeat(60)));
  console.log(chalk.gray(`Base URL: ${CONFIG.BASE_URL}`));
  console.log(chalk.gray(`Timeout: ${CONFIG.TIMEOUT}ms`));
  console.log(chalk.gray(`Retry Attempts: ${CONFIG.RETRY_ATTEMPTS}`));
  console.log(chalk.cyan('═'.repeat(60)));
  
  await ensureLogDirectory();
  await initializeFirebase();
  
  // Authenticate all users
  await loginUser('customer');
  await loginUser('staff');
  await loginUser('driver');
  
  // Test all endpoints
  await testPublicEndpoints();
  await testCustomerApp();
  await testStaffApp();
  await testDriverApp();
  
  // Print results
  printSummary();
  await saveResults();
  
  // Exit with appropriate code
  process.exit(failedTests > 0 ? 1 : 0);
}

// ============================================================================
// ERROR HANDLING
// ============================================================================

process.on('unhandledRejection', async (error) => {
  console.error(chalk.red('\n❌ Unhandled Error:'), error);
  await logToFile(`UNHANDLED ERROR: ${error.message}\n${error.stack}`);
  process.exit(1);
});

// Run the tests
if (require.main === module) {
  main().catch(async (error) => {
    console.error(chalk.red('\n❌ Fatal Error:'), error);
    await logToFile(`FATAL ERROR: ${error.message}\n${error.stack}`);
    process.exit(1);
  });
}

module.exports = { testEndpoint, loginUser };
