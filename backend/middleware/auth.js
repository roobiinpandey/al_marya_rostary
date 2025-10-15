const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Security: Validate JWT_SECRET on module load
if (!process.env.JWT_SECRET) {
  console.error('FATAL: JWT_SECRET environment variable is not set. Authentication will fail.');
  process.exit(1);
}

// Security: Validate JWT_SECRET strength
if (process.env.JWT_SECRET.length < 32) {
  console.error('WARNING: JWT_SECRET is too short. Use at least 32 characters for security.');
}

// Protect routes - require authentication
const protect = async (req, res, next) => {
  try {
    let token;

    // Check for token in header
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized to access this route'
      });
    }

    try {
      // Security: Additional JWT_SECRET validation before verification
      if (!process.env.JWT_SECRET) {
        console.error('JWT_SECRET missing during token verification');
        return res.status(500).json({
          success: false,
          message: 'Server configuration error'
        });
      }

      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Security: Remove hardcoded admin bypass - all users must be validated through database
      // REMOVED HARDCODED ADMIN TOKEN for security

      // Get user from token
      const user = await User.findById(decoded.userId);

      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'User not found'
        });
      }

      // Check if user is active
      if (!user.isActive) {
        return res.status(401).json({
          success: false,
          message: 'User account is deactivated'
        });
      }

      req.user = {
        userId: user._id,
        email: user.email,
        roles: user.roles,
        isActive: user.isActive
      };

      next();
    } catch (error) {
      // Security: Log JWT verification errors for monitoring
      console.error('JWT verification failed:', {
        error: error.message,
        token: token?.substring(0, 20) + '...', // Log only first 20 chars for debugging
        timestamp: new Date().toISOString()
      });

      // Security: Return generic error message to prevent information leakage
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired token'
      });
    }
  } catch (error) {
    console.error('Auth middleware error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error in authentication'
    });
  }
};

// Check if user has required role
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized to access this route'
      });
    }

    if (!roles.some(role => req.user.roles.includes(role))) {
      return res.status(403).json({
        success: false,
        message: `User role ${req.user.roles.join(', ')} is not authorized to access this route`
      });
    }

    next();
  };
};

// Optional authentication - doesn't fail if no token
const optionalAuth = async (req, res, next) => {
  try {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (token) {
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // Security: Remove hardcoded admin bypass - all users must be validated through database
        // REMOVED HARDCODED ADMIN TOKEN for security

        const user = await User.findById(decoded.userId);

        if (user && user.isActive) {
          req.user = {
            userId: user._id,
            email: user.email,
            roles: user.roles,
            isActive: user.isActive
          };
        }
      } catch (error) {
        // Silent fail for optional auth
        console.log('Optional auth failed:', error.message);
      }
    }

    next();
  } catch (error) {
    next();
  }
};

module.exports = {
  protect,
  authorize,
  optionalAuth
};
