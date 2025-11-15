const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const mongoose = require('mongoose');

const router = express.Router();

// Temporary Driver Schema for PIN/QR Authentication
// This uses a separate collection for PIN-based drivers
const pinDriverSchema = new mongoose.Schema({
  driverId: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String, required: true },
  pin: { type: String, required: true },
  qrBadgeToken: { type: String, unique: true, sparse: true },
  status: { 
    type: String, 
    enum: ['available', 'on_delivery', 'offline', 'on_break'],
    default: 'offline' 
  },
  location: {
    latitude: Number,
    longitude: Number,
    lastUpdated: Date
  },
  vehicleInfo: {
    type: { type: String },
    plateNumber: String,
    color: String
  },
  stats: {
    totalDeliveries: { type: Number, default: 0 },
    completedDeliveries: { type: Number, default: 0 },
    cancelledDeliveries: { type: Number, default: 0 }
  },
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

const PinDriver = mongoose.model('PinDriver', pinDriverSchema, 'drivers');

// Generate JWT token
const generateToken = (driverId) => {
  return jwt.sign(
    { driverId, role: 'driver', type: 'pin' },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE || '7d' }
  );
};

// Middleware to protect routes
const protectDriver = async (req, res, next) => {
  try {
    let token;

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
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      if (!decoded.driverId || decoded.role !== 'driver') {
        return res.status(401).json({
          success: false,
          message: 'Invalid driver token'
        });
      }

      const driver = await PinDriver.findOne({ driverId: decoded.driverId, isActive: true });

      if (!driver) {
        return res.status(401).json({
          success: false,
          message: 'Driver not found or deactivated'
        });
      }

      req.driver = driver;
      next();
    } catch (error) {
      console.error('Token verification failed:', error.message);
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

// @desc    Driver PIN Login
// @route   POST /api/driver/auth/pin-login
// @access  Public
router.post(
  '/pin-login',
  [body('pin').isLength({ min: 4, max: 4 }).withMessage('PIN must be 4 digits')],
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

      const { pin } = req.body;

      // Find driver by PIN (hashed)
      const drivers = await PinDriver.find({ isActive: true });
      let matchedDriver = null;

      for (const driver of drivers) {
        const isMatch = await bcrypt.compare(pin, driver.pin);
        if (isMatch) {
          matchedDriver = driver;
          break;
        }
      }

      if (!matchedDriver) {
        return res.status(401).json({
          success: false,
          message: 'Invalid PIN'
        });
      }

      // Generate token
      const token = generateToken(matchedDriver.driverId);

      res.status(200).json({
        success: true,
        message: 'Login successful',
        token,
        driver: {
          id: matchedDriver._id,
          driverId: matchedDriver.driverId,
          name: matchedDriver.name,
          email: matchedDriver.email,
          phone: matchedDriver.phone,
          status: matchedDriver.status,
          vehicleInfo: matchedDriver.vehicleInfo,
          stats: matchedDriver.stats
        }
      });
    } catch (error) {
      console.error('PIN login error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error during login'
      });
    }
  }
);

// @desc    Driver QR Login
// @route   POST /api/driver/auth/qr-login
// @access  Public
router.post(
  '/qr-login',
  [body('qrCode').notEmpty().withMessage('QR code is required')],
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

      const { qrCode } = req.body;

      // Find driver by QR badge token
      const driver = await PinDriver.findOne({ 
        qrBadgeToken: qrCode, 
        isActive: true 
      });

      if (!driver) {
        return res.status(401).json({
          success: false,
          message: 'Invalid QR code'
        });
      }

      // Generate token
      const token = generateToken(driver.driverId);

      res.status(200).json({
        success: true,
        message: 'Login successful',
        token,
        driver: {
          id: driver._id,
          driverId: driver.driverId,
          name: driver.name,
          email: driver.email,
          phone: driver.phone,
          status: driver.status,
          vehicleInfo: driver.vehicleInfo,
          stats: driver.stats
        }
      });
    } catch (error) {
      console.error('QR login error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error during login'
      });
    }
  }
);

// @desc    Validate Token
// @route   GET /api/driver/auth/validate-token
// @access  Private
router.get('/validate-token', protectDriver, async (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Token is valid',
    driver: {
      id: req.driver._id,
      driverId: req.driver.driverId,
      name: req.driver.name,
      email: req.driver.email,
      status: req.driver.status
    }
  });
});

// @desc    Change PIN
// @route   POST /api/driver/auth/change-pin
// @access  Private
router.post(
  '/change-pin',
  protectDriver,
  [
    body('currentPin').isLength({ min: 4, max: 4 }).withMessage('Current PIN must be 4 digits'),
    body('newPin').isLength({ min: 4, max: 4 }).withMessage('New PIN must be 4 digits')
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

      const { currentPin, newPin } = req.body;

      // Verify current PIN
      const isMatch = await bcrypt.compare(currentPin, req.driver.pin);
      if (!isMatch) {
        return res.status(401).json({
          success: false,
          message: 'Current PIN is incorrect'
        });
      }

      // Hash new PIN
      const hashedPin = await bcrypt.hash(newPin, 10);

      // Update PIN
      req.driver.pin = hashedPin;
      req.driver.updatedAt = new Date();
      await req.driver.save();

      res.status(200).json({
        success: true,
        message: 'PIN changed successfully'
      });
    } catch (error) {
      console.error('Change PIN error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to change PIN'
      });
    }
  }
);

module.exports = { router, protectDriver, PinDriver };
