const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const Staff = require('../models/Staff');
const qrBadgeService = require('../services/qrBadgeService');
const { protect } = require('../middleware/auth');

/**
 * Staff Authentication Routes (PIN + QR Badge)
 * No Firebase required - Direct database authentication
 */

// ===== Login with Employee ID + PIN =====

/**
 * @route   POST /api/staff/auth/login-pin
 * @desc    Login staff with 4-digit PIN only (no Employee ID required)
 * @access  Public
 */
router.post(
  '/login-pin',
  [
    body('pin')
      .notEmpty().withMessage('PIN is required')
      .isLength({ min: 4, max: 4 }).withMessage('PIN must be exactly 4 digits')
      .isNumeric().withMessage('PIN must contain only numbers')
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

      const { pin } = req.body;
      const deviceInfo = req.headers['user-agent'] || 'Unknown';
      const ipAddress = req.ip || req.connection.remoteAddress;

      console.log('🔐 PIN-only login attempt');

      // Find staff by PIN (searches all staff and compares hashed PINs)
      const staff = await Staff.findByPin(pin);

      if (!staff) {
        return res.status(401).json({
          success: false,
          message: 'Invalid PIN. Please try again.'
        });
      }

      console.log('✅ Staff found:', staff.employeeId, staff.name);

      // Check if staff is active
      if (staff.status === 'inactive') {
        await staff.addLoginHistory('pin', deviceInfo, ipAddress, false, 'Account inactive');
        return res.status(401).json({
          success: false,
          message: 'Account is inactive. Please contact admin.'
        });
      }

      // Check if PIN is locked
      if (staff.isPinLocked) {
        const unlockTime = new Date(staff.pinLockedUntil);
        const minutesLeft = Math.ceil((unlockTime - new Date()) / 60000);
        return res.status(423).json({
          success: false,
          message: `PIN is locked. Try again in ${minutesLeft} minutes.`,
          lockedUntil: staff.pinLockedUntil
        });
      }

      // Validate PIN
      const isValidPin = await staff.validatePin(pin);

      if (!isValidPin) {
        await staff.addLoginHistory('pin', deviceInfo, ipAddress, false, 'Invalid PIN');
        
        const attemptsLeft = 3 - staff.pinAttempts;
        return res.status(401).json({
          success: false,
          message: attemptsLeft > 0 
            ? `Invalid PIN. ${attemptsLeft} attempts remaining.`
            : 'PIN locked due to too many failed attempts.',
          attemptsLeft
        });
      }

      // Add successful login to history
      await staff.addLoginHistory('pin', deviceInfo, ipAddress, true);

      // Generate JWT token
      const token = jwt.sign(
        {
          staffId: staff._id,
          employeeId: staff.employeeId,
          role: staff.role,
          type: 'staff'
        },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRE || '12h' }
      );

      // Prepare response (exclude sensitive fields)
      const staffResponse = staff.toObject();
      delete staffResponse.pin;
      delete staffResponse.qrBadgeToken;
      delete staffResponse.firebaseUid;

      res.json({
        success: true,
        message: 'Login successful',
        token,
        staff: staffResponse,
        requirePinChange: staff.requirePinChange,
        sessionExpiry: new Date(Date.now() + 12 * 60 * 60 * 1000) // 12 hours
      });

    } catch (error) {
      console.error('PIN login error:', error);
      res.status(500).json({
        success: false,
        message: 'Login failed',
        error: error.message
      });
    }
  }
);

// ===== Login with QR Badge =====

/**
 * @route   POST /api/staff/auth/login-qr
 * @desc    Login staff by scanning QR badge
 * @access  Public
 */
router.post(
  '/login-qr',
  [
    body('qrToken').notEmpty().withMessage('QR token is required')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { qrToken } = req.body;
      const deviceInfo = req.headers['user-agent'] || 'Unknown';
      const ipAddress = req.ip || req.connection.remoteAddress;

      // Validate QR token
      const validation = qrBadgeService.validateQRToken(qrToken);

      if (!validation.valid) {
        return res.status(401).json({
          success: false,
          message: validation.message || 'Invalid QR badge',
          reason: validation.reason
        });
      }

      // Find staff by QR token or employee ID
      let staff = await Staff.findOne({ qrBadgeToken: qrToken, isDeleted: false });
      
      if (!staff) {
        // Try finding by employee ID from decrypted token
        staff = await Staff.findByEmployeeId(validation.employeeId);
      }

      if (!staff) {
        return res.status(401).json({
          success: false,
          message: 'Staff not found. Please contact admin.'
        });
      }

      // Check if staff is active
      if (staff.status === 'inactive') {
        await staff.addLoginHistory('qr', deviceInfo, ipAddress, false, 'Account inactive');
        return res.status(401).json({
          success: false,
          message: 'Account is inactive. Please contact admin.'
        });
      }

      // Add successful login to history
      await staff.addLoginHistory('qr', deviceInfo, ipAddress, true);

      // Generate JWT token
      const token = jwt.sign(
        {
          staffId: staff._id,
          employeeId: staff.employeeId,
          role: staff.role,
          type: 'staff'
        },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRE || '12h' }
      );

      // Prepare response
      const staffResponse = staff.toObject();
      delete staffResponse.pin;
      delete staffResponse.qrBadgeToken;
      delete staffResponse.firebaseUid;

      res.json({
        success: true,
        message: 'QR login successful',
        token,
        staff: staffResponse,
        sessionExpiry: new Date(Date.now() + 12 * 60 * 60 * 1000)
      });

    } catch (error) {
      console.error('QR login error:', error);
      res.status(500).json({
        success: false,
        message: 'QR login failed',
        error: error.message
      });
    }
  }
);

