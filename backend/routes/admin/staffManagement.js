const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const Staff = require('../../models/Staff');
const User = require('../../models/User');
const qrBadgeService = require('../../services/qrBadgeService');
const badgePdfService = require('../../services/badgePdfService');
const { protect, authorize } = require('../../middleware/auth');

/**
 * Admin Staff Management Routes
 * All routes require admin authentication
 */

// ===== Create New Staff =====

/**
 * @route   POST /api/admin/staff/create
 * @desc    Create new staff member with auto-generated Employee ID
 * @access  Private (Admin only)
 */
router.post(
  '/create',
  protect,
  authorize('admin'),
  [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('email').isEmail().withMessage('Valid email is required'),
    body('phone').trim().notEmpty().withMessage('Phone is required'),
    body('role').isIn(['barista', 'manager', 'cashier']).withMessage('Invalid role'),
    body('pin').optional().isLength({ min: 4, max: 4 }).isNumeric().withMessage('PIN must be 4 digits'),
    body('photo').optional().isURL().withMessage('Photo must be a valid URL'),
    body('shiftStartTime').optional().matches(/^\d{2}:\d{2}$/).withMessage('Shift start time must be HH:MM format'),
    body('shiftEndTime').optional().matches(/^\d{2}:\d{2}$/).withMessage('Shift end time must be HH:MM format')
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

      const { name, email, phone, role, pin, photo, shiftStartTime, shiftEndTime } = req.body;

      // Check if email already exists
      const existingStaff = await Staff.findOne({ email, isDeleted: false });
      if (existingStaff) {
        return res.status(400).json({
          success: false,
          message: 'Staff member with this email already exists'
        });
      }

      // Generate Employee ID based on role
      const employeeId = await Staff.generateEmployeeId(role);

      // Generate QR badge token
      const qrToken = qrBadgeService.generateQRToken(employeeId);
      const qrExpiresAt = new Date();
      qrExpiresAt.setMonth(qrExpiresAt.getMonth() + 6); // 6 months expiry

      // Create staff member
      const staff = await Staff.create({
        name,
        email,
        phone,
        role,
        employeeId,
        pin: pin || '1234', // Default PIN if not provided
        requirePinChange: true,
        qrBadgeToken: qrToken,
        qrBadgeGeneratedAt: new Date(),
        qrBadgeExpiresAt: qrExpiresAt,
        photo: photo || null,
        shiftStartTime: shiftStartTime || '08:00',
        shiftEndTime: shiftEndTime || '16:00',
        status: 'active',
        isEmailVerified: false
      });

      res.status(201).json({
        success: true,
        message: 'Staff member created successfully',
        staff: {
          id: staff._id,
          name: staff.name,
          email: staff.email,
          phone: staff.phone,
          role: staff.role,
          employeeId: staff.employeeId,
          status: staff.status,
          requirePinChange: staff.requirePinChange,
          qrBadgeExpiresAt: staff.qrBadgeExpiresAt,
          shiftStartTime: staff.shiftStartTime,
          shiftEndTime: staff.shiftEndTime
        },
        credentials: {
          employeeId: staff.employeeId,
          defaultPin: pin || '1234',
          mustChangePinOnFirstLogin: true
        }
      });

    } catch (error) {
      console.error('Create staff error:', error);
      res.status(500).json({
        success: false,
        message: 'Error creating staff member',
        error: error.message
      });
    }
  }
);

// ===== Reset Staff PIN =====

/**
 * @route   PUT /api/admin/staff/:id/reset-pin
 * @desc    Admin resets staff PIN
 * @access  Private (Admin only)
 */
router.put(
  '/:id/reset-pin',
  protect,
  authorize('admin'),
  [
    body('newPin').isLength({ min: 4, max: 4 }).isNumeric().withMessage('PIN must be 4 digits'),
    body('requireChange').optional().isBoolean().withMessage('requireChange must be boolean')
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

      const { newPin, requireChange = true } = req.body;
      const staff = await Staff.findById(req.params.id);

      if (!staff || staff.isDeleted) {
        return res.status(404).json({
          success: false,
          message: 'Staff member not found'
        });
      }

      // Reset PIN using the model method
      await staff.resetPin(newPin, requireChange);

      res.json({
        success: true,
        message: 'PIN reset successfully',
        staff: {
          id: staff._id,
          name: staff.name,
          employeeId: staff.employeeId,
          requirePinChange: staff.requirePinChange
        },
        newPin: newPin
      });

    } catch (error) {
      console.error('Reset PIN error:', error);
      res.status(500).json({
        success: false,
        message: 'Error resetting PIN',
        error: error.message
      });
    }
  }
);

