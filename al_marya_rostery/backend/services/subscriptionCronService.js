const cron = require('node-cron');
const { Subscription, SubscriptionDelivery } = require('../models/Subscription');
const Order = require('../models/Order');
const Coffee = require('../models/Coffee');
const notificationService = require('../services/notificationService');

/**
 * Subscription Cron Jobs
 * Automated processing for subscription deliveries and renewals
 */

class SubscriptionCronService {
  constructor() {
    this.jobs = [];
  }
  
  /**
   * Initialize all cron jobs
   */
  initializeCronJobs() {
    console.log('🕐 Initializing subscription cron jobs...');
    
    // Process due deliveries - runs every hour
    this.jobs.push(
      cron.schedule('0 * * * *', async () => {
        console.log('⏰ Running hourly subscription delivery check...');
        await this.processDueDeliveries();
      })
    );
    
    // Send delivery reminders - runs daily at 9 AM
    this.jobs.push(
      cron.schedule('0 9 * * *', async () => {
        console.log('📧 Sending daily delivery reminders...');
        await this.sendDeliveryReminders();
      })
    );
    
    // Process expired subscriptions - runs daily at midnight
    this.jobs.push(
      cron.schedule('0 0 * * *', async () => {
        console.log('🔄 Processing expired subscriptions...');
        await this.processExpiredSubscriptions();
      })
    );
    
    // Resume paused subscriptions - runs daily at 1 AM
    this.jobs.push(
      cron.schedule('0 1 * * *', async () => {
        console.log('▶️ Resuming paused subscriptions...');
        await this.resumePausedSubscriptions();
      })
    );
    
    // Clean up old delivery records - runs weekly
    this.jobs.push(
      cron.schedule('0 2 * * 0', async () => {
        console.log('🧹 Cleaning up old delivery records...');
        await this.cleanupOldDeliveries();
      })
    );
    
    console.log(`✅ ${this.jobs.length} cron jobs initialized`);
  }
  
  /**
   * Process subscriptions that are due for delivery
   */
  async processDueDeliveries() {
    try {
      const now = new Date();
      
      // Find active subscriptions with nextDelivery <= now
      const dueSubscriptions = await Subscription.find({
        status: 'active',
        nextDelivery: { $lte: now }
      }).limit(100); // Process in batches
      
      console.log(`📦 Found ${dueSubscriptions.length} subscriptions due for delivery`);
      
      for (const subscription of dueSubscriptions) {
        try {
          await this.processSubscriptionDelivery(subscription);
        } catch (error) {
          console.error(`Error processing subscription ${subscription._id}:`, error);
          // Continue with other subscriptions
        }
      }
      
      console.log(`✅ Processed ${dueSubscriptions.length} deliveries`);
    } catch (error) {
      console.error('Error in processDueDeliveries:', error);
    }
  }
  
  /**
   * Process a single subscription delivery
   */
  async processSubscriptionDelivery(subscription) {
    try {
      console.log(`📦 Processing delivery for subscription ${subscription._id}`);
      
      // Check inventory availability
      const product = await Coffee.findById(subscription.productId);
      
      if (!product) {
        console.error(`Coffee product ${subscription.productId} not found`);
        return;
      }
      
      if (product.stock < subscription.quantity) {
        console.warn(`Insufficient stock for coffee ${product.name}`);
        
        // Send low stock notification
        await notificationService.sendLowStockAlert(subscription, product);
        
        // Skip this delivery
        subscription.skippedDeliveries++;
        subscription.calculateNextDelivery();
        await subscription.save();
        return;
      }
      
      // Create order from subscription
      const order = await this.createOrderFromSubscription(subscription);
      
      // Create delivery record
      await subscription.createDelivery();
      
      // Reduce product stock
      product.stock -= subscription.quantity;
      await product.save();
      
      // Update subscription stats
      subscription.lastDelivery = subscription.nextDelivery;
      subscription.calculateNextDelivery();
      subscription.totalDeliveries++;
      subscription.totalAmount += subscription.subscriptionPrice * subscription.quantity;
      await subscription.save();
      
      // Send notifications
      await notificationService.sendDeliveryScheduled(subscription, order);
      
      console.log(`✅ Created order ${order.orderNumber} for subscription ${subscription._id}`);
    } catch (error) {
      console.error('Error processing subscription delivery:', error);
      throw error;
    }
  }
  
