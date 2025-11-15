const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const Staff = require('../models/Staff');
const { protect } = require('../middleware/auth');

/**
 * Staff Admin Panel Authentication Routes
 * Username/Password based authentication for web-based staff admin panel
 * Separate from PIN-based Staff App authentication
 */

// ===== Login to Staff Admin Panel =====

/**
 * @route   POST /api/staff/admin/login
 * @desc    Login staff member to admin panel with username/password
 * @access  Public
 */
router.post(
  '/login',
  [
    body('username')
      .notEmpty().withMessage('Username is required')
      .trim()
      .isLength({ min: 4 }).withMessage('Username must be at least 4 characters'),
    body('password')
      .notEmpty().withMessage('Password is required')
      .isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
  ],
  async (req, res) => {
    try {
      // Validate request
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { username, password } = req.body;
      const deviceInfo = req.headers['user-agent'] || 'Unknown';
      const ipAddress = req.ip || req.connection.remoteAddress;

      console.log('🔐 Staff Admin Panel login attempt:', username);

      // Find staff by admin username
      const staff = await Staff.findByAdminUsername(username);

      if (!staff) {
        console.log('❌ Staff not found or no admin access');
        return res.status(401).json({
          success: false,
          message: 'Invalid username or password'
        });
      }

      console.log('✅ Staff found:', staff.name, staff.employeeId);

      // Validate admin password
      const isValidPassword = await staff.validateAdminPassword(password);

      if (!isValidPassword) {
        await staff.addLoginHistory('admin-web', deviceInfo, ipAddress, false, 'Invalid password');
        return res.status(401).json({
          success: false,
          message: 'Invalid username or password'
        });
      }

      // Add successful login to history
      await staff.addLoginHistory('admin-web', deviceInfo, ipAddress, true);

      // Generate JWT token with admin role
      const token = jwt.sign(
        {
          staffId: staff._id,
          employeeId: staff.employeeId,
          role: staff.role,
          type: 'staff-admin',
          hasAdminAccess: true
        },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRE || '12h' }
      );

      // Prepare response (exclude sensitive fields)
      const staffResponse = staff.toObject();
      delete staffResponse.pin;
      delete staffResponse.adminPassword;
      delete staffResponse.qrBadgeToken;
      delete staffResponse.firebaseUid;

      res.json({
        success: true,
        message: 'Admin panel login successful',
        token,
        staff: staffResponse,
        sessionExpiry: new Date(Date.now() + 12 * 60 * 60 * 1000) // 12 hours
      });

    } catch (error) {
      console.error('Admin panel login error:', error);
      res.status(500).json({
        success: false,
        message: 'Login failed',
        error: error.message
      });
    }
  }
);

// ===== Check Session =====

/**
 * @route   GET /api/staff/admin/session
 * @desc    Validate current admin session
 * @access  Protected
 */
router.get('/session', protect, async (req, res) => {
  try {
    // Verify this is a staff admin token
    if (req.user.type !== 'staff-admin') {
      return res.status(403).json({
        success: false,
        message: 'Invalid token type'
      });
    }

    const staff = await Staff.findById(req.user.staffId);

    if (!staff || !staff.hasAdminAccess) {
      return res.status(404).json({
        success: false,
        message: 'Staff not found or no admin access'
      });
    }

    // Prepare response
    const staffResponse = staff.toObject();
    delete staffResponse.pin;
    delete staffResponse.adminPassword;
    delete staffResponse.qrBadgeToken;
    delete staffResponse.firebaseUid;

    res.json({
      success: true,
      staff: staffResponse,
      expiresAt: req.user.exp ? new Date(req.user.exp * 1000) : null
    });

  } catch (error) {
    console.error('Session check error:', error);
    res.status(500).json({
      success: false,
      message: 'Session validation failed',
      error: error.message
    });
  }
});

// ===== Logout =====

/**
 * @route   POST /api/staff/admin/logout
 * @desc    End admin panel session
 * @access  Protected
 */
router.post('/logout', protect, async (req, res) => {
  try {
    // Verify this is a staff admin token
    if (req.user.type !== 'staff-admin') {
      return res.status(403).json({
        success: false,
        message: 'Invalid token type'
      });
    }

    // Note: JWT tokens cannot be invalidated server-side
    // Client should delete the token
    res.json({
      success: true,
      message: 'Logged out successfully'
    });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      message: 'Logout failed',
      error: error.message
    });
  }
});

// ===== Change Password =====

/**
 * @route   POST /api/staff/admin/change-password
 * @desc    Change admin panel password
 * @access  Protected
 */
router.post(
  '/change-password',
  protect,
  [
    body('currentPassword').notEmpty().withMessage('Current password is required'),
    body('newPassword')
      .notEmpty().withMessage('New password is required')
      .isLength({ min: 6 }).withMessage('New password must be at least 6 characters')
  ],
  async (req, res) => {
    try {
      // Validate request
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      // Verify this is a staff admin token
      if (req.user.type !== 'staff-admin') {
        return res.status(403).json({
          success: false,
          message: 'Invalid token type'
        });
      }

      const { currentPassword, newPassword } = req.body;

      // Find staff with password field
      const staff = await Staff.findById(req.user.staffId).select('+adminPassword');

      if (!staff || !staff.hasAdminAccess) {
        return res.status(404).json({
          success: false,
          message: 'Staff not found or no admin access'
        });
      }

      // Validate current password
      const isValid = await staff.validateAdminPassword(currentPassword);

      if (!isValid) {
        return res.status(401).json({
          success: false,
          message: 'Current password is incorrect'
        });
      }

      // Set new password (will be hashed by pre-save middleware)
      staff.adminPassword = newPassword;
      await staff.save();

      res.json({
        success: true,
        message: 'Password changed successfully'
      });

    } catch (error) {
      console.error('Change password error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to change password',
        error: error.message
      });
    }
  }
);

module.exports = router;
