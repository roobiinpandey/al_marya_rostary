#!/usr/bin/env node

/**
 * Firebase Service Account Key Diagnostic Tool
 * 
 * This script helps diagnose issues with Firebase service account keys
 * by testing parsing and validating the structure without making API calls.
 */

const fs = require('fs');

console.log('🔍 Firebase Service Account Key Diagnostic Tool\n');
console.log('='.repeat(80));

// Check environment variable
const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;

if (!serviceAccountKey) {
  console.log('❌ FIREBASE_SERVICE_ACCOUNT_KEY environment variable is NOT set\n');
  console.log('Solutions:');
  console.log('1. Set it in your .env file (for local development)');
  console.log('2. Set it in Render environment variables (for production)');
  console.log('3. Use format-firebase-key.js to properly format your key');
  process.exit(1);
}

console.log('✅ FIREBASE_SERVICE_ACCOUNT_KEY is set\n');
console.log(`Length: ${serviceAccountKey.length} characters`);
console.log(`First 100 chars: ${serviceAccountKey.substring(0, 100)}...`);
console.log(`Last 100 chars: ...${serviceAccountKey.substring(serviceAccountKey.length - 100)}`);
console.log('\n' + '-'.repeat(80) + '\n');

// Check for common issues
const issues = [];

// Issue 1: Leading/trailing whitespace
if (serviceAccountKey !== serviceAccountKey.trim()) {
  issues.push('⚠️ Contains leading or trailing whitespace');
}

// Issue 2: Line breaks
if (serviceAccountKey.includes('\n') || serviceAccountKey.includes('\r')) {
  issues.push('⚠️ Contains line breaks (should be single line)');
}

// Issue 3: Starts with {
if (!serviceAccountKey.trim().startsWith('{')) {
  issues.push('❌ Does not start with { (invalid JSON)');
}

// Issue 4: Ends with }
if (!serviceAccountKey.trim().endsWith('}')) {
  issues.push('❌ Does not end with } (invalid JSON)');
}

// Issue 5: Try to parse as JSON
let serviceAccount = null;
let parseError = null;

try {
  serviceAccount = JSON.parse(serviceAccountKey.trim());
  console.log('✅ Successfully parsed as JSON\n');
} catch (error) {
  parseError = error;
  issues.push(`❌ JSON parsing failed: ${error.message}`);
}

if (issues.length > 0) {
  console.log('🚨 ISSUES FOUND:\n');
  issues.forEach(issue => console.log(`   ${issue}`));
  console.log('\n' + '-'.repeat(80) + '\n');
}

// Validate structure if parsed successfully
if (serviceAccount) {
  console.log('📋 Service Account Structure Validation:\n');
  
  const requiredFields = {
    'type': 'string',
    'project_id': 'string',
    'private_key_id': 'string',
    'private_key': 'string',
    'client_email': 'string',
    'client_id': 'string',
    'auth_uri': 'string',
    'token_uri': 'string',
    'auth_provider_x509_cert_url': 'string',
    'client_x509_cert_url': 'string'
  };
  
  let allFieldsValid = true;
  
  for (const [field, expectedType] of Object.entries(requiredFields)) {
    const hasField = field in serviceAccount;
    const correctType = hasField && typeof serviceAccount[field] === expectedType;
    
    if (hasField && correctType) {
      console.log(`   ✅ ${field}: ${expectedType}`);
      
      // Show value for non-sensitive fields
      if (field === 'type') {
        console.log(`      Value: "${serviceAccount[field]}"`);
      } else if (field === 'project_id') {
        console.log(`      Value: "${serviceAccount[field]}"`);
      } else if (field === 'client_email') {
        console.log(`      Value: "${serviceAccount[field]}"`);
      } else if (field === 'private_key') {
        const keyLength = serviceAccount[field].length;
        const hasNewlines = serviceAccount[field].includes('\n');
        console.log(`      Length: ${keyLength} chars, Has newlines: ${hasNewlines}`);
      }
    } else if (hasField && !correctType) {
      console.log(`   ⚠️ ${field}: wrong type (expected ${expectedType}, got ${typeof serviceAccount[field]})`);
      allFieldsValid = false;
    } else {
      console.log(`   ❌ ${field}: MISSING`);
      allFieldsValid = false;
    }
  }
  
  console.log('\n' + '-'.repeat(80) + '\n');
  
  if (allFieldsValid) {
    console.log('✅ ALL VALIDATIONS PASSED!');
    console.log('\nYour Firebase service account key is properly formatted.');
    console.log('If you\'re still seeing errors, the issue might be:');
    console.log('1. The key was rotated/deleted in Firebase Console');
    console.log('2. Network/firewall issues preventing Firebase API access');
    console.log('3. Firebase project permissions or billing issues');
  } else {
    console.log('❌ VALIDATION FAILED');
    console.log('\nYour service account key is missing required fields.');
    console.log('Generate a new key from Firebase Console:');
    console.log('1. Go to Firebase Console > Project Settings > Service Accounts');
    console.log('2. Click "Generate New Private Key"');
    console.log('3. Use format-firebase-key.js to format it properly');
  }
  
  // Test Firebase Admin SDK initialization
  console.log('\n' + '='.repeat(80));
  console.log('🧪 Testing Firebase Admin SDK Initialization...\n');
  
  try {
    const admin = require('firebase-admin');
    
    // Only initialize if not already initialized
    if (admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: serviceAccount.project_id
      });
      console.log('✅ Firebase Admin SDK initialized successfully!');
      console.log('   This means your service account key is working correctly.');
      
      // Clean up - don't leave the app initialized
      admin.app().delete();
    } else {
      console.log('ℹ️ Firebase Admin SDK already initialized');
    }
  } catch (initError) {
    console.log('❌ Firebase Admin SDK initialization failed:');
    console.log(`   ${initError.message}`);
    console.log('\nThis could mean:');
    console.log('1. The private key is corrupted or has wrong encoding');
    console.log('2. The service account doesn\'t have proper permissions');
    console.log('3. There\'s a network issue contacting Firebase');
  }
} else {
  console.log('\n❌ Cannot validate structure because JSON parsing failed\n');
  console.log('Parse error:', parseError?.message);
  console.log('\nTo fix this:');
  console.log('1. Get your service account JSON from Firebase Console');
  console.log('2. Run: node backend/scripts/format-firebase-key.js <path-to-json>');
  console.log('3. Copy the formatted output to your environment variable');
}

console.log('\n' + '='.repeat(80));
console.log('🏁 Diagnostic complete\n');
