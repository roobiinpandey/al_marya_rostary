#!/usr/bin/env node

/**
 * Format Firebase Service Account Key for Environment Variables
 * 
 * This script takes a Firebase service account JSON file and converts it
 * into a properly escaped single-line string suitable for environment variables.
 * 
 * Usage:
 *   node format-firebase-key.js path/to/serviceAccountKey.json
 */

const fs = require('fs');
const path = require('path');

function formatFirebaseKey(filePath) {
  try {
    // Read the service account file
    const absolutePath = path.resolve(filePath);
    console.log(`📖 Reading file: ${absolutePath}`);
    
    if (!fs.existsSync(absolutePath)) {
      console.error('❌ File not found:', absolutePath);
      process.exit(1);
    }
    
    const fileContent = fs.readFileSync(absolutePath, 'utf8');
    
    // Parse to validate JSON
    const serviceAccount = JSON.parse(fileContent);
    
    // Verify required fields
    const requiredFields = ['type', 'project_id', 'private_key_id', 'private_key', 'client_email'];
    const missingFields = requiredFields.filter(field => !serviceAccount[field]);
    
    if (missingFields.length > 0) {
      console.error('❌ Missing required fields:', missingFields.join(', '));
      process.exit(1);
    }
    
    console.log('✅ Service account JSON is valid');
    console.log(`📋 Project ID: ${serviceAccount.project_id}`);
    console.log(`📧 Client Email: ${serviceAccount.client_email}`);
    
    // Convert to minified single-line JSON
    const minified = JSON.stringify(serviceAccount);
    
    // Escape for shell (escape double quotes and backslashes)
    const escaped = minified.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
    
    console.log('\n' + '='.repeat(80));
    console.log('📋 COPY THIS VALUE TO RENDER ENVIRONMENT VARIABLES');
    console.log('='.repeat(80));
    console.log('\nVariable Name: FIREBASE_SERVICE_ACCOUNT_KEY\n');
    console.log('Variable Value (copy everything below):');
    console.log('-'.repeat(80));
    console.log(minified); // Use minified, not escaped, for Render
    console.log('-'.repeat(80));
    
    console.log('\n✅ Format complete!');
    console.log('\n📝 Instructions:');
    console.log('1. Copy the entire JSON string above (between the dashed lines)');
    console.log('2. Go to your Render dashboard');
    console.log('3. Open your web service');
    console.log('4. Go to Environment tab');
    console.log('5. Find FIREBASE_SERVICE_ACCOUNT_KEY variable');
    console.log('6. Paste the copied value');
    console.log('7. Click "Save Changes"');
    console.log('8. Render will automatically redeploy');
    
    // Also save to a file for easy reference
    const outputPath = path.join(path.dirname(absolutePath), 'firebase-key-formatted.txt');
    fs.writeFileSync(outputPath, minified, 'utf8');
    console.log(`\n💾 Also saved to: ${outputPath}`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

// Check command line arguments
if (process.argv.length < 3) {
  console.log('Usage: node format-firebase-key.js <path-to-service-account.json>');
  console.log('\nExample:');
  console.log('  node format-firebase-key.js ./serviceAccountKey.json');
  process.exit(1);
}

const filePath = process.argv[2];
formatFirebaseKey(filePath);
