/**
 * Real-Time Tracking Service
 * Handles driver location updates, order status changes, and payment confirmations
 */

const Order = require('../models/Order');

class TrackingService {
  constructor(socketServer) {
    this.socketServer = socketServer;
    this.setupEventListeners();
  }

  /**
   * Setup internal event listeners from Socket.IO
   */
  setupEventListeners() {
    const io = this.socketServer.io;

    // Driver location update
    io.on('internal_driver_location_update', async (data) => {
      await this.handleDriverLocationUpdate(data);
    });

    // Payment confirmation
    io.on('internal_payment_confirm', async (data) => {
      await this.handlePaymentConfirmation(data);
    });

    console.log('📡 Tracking service event listeners initialized');
  }

  /**
   * Handle driver location update
   */
  async handleDriverLocationUpdate(data) {
    try {
      const { orderId, driverId, currentLocation } = data;

      // Find and update order
      const order = await Order.findById(orderId);
      
      if (!order) {
        console.error(`Order not found: ${orderId}`);
        return;
      }

      // Verify driver assignment
      if (order.assignedDriver && order.assignedDriver.toString() !== driverId) {
        console.error(`Driver ${driverId} not assigned to order ${orderId}`);
        return;
      }

      // Update driver tracking
      if (!order.driverTracking) {
        order.driverTracking = {};
      }

      order.driverTracking.currentLocation = {
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
        accuracy: currentLocation.accuracy,
        heading: currentLocation.heading,
        speed: currentLocation.speed,
        updatedAt: currentLocation.updatedAt || new Date(),
      };

      // Add to location history (optional - for route replay)
      if (!order.locationHistory) {
        order.locationHistory = [];
      }
      
      order.locationHistory.push({
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
        timestamp: new Date(),
      });

      // Keep only last 100 points to avoid bloating
      if (order.locationHistory.length > 100) {
        order.locationHistory = order.locationHistory.slice(-100);
      }

      // Calculate ETA if delivery location exists
      if (order.deliveryAddress?.gps) {
        const eta = this.calculateETA(
          currentLocation,
          order.deliveryAddress.gps,
          currentLocation.speed
        );
        order.driverTracking.estimatedArrival = eta;
      }

      await order.save();

      console.log(`📍 Driver location updated for order ${orderId}`);
    } catch (error) {
      console.error('Error handling driver location update:', error);
    }
  }

  /**
   * Handle payment confirmation (COD)
   */
  async handlePaymentConfirmation(data) {
    try {
      const { orderId, driverId, method, confirmed, amount } = data;

      const order = await Order.findById(orderId);
      
      if (!order) {
        console.error(`Order not found: ${orderId}`);
        return;
      }

      // Verify driver assignment
      if (order.assignedDriver && order.assignedDriver.toString() !== driverId) {
        console.error(`Driver ${driverId} not assigned to order ${orderId}`);
        return;
      }

      // Update payment status
      if (confirmed) {
        order.paymentStatus = 'paid';
        order.paidAt = new Date();
        order.paymentMethod = method || order.paymentMethod;
        
        if (amount) {
          order.paidAmount = amount;
        }

        await order.save();

        // Broadcast payment update to all clients
        this.socketServer.emitPaymentUpdate(orderId, {
          paymentStatus: 'paid',
          paymentMethod: order.paymentMethod,
          paidAt: order.paidAt,
          amount: order.totalAmount,
        });

        console.log(`💳 Payment confirmed for order ${orderId} via ${method}`);
      }
    } catch (error) {
      console.error('Error handling payment confirmation:', error);
    }
  }

  /**
   * Update order status and broadcast
   */
  async updateOrderStatus(orderId, newStatus, additionalData = {}) {
    try {
      const order = await Order.findById(orderId);
      
      if (!order) {
        throw new Error(`Order not found: ${orderId}`);
      }

      // Update status
      const oldStatus = order.status;
      order.status = newStatus;

      // Update timestamp
      const timestampKey = this.getTimestampKey(newStatus);
      if (timestampKey && order.statusTimestamps) {
        order.statusTimestamps[timestampKey] = new Date();
      }

      // Apply additional data
      Object.assign(order, additionalData);

      await order.save();

      // Broadcast to all connected clients
      this.socketServer.emitOrderStatusUpdate(orderId, newStatus, {
        oldStatus,
        timestamp: new Date(),
        ...additionalData,
      });

      console.log(`📦 Order ${orderId} status: ${oldStatus} → ${newStatus}`);

      return order;
    } catch (error) {
      console.error('Error updating order status:', error);
      throw error;
    }
  }

