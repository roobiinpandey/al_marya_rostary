#!/usr/bin/env node

/**
 * List all images in Cloudinary account
 */

require('dotenv').config();
const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

console.log('📦 Listing all Cloudinary resources...\n');

cloudinary.api.resources({
  type: 'upload',
  max_results: 100
})
.then(result => {
  console.log(`Total resources: ${result.resources.length}\n`);
  
  // Group by folder
  const folders = {};
  result.resources.forEach(img => {
    const folder = img.public_id.split('/').slice(0, -1).join('/') || 'root';
    if (!folders[folder]) folders[folder] = [];
    folders[folder].push(img);
  });
  
  // Display grouped
  Object.keys(folders).sort().forEach(folder => {
    console.log(`📁 ${folder}/ (${folders[folder].length} files)`);
    folders[folder].forEach(img => {
      console.log(`   - ${img.public_id}`);
      console.log(`     ${img.secure_url}`);
    });
    console.log('');
  });
})
.catch(error => {
  console.error('Error:', error.message);
});
