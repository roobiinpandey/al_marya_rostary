const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');

// Admin authentication middleware (assumes it's imported from parent route)
const { protectAdmin } = require('../admin');

// Get PinDriver model - use existing model if already compiled
let PinDriver;
try {
  // Try to get existing model
  PinDriver = mongoose.model('PinDriver');
} catch (error) {
  // Model doesn't exist, create it
  PinDriver = mongoose.model('PinDriver', new mongoose.Schema({
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
      cancelledDeliveries: { type: Number, default: 0 },
      totalEarnings: { type: Number, default: 0 }
    },
    isActive: { type: Boolean, default: true },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now }
  }), 'drivers');
}

// @desc    Get all drivers
// @route   GET /api/admin/drivers
// @access  Private (Admin)
router.get('/', async (req, res) => {
  try {
    const drivers = await PinDriver.find({})
      .sort({ createdAt: -1 })
      .lean();

    // Format response
    const formattedDrivers = drivers.map(driver => ({
      ...driver,
      id: driver._id,
      // Don't send PIN in response
      pin: undefined
    }));

    res.json({
      success: true,
      drivers: formattedDrivers,
      count: formattedDrivers.length
    });
  } catch (error) {
    console.error('Error fetching drivers:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch drivers',
      error: error.message
    });
  }
});

// @desc    Get driver statistics
// @route   GET /api/admin/drivers/stats
// @access  Private (Admin)
router.get('/stats', async (req, res) => {
  try {
    const stats = await PinDriver.aggregate([
      {
        $group: {
          _id: null,
          totalDrivers: { $sum: 1 },
          activeDrivers: {
            $sum: { $cond: [{ $eq: ['$isActive', true] }, 1, 0] }
          },
          availableDrivers: {
            $sum: { $cond: [{ $eq: ['$status', 'available'] }, 1, 0] }
          },
          onDeliveryDrivers: {
            $sum: { $cond: [{ $eq: ['$status', 'on_delivery'] }, 1, 0] }
          },
          offlineDrivers: {
            $sum: { $cond: [{ $eq: ['$status', 'offline'] }, 1, 0] }
          },
          onBreakDrivers: {
            $sum: { $cond: [{ $eq: ['$status', 'on_break'] }, 1, 0] }
          },
          totalDeliveries: { $sum: '$stats.totalDeliveries' },
          completedDeliveries: { $sum: '$stats.completedDeliveries' },
          cancelledDeliveries: { $sum: '$stats.cancelledDeliveries' },
          totalEarnings: { $sum: '$stats.totalEarnings' }
        }
      }
    ]);

    const result = stats.length > 0 ? stats[0] : {
      totalDrivers: 0,
      activeDrivers: 0,
      availableDrivers: 0,
      onDeliveryDrivers: 0,
      offlineDrivers: 0,
      onBreakDrivers: 0,
      totalDeliveries: 0,
      completedDeliveries: 0,
      cancelledDeliveries: 0,
      totalEarnings: 0
    };

    // Remove _id field
    delete result._id;

    res.json({
      success: true,
      stats: result
    });
  } catch (error) {
    console.error('Error fetching driver statistics:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch driver statistics',
      error: error.message
    });
  }
});

// @desc    Get single driver by ID
// @route   GET /api/admin/drivers/:id
// @access  Private (Admin)
router.get('/:id', async (req, res) => {
  try {
    const driver = await PinDriver.findById(req.params.id).lean();

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    // Don't send PIN in response
    delete driver.pin;

    res.json({
      success: true,
      driver
    });
  } catch (error) {
    console.error('Error fetching driver:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch driver',
      error: error.message
    });
  }
});

// @desc    Create new driver
// @route   POST /api/admin/drivers
// @access  Private (Admin)
router.post('/', async (req, res) => {
  try {
    const { name, email, phone, pin, vehicleType, plateNumber, vehicleColor } = req.body;

    // Validate required fields
    if (!name || !email || !phone || !pin) {
      return res.status(400).json({
        success: false,
        message: 'Please provide name, email, phone, and PIN'
      });
    }

    // Check if driver already exists
    const existingDriver = await PinDriver.findOne({ 
      $or: [{ email }, { phone }] 
    });

    if (existingDriver) {
      return res.status(400).json({
        success: false,
        message: 'Driver with this email or phone already exists'
      });
    }

    // Generate unique driver ID
    const driverCount = await PinDriver.countDocuments();
    const driverId = `DRV${Date.now()}${String(driverCount + 1).padStart(4, '0')}`;

    // Hash PIN
    const hashedPin = await bcrypt.hash(pin, 10);

    // Create driver
    const driver = await PinDriver.create({
      driverId,
      name,
      email,
      phone,
      pin: hashedPin,
      vehicleInfo: {
        type: vehicleType || 'car',
        plateNumber: plateNumber || '',
        color: vehicleColor || ''
      },
      status: 'offline',
      isActive: true
    });

    // Return driver without PIN
    const driverResponse = driver.toObject();
    delete driverResponse.pin;

    res.status(201).json({
      success: true,
      message: 'Driver created successfully',
      driver: driverResponse
    });
  } catch (error) {
    console.error('Error creating driver:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create driver',
      error: error.message
    });
  }
});

