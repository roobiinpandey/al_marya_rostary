const express = require('express');
const mongoose = require('mongoose');
const { body, validationResult } = require('express-validator');
const { protectDriver, PinDriver } = require('./driverAuth');
const Order = require('../models/Order'); // Use actual Order model

const router = express.Router();

// Use the actual Order model instead of custom schema
const DriverOrder = Order;

// Legacy Order Schema reference (kept for reference but not used)
const __legacyOrderSchema = new mongoose.Schema({
  orderNumber: { type: String, required: true, unique: true },
  userId: { type: String, required: true },
  customerName: { type: String, required: true },
  customerPhone: { type: String, required: true },
  customerEmail: String,
  deliveryAddress: {
    fullAddress: { type: String, required: true },
    area: String,
    building: String,
    floor: String,
    apartment: String,
    instructions: String,
    coordinates: {
      latitude: Number,
      longitude: Number
    }
  },
  items: [{
    productId: String,
    name: { type: String, required: true },
    arabicName: String,
    quantity: { type: Number, required: true },
    size: String,
    roastLevel: String,
    addOns: [String],
    specialNotes: String,
    price: { type: Number, required: true },
    subtotal: { type: Number, required: true }
  }],
  totalAmount: { type: Number, required: true },
  deliveryFee: { type: Number, default: 0 },
  status: { 
    type: String, 
    enum: ['pending', 'confirmed', 'ready', 'assigned', 'out-for-delivery', 'delivered', 'cancelled'],
    default: 'pending' 
  },
  paymentMethod: {
    type: String,
    enum: ['cash', 'card', 'digital-wallet'],
    required: true
  },
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'failed', 'refunded'],
    default: 'pending'
  },
  driverId: String,
  assignedAt: Date,
  startedAt: Date,
  deliveredAt: Date,
  estimatedDeliveryTime: Date,
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

// DriverOrder model now uses the imported Order model (defined at top of file)
// const DriverOrder = mongoose.model('DriverOrder', orderSchema, 'orders'); // REMOVED - using actual Order model

// @desc    Get Available Deliveries
// @route   GET /api/driver/orders/available
// @access  Private
router.get('/orders/available', protectDriver, async (req, res) => {
  try {
    const orders = await DriverOrder.find({ 
      status: 'ready',
      driverId: { $exists: false }
    }).sort({ createdAt: -1 }).lean();

    res.status(200).json({
      success: true,
      count: orders.length,
      orders: orders || []
    });
  } catch (error) {
    console.error('Get available orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch available orders',
      orders: []
    });
  }
});

// @desc    Get My Deliveries (assigned to driver)
// @route   GET /api/driver/orders/my-deliveries
// @access  Private
router.get('/orders/my-deliveries', protectDriver, async (req, res) => {
  try {
    const orders = await DriverOrder.find({ 
      driverId: req.driver.driverId,
      status: { $in: ['assigned', 'out-for-delivery'] }
    }).sort({ assignedAt: -1 }).lean();

    res.status(200).json({
      success: true,
      count: orders.length,
      orders: orders || []
    });
  } catch (error) {
    console.error('Get my deliveries error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch my deliveries',
      orders: []
    });
  }
});

// @desc    Get Completed Deliveries
// @route   GET /api/driver/orders/completed
// @access  Private
router.get('/orders/completed', protectDriver, async (req, res) => {
  try {
    const orders = await DriverOrder.find({ 
      driverId: req.driver.driverId,
      status: 'delivered'
    }).sort({ deliveredAt: -1 }).limit(50).lean();

    res.status(200).json({
      success: true,
      count: orders.length,
      orders: orders || []
    });
  } catch (error) {
    console.error('Get completed orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch completed orders',
      orders: []
    });
  }
});

// @desc    Accept Delivery
// @route   POST /api/driver/orders/:id/accept
// @access  Private
router.post('/orders/:id/accept', protectDriver, async (req, res) => {
  try {
    console.log('📦 ACCEPT ORDER REQUEST:');
    console.log('   Order ID:', req.params.id);
    console.log('   Driver ID:', req.driver.driverId);
    console.log('   Driver Name:', req.driver.name);
    
    const order = await DriverOrder.findById(req.params.id);
    console.log('   Order found:', order ? 'YES' : 'NO');
    if (order) {
      console.log('   Order status:', order.status);
      console.log('   Order driverId:', order.driverId);
    }

    if (!order) {
      console.log('   ❌ Order not found');
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    if (order.status !== 'ready') {
      return res.status(400).json({
        success: false,
        message: 'Order is not available for pickup'
      });
    }

    // Check if already assigned to another driver
    if (order.assignedDriver) {
      return res.status(400).json({
        success: false,
        message: 'Order is already assigned to another driver'
      });
    }

    // Assign order to driver
    // Note: Order model doesn't have 'assigned' status, it goes: ready -> out-for-delivery
    // We keep status as 'ready' when driver accepts, changes to 'out-for-delivery' when they start delivery
    // Store driver's ObjectId in assignedDriver field
    order.assignedDriver = req.driver._id; // Driver ObjectId reference
    order.statusTimestamps = order.statusTimestamps || {};
    order.statusTimestamps.assignedToDriver = new Date();
    order.updatedAt = new Date();
    await order.save();

    console.log('   ✅ Order accepted successfully');
    console.log('   ✅ Assigned to driver:', req.driver._id);

    res.status(200).json({
      success: true,
      message: 'Delivery accepted successfully',
      order: order.toJSON()
    });
  } catch (error) {
    console.error('Accept delivery error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to accept delivery'
    });
  }
});

