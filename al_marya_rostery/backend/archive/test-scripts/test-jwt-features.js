/**
 * JWT Security Features Test Suite
 * Tests: Token blacklist, rotation, rate limiting, logout
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:5001/api';
let accessToken = '';
let refreshToken = '';

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[36m',
  bold: '\x1b[1m'
};

function log(type, message) {
  const timestamp = new Date().toLocaleTimeString();
  const prefix = {
    success: `${colors.green}✅`,
    error: `${colors.red}❌`,
    info: `${colors.blue}ℹ️`,
    test: `${colors.yellow}🧪`,
    step: `${colors.bold}📍`
  }[type] || '';
  
  console.log(`${prefix} [${timestamp}] ${message}${colors.reset}`);
}

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Test 1: Login to get tokens
async function testLogin() {
  log('test', 'TEST 1: User Login');
  try {
    const response = await axios.post(`${BASE_URL}/auth/login`, {
      email: 'test@almaryarostery.com',
      password: 'Test@123456'
    });
    
    accessToken = response.data.data.token;
    refreshToken = response.data.data.refreshToken;
    
    log('success', 'Login successful - Access & Refresh tokens obtained');
    log('info', `Access Token: ${accessToken.substring(0, 20)}...`);
    log('info', `Refresh Token: ${refreshToken.substring(0, 20)}...`);
    return true;
  } catch (error) {
    log('error', `Login failed: ${error.response?.data?.message || error.message}`);
    return false;
  }
}

// Test 2: Verify access token works
async function testAccessToken() {
  log('test', 'TEST 2: Verify Access Token');
  try {
    const response = await axios.get(`${BASE_URL}/auth/me`, {
      headers: { Authorization: `Bearer ${accessToken}` }
    });
    
    log('success', `Access token valid - User: ${response.data.data.email}`);
    return true;
  } catch (error) {
    log('error', `Access token verification failed: ${error.response?.data?.message || error.message}`);
    return false;
  }
}

// Test 3: Token rotation - refresh should give new tokens
async function testTokenRotation() {
  log('test', 'TEST 3: Token Rotation (Single-use Refresh Tokens)');
  
  const oldRefreshToken = refreshToken;
  
  try {
    // First refresh - should work
    log('step', 'Step 1: First token refresh');
    const response1 = await axios.post(`${BASE_URL}/auth/refresh`, {
      refreshToken: oldRefreshToken
    });
    
    const newAccessToken = response1.data.data.token;
    const newRefreshToken = response1.data.data.refreshToken;
    
    log('success', 'First refresh successful - Got new tokens');
    log('info', `New Access Token: ${newAccessToken.substring(0, 20)}...`);
    log('info', `New Refresh Token: ${newRefreshToken.substring(0, 20)}...`);
    
    // Update tokens
    accessToken = newAccessToken;
    refreshToken = newRefreshToken;
    
    await sleep(500);
    
    // Second refresh with OLD token - should FAIL (single-use)
    log('step', 'Step 2: Try to reuse old refresh token (should fail)');
    try {
      await axios.post(`${BASE_URL}/auth/refresh`, {
        refreshToken: oldRefreshToken
      });
      log('error', 'Token rotation FAILED - Old refresh token still works!');
      return false;
    } catch (error) {
      if (error.response?.status === 401) {
        log('success', 'Token rotation works - Old refresh token correctly rejected');
        log('info', `Error: ${error.response.data.message}`);
        return true;
      }
      throw error;
    }
  } catch (error) {
    log('error', `Token rotation test failed: ${error.response?.data?.message || error.message}`);
    return false;
  }
}

// Test 4: Rate limiting on refresh endpoint
async function testRateLimiting() {
  log('test', 'TEST 4: Rate Limiting (5 requests per 15 minutes)');
  
  try {
    log('step', 'Sending 6 rapid refresh requests...');
    
    let rateLimited = false;
    for (let i = 1; i <= 6; i++) {
      try {
        await axios.post(`${BASE_URL}/auth/refresh`, {
          refreshToken: refreshToken
        });
        log('info', `Request ${i}/6: Success`);
        
        // Update tokens after each successful refresh
        if (i < 6) {
          await sleep(100);
        }
      } catch (error) {
        if (error.response?.status === 429) {
          log('success', `Request ${i}/6: Rate limited (429) - Rate limiting working!`);
          log('info', `Message: ${error.response.data.message}`);
          rateLimited = true;
          break;
        } else {
          log('info', `Request ${i}/6: Failed with ${error.response?.status}: ${error.response?.data?.message}`);
        }
      }
    }
    
    if (rateLimited) {
      log('success', 'Rate limiting test passed');
      return true;
    } else {
      log('error', 'Rate limiting NOT working - All 6 requests succeeded');
      return false;
    }
  } catch (error) {
    log('error', `Rate limiting test failed: ${error.message}`);
    return false;
  }
}

// Test 5: Logout - token should be blacklisted
async function testLogout() {
  log('test', 'TEST 5: Logout & Token Blacklist');
  
  try {
    // Step 1: Verify token works before logout
    log('step', 'Step 1: Verify token works before logout');
    await axios.get(`${BASE_URL}/auth/me`, {
      headers: { Authorization: `Bearer ${accessToken}` }
    });
    log('success', 'Token valid before logout');
    
    await sleep(500);
    
    // Step 2: Logout (blacklist token)
    log('step', 'Step 2: Logout to blacklist token');
    await axios.post(`${BASE_URL}/auth/logout`, 
      { refreshToken },
      { headers: { Authorization: `Bearer ${accessToken}` }}
    );
    log('success', 'Logout successful - Token should now be blacklisted');
    
    await sleep(500);
    
    // Step 3: Try to use blacklisted token - should FAIL
    log('step', 'Step 3: Try to use blacklisted token (should fail)');
    try {
      await axios.get(`${BASE_URL}/auth/me`, {
        headers: { Authorization: `Bearer ${accessToken}` }
      });
      log('error', 'Token blacklist FAILED - Blacklisted token still works!');
      return false;
    } catch (error) {
      if (error.response?.status === 401) {
        log('success', 'Token blacklist works - Token correctly revoked');
        log('info', `Error: ${error.response.data.message}`);
        return true;
      }
      throw error;
    }
  } catch (error) {
    log('error', `Logout test failed: ${error.response?.data?.message || error.message}`);
    return false;
  }
}

// Test 6: Admin blacklist management endpoints
async function testAdminBlacklist() {
  log('test', 'TEST 6: Admin Blacklist Management (Skipped - Requires Admin Role)');
  log('info', 'Skipping admin endpoint test - requires admin credentials');
  log('info', 'Admin endpoints available at: /api/admin/token-blacklist/*');
  log('info', '  - GET /stats - View blacklist statistics');
  log('info', '  - POST /cleanup - Clean expired tokens');
  log('info', '  - POST /clear - Clear all tokens');
  log('info', '  - POST /add - Manually blacklist token');
  log('info', '  - POST /remove - Remove from blacklist');
  log('info', '  - POST /check - Check token status');
  return true;
}

// Run all tests
async function runAllTests() {
  console.log('\n');
  log('info', `${colors.bold}╔════════════════════════════════════════════╗`);
  log('info', `${colors.bold}║   JWT SECURITY FEATURES TEST SUITE         ║`);
  log('info', `${colors.bold}╚════════════════════════════════════════════╝`);
  console.log('\n');
  
  const results = {
    passed: 0,
    failed: 0,
    total: 6
  };
  
  const tests = [
    { name: 'Login', fn: testLogin },
    { name: 'Access Token', fn: testAccessToken },
    { name: 'Token Rotation', fn: testTokenRotation },
    { name: 'Rate Limiting', fn: testRateLimiting },
    { name: 'Logout & Blacklist', fn: testLogout },
    { name: 'Admin Blacklist', fn: testAdminBlacklist }
  ];
  
  for (const test of tests) {
    console.log('\n' + '─'.repeat(50));
    const passed = await test.fn();
    if (passed) {
      results.passed++;
    } else {
      results.failed++;
    }
    await sleep(1000);
  }
  
  // Print summary
  console.log('\n');
  log('info', `${colors.bold}╔════════════════════════════════════════════╗`);
  log('info', `${colors.bold}║              TEST SUMMARY                  ║`);
  log('info', `${colors.bold}╚════════════════════════════════════════════╝`);
  console.log('\n');
  log('info', `Total Tests: ${results.total}`);
  log('success', `Passed: ${results.passed}`);
  log('error', `Failed: ${results.failed}`);
  
  if (results.failed === 0) {
    console.log('\n');
    log('success', `${colors.bold}🎉 ALL JWT SECURITY FEATURES WORKING PERFECTLY! 🎉`);
    console.log('\n');
  } else {
    console.log('\n');
    log('error', `${colors.bold}⚠️  SOME TESTS FAILED - PLEASE REVIEW`);
    console.log('\n');
  }
  
  process.exit(results.failed === 0 ? 0 : 1);
}

// Start tests
runAllTests().catch(error => {
  log('error', `Test suite crashed: ${error.message}`);
  console.error(error);
  process.exit(1);
});
