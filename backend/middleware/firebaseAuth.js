const admin = require('firebase-admin');
const User = require('../models/User');

/**
 * Firebase Auth Middleware
 * Verifies Firebase ID tokens and attaches user info to request
 */
const verifyFirebaseToken = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'No token provided. Please login first.'
      });
    }

    const idToken = authHeader.split('Bearer ')[1];

    if (!idToken) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token format'
      });
    }

    try {
      // Verify Firebase ID token
      console.log('🔐 Verifying Firebase ID token...');
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      
      const { uid, email } = decodedToken;
      console.log(`✅ Token verified for Firebase user: ${email} (UID: ${uid})`);

      // Find user in database by Firebase UID - IMPROVED LOOKUP STRATEGY
      let user = await User.findOne({
        $or: [
          { firebaseUid: uid },
          { providerId: uid },
          { email: email }
        ]
      });

      // If user not found by standard lookup, try by email with case-insensitive search
      if (!user && email) {
        console.log(`⚠️ User not found by standard lookup, trying case-insensitive email search for: ${email}`);
        user = await User.findOne({ 
          email: { $regex: new RegExp(`^${email}$`, 'i') }
        });
      }

      if (!user) {
        console.log(`❌ User not found in database for Firebase UID: ${uid}, Email: ${email}`);
        return res.status(404).json({
          success: false,
          message: 'User not found. Please complete registration.',
          details: { firebaseUid: uid, email: email }
        });
      }

      // UPDATE: Sync Firebase UID if not already set (prevents future mismatches)
      if (!user.firebaseUid || user.firebaseUid !== uid) {
        console.log(`📝 Syncing Firebase UID for user ${user.email}: ${user.firebaseUid} → ${uid}`);
        user.firebaseUid = uid;
        // Don't save yet, will be saved if request succeeds
      }

      // Check if user is active
      if (!user.isActive) {
        console.log(`⛔ User account inactive: ${user.email}`);
        return res.status(403).json({
          success: false,
          message: 'Your account has been deactivated. Please contact support.'
        });
      }

      // Attach user info to request
      req.user = {
        id: user._id.toString(),
        firebaseUid: uid,
        email: user.email,
        name: user.name,
        roles: user.roles || ['customer'],
        isActive: user.isActive,
        _userDoc: user // Store full user doc for middleware chaining
      };

      console.log(`✅ User authenticated: ${user.email} (DB ID: ${user._id})`);
      next();
    } catch (error) {
      console.error('❌ Firebase token verification failed:', error.message);
      
      // Handle specific Firebase errors
      if (error.code === 'auth/id-token-expired') {
        return res.status(401).json({
          success: false,
          message: 'Token expired. Please login again.'
        });
      }
      
      if (error.code === 'auth/id-token-revoked') {
        return res.status(401).json({
          success: false,
          message: 'Token revoked. Please login again.'
        });
      }

      if (error.code === 'auth/argument-error') {
        return res.status(401).json({
          success: false,
          message: 'Invalid token format'
        });
      }

      return res.status(401).json({
        success: false,
        message: 'Invalid or expired token'
      });
    }
  } catch (error) {
    console.error('❌ Firebase auth middleware error:', error);
    return res.status(500).json({
      success: false,
      message: 'Authentication error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Optional Firebase Auth
 * Attempts to verify token but doesn't fail if not present
 */
const optionalFirebaseAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next(); // No token, continue without auth
    }

    const idToken = authHeader.split('Bearer ')[1];

    if (!idToken) {
      return next();
    }

    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      const { uid, email } = decodedToken;

      const user = await User.findOne({
        $or: [
          { firebaseUid: uid },
          { providerId: uid },
          { email: email }
        ]
      });

      if (user && user.isActive) {
        req.user = {
          id: user._id.toString(),
          firebaseUid: uid,
          email: user.email,
          name: user.name,
          roles: user.roles || ['customer'],
          isActive: user.isActive
        };
      }
    } catch (error) {
      // Silent fail for optional auth
      console.log('Optional Firebase auth failed:', error.message);
    }

    next();
  } catch (error) {
    next(); // Continue even if error
  }
};

module.exports = {
  verifyFirebaseToken,
  optionalFirebaseAuth
};
