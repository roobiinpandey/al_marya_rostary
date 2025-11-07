const express = require('express');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const Driver = require('../models/Driver');
const Order = require('../models/Order');
const pushNotificationService = require('../services/pushNotificationService');

const router = express.Router();

// ===== HELPER FUNCTIONS =====

// Generate JWT token for driver
const generateDriverToken = (driverId) => {
  return jwt.sign(
    { driverId, role: 'driver' },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE || '7d' }
  );
};

// Driver authentication middleware
const protectDriver = async (req, res, next) => {
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

      if (!decoded.driverId || decoded.role !== 'driver') {
        return res.status(401).json({
          success: false,
          message: 'Invalid driver token'
        });
      }

      // Get driver from token
      const driver = await Driver.findById(decoded.driverId);

      if (!driver || driver.isDeleted) {
        return res.status(401).json({
          success: false,
          message: 'Driver not found or deactivated'
        });
      }

      // Attach driver to request
      req.driver = driver;
      next();
    } catch (error) {
      console.error('Driver token verification failed:', error.message);
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired token'
      });
    }
  } catch (error) {
    console.error('Driver auth middleware error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error in authentication'
    });
  }
};

// ===== AUTHENTICATION ENDPOINTS =====

// @desc    Driver Login
// @route   POST /api/driver/login
// @access  Public
router.post(
  '/login',
  [
    body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email'),
    body('firebaseUid').notEmpty().withMessage('Firebase UID is required')
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

      const { email, firebaseUid } = req.body;

      // Find driver by firebaseUid
      let driver = await Driver.findOne({ firebaseUid, isDeleted: false });

      // If driver not found, try by email (for first-time Firebase login)
      if (!driver) {
        driver = await Driver.findOne({ email, isDeleted: false });
        
        // If found by email but no firebaseUid, update it
        if (driver && !driver.firebaseUid) {
          driver.firebaseUid = firebaseUid;
          await driver.save();
        }
      }

      if (!driver) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials. Please contact admin to create your driver account.'
        });
      }

      // Generate token
      const token = generateDriverToken(driver._id);

      res.status(200).json({
        success: true,
        message: 'Login successful',
        token,
        driver: {
          id: driver._id,
          name: driver.name,
          email: driver.email,
          phone: driver.phone,
          vehicleType: driver.vehicleType,
          vehicleNumber: driver.vehicleNumber,
          status: driver.status,
          stats: driver.stats,
          currentLocation: driver.currentLocation
        }
      });
    } catch (error) {
      console.error('Driver login error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error during login'
      });
    }
  }
);

// @desc    Driver Register (Admin creates driver account)
// @route   POST /api/driver/register
// @access  Public (will be protected by admin in production)
router.post(
  '/register',
  [
    body('name').trim().isLength({ min: 2, max: 100 }).withMessage('Name must be between 2 and 100 characters'),
    body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email'),
    body('phone').notEmpty().withMessage('Phone number is required'),
    body('vehicleType').isIn(['bike', 'car', 'scooter', 'bicycle']).withMessage('Invalid vehicle type'),
    body('vehicleNumber').notEmpty().withMessage('Vehicle number is required'),
    body('firebaseUid').optional().notEmpty().withMessage('Firebase UID cannot be empty if provided')
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

      const { name, email, phone, vehicleType, vehicleNumber, firebaseUid, vehicleColor, vehicleMake, vehicleModel } = req.body;

      // Check if driver already exists
      const existingDriver = await Driver.findOne({
        $or: [{ email }, { firebaseUid: firebaseUid || null }],
        isDeleted: false
      });

      if (existingDriver) {
        return res.status(400).json({
          success: false,
          message: 'Driver with this email or Firebase UID already exists'
        });
      }

      // Create driver
      const driver = await Driver.create({
        name,
        email,
        phone,
        vehicleType,
        vehicleNumber: vehicleNumber.toUpperCase(),
        vehicleColor,
        vehicleMake,
        vehicleModel,
        firebaseUid: firebaseUid || `temp_${Date.now()}_${email}`, // Temporary UID if not provided
        status: 'offline' // Default to offline until driver goes online
      });

      // Generate token
      const token = generateDriverToken(driver._id);

      res.status(201).json({
        success: true,
        message: 'Driver account created successfully',
        token,
        driver: {
          id: driver._id,
          name: driver.name,
          email: driver.email,
          phone: driver.phone,
          vehicleType: driver.vehicleType,
          vehicleNumber: driver.vehicleNumber,
          status: driver.status
        }
      });
    } catch (error) {
      console.error('Driver registration error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error during registration'
      });
    }
  }
);

