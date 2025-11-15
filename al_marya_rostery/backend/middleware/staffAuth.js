const jwt = require('jsonwebtoken');
const Staff = require('../models/Staff');
const { isBlacklisted } = require('../utils/tokenBlacklist');

/**
 * Protect staff-admin routes
 * Verifies JWT token with type: 'staff-admin' and checks hasAdminAccess
 */
const protectStaffAdmin = async (req, res, next) => {
  try {
    let token;

    // Check for token in header
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized. Please login with your staff admin credentials.'
      });
    }

    try {
      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Check token type - must be 'staff-admin'
      if (decoded.type !== 'staff-admin') {
        return res.status(403).json({
          success: false,
          message: 'Access denied. Staff admin credentials required.'
        });
      }

      // Check if token has been blacklisted (revoked)
      if (isBlacklisted(token)) {
        return res.status(401).json({
          success: false,
          message: 'Token has been revoked. Please login again.'
        });
      }

      // Get staff member from token
      const staff = await Staff.findById(decoded.staffId).select('+adminPassword');

      if (!staff) {
        return res.status(401).json({
          success: false,
          message: 'Staff member not found'
        });
      }

      // Check if staff is active
      if (staff.status !== 'active') {
        return res.status(401).json({
          success: false,
          message: 'Staff account is not active'
        });
      }

      // Check if staff has admin access
      if (!staff.hasAdminAccess) {
        return res.status(403).json({
          success: false,
          message: 'Admin panel access has been revoked. Please contact your administrator.'
        });
      }

      // Attach staff info to request
      req.staff = {
        staffId: staff._id,
        name: staff.name,
        role: staff.role,
        hasAdminAccess: staff.hasAdminAccess,
        adminUsername: staff.adminUsername
      };

      next();
    } catch (error) {
      console.error('JWT verification failed:', {
        error: error.message,
        timestamp: new Date().toISOString()
      });

      return res.status(401).json({
        success: false,
        message: 'Invalid or expired token'
      });
    }
  } catch (error) {
    console.error('Staff auth middleware error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error in authentication'
    });
  }
};

module.exports = {
  protectStaffAdmin
};
