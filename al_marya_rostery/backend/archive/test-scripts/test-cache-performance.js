/**
 * ⚡ Cache Performance Test Script
 * 
 * Tests the effectiveness of authenticated request caching
 * Run: node test-cache-performance.js
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:5001/api';
const ADMIN_TOKEN = process.env.ADMIN_TOKEN || 'YOUR_ADMIN_TOKEN_HERE';

// Test endpoints
const endpoints = [
  { name: 'Dashboard Overview', url: '/analytics/admin/dashboard' },
  { name: 'Firebase Users List', url: '/firebase-sync/firebase-users' },
  { name: 'Staff List', url: '/admin/staff' },
  { name: 'Origin Countries', url: '/attributes/origin_countries/values?hierarchical=true&active=true' },
  { name: 'Loyalty Stats', url: '/loyalty/admin/stats' },
  { name: 'Subscription Stats', url: '/subscriptions/admin/stats' },
];

async function testEndpoint(endpoint, requestNumber) {
  const startTime = Date.now();
  
  try {
    const response = await axios.get(`${BASE_URL}${endpoint.url}`, {
      headers: {
        'Authorization': `Bearer ${ADMIN_TOKEN}`
      }
    });
    
    const responseTime = Date.now() - startTime;
    const cacheStatus = response.headers['x-cache'] || 'NO-HEADER';
    const cacheKey = response.headers['x-cache-key'] || 'N/A';
    
    return {
      name: endpoint.name,
      requestNumber,
      responseTime,
      cacheStatus,
      statusCode: response.status,
      success: true
    };
  } catch (error) {
    return {
      name: endpoint.name,
      requestNumber,
      responseTime: Date.now() - startTime,
      cacheStatus: 'ERROR',
      statusCode: error.response?.status || 500,
      error: error.message,
      success: false
    };
  }
}

async function runPerformanceTest() {
  console.log('🚀 Starting Cache Performance Test...\n');
  console.log('=' .repeat(80));
  
  if (ADMIN_TOKEN === 'YOUR_ADMIN_TOKEN_HERE') {
    console.log('⚠️  WARNING: Using placeholder token. Set ADMIN_TOKEN environment variable.');
    console.log('   Example: ADMIN_TOKEN=your_token node test-cache-performance.js\n');
  }
  
  const results = {};
  
  // Test each endpoint twice (first = MISS, second = HIT)
  for (const endpoint of endpoints) {
    console.log(`\n📊 Testing: ${endpoint.name}`);
    console.log('-'.repeat(80));
    
    results[endpoint.name] = [];
    
    // First request (cache MISS expected)
    console.log('   Request #1 (Cold Cache - Expected: MISS)...');
    const result1 = await testEndpoint(endpoint, 1);
    results[endpoint.name].push(result1);
    
    if (result1.success) {
      console.log(`   ✅ ${result1.responseTime}ms - Cache: ${result1.cacheStatus}`);
    } else {
      console.log(`   ❌ ${result1.responseTime}ms - Error: ${result1.error}`);
    }
    
    // Wait a moment
    await new Promise(resolve => setTimeout(resolve, 100));
    
    // Second request (cache HIT expected)
    console.log('   Request #2 (Warm Cache - Expected: HIT)...');
    const result2 = await testEndpoint(endpoint, 2);
    results[endpoint.name].push(result2);
    
    if (result2.success) {
      console.log(`   ✅ ${result2.responseTime}ms - Cache: ${result2.cacheStatus}`);
      
      // Calculate improvement
      if (result1.success && result1.responseTime > 0) {
        const improvement = ((result1.responseTime - result2.responseTime) / result1.responseTime * 100).toFixed(1);
        const speedup = (result1.responseTime / result2.responseTime).toFixed(1);
        console.log(`   ⚡ Improvement: ${improvement}% faster (${speedup}x speedup)`);
      }
    } else {
      console.log(`   ❌ ${result2.responseTime}ms - Error: ${result2.error}`);
    }
  }
  
  // Summary
  console.log('\n' + '='.repeat(80));
  console.log('📈 PERFORMANCE SUMMARY');
  console.log('='.repeat(80));
  
  let totalHits = 0;
  let totalRequests = 0;
  let totalFirstRequest = 0;
  let totalSecondRequest = 0;
  let successfulTests = 0;
  
  console.log('\n| Endpoint | 1st Request | 2nd Request | Cache Hit | Improvement |');
  console.log('|----------|-------------|-------------|-----------|-------------|');
  
  for (const [name, tests] of Object.entries(results)) {
    const first = tests[0];
    const second = tests[1];
    
    if (first.success && second.success) {
      const improvement = ((first.responseTime - second.responseTime) / first.responseTime * 100).toFixed(0);
      const cacheHit = second.cacheStatus === 'HIT' ? '✅' : '❌';
      
      console.log(`| ${name.padEnd(30)} | ${first.responseTime}ms | ${second.responseTime}ms | ${cacheHit} ${second.cacheStatus} | ${improvement}% |`);
      
      totalFirstRequest += first.responseTime;
      totalSecondRequest += second.responseTime;
      successfulTests++;
      
      if (second.cacheStatus === 'HIT') {
        totalHits++;
      }
      totalRequests += 2;
    } else {
      console.log(`| ${name.padEnd(30)} | ${first.success ? first.responseTime + 'ms' : 'ERROR'} | ${second.success ? second.responseTime + 'ms' : 'ERROR'} | ❌ FAIL | N/A |`);
    }
  }
  
  const cacheHitRate = totalRequests > 0 ? ((totalHits / totalRequests) * 100).toFixed(1) : 0;
  const avgImprovement = successfulTests > 0 ? 
    (((totalFirstRequest - totalSecondRequest) / totalFirstRequest) * 100).toFixed(1) : 0;
  
  console.log('\n' + '='.repeat(80));
  console.log('📊 OVERALL STATISTICS');
  console.log('='.repeat(80));
  console.log(`   Total Endpoints Tested: ${endpoints.length}`);
  console.log(`   Successful Tests: ${successfulTests}`);
  console.log(`   Total Requests: ${totalRequests}`);
  console.log(`   Cache Hits: ${totalHits}`);
  console.log(`   Cache Hit Rate: ${cacheHitRate}%`);
  console.log(`   Avg 1st Request Time: ${successfulTests > 0 ? Math.round(totalFirstRequest / successfulTests) : 0}ms`);
  console.log(`   Avg 2nd Request Time: ${successfulTests > 0 ? Math.round(totalSecondRequest / successfulTests) : 0}ms`);
  console.log(`   Avg Performance Improvement: ${avgImprovement}%`);
  
  // Performance grade
  console.log('\n' + '='.repeat(80));
  console.log('🎯 PERFORMANCE GRADE');
  console.log('='.repeat(80));
  
  const hitRateNum = parseFloat(cacheHitRate);
  const improvementNum = parseFloat(avgImprovement);
  
  let grade = 'F';
  let emoji = '❌';
  let comment = 'Critical issues - caching not working';
  
  if (hitRateNum >= 80 && improvementNum >= 80) {
    grade = 'A+';
    emoji = '🏆';
    comment = 'Excellent! Cache working perfectly';
  } else if (hitRateNum >= 60 && improvementNum >= 60) {
    grade = 'A';
    emoji = '✅';
    comment = 'Great! Cache providing significant benefits';
  } else if (hitRateNum >= 40 && improvementNum >= 40) {
    grade = 'B';
    emoji = '👍';
    comment = 'Good! Cache helping but could be better';
  } else if (hitRateNum >= 20 && improvementNum >= 20) {
    grade = 'C';
    emoji = '⚠️';
    comment = 'Fair - cache working but needs optimization';
  } else if (hitRateNum > 0) {
    grade = 'D';
    emoji = '⚠️';
    comment = 'Poor - cache barely working';
  }
  
  console.log(`   Grade: ${grade} ${emoji}`);
  console.log(`   Assessment: ${comment}`);
  
  // Recommendations
  console.log('\n' + '='.repeat(80));
  console.log('💡 RECOMMENDATIONS');
  console.log('='.repeat(80));
  
  if (hitRateNum < 50) {
    console.log('   ⚠️  Cache hit rate is low! Check:');
    console.log('       - Is cacheAuthenticated: true set in server.js?');
    console.log('       - Are routes using createCacheMiddleware()?');
    console.log('       - Check cache configuration in performance.js');
  }
  
  if (improvementNum < 50) {
    console.log('   ⚠️  Performance improvement is low! Consider:');
    console.log('       - Increasing cache TTL for static data');
    console.log('       - Using Redis for production');
    console.log('       - Optimizing database queries with .lean()');
  }
  
  if (hitRateNum >= 80 && improvementNum >= 80) {
    console.log('   🎉 Excellent performance! Cache is working as expected.');
    console.log('   💡 Next steps:');
    console.log('       - Add cache invalidation on data updates');
    console.log('       - Monitor cache hit rates in production');
    console.log('       - Consider Redis for multi-server scaling');
  }
  
  console.log('\n' + '='.repeat(80));
  console.log('✅ Test Complete!');
  console.log('='.repeat(80));
  console.log();
}

// Run the test
runPerformanceTest().catch(error => {
  console.error('❌ Test failed:', error.message);
  process.exit(1);
});
