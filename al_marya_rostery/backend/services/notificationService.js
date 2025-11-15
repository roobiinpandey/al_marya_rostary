const admin = require('firebase-admin');
const { Subscription } = require('../models/Subscription');
const User = require('../models/User');

/**
 * Notification Service
 * Handles FCM notifications for subscriptions
 */

class NotificationService {
  /**
   * Send notification to user
   */
  async sendNotification(userId, notification) {
    try {
      const user = await User.findOne({ firebaseUid: userId });
      
      if (!user || !user.fcmToken) {
        console.log(`No FCM token found for user ${userId}`);
        return;
      }
      
      const message = {
        token: user.fcmToken,
        notification: {
          title: notification.title,
          body: notification.body
        },
        data: notification.data || {},
        android: {
          priority: 'high',
          notification: {
            channelId: 'subscriptions',
            sound: 'default'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1
            }
          }
        }
      };
      
      const response = await admin.messaging().send(message);
      console.log(`✅ Notification sent to user ${userId}:`, response);
      
      return response;
    } catch (error) {
      console.error('Error sending notification:', error);
      throw error;
    }
  }
  
  /**
   * Send notification to multiple users
   */
  async sendBulkNotification(userIds, notification) {
    try {
      const users = await User.find({
        firebaseUid: { $in: userIds },
        fcmToken: { $exists: true, $ne: null }
      });
      
      if (users.length === 0) {
        console.log('No users with FCM tokens found');
        return;
      }
      
      const tokens = users.map(user => user.fcmToken);
      
      const message = {
        notification: {
          title: notification.title,
          body: notification.body
        },
        data: notification.data || {},
        tokens: tokens
      };
      
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`✅ Bulk notification sent to ${response.successCount} users`);
      
      return response;
    } catch (error) {
      console.error('Error sending bulk notification:', error);
      throw error;
    }
  }
  
  /**
   * Subscription created notification
   */
  async sendSubscriptionCreated(subscription) {
    return this.sendNotification(subscription.userId, {
      title: '🎉 Subscription Activated!',
      body: `Your ${subscription.planName} subscription is now active. Next delivery: ${subscription.nextDelivery.toLocaleDateString()}`,
      data: {
        type: 'subscription_created',
        subscriptionId: subscription._id.toString(),
        planName: subscription.planName
      }
    });
  }
  
  /**
   * Subscription status changed notification
   */
  async sendSubscriptionStatusChanged(subscription) {
    const statusMessages = {
      'cancelled': '❌ Your subscription has been cancelled',
      'past_due': '⚠️ Payment overdue - please update your payment method',
      'payment_failed': '❌ Payment failed - please check your payment details'
    };
    
    const message = statusMessages[subscription.status] || 'Your subscription status has changed';
    
    return this.sendNotification(subscription.userId, {
      title: 'Subscription Status Update',
      body: message,
      data: {
        type: 'subscription_status_changed',
        subscriptionId: subscription._id.toString(),
        status: subscription.status
      }
    });
  }
  
  /**
   * Subscription cancelled notification
   */
  async sendSubscriptionCancelled(subscription) {
    return this.sendNotification(subscription.userId, {
      title: 'Subscription Cancelled',
      body: `Your ${subscription.planName} subscription has been cancelled. We hope to see you again soon!`,
      data: {
        type: 'subscription_cancelled',
        subscriptionId: subscription._id.toString()
      }
    });
  }
  
  /**
   * Payment success notification
   */
  async sendPaymentSuccess(subscription, invoice) {
    return this.sendNotification(subscription.userId, {
      title: '✅ Payment Successful',
      body: `Payment of AED ${(invoice.amount_paid / 100).toFixed(2)} processed successfully for your ${subscription.planName} subscription`,
      data: {
        type: 'payment_success',
        subscriptionId: subscription._id.toString(),
        amount: (invoice.amount_paid / 100).toString(),
        invoiceId: invoice.id
      }
    });
  }
  
  /**
   * Payment failed notification
   */
  async sendPaymentFailed(subscription, invoice) {
    return this.sendNotification(subscription.userId, {
      title: '⚠️ Payment Failed',
      body: `We couldn't process your payment for ${subscription.planName}. Please update your payment method.`,
      data: {
        type: 'payment_failed',
        subscriptionId: subscription._id.toString(),
        invoiceId: invoice.id
      }
    });
  }
  
  /**
   * Trial ending reminder
   */
  async sendTrialEndingReminder(subscription, trialEndDate) {
    const daysLeft = Math.ceil((trialEndDate - new Date()) / (1000 * 60 * 60 * 24));
    
    return this.sendNotification(subscription.userId, {
      title: '⏰ Trial Ending Soon',
      body: `Your ${subscription.planName} trial ends in ${daysLeft} days. Your first payment will be processed on ${trialEndDate.toLocaleDateString()}`,
      data: {
        type: 'trial_ending',
        subscriptionId: subscription._id.toString(),
        daysLeft: daysLeft.toString()
      }
    });
  }
  
  /**
   * Delivery scheduled notification
   */
  async sendDeliveryScheduled(subscription, order) {
    return this.sendNotification(subscription.userId, {
      title: '📦 Delivery Scheduled',
      body: `Your ${subscription.productName} subscription delivery is scheduled for ${order.scheduledDeliveryDate.toLocaleDateString()}`,
      data: {
        type: 'delivery_scheduled',
        subscriptionId: subscription._id.toString(),
        orderId: order._id.toString(),
        orderNumber: order.orderNumber
      }
    });
  }
  
  /**
   * Delivery reminder (1 day before)
   */
  async sendDeliveryReminder(subscription) {
    return this.sendNotification(subscription.userId, {
      title: '🚚 Delivery Tomorrow',
      body: `Your ${subscription.productName} subscription will be delivered tomorrow!`,
      data: {
        type: 'delivery_reminder',
        subscriptionId: subscription._id.toString(),
        productName: subscription.productName
      }
    });
  }
  
  /**
   * Low stock alert (internal notification)
   */
  async sendLowStockAlert(subscription, product) {
    console.warn(`⚠️ Low stock alert: ${product.name} - Stock: ${product.stock}, Required: ${subscription.quantity}`);
    
    // Send to admin users
    const adminUsers = await User.find({ role: 'admin', fcmToken: { $exists: true } });
    const adminIds = adminUsers.map(u => u.firebaseUid);
    
    if (adminIds.length > 0) {
      return this.sendBulkNotification(adminIds, {
        title: '⚠️ Low Stock Alert',
        body: `${product.name} stock is low. Current: ${product.stock}, Required for subscription: ${subscription.quantity}`,
        data: {
          type: 'low_stock_alert',
          productId: product._id.toString(),
          subscriptionId: subscription._id.toString()
        }
      });
    }
  }
  
  /**
   * Subscription expired notification
   */
  async sendSubscriptionExpired(subscription) {
    return this.sendNotification(subscription.userId, {
      title: 'Subscription Expired',
      body: `Your ${subscription.planName} subscription has expired. Renew now to continue enjoying your coffee deliveries!`,
      data: {
        type: 'subscription_expired',
        subscriptionId: subscription._id.toString()
      }
    });
  }
  
  /**
   * Subscription resumed notification
   */
  async sendSubscriptionResumed(subscription) {
    return this.sendNotification(subscription.userId, {
      title: '▶️ Subscription Resumed',
      body: `Your ${subscription.planName} subscription has been resumed. Next delivery: ${subscription.nextDelivery.toLocaleDateString()}`,
      data: {
        type: 'subscription_resumed',
        subscriptionId: subscription._id.toString()
      }
    });
  }
  
  /**
   * Referral code reward notification
   */
  async sendReferralReward(userId, reward) {
    return this.sendNotification(userId, {
      title: '🎁 Referral Reward Earned!',
      body: `You've earned ${reward.discount}% discount for referring a friend!`,
      data: {
        type: 'referral_reward',
        discount: reward.discount.toString(),
        code: reward.code
      }
    });
  }
}

module.exports = new NotificationService();
