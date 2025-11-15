const express = require('express');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const Staff = require('../models/Staff');
const Order = require('../models/Order');
const User = require('../models/User');
const pushNotificationService = require('../services/pushNotificationService');
const { protect } = require('../middleware/auth'); // Import admin auth middleware

const router = express.Router();

// ===== HELPER FUNCTIONS =====

// Generate JWT token for staff
const generateStaffToken = (staffId) => {
  return jwt.sign(
    { staffId, role: 'staff' },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE || '7d' }
  );
};

// Staff authentication middleware
const protectStaff = async (req, res, next) => {
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

      // Check if it's a staff token (by staffId or type field)
      if (!decoded.staffId || (decoded.type && decoded.type !== 'staff')) {
        return res.status(401).json({
          success: false,
          message: 'Invalid staff token'
        });
      }

      // Get staff from token
      const staff = await Staff.findById(decoded.staffId);

      if (!staff || staff.isDeleted) {
        return res.status(401).json({
          success: false,
          message: 'Staff not found or deactivated'
        });
      }

      // Check if staff is active
      if (staff.status === 'inactive') {
        return res.status(401).json({
          success: false,
          message: 'Staff account is inactive'
        });
      }

      // Attach staff to request
      req.staff = staff;
      next();
    } catch (error) {
      console.error('Staff token verification failed:', error.message);
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

// ===== AUTHENTICATION ENDPOINTS =====

// @desc    Staff Login
// @route   POST /api/staff/login
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

      // Find staff by firebaseUid
      let staff = await Staff.findOne({ firebaseUid, isDeleted: false });

      // If staff not found, try by email (for first-time Firebase login)
      if (!staff) {
        staff = await Staff.findOne({ email, isDeleted: false });
        
        // If found by email but no firebaseUid, update it
        if (staff && !staff.firebaseUid) {
          staff.firebaseUid = firebaseUid;
          await staff.save();
        }
      }

      if (!staff) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials. Please contact admin to create your staff account.'
        });
      }

      // Check if staff is active
      if (staff.status === 'inactive') {
        return res.status(401).json({
          success: false,
          message: 'Staff account is inactive. Please contact admin.'
        });
      }

      // Generate token
      const token = generateStaffToken(staff._id);

      res.status(200).json({
        success: true,
        message: 'Login successful',
        token,
        staff: {
          id: staff._id,
          name: staff.name,
          email: staff.email,
          phone: staff.phone,
          role: staff.role,
          status: staff.status,
          stats: staff.stats
        }
      });
    } catch (error) {
      console.error('Staff login error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error during login'
      });
    }
  }
);

// @desc    Staff Register (Admin creates staff account)
// @route   POST /api/staff/register
// @access  Public (will be protected by admin in production)
router.post(
  '/register',
  [
    body('name').trim().isLength({ min: 2, max: 100 }).withMessage('Name must be between 2 and 100 characters'),
    body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email'),
    body('phone').notEmpty().withMessage('Phone number is required'),
    body('role').isIn(['barista', 'manager', 'cashier']).withMessage('Invalid role'),
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

      const { name, email, phone, role, firebaseUid } = req.body;

      // Check if staff already exists
      const existingStaff = await Staff.findOne({
        $or: [{ email }, { firebaseUid: firebaseUid || null }],
        isDeleted: false
      });

      if (existingStaff) {
        return res.status(400).json({
          success: false,
          message: 'Staff with this email or Firebase UID already exists'
        });
      }

      // Create staff
      const staff = await Staff.create({
        name,
        email,
        phone,
        role,
        firebaseUid: firebaseUid || `temp_${Date.now()}_${email}`, // Temporary UID if not provided
        status: 'active'
      });

      // Generate token
      const token = generateStaffToken(staff._id);

      res.status(201).json({
        success: true,
        message: 'Staff account created successfully',
        token,
        staff: {
          id: staff._id,
          name: staff.name,
          email: staff.email,
          phone: staff.phone,
          role: staff.role,
          status: staff.status
        }
      });
    } catch (error) {
      console.error('Staff registration error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error during registration'
      });
    }
  }
);

