#!/usr/bin/env node

/**
 * Standalone Firebase Token Tester
 * Tests Firebase token validation without database dependency
 */

const express = require('express');
const admin = require('firebase-admin');
require('dotenv').config();

const app = express();
app.use(express.json());

// Initialize Firebase Admin SDK
if (admin.apps.length === 0) {
  const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
  if (serviceAccountKey) {
    try {
      const serviceAccount = JSON.parse(serviceAccountKey.trim());
      const projectId = process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id;
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: projectId
      });
      
      console.log('✅ Firebase Admin SDK initialized');
      console.log(`   Project ID: ${projectId}`);
    } catch (error) {
      console.error('❌ Firebase initialization failed:', error.message);
      process.exit(1);
    }
  } else {
    console.error('❌ FIREBASE_SERVICE_ACCOUNT_KEY not found');
    process.exit(1);
  }
}

// Test endpoint for Firebase token validation
app.post('/test-firebase-token', async (req, res) => {
  try {
    console.log('\n🔍 Firebase Token Test Started');
    
    const authHeader = req.headers.authorization;
    console.log('   Authorization Header:', authHeader ? 'Present' : 'Missing');
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'No Bearer token provided',
        format: 'Expected: Authorization: Bearer <firebase-id-token>'
      });
    }

    const token = authHeader.split('Bearer ')[1];
    console.log('   Token Length:', token.length);
    console.log('   Token Preview:', token.substring(0, 50) + '...');
    
    // Verify Firebase ID token
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    console.log('   ✅ Token Valid!');
    console.log('   User UID:', decodedToken.uid);
    console.log('   User Email:', decodedToken.email);
    console.log('   Token Issued:', new Date(decodedToken.iat * 1000).toISOString());
    console.log('   Token Expires:', new Date(decodedToken.exp * 1000).toISOString());
    
    return res.status(200).json({
      success: true,
      message: 'Firebase token is valid!',
      tokenInfo: {
        uid: decodedToken.uid,
        email: decodedToken.email,
        tokenLength: token.length,
        issuer: decodedToken.iss,
        audience: decodedToken.aud,
        authTime: new Date(decodedToken.auth_time * 1000).toISOString(),
        issuedAt: new Date(decodedToken.iat * 1000).toISOString(),
        expiresAt: new Date(decodedToken.exp * 1000).toISOString()
      }
    });

  } catch (error) {
    console.error('   ❌ Token Validation Failed:', error.message);
    
    let errorType = 'unknown';
    let solution = 'Check token format and user authentication';
    
    if (error.code === 'auth/id-token-expired') {
      errorType = 'expired';
      solution = 'Get a fresh Firebase ID token from the Flutter app';
    } else if (error.code === 'auth/argument-error') {
      errorType = 'invalid-format';
      solution = 'Ensure you are passing a valid Firebase ID token (JWT format)';
    } else if (error.code === 'auth/id-token-revoked') {
      errorType = 'revoked';
      solution = 'User session was revoked, re-authenticate in the Flutter app';
    }

    return res.status(401).json({
      success: false,
      message: 'Token validation failed',
      error: {
        code: error.code,
        message: error.message,
        type: errorType,
        solution: solution
      }
    });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'Firebase Token Tester',
    firebase: admin.apps.length > 0 ? 'initialized' : 'not-initialized'
  });
});

// Start server
const port = 3001;
app.listen(port, () => {
  console.log(`\n🔥 Firebase Token Tester running on port ${port}`);
  console.log('📋 Test your Firebase token:');
  console.log('   POST http://localhost:3001/test-firebase-token');
  console.log('   Header: Authorization: Bearer <your-firebase-id-token>');
  console.log('\n💡 How to get a Firebase token from Flutter:');
  console.log('   1. Open Flutter app');
  console.log('   2. Sign in with a user');
  console.log('   3. Add debug code: print(await FirebaseAuth.instance.currentUser?.getIdToken());');
  console.log('   4. Copy the printed token');
  console.log('   5. Test with this endpoint\n');
});