// ===== FCM TOKEN MANAGEMENT =====

// @desc    Update Driver FCM Token
// @route   POST /api/driver/fcm-token
// @access  Private (Driver)
router.post(
  '/fcm-token',
  protectDriver,
  [body('fcmToken').notEmpty().withMessage('FCM token is required')],
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

      const { fcmToken } = req.body;

      // Update FCM token
      await req.driver.updateFcmToken(fcmToken);

      res.status(200).json({
        success: true,
        message: 'FCM token updated successfully'
      });
    } catch (error) {
      console.error('FCM token update error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update FCM token'
      });
    }
  }
);

// ===== ORDER MANAGEMENT ENDPOINTS =====

// @desc    Get Available Orders for Driver
// @route   GET /api/driver/orders
// @access  Private (Driver)
router.get('/orders', protectDriver, async (req, res) => {
  try {
    const { status } = req.query;

    let orders;

    if (status === 'available') {
      // Get ready orders waiting for driver
      orders = await Order.findReadyForDriver();
    } else if (status === 'my-deliveries') {
      // Get orders assigned to this driver
      orders = await Order.findByDriver(req.driver._id);
    } else {
      // Get both: available + assigned to this driver
      const availableOrders = await Order.findReadyForDriver();
      const myOrders = await Order.findByDriver(req.driver._id);
      orders = [...availableOrders, ...myOrders];
    }

    res.status(200).json({
      success: true,
      count: orders.length,
      orders: orders.map(order => ({
        id: order._id,
        orderNumber: order.orderNumber,
        user: order.user,
        items: order.items,
        totalAmount: order.totalAmount,
        status: order.status,
        deliveryMethod: order.deliveryMethod,
        deliveryAddress: order.deliveryAddress,
        assignedStaff: order.assignedStaff,
        assignedDriver: order.assignedDriver,
        statusTimestamps: order.statusTimestamps,
        preparationTime: order.preparationTime,
        deliveryTime: order.deliveryTime,
        driverTracking: order.driverTracking,
        createdAt: order.createdAt,
        isAssignedToMe: order.assignedDriver?.toString() === req.driver._id.toString()
      }))
    });
  } catch (error) {
    console.error('Get orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch orders'
    });
  }
});

// @desc    Get Order Details
// @route   GET /api/driver/orders/:id
// @access  Private (Driver)
router.get('/orders/:id', protectDriver, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate('user', 'name email phone')
      .populate('items.coffee', 'name price imageUrl')
      .populate('assignedStaff', 'name role')
      .populate('assignedDriver', 'name vehicleType vehicleNumber');

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    res.status(200).json({
      success: true,
      order: {
        id: order._id,
        orderNumber: order.orderNumber,
        user: order.user,
        items: order.items,
        totalAmount: order.totalAmount,
        status: order.status,
        deliveryMethod: order.deliveryMethod,
        deliveryAddress: order.deliveryAddress,
        assignedStaff: order.assignedStaff,
        assignedDriver: order.assignedDriver,
        statusTimestamps: order.statusTimestamps,
        preparationTime: order.preparationTime,
        deliveryTime: order.deliveryTime,
        driverTracking: order.driverTracking,
        driverNotes: order.driverNotes,
        createdAt: order.createdAt,
        isAssignedToMe: order.assignedDriver?.toString() === req.driver._id.toString()
      }
    });
  } catch (error) {
    console.error('Get order details error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch order details'
    });
  }
});