// @desc    Start Delivery
// @route   POST /api/driver/orders/:id/start
// @access  Private
router.post('/orders/:id/start', protectDriver, async (req, res) => {
  try {
    console.log('🚀 START DELIVERY REQUEST:');
    console.log('   Order ID:', req.params.id);
    console.log('   Driver ID from req:', req.driver.driverId);
    console.log('   Driver ObjectId from req:', req.driver._id);
    
    const order = await DriverOrder.findById(req.params.id);
    console.log('   Order found:', order ? 'YES' : 'NO');
    if (order) {
      console.log('   Order assignedDriver:', order.assignedDriver);
      console.log('   Order status:', order.status);
      console.log('   Driver ObjectId match:', order.assignedDriver && order.assignedDriver.toString() === req.driver._id.toString());
    }

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Check if order is assigned to this driver (compare ObjectIds)
    if (!order.assignedDriver || order.assignedDriver.toString() !== req.driver._id.toString()) {
      console.log('   ❌ Driver assignment mismatch!');
      return res.status(403).json({
        success: false,
        message: 'This order is not assigned to you'
      });
    }

    // Order should be 'ready' status (driver accepted but hasn't started yet)
    if (order.status !== 'ready') {
      return res.status(400).json({
        success: false,
        message: 'Order cannot be started in current status'
      });
    }

    // Start delivery - change status to 'out-for-delivery'
    order.status = 'out-for-delivery';
    order.statusTimestamps = order.statusTimestamps || {};
    order.statusTimestamps.outForDelivery = new Date();
    order.updatedAt = new Date();
    await order.save();

    // Update driver status
    req.driver.status = 'on_delivery';
    req.driver.updatedAt = new Date();
    await req.driver.save();

    res.status(200).json({
      success: true,
      message: 'Delivery started',
      order: order.toJSON()
    });
  } catch (error) {
    console.error('Start delivery error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to start delivery'
    });
  }
});

// @desc    Complete Delivery
// @route   POST /api/driver/orders/:id/complete
// @access  Private
router.post('/orders/:id/complete', protectDriver, async (req, res) => {
  try {
    const order = await DriverOrder.findById(req.params.id);

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Check if order is assigned to this driver (compare ObjectIds)
    if (!order.assignedDriver || order.assignedDriver.toString() !== req.driver._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'This order is not assigned to you'
      });
    }

    if (order.status !== 'out-for-delivery') {
      return res.status(400).json({
        success: false,
        message: 'Order cannot be completed in current status'
      });
    }

    // Complete delivery
    order.status = 'delivered';
    order.statusTimestamps = order.statusTimestamps || {};
    order.statusTimestamps.delivered = new Date();
    order.actualDeliveryTime = new Date();
    order.updatedAt = new Date();
    
    // Add delivery notes if provided
    if (req.body.notes) {
      order.notes = (order.notes || '') + '\nDelivery Notes: ' + req.body.notes;
    }
    
    await order.save();

    // Update driver status and stats
    req.driver.status = 'available';
    req.driver.stats.completedDeliveries += 1;
    req.driver.stats.totalDeliveries += 1;
    req.driver.updatedAt = new Date();
    await req.driver.save();

    res.status(200).json({
      success: true,
      message: 'Delivery completed successfully',
      order: order.toJSON()
    });
  } catch (error) {
    console.error('Complete delivery error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to complete delivery'
    });
  }
});

// @desc    Update Driver Location
// @route   POST /api/driver/location
// @access  Private
router.post(
  '/location',
  protectDriver,
  [
    body('latitude').isFloat({ min: -90, max: 90 }).withMessage('Invalid latitude'),
    body('longitude').isFloat({ min: -180, max: 180 }).withMessage('Invalid longitude')
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

      const { latitude, longitude } = req.body;

      // Update driver location
      req.driver.location = {
        latitude,
        longitude,
        lastUpdated: new Date()
      };
      req.driver.updatedAt = new Date();
      await req.driver.save();

      res.status(200).json({
        success: true,
        message: 'Location updated successfully',
        location: req.driver.location
      });
    } catch (error) {
      console.error('Update location error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update location'
      });
    }
  }
);

// @desc    Update Driver Status
// @route   POST /api/driver/status
// @access  Private
router.post(
  '/status',
  protectDriver,
  [
    body('status').isIn(['available', 'offline', 'on_break']).withMessage('Invalid status')
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

      const { status } = req.body;

      // Update driver status
      req.driver.status = status;
      req.driver.updatedAt = new Date();
      await req.driver.save();

      res.status(200).json({
        success: true,
        message: 'Status updated successfully',
        status: req.driver.status
      });
    } catch (error) {
      console.error('Update status error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update status'
      });
    }
  }
);

module.exports = router;
