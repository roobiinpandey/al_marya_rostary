const admin = require('firebase-admin');
const User = require('../models/User');
const Staff = require('../models/Staff');
const Driver = require('../models/Driver');
const Order = require('../models/Order');
const auditLogger = require('../utils/auditLogger');

class PushNotificationService {
  constructor() {
    this.messaging = null;
    this.initializeFirebase();
    // Throttle mechanism for location updates (orderId -> lastSentTimestamp)
    this.locationUpdateThrottle = new Map();
  }

  /**
   * Initialize Firebase Admin SDK
   */
  initializeFirebase() {
    try {
      // Check if Firebase is already initialized
      if (admin.apps.length === 0) {
        // Initialize Firebase Admin SDK
        // You need to set up your Firebase service account key
        const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
        const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;

        if (serviceAccountPath) {
          // Initialize with service account file
          const serviceAccount = require(serviceAccountPath);
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            projectId: serviceAccount.project_id || process.env.FIREBASE_PROJECT_ID
          });
        } else if (serviceAccountKey) {
          // Initialize with service account key as environment variable
          const serviceAccount = JSON.parse(serviceAccountKey);
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            projectId: serviceAccount.project_id || process.env.FIREBASE_PROJECT_ID
          });
        } else {
          console.warn('⚠️  Firebase service account not configured. Push notifications will be simulated.');
          this.initialized = false;
          return;
        }

        this.initialized = true;
        console.log('✅ Firebase Admin SDK initialized successfully');
      } else {
        this.initialized = true;
        console.log('✅ Firebase Admin SDK already initialized');
      }
    } catch (error) {
      console.error('❌ Firebase initialization error:', error.message);
      this.initialized = false;
    }
  }

  /**
   * Send push notification to specific devices
   * @param {Array} deviceTokens - Array of FCM device tokens
   * @param {Object} notification - Notification data
   * @param {Object} data - Additional data payload
   * @returns {Promise<Object>} Send result
   */
  async sendToDevices(deviceTokens, notification, data = {}) {
    if (!this.initialized) {
      return this.simulateSend(deviceTokens, notification, data);
    }

    try {
      const message = {
        notification: {
          title: notification.title,
          body: notification.message,
          imageUrl: notification.image ? `${process.env.BASE_URL}${notification.image}` : undefined
        },
        data: {
          type: notification.type || 'info',
          priority: notification.priority || 'normal',
          id: notification._id?.toString() || 'unknown',
          ...data
        },
        tokens: deviceTokens.filter(token => token && token.length > 0) // Filter out invalid tokens
      };

      // Add action button if provided
      if (notification.actionButton?.text && notification.actionButton?.link) {
        message.data.actionText = notification.actionButton.text;
        message.data.actionUrl = notification.actionButton.link;
      }

      const response = await admin.messaging().sendMulticast(message);

      // Handle failed tokens
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push({
            token: deviceTokens[idx],
            error: resp.error?.code,
            message: resp.error?.message
          });
        }
      });

      // Clean up invalid tokens
      await this.cleanupInvalidTokens(failedTokens);

      const result = {
        success: true,
        totalSent: deviceTokens.length,
        successCount: response.successCount,
        failureCount: response.failureCount,
        failedTokens: failedTokens
      };

      console.log(`📱 Push notification sent: ${response.successCount}/${deviceTokens.length} successful`);
      return result;

    } catch (error) {
      console.error('❌ Push notification send error:', error);
      return {
        success: false,
        error: error.message,
        totalSent: deviceTokens.length,
        successCount: 0,
        failureCount: deviceTokens.length
      };
    }
  }

  /**
   * Send push notification to specific users
   * @param {Array} userIds - Array of user IDs
   * @param {Object} notification - Notification data
   * @returns {Promise<Object>} Send result
   */
  async sendToUsers(userIds, notification) {
    try {
      // Get device tokens for users
      const users = await User.find({
        _id: { $in: userIds },
        fcmToken: { $exists: true, $ne: null, $ne: '' }
      }).select('fcmToken');

      const deviceTokens = users.map(user => user.fcmToken).filter(token => token);

      if (deviceTokens.length === 0) {
        console.warn('⚠️  No valid device tokens found for users');
        return {
          success: true,
          totalSent: 0,
          successCount: 0,
          failureCount: 0,
          message: 'No devices to send to'
        };
      }

      return await this.sendToDevices(deviceTokens, notification);
    } catch (error) {
      console.error('❌ Send to users error:', error);
      return {
        success: false,
        error: error.message,
        totalSent: 0,
        successCount: 0,
        failureCount: 0
      };
    }
  }

  /**
   * Send push notification based on target audience
   * @param {Object} notification - Notification data with targetAudience
   * @returns {Promise<Object>} Send result
   */
  async sendByAudience(notification) {
    try {
      const { targetAudience, specificUsers } = notification;
      let deviceTokens = [];

      if (specificUsers && specificUsers.length > 0) {
        // Send to specific users
        const result = await this.sendToUsers(specificUsers, notification);
        return result;
      }

      // Build query based on target audience
      let userQuery = { fcmToken: { $exists: true, $ne: null, $ne: '' } };

      if (targetAudience.includes('all')) {
        // Send to all users with FCM tokens - no additional filters
      } else {
        // Build audience-specific query
        const audienceConditions = [];

        if (targetAudience.includes('new-customers')) {
          audienceConditions.push({ createdAt: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) } });
        }

        if (targetAudience.includes('returning-customers')) {
          audienceConditions.push({ lastLogin: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } });
        }

        if (targetAudience.includes('loyal-customers')) {
          audienceConditions.push({ loyaltyPoints: { $gte: 100 } });
        }

        if (audienceConditions.length > 0) {
          userQuery.$or = audienceConditions;
        }
      }

      // Get users matching the audience criteria
      const users = await User.find(userQuery).select('fcmToken');
      deviceTokens = users.map(user => user.fcmToken).filter(token => token);

      if (deviceTokens.length === 0) {
        console.warn('⚠️  No users found matching target audience criteria');
        return {
          success: true,
          totalSent: 0,
          successCount: 0,
          failureCount: 0,
          message: 'No devices matching audience criteria'
        };
      }

      return await this.sendToDevices(deviceTokens, notification);
    } catch (error) {
      console.error('❌ Send by audience error:', error);
      return {
        success: false,
        error: error.message,
        totalSent: 0,
        successCount: 0,
        failureCount: 0
      };
    }
  }

  /**
   * Send push notification to topic subscribers
   * @param {String} topic - FCM topic name
   * @param {Object} notification - Notification data
   * @returns {Promise<Object>} Send result
   */
  async sendToTopic(topic, notification) {
    if (!this.initialized) {
      return this.simulateSend([topic], notification, {}, 'topic');
    }

    try {
      const message = {
        notification: {
          title: notification.title,
          body: notification.message,
          imageUrl: notification.image ? `${process.env.BASE_URL}${notification.image}` : undefined
        },
        data: {
          type: notification.type || 'info',
          priority: notification.priority || 'normal',
          id: notification._id?.toString() || 'unknown'
        },
        topic: topic
      };

      const response = await admin.messaging().send(message);

      console.log(`📱 Push notification sent to topic "${topic}":`, response);
      return {
        success: true,
        messageId: response,
        topic: topic
      };

    } catch (error) {
      console.error('❌ Push notification to topic error:', error);
      return {
        success: false,
        error: error.message,
        topic: topic
      };
    }
  }

  /**
   * Clean up invalid FCM tokens from user records
   * @param {Array} failedTokens - Array of failed token objects
   */
  async cleanupInvalidTokens(failedTokens) {
    try {
      const invalidTokens = failedTokens
        .filter(failure => 
          failure.error === 'messaging/invalid-registration-token' ||
          failure.error === 'messaging/registration-token-not-registered'
        )
        .map(failure => failure.token);

      if (invalidTokens.length > 0) {
        await User.updateMany(
          { fcmToken: { $in: invalidTokens } },
          { $unset: { fcmToken: "" } }
        );
        console.log(`🧹 Cleaned up ${invalidTokens.length} invalid FCM tokens`);
      }
    } catch (error) {
      console.error('❌ Token cleanup error:', error);
    }
  }

  /**
   * Simulate push notification sending (for development/testing)
   */
  async simulateSend(deviceTokens, notification, data = {}, type = 'devices') {
    console.log('🔄 Simulating push notification send...');
    console.log(`📱 Target: ${type === 'topic' ? `Topic "${deviceTokens[0]}"` : `${deviceTokens.length} devices`}`);
    console.log(`📝 Title: ${notification.title}`);
    console.log(`💬 Message: ${notification.message}`);
    console.log(`🏷️  Type: ${notification.type || 'info'}`);

    // Simulate some processing time
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Simulate success with some random failures for realism
    const totalSent = Array.isArray(deviceTokens) ? deviceTokens.length : 1;
    const successCount = Math.max(1, Math.floor(totalSent * 0.95)); // 95% success rate
    const failureCount = totalSent - successCount;

    const result = {
      success: true,
      totalSent,
      successCount,
      failureCount,
      simulated: true,
      message: 'Push notification simulated (Firebase not configured)'
    };

    console.log(`✅ Simulated send complete: ${successCount}/${totalSent} successful`);
    return result;
  }

  /**
   * Subscribe device token to topic
   * @param {String|Array} tokens - FCM token(s)
   * @param {String} topic - Topic name
   */
  async subscribeToTopic(tokens, topic) {
    if (!this.initialized) {
      console.log(`🔄 Simulated subscription of ${Array.isArray(tokens) ? tokens.length : 1} token(s) to topic "${topic}"`);
      return { success: true, simulated: true };
    }

    try {
      const response = await admin.messaging().subscribeToTopic(
        Array.isArray(tokens) ? tokens : [tokens],
        topic
      );
      console.log(`📌 Subscribed to topic "${topic}":`, response);
      return { success: true, response };
    } catch (error) {
      console.error('❌ Topic subscription error:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Unsubscribe device token from topic
   * @param {String|Array} tokens - FCM token(s)
   * @param {String} topic - Topic name
   */
  async unsubscribeFromTopic(tokens, topic) {
    if (!this.initialized) {
      console.log(`🔄 Simulated unsubscription of ${Array.isArray(tokens) ? tokens.length : 1} token(s) from topic "${topic}"`);
      return { success: true, simulated: true };
    }

    try {
      const response = await admin.messaging().unsubscribeFromTopic(
        Array.isArray(tokens) ? tokens : [tokens],
        topic
      );
      console.log(`📌 Unsubscribed from topic "${topic}":`, response);
      return { success: true, response };
    } catch (error) {
      console.error('❌ Topic unsubscription error:', error);
      return { success: false, error: error.message };
    }
  }

  // ============================================================================
  // MULTI-APP NOTIFICATION METHODS (Staff, Driver, Customer)
  // ============================================================================

  /**
   * Notify all active staff members about a new order
   * @param {Object} order - The order object
   * @returns {Promise<Object>} Send result
   */
  async notifyStaffNewOrder(order) {
    try {
      // Get all active staff members with FCM tokens
      const staff = await Staff.find({ 
        status: 'active', 
        isDeleted: false 
      }).select('fcmToken name');
      
      const tokens = staff.map(s => s.fcmToken).filter(t => t);
      
      if (tokens.length === 0) {
        console.log('No active staff with FCM tokens found');
        return { success: true, message: 'No recipients' };
      }

      const notification = {
        title: `New Order #${order.orderNumber}`,
        message: `Order for ${order.items.length} items ready for preparation`,
        type: 'order',
        priority: 'high',
        actionButton: {
          text: 'View Order',
          link: `/staff/orders/${order._id}`
        }
      };

      const data = {
        orderId: order._id.toString(),
        orderNumber: order.orderNumber,
        totalAmount: order.totalAmount.toString(),
        itemCount: order.items.length.toString(),
        deliveryMethod: order.deliveryMethod
      };

      console.log(`Notifying ${tokens.length} active staff about new order #${order.orderNumber}`);
      return await this.sendToDevices(tokens, notification, data);
    } catch (error) {
      console.error('Error notifying staff about new order:', error);
      throw error;
    }
  }

  /**
   * Notify available drivers that an order is ready for delivery
   * @param {Object} order - The order object
   * @returns {Promise<Object>} Send result
   */
  async notifyDriversOrderReady(order) {
    try {
      // Only notify for delivery orders
      if (order.deliveryMethod !== 'delivery') {
        console.log(`Order #${order.orderNumber} is ${order.deliveryMethod}, skipping driver notification`);
        return { success: true, message: 'Not a delivery order' };
      }

      // Get all available drivers (not on active delivery)
      const drivers = await Driver.find({ 
        status: 'available', 
        activeDelivery: null,
        isDeleted: false 
      }).select('fcmToken name');
      
      const tokens = drivers.map(d => d.fcmToken).filter(t => t);
      
      if (tokens.length === 0) {
        console.log('No available drivers with FCM tokens found');
        return { success: true, message: 'No recipients' };
      }

      const notification = {
        title: 'Order Ready for Delivery',
        message: `Pick up order #${order.orderNumber} from cafe`,
        type: 'delivery',
        priority: 'high',
        actionButton: {
          text: 'View Details',
          link: `/driver/orders/${order._id}`
        }
      };

      const data = {
        orderId: order._id.toString(),
        orderNumber: order.orderNumber,
        deliveryAddress: order.deliveryAddress?.fullAddress || 'Address not available',
        estimatedTime: order.deliveryTime?.estimatedMinutes?.toString() || '30',
        totalAmount: order.totalAmount.toString()
      };

      console.log(`Notifying ${tokens.length} available drivers about order #${order.orderNumber}`);
      return await this.sendToDevices(tokens, notification, data);
    } catch (error) {
      console.error('Error notifying drivers about ready order:', error);
      throw error;
    }
  }

  /**
   * Notify customer that a driver has been assigned to their order
   * @param {Object} order - The order object (should be populated with user)
   * @param {Object} driver - The driver object
   * @returns {Promise<Object>} Send result
   */
  async notifyCustomerDriverAssigned(order, driver) {
    try {
      // Populate user if not already populated
      if (!order.user?.fcmToken) {
        await order.populate('user');
      }

      if (!order.user || !order.user.fcmToken) {
        console.log(`User for order #${order.orderNumber} has no FCM token`);
        return { success: true, message: 'No recipient FCM token' };
      }

      const notification = {
        title: 'Driver Assigned',
        message: `${driver.name} is on the way with your order`,
        type: 'delivery',
        priority: 'high',
        image: driver.profileImage || null,
        actionButton: {
          text: 'Track Order',
          link: `/orders/${order._id}/track`
        }
      };

      const data = {
        orderId: order._id.toString(),
        orderNumber: order.orderNumber,
        driverId: driver._id.toString(),
        driverName: driver.name,
        vehicleType: driver.vehicleType || 'vehicle',
        vehicleNumber: driver.vehicleNumber || '',
        estimatedArrival: order.driverTracking?.estimatedArrival?.toISOString() || ''
      };

      console.log(`Notifying customer about driver assignment for order #${order.orderNumber}`);
      return await this.sendToUsers([order.user._id], notification, data);
    } catch (error) {
      console.error('Error notifying customer about driver assignment:', error);
      throw error;
    }
  }

  /**
   * Notify customer about driver's location update (throttled to every 2 minutes)
   * @param {Object} order - The order object (should be populated with user)
   * @param {Object} location - Location object with latitude and longitude
   * @returns {Promise<Object>} Send result
   */
  async notifyCustomerLocationUpdate(order, location) {
    try {
      const orderId = order._id.toString();
      const now = Date.now();
      const lastSent = this.locationUpdateThrottle.get(orderId);

      // Throttle: Only send location updates every 2 minutes
      if (lastSent && (now - lastSent) < 120000) {
        console.log(`Location update throttled for order #${order.orderNumber} (sent ${Math.floor((now - lastSent) / 1000)}s ago)`);
        return { success: true, throttled: true };
      }

      // Update throttle timestamp
      this.locationUpdateThrottle.set(orderId, now);

      // Populate user if not already populated
      if (!order.user?.fcmToken) {
        await order.populate('user');
      }

      if (!order.user || !order.user.fcmToken) {
        console.log(`User for order #${order.orderNumber} has no FCM token`);
        return { success: true, message: 'No recipient FCM token' };
      }

      const notification = {
        title: 'Driver Location Update',
        message: 'Your driver is on the way',
        type: 'location',
        priority: 'normal',
        actionButton: {
          text: 'Track',
          link: `/orders/${order._id}/track`
        }
      };

      const data = {
        orderId: order._id.toString(),
        orderNumber: order.orderNumber,
        latitude: location.latitude?.toString() || '',
        longitude: location.longitude?.toString() || '',
        distanceRemaining: order.driverTracking?.distanceRemaining?.toString() || '',
        estimatedArrival: order.driverTracking?.estimatedArrival?.toISOString() || ''
      };

      console.log(`Notifying customer about location update for order #${order.orderNumber}`);
      return await this.sendToUsers([order.user._id], notification, data);
    } catch (error) {
      console.error('Error notifying customer about location update:', error);
      throw error;
    }
  }

  /**
   * Notify customer that their order has been delivered
   * @param {Object} order - The order object (should be populated with user)
   * @returns {Promise<Object>} Send result
   */
  async notifyCustomerDelivered(order) {
    try {
      // Clean up throttle entry since delivery is complete
      const orderId = order._id.toString();
      this.locationUpdateThrottle.delete(orderId);

      // Populate user if not already populated
      if (!order.user?.fcmToken) {
        await order.populate('user');
      }

      if (!order.user || !order.user.fcmToken) {
        console.log(`User for order #${order.orderNumber} has no FCM token`);
        return { success: true, message: 'No recipient FCM token' };
      }

      const notification = {
        title: 'Order Delivered',
        message: 'Enjoy your coffee! ☕',
        type: 'delivery',
        priority: 'high',
        actionButton: {
          text: 'Rate Order',
          link: `/orders/${order._id}/rate`
        }
      };

      const data = {
        orderId: order._id.toString(),
        orderNumber: order.orderNumber,
        deliveredAt: order.statusTimestamps?.delivered?.toISOString() || new Date().toISOString(),
        totalAmount: order.totalAmount.toString()
      };

      console.log(`Notifying customer about delivery completion for order #${order.orderNumber}`);
      return await this.sendToUsers([order.user._id], notification, data);
    } catch (error) {
      console.error('Error notifying customer about delivery:', error);
      throw error;
    }
  }
}

// Export singleton instance
module.exports = new PushNotificationService();