// @desc    Accept Delivery (Assign to Driver)
// @route   POST /api/driver/orders/:id/accept
// @access  Private (Driver)
router.post('/orders/:id/accept', protectDriver, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Check if driver is available
    if (!req.driver.isAvailable()) {
      return res.status(400).json({
        success: false,
        message: 'Cannot accept order. You must be available and not have an active delivery.'
      });
    }

    // Check if order is already assigned to a driver
    if (order.assignedDriver) {
      return res.status(400).json({
        success: false,
        message: 'Order is already assigned to another driver'
      });
    }

    // Check if order status is appropriate (should be ready)
    if (order.status !== 'ready') {
      return res.status(400).json({
        success: false,
        message: `Cannot accept order with status: ${order.status}. Order must be ready.`
      });
    }

    // Assign order to driver
    await order.assignToDriver(req.driver._id);

    // Start delivery on driver side
    await req.driver.startDelivery(order._id);

    // Populate order details for response
    await order.populate('user', 'name email phone');
    await order.populate('items.coffee', 'name price');

    res.status(200).json({
      success: true,
      message: 'Delivery accepted successfully',
      order: {
        id: order._id,
        orderNumber: order.orderNumber,
        status: order.status,
        assignedDriver: order.assignedDriver,
        statusTimestamps: order.statusTimestamps,
        items: order.items,
        totalAmount: order.totalAmount,
        deliveryAddress: order.deliveryAddress,
        deliveryTime: order.deliveryTime
      }
    });

    // Trigger FCM notification to customer
    await pushNotificationService.notifyCustomerDriverAssigned(order, req.driver).catch(err => {
      console.error('Failed to send customer notification:', err);
    });
  } catch (error) {
    console.error('Accept delivery error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to accept delivery'
    });
  }
});

// @desc    Mark Order Picked Up
// @route   POST /api/driver/orders/:id/pickup
// @access  Private (Driver)
router.post('/orders/:id/pickup', protectDriver, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Check if order is assigned to this driver
    if (order.assignedDriver?.toString() !== req.driver._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'This order is not assigned to you'
      });
    }

    // Check if order status is appropriate
    if (order.status !== 'ready') {
      return res.status(400).json({
        success: false,
        message: `Cannot pick up order with status: ${order.status}`
      });
    }

    // Check if driver has active delivery
    if (req.driver.activeDelivery && req.driver.activeDelivery.toString() !== order._id.toString()) {
      return res.status(400).json({
        success: false,
        message: 'You already have an active delivery'
      });
    }

    // Mark order picked up
    await order.markPickedUp();

    res.status(200).json({
      success: true,
      message: 'Order marked as picked up',
      order: {
        id: order._id,
        orderNumber: order.orderNumber,
        status: order.status,
        statusTimestamps: order.statusTimestamps,
        deliveryTime: order.deliveryTime
      }
    });

    // TODO: Trigger FCM notification to customer
    // notifyCustomerOrderPickedUp(order);
  } catch (error) {
    console.error('Mark pickup error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark order as picked up'
    });
  }
});

// @desc    Deliver Order (Complete Delivery)
// @route   POST /api/driver/orders/:id/deliver
// @access  Private (Driver)
router.post('/orders/:id/deliver', protectDriver, async (req, res) => {
  try {
    const { driverNotes } = req.body;

    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Check if order is assigned to this driver
    if (order.assignedDriver?.toString() !== req.driver._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'This order is not assigned to you'
      });
    }

    // Check if order was picked up
    if (!order.statusTimestamps.pickedUpByDriver) {
      return res.status(400).json({
        success: false,
        message: 'Order must be picked up before delivery'
      });
    }

    // Check if order status is appropriate
    if (order.status === 'delivered') {
      return res.status(400).json({
        success: false,
        message: 'Order is already marked as delivered'
      });
    }

    // Add driver notes if provided
    if (driverNotes) {
      order.driverNotes = driverNotes;
    }

    // Complete delivery (this will calculate actual delivery time)
    await order.completeDelivery();

    // Calculate delivery earnings (simplified - can be enhanced with distance-based calculation)
    const deliveryFee = order.deliveryFee || 15; // Default AED 15
    const deliveryTime = order.deliveryTime.actualMinutes;

    // Update driver statistics
    await req.driver.completeDelivery(deliveryTime, deliveryFee);

    res.status(200).json({
      success: true,
      message: 'Order delivered successfully',
      order: {
        id: order._id,
        orderNumber: order.orderNumber,
        status: order.status,
        statusTimestamps: order.statusTimestamps,
        deliveryTime: order.deliveryTime,
        driverNotes: order.driverNotes
      },
      earnings: deliveryFee
    });

    // Trigger FCM notification to customer
    await pushNotificationService.notifyCustomerDelivered(order).catch(err => {
      console.error('Failed to send customer notification:', err);
    });
  } catch (error) {
    console.error('Deliver order error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to complete delivery'
    });
  }
});

