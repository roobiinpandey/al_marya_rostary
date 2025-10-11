const jwt = require('jsonwebtoken');
const User = require('../models/User');

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
      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Handle special admin token
      if (decoded.userId === 'admin' && decoded.role === 'admin') {
        req.user = {
          userId: 'admin',
          email: 'admin@qahwatalemarat.com',
          roles: ['admin'],
          isActive: true
        };
        next();
        return;
      }

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
      return res.status(401).json({
        success: false,
        message: 'Not authorized to access this route'
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
        
        // Handle special admin token
        if (decoded.userId === 'admin' && decoded.role === 'admin') {
          req.user = {
            userId: 'admin',
            email: 'admin@qahwatalemarat.com',
            roles: ['admin'],
            isActive: true
          };
          return next();
        }

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