// ===== Check PIN Uniqueness =====

/**
 * @route   POST /api/staff/auth/check-pin-uniqueness
 * @desc    Check if PIN is already taken by another staff member
 * @access  Public (used during registration/PIN change)
 */
router.post(
  '/check-pin-uniqueness',
  [
    body('pin').isLength({ min: 4, max: 4 }).isNumeric().withMessage('PIN must be exactly 4 digits'),
    body('staffId').optional().isMongoId().withMessage('Invalid staff ID')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          errors: errors.array()
        });
      }

      const { pin, staffId } = req.body;
      
      // Check if PIN is taken
      const result = await Staff.isPinTaken(pin, staffId || null);

      if (result.taken) {
        return res.json({
          success: false,
          available: false,
          message: `This PIN is already taken by ${result.takenBy.name} (${result.takenBy.employeeId}). Please choose a different PIN.`,
          takenBy: result.takenBy
        });
      }

      res.json({
        success: true,
        available: true,
        message: 'PIN is available'
      });

    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

// ===== Validate PIN =====

/**
 * @route   POST /api/staff/auth/validate-pin
 * @desc    Check if PIN is correct (used for verification)
 * @access  Public
 */
router.post(
  '/validate-pin',
  [
    body('employeeId').notEmpty(),
    body('pin').isLength({ min: 4, max: 4 }).isNumeric()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          errors: errors.array()
        });
      }

      const { employeeId, pin } = req.body;
      const staff = await Staff.findByEmployeeId(employeeId).select('+pin');

      if (!staff || staff.isPinLocked) {
        return res.json({ valid: false });
      }

      const isValid = await staff.validatePin(pin);
      res.json({ valid: isValid });

    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

// ===== Change PIN (Authenticated Staff) =====

/**
 * @route   POST /api/staff/auth/change-pin
 * @desc    Staff changes their own PIN
 * @access  Private (Staff)
 */
router.post(
  '/change-pin',
  protect,
  [
    body('currentPin').isLength({ min: 4, max: 4 }).isNumeric(),
    body('newPin').isLength({ min: 4, max: 4 }).isNumeric()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          errors: errors.array()
        });
      }

      const { currentPin, newPin } = req.body;
      const staff = await Staff.findById(req.user.staffId).select('+pin');

      if (!staff) {
        return res.status(404).json({
          success: false,
          message: 'Staff not found'
        });
      }

      // Verify current PIN
      const isValid = await staff.validatePin(currentPin);
      if (!isValid) {
        return res.status(401).json({
          success: false,
          message: 'Current PIN is incorrect'
        });
      }

      // Change to new PIN
      await staff.changePin(newPin);

      res.json({
        success: true,
        message: 'PIN changed successfully'
      });

    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

// ===== Check Session =====

/**
 * @route   GET /api/staff/auth/session
 * @desc    Validate current session and get staff info
 * @access  Private (Staff)
 */
router.get('/session', protect, async (req, res) => {
  try {
    const staff = await Staff.findById(req.user.staffId);

    if (!staff || staff.isDeleted) {
      return res.status(404).json({
        success: false,
        message: 'Staff not found'
      });
    }

    const staffResponse = staff.toObject();
    delete staffResponse.pin;
    delete staffResponse.qrBadgeToken;
    delete staffResponse.firebaseUid;

    res.json({
      success: true,
      staff: staffResponse,
      isOnShift: staff.isOnShift,
      sessionValid: true
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ===== Logout =====

/**
 * @route   POST /api/staff/auth/logout
 * @desc    Logout staff (client-side token deletion)
 * @access  Private (Staff)
 */
router.post('/logout', protect, async (req, res) => {
  try {
    // In a more advanced setup, you could blacklist the token
    // For now, client will delete the token
    
    res.json({
      success: true,
      message: 'Logged out successfully'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;