// ===== FCM TOKEN MANAGEMENT =====

// @desc    Update Staff FCM Token
// @route   POST /api/staff/fcm-token
// @access  Private (Staff)
router.post(
  '/fcm-token',
  protectStaff,
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
      await req.staff.updateFcmToken(fcmToken);

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

// @desc    Get Pending Orders for Staff
// @route   GET /api/staff/orders
// @access  Private (Staff)
router.get('/orders', protectStaff, async (req, res) => {
  try {
    const { status } = req.query;

    console.log(`📋 Staff ${req.staff.employeeId} requesting orders with filter: ${status || 'all'}`);

    let query = {};
    let orders;

    if (status === 'pending') {
      // Show all pending/confirmed orders (not completed/cancelled)
      query = {
        status: { $in: ['pending', 'confirmed'] },
        $or: [
          { assignedStaff: null },
          { assignedStaff: req.staff._id }
        ]
      };
    } else if (status === 'completed') {
      // Show completed/delivered orders
      query = {
        status: { $in: ['completed', 'delivered', 'cancelled'] }
      };
    } else {
      // Show all active orders (not completed)
      query = {
        status: { $in: ['pending', 'confirmed', 'accepted', 'preparing', 'ready', 'on-hold', 'out-for-delivery'] }
      };
    }

    orders = await Order.find(query)
      .sort({ createdAt: -1 }) // Newest first
      .populate('user', 'name email phone')
      .populate('items.coffee', 'name price');

    console.log(`📋 Found ${orders.length} orders`);


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
        notes: order.notes,
        assignedStaff: order.assignedStaff,
        statusTimestamps: order.statusTimestamps,
        preparationTime: order.preparationTime,
        createdAt: order.createdAt,
        isAssignedToMe: order.assignedStaff?.toString() === req.staff._id.toString()
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
// @route   GET /api/staff/orders/:id
// @access  Private (Staff)
router.get('/orders/:id', protectStaff, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate('user', 'name email phone')
      .populate('items.coffee', 'name price imageUrl')
      .populate('assignedStaff', 'name role');

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
        staffNotes: order.staffNotes,
        createdAt: order.createdAt,
        isAssignedToMe: order.assignedStaff?.toString() === req.staff._id.toString()
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

// @desc    Accept Order (Assign to Staff)
// @route   POST /api/staff/orders/:id/accept
// @access  Private (Staff)
router.post('/orders/:id/accept', protectStaff, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Check if order is already assigned
    if (order.assignedStaff) {
      return res.status(400).json({
        success: false,
        message: 'Order is already assigned to another staff member'
      });
    }

    // Check if order status is appropriate
    if (order.status !== 'pending' && order.status !== 'confirmed') {
      return res.status(400).json({
        success: false,
        message: `Cannot accept order with status: ${order.status}`
      });
    }

    // Assign order to staff and update status to preparing (auto-start)
    order.assignedStaff = req.staff._id;
    order.status = 'preparing';
    order.statusTimestamps.acceptedByStaff = new Date();
    order.statusTimestamps.preparationStarted = new Date();
    await order.save();

    // Add order to staff's assignment list
    if (!req.staff.assignedOrders.includes(order._id)) {
      req.staff.assignedOrders.push(order._id);
      await req.staff.save();
    }

    // Populate order details for response
    await order.populate('user', 'name email phone');
    await order.populate('items.coffee', 'name price');

    res.status(200).json({
      success: true,
      message: 'Order accepted successfully',
      order: {
        id: order._id,
        orderNumber: order.orderNumber,
        status: order.status,
        assignedStaff: order.assignedStaff,
        statusTimestamps: order.statusTimestamps,
        items: order.items,
        totalAmount: order.totalAmount
      }
    });

    // Send push notification to customer (async - don't block response)
    setImmediate(async () => {
      try {
        const user = await User.findById(order.userId).select('+fcmToken');
        if (user && user.fcmToken) {
          await pushNotificationService.sendToDevices(
            [user.fcmToken],
            {
              title: '✅ Order Accepted!',
              message: `Your order #${order.orderNumber} has been accepted and is now being prepared.`,
              type: 'order_update',
              priority: 'high'
            },
            {
              orderId: order._id.toString(),
              orderNumber: order.orderNumber,
              status: 'preparing',
              screen: 'order_tracking'
            }
          );
          console.log(`📱 Push notification sent to user for order ${order.orderNumber}`);
        }
      } catch (notifError) {
        console.error('❌ Failed to send order accepted notification:', notifError);
      }
    });
  } catch (error) {
    console.error('Accept order error:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Failed to accept order',
      error: error.message
    });
  }
});

// @desc    Update Order Status
// @route   PUT /api/staff/orders/:id/status
// @access  Private (Staff)
router.put('/orders/:id/status', protectStaff, async (req, res) => {
  try {
    const { status } = req.body;
    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Validate status
    const validStatuses = ['accepted', 'preparing', 'ready', 'completed', 'rejected', 'on-hold', 'out-for-delivery'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`
      });
    }

    // Update status and timestamp
    const oldStatus = order.status;
    order.status = status;

    // Set appropriate timestamps
    switch (status) {
      case 'accepted':
        order.statusTimestamps.acceptedByStaff = new Date();
        break;
      case 'preparing':
        order.statusTimestamps.preparationStarted = new Date();
        break;
      case 'ready':
        order.statusTimestamps.preparationCompleted = new Date();
        order.statusTimestamps.markedReady = new Date();
        // Calculate preparation time
        if (order.statusTimestamps.preparationStarted) {
          const startTime = order.statusTimestamps.preparationStarted;
          const endTime = order.statusTimestamps.preparationCompleted;
          order.preparationTime.actualMinutes = Math.round((endTime - startTime) / (1000 * 60));
        }
        break;
      case 'out-for-delivery':
        order.statusTimestamps.outForDelivery = new Date();
        break;
      case 'completed':
        order.statusTimestamps.completed = new Date();
        break;
    }

    await order.save();

    res.status(200).json({
      success: true,
      message: `Order status updated from ${oldStatus} to ${status}`,
      order: {
        id: order._id,
        orderNumber: order.orderNumber,
        status: order.status,
        statusTimestamps: order.statusTimestamps
      }
    });

    // Send push notification to customer based on status (async)
    setImmediate(async () => {
      try {
        const user = await User.findById(order.userId).select('+fcmToken');
        if (user && user.fcmToken) {
          let title, message;
          
          switch (status) {
            case 'preparing':
              title = '👨‍🍳 Order Preparing';
              message = `Your order #${order.orderNumber} is now being prepared by our barista.`;
              break;
            case 'ready':
              title = '✅ Order Ready!';
              message = `Your order #${order.orderNumber} is ready for pickup or delivery.`;
              break;
            case 'out-for-delivery':
              title = '🚚 Out for Delivery!';
              message = `Your order #${order.orderNumber} is on its way! Our driver will be there soon.`;
              break;
            case 'completed':
              title = '🎉 Order Delivered!';
              message = `Your order #${order.orderNumber} has been completed. Enjoy your coffee!`;
              break;
            case 'rejected':
              title = '❌ Order Update';
              message = `Unfortunately, order #${order.orderNumber} could not be processed. Please contact support.`;
              break;
            case 'on-hold':
              title = '⏸️ Order On Hold';
              message = `Your order #${order.orderNumber} is temporarily on hold. We'll update you shortly.`;
              break;
            default:
              return; // Don't send notification for other statuses
          }
          
          await pushNotificationService.sendToDevices(
            [user.fcmToken],
            { title, message, type: 'order_update', priority: 'high' },
            {
              orderId: order._id.toString(),
              orderNumber: order.orderNumber,
              status: status,
              screen: 'order_tracking'
            }
          );
          console.log(`📱 Status notification sent for order ${order.orderNumber}: ${status}`);
        }
      } catch (notifError) {
        console.error('❌ Failed to send status notification:', notifError);
      }
    });
  } catch (error) {
    console.error('Update order status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update order status',
      error: error.message
    });
  }
});