// ===== Unlock Staff PIN =====

/**
 * @route   PUT /api/admin/staff/:id/unlock-pin
 * @desc    Admin unlocks locked PIN
 * @access  Private (Admin only)
 */
router.put(
  '/:id/unlock-pin',
  protect,
  authorize('admin'),
  async (req, res) => {
    try {
      const staff = await Staff.findById(req.params.id);

      if (!staff || staff.isDeleted) {
        return res.status(404).json({
          success: false,
          message: 'Staff member not found'
        });
      }

      if (!staff.isPinLocked) {
        return res.status(400).json({
          success: false,
          message: 'PIN is not locked'
        });
      }

      // Unlock PIN using the model method
      staff.unlockPin();
      await staff.save();

      res.json({
        success: true,
        message: 'PIN unlocked successfully',
        staff: {
          id: staff._id,
          name: staff.name,
          employeeId: staff.employeeId,
          isPinLocked: staff.isPinLocked
        }
      });

    } catch (error) {
      console.error('Unlock PIN error:', error);
      res.status(500).json({
        success: false,
        message: 'Error unlocking PIN',
        error: error.message
      });
    }
  }
);

// ===== Generate New QR Badge =====

/**
 * @route   POST /api/admin/staff/:id/generate-badge
 * @desc    Generate new QR badge for staff
 * @access  Private (Admin only)
 */
router.post(
  '/:id/generate-badge',
  protect,
  authorize('admin'),
  async (req, res) => {
    try {
      const staff = await Staff.findById(req.params.id);

      if (!staff || staff.isDeleted) {
        return res.status(404).json({
          success: false,
          message: 'Staff member not found'
        });
      }

      // Generate new QR badge token
      const qrToken = qrBadgeService.generateQRToken(staff.employeeId);
      const qrExpiresAt = new Date();
      qrExpiresAt.setMonth(qrExpiresAt.getMonth() + 6); // 6 months expiry

      staff.qrBadgeToken = qrToken;
      staff.qrBadgeGeneratedAt = new Date();
      staff.qrBadgeExpiresAt = qrExpiresAt;
      await staff.save();

      console.log('✅ QR Badge generated for staff:', {
        employeeId: staff.employeeId,
        name: staff.name,
        tokenLength: qrToken.length,
        expiresAt: qrExpiresAt
      });

      // Generate badge data with QR code
      const badgeData = await qrBadgeService.generateBadgeData(staff);

      res.json({
        success: true,
        message: 'QR badge generated successfully',
        badge: badgeData,
        staff: {
          id: staff._id,
          name: staff.name,
          employeeId: staff.employeeId,
          qrBadgeGeneratedAt: staff.qrBadgeGeneratedAt,
          qrBadgeExpiresAt: staff.qrBadgeExpiresAt
        }
      });

    } catch (error) {
      console.error('Generate badge error:', error);
      console.error('Error stack:', error.stack);
      res.status(500).json({
        success: false,
        message: 'Error generating badge',
        error: error.message
      });
    }
  }
);

// ===== Get Staff Login History =====

/**
 * @route   GET /api/admin/staff/:id/login-history
 * @desc    Get staff login history with filtering
 * @access  Private (Admin only)
 */
router.get(
  '/:id/login-history',
  protect,
  authorize('admin'),
  async (req, res) => {
    try {
      const { startDate, endDate, method, successOnly } = req.query;
      
      const staff = await Staff.findById(req.params.id);

      if (!staff || staff.isDeleted) {
        return res.status(404).json({
          success: false,
          message: 'Staff member not found'
        });
      }

      let loginHistory = staff.loginHistory || [];

      // Filter by date range
      if (startDate) {
        const start = new Date(startDate);
        loginHistory = loginHistory.filter(entry => 
          new Date(entry.timestamp) >= start
        );
      }
      if (endDate) {
        const end = new Date(endDate);
        loginHistory = loginHistory.filter(entry => 
          new Date(entry.timestamp) <= end
        );
      }

      // Filter by method (pin/qr)
      if (method) {
        loginHistory = loginHistory.filter(entry => 
          entry.method === method
        );
      }

      // Filter by success status
      if (successOnly === 'true') {
        loginHistory = loginHistory.filter(entry => entry.success === true);
      }

      // Sort by most recent first
      loginHistory.sort((a, b) => 
        new Date(b.timestamp) - new Date(a.timestamp)
      );

      // Calculate stats
      const stats = {
        totalLogins: loginHistory.filter(e => e.success).length,
        failedAttempts: loginHistory.filter(e => !e.success).length,
        pinLogins: loginHistory.filter(e => e.method === 'pin' && e.success).length,
        qrLogins: loginHistory.filter(e => e.method === 'qr' && e.success).length,
        lastLogin: staff.lastLoginAt
      };

      res.json({
        success: true,
        staff: {
          id: staff._id,
          name: staff.name,
          employeeId: staff.employeeId,
          role: staff.role
        },
        stats,
        loginHistory
      });

    } catch (error) {
      console.error('Get login history error:', error);
      res.status(500).json({
        success: false,
        message: 'Error fetching login history',
        error: error.message
      });
    }
  }
);