  /**
   * Assign driver and broadcast
   */
  async assignDriver(orderId, driverId, driverData) {
    try {
      const order = await Order.findById(orderId);
      
      if (!order) {
        throw new Error(`Order not found: ${orderId}`);
      }

      order.assignedDriver = driverId;
      order.statusTimestamps.acceptedByDriver = new Date();
      
      await order.save();

      // Broadcast driver assignment
      this.socketServer.emitDriverAssigned(orderId, {
        id: driverId,
        ...driverData,
      });

      console.log(`🚗 Driver ${driverId} assigned to order ${orderId}`);

      return order;
    } catch (error) {
      console.error('Error assigning driver:', error);
      throw error;
    }
  }

  /**
   * Calculate ETA based on distance and speed
   */
  calculateETA(currentLocation, destinationLocation, speed) {
    if (!speed || speed === 0) {
      // Default to 30 minutes if no speed data
      return new Date(Date.now() + 30 * 60 * 1000);
    }

    // Calculate distance using Haversine formula
    const R = 6371; // Earth radius in km
    const dLat = this.toRad(destinationLocation.latitude - currentLocation.latitude);
    const dLon = this.toRad(destinationLocation.longitude - currentLocation.longitude);
    
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(this.toRad(currentLocation.latitude)) * 
              Math.cos(this.toRad(destinationLocation.latitude)) *
              Math.sin(dLon / 2) * Math.sin(dLon / 2);
    
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c; // Distance in km

    // Calculate time in hours, then convert to milliseconds
    const timeInHours = distance / speed;
    const timeInMs = timeInHours * 60 * 60 * 1000;

    return new Date(Date.now() + timeInMs);
  }

  toRad(deg) {
    return deg * (Math.PI / 180);
  }

  /**
   * Get timestamp key for status
   */
  getTimestampKey(status) {
    const mapping = {
      'pending': 'placed',
      'confirmed': 'confirmed',
      'preparing': 'preparationStarted',
      'ready': 'markedReady',
      'assigned': 'acceptedByDriver',
      'out-for-delivery': 'outForDelivery',
      'delivered': 'delivered',
      'cancelled': 'cancelled',
    };
    return mapping[status];
  }

  /**
   * Get tracking data for an order
   */
  async getTrackingData(orderId) {
    try {
      const order = await Order.findById(orderId)
        .populate('assignedDriver', 'name phone profileImage')
        .lean();

      if (!order) {
        throw new Error('Order not found');
      }

      return {
        orderId: order._id,
        orderNumber: order.orderNumber,
        status: order.status,
        paymentStatus: order.paymentStatus,
        paymentMethod: order.paymentMethod,
        driverTracking: order.driverTracking,
        deliveryAddress: order.deliveryAddress,
        assignedDriver: order.assignedDriver,
        statusTimestamps: order.statusTimestamps,
        estimatedDelivery: this.calculateEstimatedDelivery(order),
      };
    } catch (error) {
      console.error('Error getting tracking data:', error);
      throw error;
    }
  }

  /**
   * Calculate estimated delivery time
   */
  calculateEstimatedDelivery(order) {
    if (order.driverTracking?.estimatedArrival) {
      return {
        start: order.driverTracking.estimatedArrival,
        end: new Date(order.driverTracking.estimatedArrival.getTime() + 10 * 60 * 1000), // +10 min window
      };
    }

    // Default estimate based on status
    const now = new Date();
    if (order.status === 'preparing') {
      return {
        start: new Date(now.getTime() + 20 * 60 * 1000), // +20 min
        end: new Date(now.getTime() + 40 * 60 * 1000), // +40 min
      };
    } else if (order.status === 'out-for-delivery') {
      return {
        start: new Date(now.getTime() + 10 * 60 * 1000), // +10 min
        end: new Date(now.getTime() + 30 * 60 * 1000), // +30 min
      };
    }

    return {
      start: new Date(now.getTime() + 30 * 60 * 1000), // +30 min
      end: new Date(now.getTime() + 60 * 60 * 1000), // +60 min
    };
  }
}

module.exports = TrackingService;