// ===== GPS LOCATION TRACKING =====

// @desc    Update Driver Location
// @route   POST /api/driver/location
// @access  Private (Driver)
router.post(
  '/location',
  protectDriver,
  [
    body('latitude').isFloat({ min: -90, max: 90 }).withMessage('Invalid latitude'),
    body('longitude').isFloat({ min: -180, max: 180 }).withMessage('Invalid longitude'),
    body('accuracy').optional().isFloat({ min: 0 }).withMessage('Accuracy must be positive'),
    body('heading').optional().isFloat({ min: 0, max: 360 }).withMessage('Heading must be 0-360'),
    body('speed').optional().isFloat({ min: 0 }).withMessage('Speed must be positive')
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

      const { latitude, longitude, accuracy, heading, speed } = req.body;

      // Update driver's current location
      await req.driver.updateLocation(latitude, longitude, accuracy, heading, speed);

      // If driver has active delivery, update order's driver tracking
      if (req.driver.activeDelivery) {
        const order = await Order.findById(req.driver.activeDelivery);
        if (order) {
          await order.updateDriverLocation(latitude, longitude, accuracy, heading, speed);
        }
      }

      res.status(200).json({
        success: true,
        message: 'Location updated successfully',
        location: {
          latitude,
          longitude,
          accuracy,
          heading,
          speed,
          updatedAt: new Date()
        }
      });

      // Trigger FCM notification to customer (throttled to every 2 minutes)
      if (req.driver.activeDelivery) {
        const order = await Order.findById(req.driver.activeDelivery);
        if (order) {
          await pushNotificationService.notifyCustomerLocationUpdate(order, { latitude, longitude }).catch(err => {
            console.error('Failed to send location notification:', err);
          });
        }
      }
    } catch (error) {
      console.error('Update location error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update location'
      });
    }
  }
);

// @desc    Get Driver Location for Order
// @route   GET /api/driver/location/:orderId
// @access  Public (for customer tracking)
router.get('/location/:orderId', async (req, res) => {
  try {
    const order = await Order.findById(req.params.orderId)
      .populate('assignedDriver', 'name vehicleType vehicleNumber vehicleColor currentLocation');

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    if (!order.assignedDriver) {
      return res.status(404).json({
        success: false,
        message: 'No driver assigned to this order yet'
      });
    }

    // Check if order is in delivery status
    if (!['ready', 'preparing', 'delivered'].includes(order.status) || 
        !order.statusTimestamps.pickedUpByDriver) {
      return res.status(400).json({
        success: false,
        message: 'Order is not in delivery status'
      });
    }

    const driver = order.assignedDriver;
    const driverLocation = order.driverTracking?.currentLocation || driver.currentLocation;

    res.status(200).json({
      success: true,
      driver: {
        name: driver.name,
        vehicleType: driver.vehicleType,
        vehicleNumber: driver.vehicleNumber,
        vehicleColor: driver.vehicleColor
      },
      location: {
        latitude: driverLocation?.latitude,
        longitude: driverLocation?.longitude,
        accuracy: driverLocation?.accuracy,
        heading: driverLocation?.heading,
        speed: driverLocation?.speed,
        updatedAt: driverLocation?.updatedAt
      },
      estimatedArrival: order.driverTracking?.estimatedArrival,
      distanceRemaining: order.driverTracking?.distanceRemaining
    });
  } catch (error) {
    console.error('Get driver location error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch driver location'
    });
  }
});

// ===== PROFILE MANAGEMENT =====

