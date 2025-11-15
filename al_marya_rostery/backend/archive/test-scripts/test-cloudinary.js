#!/usr/bin/env node

/**
 * Cloudinary Connection Test Script
 * Tests if Cloudinary credentials are working properly
 */

require('dotenv').config();
const cloudinary = require('cloudinary').v2;

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

console.log('🔍 Testing Cloudinary Connection...\n');
console.log('📋 Configuration:');
console.log(`   Cloud Name: ${process.env.CLOUDINARY_CLOUD_NAME || '❌ MISSING'}`);
console.log(`   API Key: ${process.env.CLOUDINARY_API_KEY ? '✅ Set' : '❌ MISSING'}`);
console.log(`   API Secret: ${process.env.CLOUDINARY_API_SECRET ? '✅ Set' : '❌ MISSING'}`);
console.log('');

// Test 1: Ping API
console.log('📡 Test 1: Pinging Cloudinary API...');
cloudinary.api.ping()
  .then(result => {
    console.log('✅ SUCCESS: Cloudinary API is reachable');
    console.log(`   Response: ${result.status}\n`);
    
    // Test 2: List resources
    console.log('📦 Test 2: Fetching existing resources...');
    return cloudinary.api.resources({
      type: 'upload',
      prefix: 'al-marya/products',
      max_results: 5
    });
  })
  .then(result => {
    console.log(`✅ SUCCESS: Found ${result.resources.length} product images`);
    if (result.resources.length > 0) {
      console.log('   Sample images:');
      result.resources.forEach((img, i) => {
        console.log(`   ${i + 1}. ${img.public_id}`);
        console.log(`      URL: ${img.secure_url}`);
      });
    } else {
      console.log('   ⚠️  No product images found in al-marya/products folder');
      console.log('   This is normal if you haven\'t uploaded any images yet.');
    }
    console.log('');
    
    // Test 3: Get usage stats
    console.log('📊 Test 3: Checking account usage...');
    return cloudinary.api.usage();
  })
  .then(result => {
    console.log('✅ SUCCESS: Retrieved account usage');
    console.log(`   Plan: ${result.plan || 'Free'}`);
    console.log(`   Credits used: ${result.credits?.used_percent || 0}%`);
    console.log(`   Bandwidth used: ${(result.bandwidth.used_bytes / 1024 / 1024).toFixed(2)} MB`);
    console.log(`   Storage used: ${(result.storage.used_bytes / 1024 / 1024).toFixed(2)} MB`);
    console.log(`   Resources: ${result.resources || 0} files`);
    console.log('');
    
    console.log('🎉 ALL TESTS PASSED!');
    console.log('');
    console.log('✅ Cloudinary is configured correctly and ready to use!');
    console.log('✅ You can now upload product images via the admin panel.');
    console.log('✅ Images will be stored at: https://res.cloudinary.com/dzzonkdpm/');
    process.exit(0);
  })
  .catch(error => {
    console.error('❌ ERROR: Cloudinary test failed');
    console.error(`   Message: ${error.message}`);
    if (error.http_code) {
      console.error(`   HTTP Code: ${error.http_code}`);
    }
    console.error('');
    console.error('🔧 Troubleshooting:');
    console.error('   1. Verify credentials are correct');
    console.error('   2. Check internet connection');
    console.error('   3. Ensure Cloudinary account is active');
    console.error('   4. On Render.com, verify environment variables are set');
    process.exit(1);
  });