// @desc    Start Preparation
// @route   POST /api/staff/orders/:id/start
// @access  Private (Staff)
router.post('/orders/:id/start', protectStaff, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Check if order is assigned to this staff
    if (order.assignedStaff?.toString() !== req.staff._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'This order is not assigned to you'
      });
    }

    // Check if order status is appropriate
    if (order.status === 'preparing') {
      return res.status(400).json({
        success: false,
        message: 'Order preparation already started'
      });
    }

    if (order.status !== 'pending' && order.status !== 'confirmed') {
      return res.status(400).json({
        success: false,
        message: `Cannot start preparation for order with status: ${order.status}`
      });
    }

    // Start preparation
    await order.startPreparation();

    res.status(200).json({
      success: true,
      message: 'Order preparation started',
      order: {
        id: order._id,
        orderNumber: order.orderNumber,
        status: order.status,
        statusTimestamps: order.statusTimestamps,
        preparationTime: order.preparationTime
      }
    });
  } catch (error) {
    console.error('Start preparation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to start preparation'
    });
  }
});

// @desc    Mark Order Ready
// @route   POST /api/staff/orders/:id/ready
// @access  Private (Staff)
router.post('/orders/:id/ready', protectStaff, async (req, res) => {
  try {
    const { staffNotes } = req.body;

    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Check if order is assigned to this staff
    if (order.assignedStaff?.toString() !== req.staff._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'This order is not assigned to you'
      });
    }

    // Check if order status is appropriate
    if (order.status === 'ready') {
      return res.status(400).json({
        success: false,
        message: 'Order is already marked as ready'
      });
    }

    if (order.status !== 'preparing') {
      return res.status(400).json({
        success: false,
        message: `Cannot mark order ready with status: ${order.status}`
      });
    }

    // Add staff notes if provided
    if (staffNotes) {
      order.staffNotes = staffNotes;
    }

    // Mark order ready (this will calculate actual preparation time)
    await order.markReady();

    // Update staff statistics
    const preparationTime = order.preparationTime.actualMinutes;
    await req.staff.updateStats(preparationTime);

    // Remove order from staff's active assignments
    await req.staff.removeOrder(order._id);

    res.status(200).json({
      success: true,
      message: 'Order marked as ready',
      order: {
        id: order._id,
        orderNumber: order.orderNumber,
        status: order.status,
        statusTimestamps: order.statusTimestamps,
        preparationTime: order.preparationTime,
        staffNotes: order.staffNotes
      }
    });

    // Trigger FCM notification to available drivers
    await pushNotificationService.notifyDriversOrderReady(order).catch(err => {
      console.error('Failed to send driver notification:', err);
    });
  } catch (error) {
    console.error('Mark order ready error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark order as ready'
    });
  }
});