  /**
   * Create order from subscription
   */
  async createOrderFromSubscription(subscription) {
    try {
      const orderData = {
        orderNumber: `SUB-${Date.now()}-${Math.random().toString(36).substr(2, 5).toUpperCase()}`,
        userId: subscription.userId,
        userEmail: subscription.userEmail,
        userName: subscription.userName,
        
        items: [{
          productId: subscription.productId,
          name: subscription.productName,
          size: subscription.productSize,
          quantity: subscription.quantity,
          price: subscription.subscriptionPrice,
          subtotal: subscription.subscriptionPrice * subscription.quantity
        }],
        
        subtotal: subscription.subscriptionPrice * subscription.quantity,
        deliveryFee: 0, // Free delivery for subscriptions
        discount: subscription.originalPrice - subscription.subscriptionPrice,
        total: subscription.subscriptionPrice * subscription.quantity,
        
        deliveryAddress: subscription.deliveryAddress,
        deliveryInstructions: subscription.deliveryInstructions,
        
        paymentMethod: subscription.paymentMethod,
        paymentStatus: subscription.paymentMethod === 'card' ? 'paid' : 'pending',
        
        status: 'confirmed',
        orderType: 'subscription',
        subscriptionId: subscription._id,
        
        scheduledDeliveryDate: subscription.nextDelivery,
        
        metadata: {
          frequency: subscription.frequency,
          planId: subscription.planId,
          planName: subscription.planName,
          deliveryNumber: subscription.totalDeliveries + 1
        }
      };
      
      const order = new Order(orderData);
      await order.save();
      
      return order;
    } catch (error) {
      console.error('Error creating order from subscription:', error);
      throw error;
    }
  }
  
  /**
   * Send delivery reminders for upcoming deliveries
   */
  async sendDeliveryReminders() {
    try {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      tomorrow.setHours(0, 0, 0, 0);
      
      const dayAfterTomorrow = new Date(tomorrow);
      dayAfterTomorrow.setDate(dayAfterTomorrow.getDate() + 1);
      
      // Find subscriptions with delivery tomorrow
      const upcomingDeliveries = await Subscription.find({
        status: 'active',
        nextDelivery: {
          $gte: tomorrow,
          $lt: dayAfterTomorrow
        }
      });
      
      console.log(`📧 Sending reminders for ${upcomingDeliveries.length} upcoming deliveries`);
      
      for (const subscription of upcomingDeliveries) {
        try {
          await notificationService.sendDeliveryReminder(subscription);
        } catch (error) {
          console.error(`Error sending reminder for subscription ${subscription._id}:`, error);
        }
      }
      
      console.log(`✅ Sent ${upcomingDeliveries.length} delivery reminders`);
    } catch (error) {
      console.error('Error in sendDeliveryReminders:', error);
    }
  }
  
  /**
   * Process expired subscriptions
   */
  async processExpiredSubscriptions() {
    try {
      const now = new Date();
      
      // Find subscriptions that should be expired
      const expiredSubscriptions = await Subscription.find({
        status: 'active',
        cancelAt: { $lte: now }
      });
      
      console.log(`🔄 Found ${expiredSubscriptions.length} expired subscriptions`);
      
      for (const subscription of expiredSubscriptions) {
        subscription.status = 'expired';
        subscription.updatedAt = new Date();
        await subscription.save();
        
        // Send notification
        await notificationService.sendSubscriptionExpired(subscription);
      }
      
      console.log(`✅ Processed ${expiredSubscriptions.length} expired subscriptions`);
    } catch (error) {
      console.error('Error in processExpiredSubscriptions:', error);
    }
  }
  
  /**
   * Resume paused subscriptions that have reached their resume date
   */
  async resumePausedSubscriptions() {
    try {
      const now = new Date();
      
      // Find paused subscriptions that should be resumed
      const subscriptionsToResume = await Subscription.find({
        status: 'paused',
        pausedUntil: { $lte: now }
      });
      
      console.log(`▶️ Found ${subscriptionsToResume.length} subscriptions to resume`);
      
      for (const subscription of subscriptionsToResume) {
        await subscription.resume();
        
        // Send notification
        await notificationService.sendSubscriptionResumed(subscription);
      }
      
      console.log(`✅ Resumed ${subscriptionsToResume.length} subscriptions`);
    } catch (error) {
      console.error('Error in resumePausedSubscriptions:', error);
    }
  }
  
  /**
   * Clean up old delivery records (older than 1 year)
   */
  async cleanupOldDeliveries() {
    try {
      const oneYearAgo = new Date();
      oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);
      
      const result = await SubscriptionDelivery.deleteMany({
        deliveryDate: { $lt: oneYearAgo },
        status: { $in: ['delivered', 'failed', 'skipped'] }
      });
      
      console.log(`🧹 Cleaned up ${result.deletedCount} old delivery records`);
    } catch (error) {
      console.error('Error in cleanupOldDeliveries:', error);
    }
  }
  
  /**
   * Stop all cron jobs
   */
  stopAllJobs() {
    console.log('⏹️ Stopping all cron jobs...');
    this.jobs.forEach(job => job.stop());
    this.jobs = [];
    console.log('✅ All cron jobs stopped');
  }
  
  /**
   * Manually trigger delivery processing (for testing)
   */
  async triggerDeliveryProcessing() {
    console.log('🔧 Manually triggering delivery processing...');
    await this.processDueDeliveries();
  }
}

module.exports = new SubscriptionCronService();
