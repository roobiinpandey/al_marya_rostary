#!/usr/bin/env node

/**
 * Quick API Test - No Authentication Required
 * Tests public endpoints and basic connectivity
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:5001';
const colors = {
  green: (text) => `\x1b[32m${text}\x1b[0m`,
  red: (text) => `\x1b[31m${text}\x1b[0m`,
  cyan: (text) => `\x1b[36m${text}\x1b[0m`,
  yellow: (text) => `\x1b[33m${text}\x1b[0m`
};

async function testEndpoint(name, method, url, data = null) {
  try {
    const startTime = Date.now();
    const response = await axios({
      method,
      url: `${BASE_URL}${url}`,
      data,
      timeout: 5000
    });
    const endTime = Date.now();
    console.log(colors.green(`  ✅ ${name} → ${response.status} (${endTime - startTime}ms)`));
    return true;
  } catch (error) {
    const status = error.response?.status || 'ERR';
    console.log(colors.red(`  ❌ ${name} → ${status}`));
    if (error.response?.data) {
      console.log(colors.yellow(`     ${JSON.stringify(error.response.data).substring(0, 100)}`));
    }
    return false;
  }
}

async function main() {
  console.log(colors.cyan('\n🚀 QUICK API CONNECTIVITY TEST\n'));
  console.log('═'.repeat(60));
  
  let passed = 0;
  let total = 0;
  
  // Public endpoints
  console.log(colors.cyan('\n🌐 Public Endpoints:'));
  total++; if (await testEndpoint('Health Check', 'GET', '/health')) passed++;
  total++; if (await testEndpoint('API Status', 'GET', '/api/v1/status')) passed++;
  total++; if (await testEndpoint('Products', 'GET', '/api/products')) passed++;
  total++; if (await testEndpoint('Categories', 'GET', '/api/categories')) passed++;
  total++; if (await testEndpoint('Featured Products', 'GET', '/api/products/featured')) passed++;
  
  // Summary
  console.log('\n' + '═'.repeat(60));
  console.log(colors.cyan(`\n📊 Results: ${passed}/${total} passed`));
  
  if (passed === total) {
    console.log(colors.green('✅ All public endpoints working!\n'));
    process.exit(0);
  } else {
    console.log(colors.yellow(`⚠️ ${total - passed} endpoints failed\n`));
    process.exit(1);
  }
}

main().catch(err => {
  console.error(colors.red('\n❌ Fatal error:'), err.message);
  process.exit(1);
});
