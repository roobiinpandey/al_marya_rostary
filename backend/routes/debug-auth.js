/**
 * Debug Authentication Endpoint
 * Helps debug Firebase token generation and authentication flow
 */

const express = require('express');
const admin = require('firebase-admin');
const router = express.Router();

/**
 * Debug endpoint to test Firebase token validation
 */
router.post('/debug-token', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    
    console.log('🔍 Debug Token Test Started');
    console.log('   Authorization Header:', authHeader ? 'Present' : 'Missing');
    
    if (!authHeader) {
      return res.status(401).json({
        success: false,
        message: 'No authorization header provided',
        debug: {
          headers: Object.keys(req.headers),
          bodyKeys: Object.keys(req.body)
        }
      });
    }

    if (!authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Authorization header must start with "Bearer "',
        debug: {
          authHeader: authHeader.substring(0, 50) + '...',
          format: 'Expected: Bearer <token>'
        }
      });
    }

    const token = authHeader.split('Bearer ')[1];
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'No token found after Bearer',
        debug: {
          authHeaderLength: authHeader.length,
          splitResult: authHeader.split('Bearer ')
        }
      });
    }

    console.log('   Token received:', token.substring(0, 50) + '...');
    console.log('   Token length:', token.length);

    // Verify the Firebase token
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    console.log('   ✅ Token verification successful');
    console.log('   User UID:', decodedToken.uid);
    console.log('   User Email:', decodedToken.email);
    
    return res.status(200).json({
      success: true,
      message: 'Firebase token is valid',
      debug: {
        tokenLength: token.length,
        uid: decodedToken.uid,
        email: decodedToken.email,
        issuer: decodedToken.iss,
        audience: decodedToken.aud,
        authTime: new Date(decodedToken.auth_time * 1000).toISOString(),
        tokenCreated: new Date(decodedToken.iat * 1000).toISOString(),
        tokenExpires: new Date(decodedToken.exp * 1000).toISOString()
      }
    });

  } catch (error) {
    console.error('❌ Debug Token Test Failed:', error.message);
    
    let errorType = 'unknown';
    let suggestion = 'Check token format and ensure user is authenticated';
    
    if (error.code === 'auth/id-token-expired') {
      errorType = 'expired';
      suggestion = 'Refresh the Firebase ID token and try again';
    } else if (error.code === 'auth/argument-error') {
      errorType = 'format';
      suggestion = 'Ensure the token is a valid Firebase ID token (JWT format)';
    } else if (error.code === 'auth/id-token-revoked') {
      errorType = 'revoked';
      suggestion = 'User session was revoked, re-authenticate the user';
    }

    return res.status(401).json({
      success: false,
      message: 'Token verification failed',
      error: error.message,
      debug: {
        errorCode: error.code,
        errorType: errorType,
        suggestion: suggestion,
        tokenReceived: !!req.headers.authorization,
        timestamp: new Date().toISOString()
      }
    });
  }
});

/**
 * Test endpoint for profile update debugging
 */
router.put('/debug-profile', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    console.log('🔍 Debug Profile Update Test');
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required',
        debug: { step: 'auth_header_check' }
      });
    }

    const token = authHeader.split('Bearer ')[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    console.log('   ✅ Authentication successful for:', decodedToken.email);
    console.log('   Request body keys:', Object.keys(req.body));
    console.log('   Content type:', req.headers['content-type']);
    
    return res.status(200).json({
      success: true,
      message: 'Profile update would succeed',
      debug: {
        userEmail: decodedToken.email,
        userUid: decodedToken.uid,
        bodyKeys: Object.keys(req.body),
        contentType: req.headers['content-type'],
        hasName: !!req.body.name,
        hasPhone: !!req.body.phone,
        hasAvatar: !!req.files?.avatar,
        timestamp: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('❌ Debug Profile Test Failed:', error.message);
    
    return res.status(401).json({
      success: false,
      message: 'Authentication failed',
      error: error.message,
      debug: {
        errorCode: error.code,
        step: 'token_verification',
        timestamp: new Date().toISOString()
      }
    });
  }
});

module.exports = router;