// ===== Get All Staff =====

/**
 * @route   GET /api/admin/staff
 * @desc    Get all staff members with authentication status
 * @access  Private (Admin only)
 */
router.get(
  '/',
  protect,
  authorize('admin'),
  async (req, res) => {
    try {
      const { role, status, search } = req.query;
      
      const query = { isDeleted: false };

      if (role) query.role = role;
      if (status) query.status = status;
      if (search) {
        query.$or = [
          { name: { $regex: search, $options: 'i' } },
          { email: { $regex: search, $options: 'i' } },
          { employeeId: { $regex: search, $options: 'i' } }
        ];
      }

      const staff = await Staff.find(query)
        .sort({ createdAt: -1 })
        .select('-pin -qrBadgeToken -loginHistory')
        .lean(); // Use lean() for better performance - returns plain JS objects

      // Add computed fields efficiently
      const now = new Date();
      const staffWithStatus = staff.map(s => {
        // Compute badge validity inline (faster than virtual getter)
        const isQrBadgeValid = s.qrBadgeToken && 
          (!s.qrBadgeExpiresAt || new Date(s.qrBadgeExpiresAt) > now);
        
        // Compute locked status inline
        const isPinLocked = s.isPinLocked || 
          (s.pinLockedUntil && new Date(s.pinLockedUntil) > now);

        return {
          id: s._id,
          name: s.name,
          email: s.email,
          phone: s.phone,
          role: s.role,
          employeeId: s.employeeId,
          status: s.status,
          photo: s.photo,
          shiftStartTime: s.shiftStartTime,
          shiftEndTime: s.shiftEndTime,
          requirePinChange: s.requirePinChange,
          isPinLocked: isPinLocked,
          pinLockedUntil: s.pinLockedUntil,
          isQrBadgeValid: isQrBadgeValid,
          qrBadgeExpiresAt: s.qrBadgeExpiresAt,
          lastLoginAt: s.lastLoginAt,
          hireDate: s.hireDate,
          createdAt: s.createdAt
        };
      });

      res.json({
        success: true,
        count: staffWithStatus.length,
        staff: staffWithStatus
      });

    } catch (error) {
      console.error('Get staff error:', error);
      res.status(500).json({
        success: false,
        message: 'Error fetching staff',
        error: error.message
      });
    }
  }
);

// ===== Get Single Staff =====

/**
 * @route   GET /api/admin/staff/:id
 * @desc    Get single staff member details
 * @access  Private (Admin only)
 */
router.get(
  '/:id',
  protect,
  authorize('admin'),
  async (req, res) => {
    try {
      // Include PIN (with +pin since it has select: false) but exclude qrBadgeToken
      const staff = await Staff.findById(req.params.id).select('-qrBadgeToken +pin');

      if (!staff || staff.isDeleted) {
        return res.status(404).json({
          success: false,
          message: 'Staff member not found'
        });
      }

      // Note: PIN is returned hashed for security
      // Frontend should use a separate endpoint to verify/display if needed
      res.json({
        success: true,
        staff: {
          id: staff._id,
          name: staff.name,
          email: staff.email,
          phone: staff.phone,
          role: staff.role,
          employeeId: staff.employeeId,
          status: staff.status,
          photo: staff.photo,
          shiftStartTime: staff.shiftStartTime,
          shiftEndTime: staff.shiftEndTime,
          requirePinChange: staff.requirePinChange,
          isPinLocked: staff.isPinLocked,
          pinAttempts: staff.pinAttempts,
          pinLockedUntil: staff.pinLockedUntil,
          isQrBadgeValid: staff.isQrBadgeValid,
          isOnShift: staff.isOnShift,
          qrBadgeGeneratedAt: staff.qrBadgeGeneratedAt,
          qrBadgeExpiresAt: staff.qrBadgeExpiresAt,
          lastLoginAt: staff.lastLoginAt,
          hireDate: staff.hireDate,
          stats: staff.stats,
          assignedOrders: staff.assignedOrders,
          loginHistory: (staff.loginHistory || []).slice(-20), // Last 20 login attempts
          createdAt: staff.createdAt,
          updatedAt: staff.updatedAt,
          hasPin: !!staff.pin, // Boolean flag indicating if PIN is set
          pinHashedValue: staff.pin // Hashed PIN value (for display purposes - shows it's set)
        }
      });

    } catch (error) {
      console.error('Get staff error:', error);
      res.status(500).json({
        success: false,
        message: 'Error fetching staff',
        error: error.message
      });
    }
  }
);

