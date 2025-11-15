#!/usr/bin/env node

/**
 * Render Firebase Connection Test
 * 
 * Run this on Render to test if Firebase credentials are working
 * Usage: node test-firebase-connection.js
 */

const admin = require('firebase-admin');

console.log('🔍 Testing Firebase Connection on Render\n');
console.log('='.repeat(80));
console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
console.log(`Timestamp: ${new Date().toISOString()}`);
console.log('='.repeat(80) + '\n');

async function testFirebaseConnection() {
  try {
    // Check if environment variables are set
    console.log('📋 Checking Environment Variables:\n');
    
    const hasServiceAccount = !!process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
    const hasProjectId = !!process.env.FIREBASE_PROJECT_ID;
    const hasSecretFile = require('fs').existsSync('/etc/secrets/firebase-service-account.json');
    
    console.log(`   FIREBASE_SERVICE_ACCOUNT_KEY: ${hasServiceAccount ? '✅ Set' : '❌ Not set'}`);
    if (hasServiceAccount) {
      const keyLength = process.env.FIREBASE_SERVICE_ACCOUNT_KEY.length;
      console.log(`      Length: ${keyLength} characters`);
      console.log(`      First 20 chars: ${process.env.FIREBASE_SERVICE_ACCOUNT_KEY.substring(0, 20)}...`);
    }
    
    console.log(`   FIREBASE_PROJECT_ID: ${hasProjectId ? '✅ Set' : '❌ Not set'}`);
    if (hasProjectId) {
      console.log(`      Value: ${process.env.FIREBASE_PROJECT_ID}`);
    }
    
    console.log(`   Secret File (/etc/secrets/...): ${hasSecretFile ? '✅ Exists' : '❌ Not found'}`);
    
    if (!hasServiceAccount && !hasSecretFile) {
      console.log('\n❌ ERROR: No Firebase credentials found!');
      console.log('   Please set FIREBASE_SERVICE_ACCOUNT_KEY or create a secret file.');
      process.exit(1);
    }
    
    console.log('\n' + '-'.repeat(80) + '\n');
    
    // Try to parse the service account
    console.log('🔧 Parsing Service Account Credentials:\n');
    
    let serviceAccount = null;
    
    if (hasSecretFile) {
      try {
        const fs = require('fs');
        const content = fs.readFileSync('/etc/secrets/firebase-service-account.json', 'utf8');
        serviceAccount = JSON.parse(content);
        console.log('   ✅ Successfully parsed secret file');
      } catch (error) {
        console.log(`   ❌ Failed to parse secret file: ${error.message}`);
      }
    }
    
    if (!serviceAccount && hasServiceAccount) {
      try {
        const key = process.env.FIREBASE_SERVICE_ACCOUNT_KEY.trim();
        serviceAccount = JSON.parse(key);
        console.log('   ✅ Successfully parsed environment variable');
      } catch (error) {
        console.log(`   ❌ Failed to parse environment variable: ${error.message}`);
        console.log(`   This is the error you're seeing on Render!`);
        console.log('\n   💡 Solution: Use format-firebase-key.js to properly format your key');
        process.exit(1);
      }
    }
    
    if (!serviceAccount) {
      console.log('   ❌ Could not load service account from any source');
      process.exit(1);
    }
    
    // Validate structure
    console.log('\n📊 Validating Service Account Structure:\n');
    
    const requiredFields = ['type', 'project_id', 'private_key_id', 'private_key', 'client_email'];
    const missingFields = requiredFields.filter(field => !serviceAccount[field]);
    
    if (missingFields.length > 0) {
      console.log(`   ❌ Missing required fields: ${missingFields.join(', ')}`);
      process.exit(1);
    }
    
    console.log('   ✅ All required fields present');
    console.log(`   Project ID: ${serviceAccount.project_id}`);
    console.log(`   Client Email: ${serviceAccount.client_email}`);
    console.log(`   Private Key Length: ${serviceAccount.private_key.length} characters`);
    
    console.log('\n' + '-'.repeat(80) + '\n');
    
    // Try to initialize Firebase
    console.log('🚀 Initializing Firebase Admin SDK:\n');
    
    if (admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: serviceAccount.project_id
      });
      console.log('   ✅ Firebase Admin SDK initialized successfully!');
    } else {
      console.log('   ℹ️ Firebase already initialized');
    }
    
    console.log('\n' + '-'.repeat(80) + '\n');
    
    // Test Firebase Auth connection
    console.log('🔐 Testing Firebase Auth Connection:\n');
    
    const auth = admin.auth();
    
    // Try to list users (limit 1 to test connection)
    const listUsersResult = await auth.listUsers(1);
    console.log(`   ✅ Successfully connected to Firebase Auth`);
    console.log(`   Found ${listUsersResult.users.length} user(s) in first batch`);
    
    if (listUsersResult.users.length > 0) {
      const user = listUsersResult.users[0];
      console.log(`   Sample user: ${user.email || user.uid}`);
    }
    
    console.log('\n' + '-'.repeat(80) + '\n');
    
    // Test Firestore connection (if available)
    console.log('📚 Testing Firestore Connection:\n');
    
    try {
      const db = admin.firestore();
      const snapshot = await db.collection('users').limit(1).get();
      console.log(`   ✅ Successfully connected to Firestore`);
      console.log(`   Collection 'users' has at least ${snapshot.size} document(s)`);
    } catch (firestoreError) {
      console.log(`   ⚠️ Firestore test skipped: ${firestoreError.message}`);
    }
    
    console.log('\n' + '='.repeat(80));
    console.log('✅ ALL TESTS PASSED!');
    console.log('='.repeat(80));
    console.log('\nYour Firebase connection is working correctly on Render.');
    console.log('The service account credentials are valid and Firebase APIs are accessible.\n');
    
    // Clean up
    await admin.app().delete();
    
  } catch (error) {
    console.log('\n' + '='.repeat(80));
    console.log('❌ TEST FAILED');
    console.log('='.repeat(80));
    console.log('\nError Details:');
    console.log(`   Type: ${error.code || error.name}`);
    console.log(`   Message: ${error.message}`);
    
    if (error.message.includes('DECODER routines::unsupported')) {
      console.log('\n💡 This is the DECODER error you\'re seeing on Render!');
      console.log('\nCause: Your FIREBASE_SERVICE_ACCOUNT_KEY is corrupted or improperly formatted.');
      console.log('\nSolution:');
      console.log('1. Download a fresh service account key from Firebase Console');
      console.log('2. Run: node backend/scripts/format-firebase-key.js <path-to-key>');
      console.log('3. Copy the formatted output to Render environment variable');
      console.log('4. Or use Secret Files instead (see FIREBASE_RENDER_FIX.md)');
    } else if (error.code === 'auth/invalid-credential') {
      console.log('\n💡 The service account key is formatted correctly but not valid.');
      console.log('\nPossible causes:');
      console.log('- The key was deleted or rotated in Firebase Console');
      console.log('- The service account doesn\'t have proper permissions');
      console.log('- Wrong Firebase project');
      console.log('\nSolution: Generate a new service account key from Firebase Console');
    } else {
      console.log('\n💡 Unexpected error. Check the error message above.');
    }
    
    console.log('\n');
    process.exit(1);
  }
}

// Run the test
testFirebaseConnection().catch(error => {
  console.error('Unhandled error:', error);
  process.exit(1);
});