// @desc    Update driver
// @route   PUT /api/admin/drivers/:id
// @access  Private (Admin)
router.put('/:id', async (req, res) => {
  try {
    const { name, email, phone, vehicleType, plateNumber, vehicleColor, status, isActive } = req.body;

    const driver = await PinDriver.findById(req.params.id);

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    // Update fields
    if (name) driver.name = name;
    if (email) driver.email = email;
    if (phone) driver.phone = phone;
    if (status) driver.status = status;
    if (typeof isActive !== 'undefined') driver.isActive = isActive;

    // Update vehicle info
    if (vehicleType) driver.vehicleInfo.type = vehicleType;
    if (plateNumber) driver.vehicleInfo.plateNumber = plateNumber;
    if (vehicleColor) driver.vehicleInfo.color = vehicleColor;

    driver.updatedAt = Date.now();

    await driver.save();

    // Return driver without PIN
    const driverResponse = driver.toObject();
    delete driverResponse.pin;

    res.json({
      success: true,
      message: 'Driver updated successfully',
      driver: driverResponse
    });
  } catch (error) {
    console.error('Error updating driver:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update driver',
      error: error.message
    });
  }
});

// @desc    Update driver PIN
// @route   PUT /api/admin/drivers/:id/pin
// @access  Private (Admin)
router.put('/:id/pin', async (req, res) => {
  try {
    const { newPin } = req.body;

    if (!newPin || newPin.length !== 4) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid 4-digit PIN'
      });
    }

    const driver = await PinDriver.findById(req.params.id);

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    // Hash new PIN
    driver.pin = await bcrypt.hash(newPin, 10);
    driver.updatedAt = Date.now();

    await driver.save();

    res.json({
      success: true,
      message: 'Driver PIN updated successfully'
    });
  } catch (error) {
    console.error('Error updating driver PIN:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update driver PIN',
      error: error.message
    });
  }
});

// @desc    Delete driver
// @route   DELETE /api/admin/drivers/:id
// @access  Private (Admin)
router.delete('/:id', async (req, res) => {
  try {
    const driver = await PinDriver.findById(req.params.id);

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    await driver.deleteOne();

    res.json({
      success: true,
      message: 'Driver deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting driver:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete driver',
      error: error.message
    });
  }
});

// @desc    Toggle driver active status
// @route   PATCH /api/admin/drivers/:id/toggle-active
// @access  Private (Admin)
router.patch('/:id/toggle-active', async (req, res) => {
  try {
    const driver = await PinDriver.findById(req.params.id);

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    driver.isActive = !driver.isActive;
    driver.updatedAt = Date.now();

    // If deactivating, set status to offline
    if (!driver.isActive) {
      driver.status = 'offline';
    }

    await driver.save();

    const driverResponse = driver.toObject();
    delete driverResponse.pin;

    res.json({
      success: true,
      message: `Driver ${driver.isActive ? 'activated' : 'deactivated'} successfully`,
      driver: driverResponse
    });
  } catch (error) {
    console.error('Error toggling driver status:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle driver status',
      error: error.message
    });
  }
});

// @desc    Get driver delivery history
// @route   GET /api/admin/drivers/:id/deliveries
// @access  Private (Admin)
router.get('/:id/deliveries', async (req, res) => {
  try {
    const driver = await PinDriver.findById(req.params.id);

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    // Get orders assigned to this driver
    const Order = mongoose.model('Order');
    const deliveries = await Order.find({
      assignedDriver: driver.driverId
    })
    .sort({ createdAt: -1 })
    .limit(50)
    .select('orderNumber status totalAmount createdAt deliveryAddress')
    .lean();

    res.json({
      success: true,
      deliveries,
      count: deliveries.length
    });
  } catch (error) {
    console.error('Error fetching driver deliveries:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch driver deliveries',
      error: error.message
    });
  }
});

module.exports = router;