// ===== Update Staff =====

/**
 * @route   PUT /api/admin/staff/:id
 * @desc    Update staff member details
 * @access  Private (Admin only)
 */
router.put(
  '/:id',
  protect,
  authorize('admin'),
  [
    body('name').optional().trim().notEmpty().withMessage('Name cannot be empty'),
    body('email').optional().isEmail().withMessage('Valid email is required'),
    body('phone').optional().trim().notEmpty().withMessage('Phone cannot be empty'),
    body('role').optional().isIn(['barista', 'manager', 'cashier']).withMessage('Invalid role'),
    body('status').optional().isIn(['active', 'inactive', 'on_break']).withMessage('Invalid status'),
    body('photo').optional().isURL().withMessage('Photo must be a valid URL'),
    body('shiftStartTime').optional().matches(/^\d{2}:\d{2}$/).withMessage('Shift start time must be HH:MM format'),
    body('shiftEndTime').optional().matches(/^\d{2}:\d{2}$/).withMessage('Shift end time must be HH:MM format')
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

      const staff = await Staff.findById(req.params.id);

      if (!staff || staff.isDeleted) {
        return res.status(404).json({
          success: false,
          message: 'Staff member not found'
        });
      }

      const allowedUpdates = ['name', 'email', 'phone', 'role', 'status', 'photo', 'shiftStartTime', 'shiftEndTime'];
      const updates = {};

      allowedUpdates.forEach(field => {
        if (req.body[field] !== undefined) {
          updates[field] = req.body[field];
        }
      });

      Object.assign(staff, updates);
      await staff.save();

      res.json({
        success: true,
        message: 'Staff updated successfully',
        staff: {
          id: staff._id,
          name: staff.name,
          email: staff.email,
          phone: staff.phone,
          role: staff.role,
          employeeId: staff.employeeId,
          status: staff.status,
          photo: staff.photo,
          shiftStartTime: staff.shiftStartTime,
          shiftEndTime: staff.shiftEndTime
        }
      });

    } catch (error) {
      console.error('Update staff error:', error);
      res.status(500).json({
        success: false,
        message: 'Error updating staff',
        error: error.message
      });
    }
  }
);

// ===== Delete Staff (Soft Delete) =====

/**
 * @route   DELETE /api/admin/staff/:id
 * @desc    Soft delete staff member
 * @access  Private (Admin only)
 */
router.delete(
  '/:id',
  protect,
  authorize('admin'),
  async (req, res) => {
    try {
      const staff = await Staff.findById(req.params.id);

      if (!staff || staff.isDeleted) {
        return res.status(404).json({
          success: false,
          message: 'Staff member not found'
        });
      }

      staff.isDeleted = true;
      staff.deletedAt = new Date();
      staff.status = 'inactive';
      await staff.save();

      res.json({
        success: true,
        message: 'Staff member deleted successfully'
      });

    } catch (error) {
      console.error('Delete staff error:', error);
      res.status(500).json({
        success: false,
        message: 'Error deleting staff',
        error: error.message
      });
    }
  }
);

// ===== Download Badge PDF =====

/**
 * @route   GET /api/admin/staff/:id/badge-pdf
 * @desc    Download printable badge PDF for staff
 * @access  Private (Admin only)
 */