// ===== PROFILE MANAGEMENT =====

// @desc    Get Staff Profile
// @route   GET /api/staff/profile
// @access  Private (Staff)
router.get('/profile', protectStaff, async (req, res) => {
  try {
    const staff = await Staff.findById(req.staff._id)
      .populate('assignedOrders', 'orderNumber status totalAmount createdAt');

    res.status(200).json({
      success: true,
      staff: {
        id: staff._id,
        name: staff.name,
        email: staff.email,
        phone: staff.phone,
        role: staff.role,
        status: staff.status,
        assignedOrders: staff.assignedOrders,
        stats: staff.stats,
        createdAt: staff.createdAt
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

// @desc    Update Staff Status
// @route   PUT /api/staff/status
// @access  Private (Staff)
router.put(
  '/status',
  protectStaff,
  [body('status').isIn(['active', 'on_break']).withMessage('Invalid status')],
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

      // Check if staff has active orders and trying to go on break
      if (status === 'on_break' && req.staff.assignedOrders.length > 0) {
        return res.status(400).json({
          success: false,
          message: 'Cannot go on break with active orders. Please complete or reassign your orders first.',
          activeOrders: req.staff.assignedOrders.length
        });
      }

      // Update status
      await req.staff.updateStatus(status);

      res.status(200).json({
        success: true,
        message: `Status updated to ${status}`,
        status: req.staff.status
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

// @desc    Get Staff Statistics
// @route   GET /api/staff/stats
// @access  Private (Staff)
router.get('/stats', protectStaff, async (req, res) => {
  try {
    const staff = await Staff.findById(req.staff._id);

    // Get today's completed orders
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const todayOrders = await Order.find({
      assignedStaff: staff._id,
      status: { $in: ['ready', 'delivered'] },
      'statusTimestamps.markedReady': { $gte: todayStart }
    });

    // Get this week's completed orders
    const weekStart = new Date();
    weekStart.setDate(weekStart.getDate() - weekStart.getDay());
    weekStart.setHours(0, 0, 0, 0);

    const weekOrders = await Order.find({
      assignedStaff: staff._id,
      status: { $in: ['ready', 'delivered'] },
      'statusTimestamps.markedReady': { $gte: weekStart }
    });

    res.status(200).json({
      success: true,
      stats: {
        overall: {
          totalOrdersProcessed: staff.stats.totalOrdersProcessed,
          averagePreparationTime: staff.stats.averagePreparationTime,
          lastOrderProcessedAt: staff.stats.lastOrderProcessedAt
        },
        today: {
          ordersProcessed: staff.stats.ordersProcessedToday,
          orders: todayOrders.length
        },
        thisWeek: {
          ordersProcessed: weekOrders.length
        },
        current: {
          activeOrders: staff.assignedOrders.length,
          status: staff.status
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

// ===== Admin Panel Credential Management (Admin Only) =====

/**
 * @route   POST /api/staff/:staffId/admin-credentials
 * @desc    Set or update admin panel credentials for a staff member
 * @access  Private (Admin only)
 */
router.post(
  '/:staffId/admin-credentials',
  protect,
  [
    body('username')
      .notEmpty().withMessage('Admin username is required')
      .isLength({ min: 4 }).withMessage('Username must be at least 4 characters')
      .matches(/^[a-zA-Z0-9_]+$/).withMessage('Username can only contain letters, numbers, and underscores'),
    body('password')
      .notEmpty().withMessage('Admin password is required')
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

      const { staffId } = req.params;
      const { username, password } = req.body;

      // Find staff member
      const staff = await Staff.findById(staffId);

      if (!staff) {
        return res.status(404).json({
          success: false,
          message: 'Staff member not found'
        });
      }

      // Check if username is already taken by another staff member
      const existingStaff = await Staff.findOne({
        adminUsername: username.toLowerCase().trim(),
        _id: { $ne: staffId }
      });

      if (existingStaff) {
        return res.status(400).json({
          success: false,
          message: 'This username is already taken by another staff member'
        });
      }

      // Set admin credentials
      await staff.setAdminCredentials(username, password);

      res.json({
        success: true,
        message: 'Admin panel credentials set successfully',
        staff: {
          id: staff._id,
          name: staff.name,
          employeeId: staff.employeeId,
          adminUsername: staff.adminUsername,
          hasAdminAccess: staff.hasAdminAccess
        }
      });

    } catch (error) {
      console.error('Set admin credentials error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to set admin credentials',
        error: error.message
      });
    }
  }
);

/**
 * @route   DELETE /api/staff/:staffId/admin-credentials
 * @desc    Remove admin panel access from a staff member
 * @access  Private (Admin only)
 */
router.delete(
  '/:staffId/admin-credentials',
  protect,
  async (req, res) => {
    try {
      const { staffId } = req.params;

      // Find staff member
      const staff = await Staff.findById(staffId);

      if (!staff) {
        return res.status(404).json({
          success: false,
          message: 'Staff member not found'
        });
      }

      if (!staff.hasAdminAccess) {
        return res.status(400).json({
          success: false,
          message: 'Staff member does not have admin panel access'
        });
      }

      // Remove admin access
      await staff.removeAdminAccess();

      res.json({
        success: true,
        message: 'Admin panel access removed successfully',
        staff: {
          id: staff._id,
          name: staff.name,
          employeeId: staff.employeeId,
          hasAdminAccess: false
        }
      });

    } catch (error) {
      console.error('Remove admin credentials error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to remove admin credentials',
        error: error.message
      });
    }
  }
);

module.exports = router;