// @desc    Get Driver Profile
// @route   GET /api/driver/profile
// @access  Private (Driver)
router.get('/profile', protectDriver, async (req, res) => {
  try {
    const driver = await Driver.findById(req.driver._id)
      .populate('activeDelivery', 'orderNumber status totalAmount deliveryAddress createdAt');

    res.status(200).json({
      success: true,
      driver: {
        id: driver._id,
        name: driver.name,
        email: driver.email,
        phone: driver.phone,
        vehicleType: driver.vehicleType,
        vehicleNumber: driver.vehicleNumber,
        vehicleColor: driver.vehicleColor,
        vehicleMake: driver.vehicleMake,
        vehicleModel: driver.vehicleModel,
        status: driver.status,
        currentLocation: driver.currentLocation,
        activeDelivery: driver.activeDelivery,
        stats: driver.stats,
        ratings: driver.ratings.slice(-10), // Last 10 ratings
        availability: driver.availability,
        documents: driver.documents,
        createdAt: driver.createdAt
      }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch profile'
    });
  }
});

// @desc    Update Driver Status
// @route   PUT /api/driver/status
// @access  Private (Driver)
router.put(
  '/status',
  protectDriver,
  [body('status').isIn(['available', 'offline']).withMessage('Invalid status. Must be available or offline.')],
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

      const { status } = req.body;

      // Check if driver has active delivery and trying to go offline
      if (status === 'offline' && req.driver.activeDelivery) {
        return res.status(400).json({
          success: false,
          message: 'Cannot go offline with an active delivery. Please complete your delivery first.',
          activeDelivery: req.driver.activeDelivery
        });
      }

      // Update status
      await req.driver.updateStatus(status);

      res.status(200).json({
        success: true,
        message: `Status updated to ${status}`,
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

// ===== STATISTICS =====

// @desc    Get Driver Statistics
// @route   GET /api/driver/stats
// @access  Private (Driver)
router.get('/stats', protectDriver, async (req, res) => {
  try {
    const driver = await Driver.findById(req.driver._id);

    // Get today's completed deliveries
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const todayDeliveries = await Order.find({
      assignedDriver: driver._id,
      status: 'delivered',
      'statusTimestamps.delivered': { $gte: todayStart }
    });

    // Get this week's completed deliveries
    const weekStart = new Date();
    weekStart.setDate(weekStart.getDate() - weekStart.getDay());
    weekStart.setHours(0, 0, 0, 0);

    const weekDeliveries = await Order.find({
      assignedDriver: driver._id,
      status: 'delivered',
      'statusTimestamps.delivered': { $gte: weekStart }
    });

    // Get this month's completed deliveries
    const monthStart = new Date();
    monthStart.setDate(1);
    monthStart.setHours(0, 0, 0, 0);

    const monthDeliveries = await Order.find({
      assignedDriver: driver._id,
      status: 'delivered',
      'statusTimestamps.delivered': { $gte: monthStart }
    });

    res.status(200).json({
      success: true,
      stats: {
        overall: {
          totalDeliveries: driver.stats.totalDeliveries,
          totalEarnings: driver.stats.totalEarnings,
          averageDeliveryTime: driver.stats.averageDeliveryTime,
          averageRating: driver.stats.averageRating,
          totalRatings: driver.stats.totalRatings,
          lastDeliveryAt: driver.stats.lastDeliveryAt
        },
        today: {
          deliveries: driver.stats.completedToday,
          earnings: driver.stats.earningsToday,
          actualDeliveries: todayDeliveries.length
        },
        thisWeek: {
          deliveries: driver.stats.completedThisWeek,
          earnings: driver.stats.earningsThisWeek,
          actualDeliveries: weekDeliveries.length
        },
        thisMonth: {
          deliveries: driver.stats.completedThisMonth,
          earnings: driver.stats.earningsThisMonth,
          actualDeliveries: monthDeliveries.length
        },
        current: {
          status: driver.status,
          hasActiveDelivery: driver.activeDelivery !== null,
          activeDelivery: driver.activeDelivery,
          locationUpdatedAt: driver.currentLocation?.updatedAt
        }
      }
    });
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch statistics'
    });
  }
});

module.exports = router;