router.get(
  '/:id/badge-pdf',
  async (req, res) => {
    try {
      // Custom auth for file downloads - accept token from query parameter
      let token;
      if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        token = req.headers.authorization.split(' ')[1];
      } else if (req.query.token) {
        token = req.query.token;
      }

      console.log('🔐 Badge PDF auth check:', {
        hasAuthHeader: !!req.headers.authorization,
        hasQueryToken: !!req.query.token,
        tokenLength: token ? token.length : 0
      });

      if (!token) {
        console.log('❌ No token provided');
        return res.status(401).json({
          success: false,
          message: 'Not authorized to access this route'
        });
      }

      // Verify token
      let decoded;
      try {
        decoded = jwt.verify(token, process.env.JWT_SECRET);
        console.log('🔓 Token decoded:', {
          userId: decoded.userId || decoded.id,
          role: decoded.role
        });
      } catch (jwtError) {
        console.error('❌ JWT verification failed:', jwtError.message);
        return res.status(401).json({
          success: false,
          message: 'Invalid or expired token'
        });
      }

      // Check if admin role in token (admin panel uses hardcoded admin username)
      if (decoded.role === 'admin') {
        console.log('✅ Admin authenticated via token role');
        // Admin is authenticated, proceed to generate PDF
      } else {
        // For regular users, check database
        const userId = decoded.userId || decoded.id;
        const user = await User.findById(userId);

        console.log('👤 User check:', {
          decodedUserId: userId,
          userFound: !!user,
          userId: user?._id,
          userRole: user?.role,
          isAdmin: user?.role === 'admin'
        });

        if (!user || user.role !== 'admin') {
          console.log('❌ User not authorized');
          return res.status(403).json({
            success: false,
            message: 'Not authorized to access this route'
          });
        }
      }

      // Get staff member
      const staff = await Staff.findById(req.params.id);

      if (!staff || staff.isDeleted) {
        return res.status(404).json({
          success: false,
          message: 'Staff member not found'
        });
      }

      // Check if staff has QR badge token
      if (!staff.qrBadgeToken) {
        return res.status(400).json({
          success: false,
          message: 'Staff member does not have a QR badge. Please generate badge first.'
        });
      }

      console.log('📄 Generating badge PDF for:', {
        employeeId: staff.employeeId,
        name: staff.name,
        hasToken: !!staff.qrBadgeToken
      });

      // Generate badge PDF
      const pdfDoc = await badgePdfService.generateBadgePDF(staff);

      // Set response headers for PDF download
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="badge_${staff.employeeId}_${staff.name.replace(/\s+/g, '_')}.pdf"`);

      // Pipe PDF to response
      pdfDoc.pipe(res);
      pdfDoc.end();

    } catch (error) {
      console.error('Download badge PDF error:', error);
      console.error('Error stack:', error.stack);
      if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
        return res.status(401).json({
          success: false,
          message: 'Invalid or expired token'
        });
      }
      res.status(500).json({
        success: false,
        message: 'Error generating badge PDF',
        error: error.message
      });
    }
  }
);

/**
 * @route   GET /api/admin/staff/badges/download-all
 * @desc    Download all staff badges as single PDF
 * @access  Private (Admin only)
 */
router.get(
  '/badges/download-all',
  async (req, res) => {
    try {
      // Custom auth for file downloads - accept token from query parameter
      let token;
      if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        token = req.headers.authorization.split(' ')[1];
      } else if (req.query.token) {
        token = req.query.token;
      }

      if (!token) {
        return res.status(401).json({
          success: false,
          message: 'Not authorized to access this route'
        });
      }

      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.id);

      if (!user || user.role !== 'admin') {
        return res.status(403).json({
          success: false,
          message: 'Not authorized to access this route'
        });
      }

      // Get active staff
      const staff = await Staff.find({ isDeleted: false, status: 'active' })
        .sort({ role: 1, employeeId: 1 });

      if (staff.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'No active staff found'
        });
      }

      // Generate badge sheet PDF
      const pdfDoc = await badgePdfService.generateBadgeSheetPDF(staff);

      // Set response headers for PDF download
      const timestamp = new Date().toISOString().split('T')[0];
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="all_staff_badges_${timestamp}.pdf"`);

      // Pipe PDF to response
      pdfDoc.pipe(res);
      pdfDoc.end();

    } catch (error) {
      console.error('Download all badges error:', error);
      if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
        return res.status(401).json({
          success: false,
          message: 'Invalid or expired token'
        });
      }
      res.status(500).json({
        success: false,
        message: 'Error generating badges PDF',
        error: error.message
      });
    }
  }
);

module.exports = router;
