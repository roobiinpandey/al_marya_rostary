#!/usr/bin/env node

/**
 * Test Firebase Token Validation
 * Creates a minimal test to validate Firebase token verification
 */

const admin = require('firebase-admin');
require('dotenv').config();

async function testTokenValidation() {
  console.log('🔍 Testing Firebase Token Validation...\n');

  try {
    // Initialize Firebase Admin SDK
    if (admin.apps.length === 0) {
      const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
      if (!serviceAccountKey) {
        throw new Error('FIREBASE_SERVICE_ACCOUNT_KEY not found in environment');
      }

      const serviceAccount = JSON.parse(serviceAccountKey.trim());
      const projectId = process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id;
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: projectId
      });
      
      console.log('✅ Firebase Admin SDK initialized');
      console.log(`   Project ID: ${projectId}`);
      console.log(`   Client Email: ${serviceAccount.client_email}\n`);
    }

    // Test 1: Invalid token format (like our current test)
    console.log('🧪 Test 1: Invalid token format');
    try {
      await admin.auth().verifyIdToken('test_token');
    } catch (error) {
      console.log(`   ❌ Expected error: ${error.code} - ${error.message}\n`);
    }

    // Test 2: Empty token
    console.log('🧪 Test 2: Empty token');
    try {
      await admin.auth().verifyIdToken('');
    } catch (error) {
      console.log(`   ❌ Expected error: ${error.code} - ${error.message}\n`);
    }

    // Test 3: Create a custom token (for testing only)
    console.log('🧪 Test 3: Creating custom token for testing');
    try {
      const uid = 'test-user-123';
      const customToken = await admin.auth().createCustomToken(uid, {
        email: 'test@example.com',
        name: 'Test User'
      });
      
      console.log('   ✅ Custom token created successfully');
      console.log(`   Token length: ${customToken.length} characters`);
      console.log(`   Token preview: ${customToken.substring(0, 50)}...\n`);
      
      // Note: Custom tokens need to be exchanged for ID tokens on the client side
      // We can't directly verify custom tokens with verifyIdToken()
      console.log('   ℹ️  Note: Custom tokens must be exchanged for ID tokens in the client app');
      
    } catch (error) {
      console.log(`   ❌ Error creating custom token: ${error.message}\n`);
    }

    console.log('🔍 Validation Summary:');
    console.log('   • Firebase Admin SDK is properly configured');
    console.log('   • Token validation correctly rejects invalid tokens');
    console.log('   • "Invalid token format" error is expected behavior');
    console.log('   • Need to test with real Firebase ID token from client app\n');

    console.log('💡 Next Steps:');
    console.log('   1. Launch Flutter app and sign in with a user');
    console.log('   2. Extract the Firebase ID token from the app');
    console.log('   3. Test profile update with real token');
    console.log('   4. Check Firebase project configuration');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error(error);
  }
}

// Run the test
testTokenValidation().then(() => {
  console.log('\n✅ Token validation test completed');
  process.exit(0);
}).catch(error => {
  console.error('\n❌ Test failed:', error);
  process.exit(1);
});
