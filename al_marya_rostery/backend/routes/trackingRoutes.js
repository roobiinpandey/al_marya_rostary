/**
 * Real-Time Tracking API Routes
 * Endpoints for order tracking, driver updates, and payment confirmations
 */

const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const Order = require('../models/Order');

/**
 * @route   GET /api/tracking/:orderId
 * @desc    Get real-time tracking data for an order
 * @access  Private
 */
router.get('/:orderId', protect, async (req, res) => {
  try {
    const { orderId } = req.params;
    const trackingService = req.app.get('trackingService');

    if (!trackingService) {
      return res.status(500).json({
        success: false,
        message: 'Tracking service not available',
      });
    }

    const trackingData = await trackingService.getTrackingData(orderId);

    res.json({
      success: true,
      data: trackingData,
    });
  } catch (error) {
    console.error('Error fetching tracking data:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Error fetching tracking data',
    });
  }
});

/**
 * @route   POST /api/tracking/:orderId/status
 * @desc    Update order status (Admin/Staff only)
 * @access  Private (Admin/Staff)
 */
router.post('/:orderId/status', protect, async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status, additionalData } = req.body;

    // Check if user is admin or staff
    if (req.user.role !== 'admin' && req.user.role !== 'staff') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Admin/Staff only.',
      });
    }

    const trackingService = req.app.get('trackingService');

    if (!trackingService) {
      return res.status(500).json({
        success: false,
        message: 'Tracking service not available',
      });
    }

    const order = await trackingService.updateOrderStatus(
      orderId,
      status,
      additionalData || {}
    );

    res.json({
      success: true,
      message: 'Order status updated successfully',
      data: {
        orderId: order._id,
        status: order.status,
        statusTimestamps: order.statusTimestamps,
      },
    });
  } catch (error) {
    console.error('Error updating order status:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Error updating order status',
    });
  }
});

/**
 * @route   POST /api/tracking/:orderId/assign-driver
 * @desc    Assign driver to order
 * @access  Private (Admin/Staff)
 */
router.post('/:orderId/assign-driver', protect, async (req, res) => {
  try {
    const { orderId } = req.params;
    const { driverId, driverData } = req.body;

    // Check if user is admin or staff
    if (req.user.role !== 'admin' && req.user.role !== 'staff') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Admin/Staff only.',
      });
    }

    if (!driverId) {
      return res.status(400).json({
        success: false,
        message: 'Driver ID is required',
      });
    }

    const trackingService = req.app.get('trackingService');

    if (!trackingService) {
      return res.status(500).json({
        success: false,
        message: 'Tracking service not available',
      });
    }

    const order = await trackingService.assignDriver(orderId, driverId, driverData);

    res.json({
      success: true,
      message: 'Driver assigned successfully',
      data: {
        orderId: order._id,
        assignedDriver: order.assignedDriver,
        status: order.status,
      },
    });
  } catch (error) {
    console.error('Error assigning driver:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Error assigning driver',
    });
  }
});

/**
 * @route   POST /api/tracking/:orderId/location
 * @desc    Update driver location (Driver only)
 * @access  Private (Driver)
 */
router.post('/:orderId/location', protect, async (req, res) => {
  try {
    const { orderId } = req.params;
    const { latitude, longitude, accuracy, heading, speed } = req.body;

    // In production, verify driver is assigned to this order
    const order = await Order.findById(orderId);
    
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found',
      });
    }

    // Verify driver assignment (optional - depends on auth implementation)
    // if (order.assignedDriver.toString() !== req.user.id) {
    //   return res.status(403).json({
    //     success: false,
    //     message: 'You are not assigned to this order',
    //   });
    // }

    // Emit location update via Socket.IO
    const socketServer = req.app.get('socketServer');
    
    if (socketServer) {
      socketServer.io.emit('internal_driver_location_update', {
        orderId,
        driverId: req.user.id,
        currentLocation: {
          latitude,
          longitude,
          accuracy,
          heading,
          speed,
          updatedAt: new Date(),
        },
      });
    }

    res.json({
      success: true,
      message: 'Location updated successfully',
    });
  } catch (error) {
    console.error('Error updating driver location:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Error updating driver location',
    });
  }
});

/**
 * @route   GET /api/tracking/driver/active-orders
 * @desc    Get driver's active orders
 * @access  Private (Driver)
 */
router.get('/driver/active-orders', protect, async (req, res) => {
  try {
    const orders = await Order.find({
      assignedDriver: req.user.id,
      status: { $in: ['assigned', 'out-for-delivery'] },
    })
      .populate('customer', 'name phone')
      .populate('items.product', 'name price')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      count: orders.length,
      data: orders,
    });
  } catch (error) {
    console.error('Error fetching active orders:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Error fetching active orders',
    });
  }
});

/**
 * @route   GET /api/tracking/customer/orders
 * @desc    Get customer's orders with tracking
 * @access  Private (Customer)
 */
router.get('/customer/orders', protect, async (req, res) => {
  try {
    const { status } = req.query;

    const query = { customer: req.user.id };
    if (status) {
      query.status = status;
    } else {
      // Default: show active orders
      query.status = { 
        $in: ['pending', 'confirmed', 'preparing', 'ready', 'assigned', 'out-for-delivery'] 
      };
    }

    const orders = await Order.find(query)
      .populate('assignedDriver', 'name phone profileImage')
      .populate('items.product', 'name price images')
      .sort({ createdAt: -1 })
      .limit(20);

    res.json({
      success: true,
      count: orders.length,
      data: orders,
    });
  } catch (error) {
    console.error('Error fetching customer orders:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Error fetching customer orders',
    });
  }
});

module.exports = router;
