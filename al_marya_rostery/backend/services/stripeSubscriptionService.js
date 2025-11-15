const { stripe, subscriptionConfig } = require('../config/stripe');
const { Subscription } = require('../models/Subscription');
const User = require('../models/User');

/**
 * Stripe Subscription Service
 * Handles all Stripe subscription operations
 */

class StripeSubscriptionService {
  /**
   * Create or retrieve Stripe customer for user
   */
  async getOrCreateCustomer(userId, userEmail, userName) {
    try {
      const user = await User.findOne({ firebaseUid: userId });
      
      // Check if customer already exists
      if (user && user.stripeCustomerId) {
        try {
          const customer = await stripe.customers.retrieve(user.stripeCustomerId);
          if (!customer.deleted) {
            return customer;
          }
        } catch (error) {
          console.log('Stripe customer not found, creating new one');
        }
      }
      
      // Create new customer
      const customer = await stripe.customers.create({
        email: userEmail,
        name: userName,
        metadata: {
          userId: userId,
          firebaseUid: userId
        }
      });
      
      // Save customer ID to user
      if (user) {
        user.stripeCustomerId = customer.id;
        await user.save();
      }
      
      return customer;
    } catch (error) {
      console.error('Error creating Stripe customer:', error);
      throw new Error('Failed to create payment customer');
    }
  }
  
  /**
   * Create Stripe product for subscription plan
   */
  async getOrCreateProduct(planId, planName, planDescription) {
    try {
      // Search for existing product
      const products = await stripe.products.search({
        query: `metadata['planId']:'${planId}'`,
      });
      
      if (products.data.length > 0) {
        return products.data[0];
      }
      
      // Create new product
      const product = await stripe.products.create({
        name: planName,
        description: planDescription,
        metadata: {
          planId: planId,
          type: 'subscription'
        }
      });
      
      return product;
    } catch (error) {
      console.error('Error creating Stripe product:', error);
      throw new Error('Failed to create subscription product');
    }
  }
  
  /**
   * Create Stripe price for subscription
   */
  async getOrCreatePrice(productId, amount, frequency) {
    try {
      const intervalConfig = subscriptionConfig.intervals[frequency];
      
      if (!intervalConfig) {
        throw new Error(`Invalid frequency: ${frequency}`);
      }
      
      // Search for existing price
      const prices = await stripe.prices.list({
        product: productId,
        active: true
      });
      
      const existingPrice = prices.data.find(price => 
        price.recurring.interval === intervalConfig.interval &&
        price.recurring.interval_count === intervalConfig.interval_count &&
        price.unit_amount === Math.round(amount * 100)
      );
      
      if (existingPrice) {
        return existingPrice;
      }
      
      // Create new price
      const price = await stripe.prices.create({
        product: productId,
        unit_amount: Math.round(amount * 100), // Convert to fils (cents)
        currency: subscriptionConfig.currency,
        recurring: {
          interval: intervalConfig.interval,
          interval_count: intervalConfig.interval_count
        },
        metadata: {
          frequency: frequency
        }
      });
      
      return price;
    } catch (error) {
      console.error('Error creating Stripe price:', error);
      throw new Error('Failed to create subscription price');
    }
  }
  
  /**
   * Create Stripe subscription
   */
  async createSubscription(subscriptionData) {
    try {
      const {
        userId,
        userEmail,
        userName,
        planId,
        planName,
        planDescription,
        amount,
        frequency,
        paymentMethodId,
        trialDays = 0
      } = subscriptionData;
      
      // Get or create customer
      const customer = await this.getOrCreateCustomer(userId, userEmail, userName);
      
      // Attach payment method to customer
      if (paymentMethodId) {
        await stripe.paymentMethods.attach(paymentMethodId, {
          customer: customer.id,
        });
        
        // Set as default payment method
        await stripe.customers.update(customer.id, {
          invoice_settings: {
            default_payment_method: paymentMethodId,
          },
        });
      }
      
      // Get or create product
      const product = await this.getOrCreateProduct(planId, planName, planDescription);
      
      // Get or create price
      const price = await this.getOrCreatePrice(product.id, amount, frequency);
      
      // Create subscription
      const subscriptionParams = {
        customer: customer.id,
        items: [{ price: price.id }],
        payment_behavior: 'default_incomplete',
        payment_settings: {
          payment_method_types: ['card'],
          save_default_payment_method: 'on_subscription'
        },
        expand: ['latest_invoice.payment_intent'],
        metadata: {
          userId: userId,
          planId: planId,
          frequency: frequency
        }
      };
      
      // Add trial period if specified
      if (trialDays > 0) {
        subscriptionParams.trial_period_days = trialDays;
      }
      
      const stripeSubscription = await stripe.subscriptions.create(subscriptionParams);
      
      return {
        subscriptionId: stripeSubscription.id,
        clientSecret: stripeSubscription.latest_invoice.payment_intent?.client_secret,
        status: stripeSubscription.status,
        currentPeriodEnd: new Date(stripeSubscription.current_period_end * 1000),
        customerId: customer.id
      };
    } catch (error) {
      console.error('Error creating Stripe subscription:', error);
      throw new Error(`Failed to create subscription: ${error.message}`);
    }
  }
  
  /**
   * Update Stripe subscription
   */
  async updateSubscription(stripeSubscriptionId, updates) {
    try {
      const { amount, frequency } = updates;
      
      if (amount && frequency) {
        const stripeSubscription = await stripe.subscriptions.retrieve(stripeSubscriptionId);
        const product = await stripe.products.retrieve(
          stripeSubscription.items.data[0].price.product
        );
        
        const newPrice = await this.getOrCreatePrice(product.id, amount, frequency);
        
        const updatedSubscription = await stripe.subscriptions.update(stripeSubscriptionId, {
          items: [{
            id: stripeSubscription.items.data[0].id,
            price: newPrice.id
          }],
          proration_behavior: 'create_prorations'
        });
        
        return updatedSubscription;
      }
      
      return await stripe.subscriptions.update(stripeSubscriptionId, updates);
    } catch (error) {
      console.error('Error updating Stripe subscription:', error);
      throw new Error('Failed to update subscription');
    }
  }
  
  /**
   * Pause Stripe subscription
   */
  async pauseSubscription(stripeSubscriptionId) {
    try {
      const subscription = await stripe.subscriptions.update(stripeSubscriptionId, {
        pause_collection: {
          behavior: 'keep_as_draft'
        }
      });
      
      return subscription;
    } catch (error) {
      console.error('Error pausing Stripe subscription:', error);
      throw new Error('Failed to pause subscription');
    }
  }
  
  /**
   * Resume Stripe subscription
   */
  async resumeSubscription(stripeSubscriptionId) {
    try {
      const subscription = await stripe.subscriptions.update(stripeSubscriptionId, {
        pause_collection: ''
      });
      
      return subscription;
    } catch (error) {
      console.error('Error resuming Stripe subscription:', error);
      throw new Error('Failed to resume subscription');
    }
  }
  
  /**
   * Cancel Stripe subscription
   */
  async cancelSubscription(stripeSubscriptionId, immediate = false) {
    try {
      if (immediate) {
        return await stripe.subscriptions.cancel(stripeSubscriptionId);
      } else {
        return await stripe.subscriptions.update(stripeSubscriptionId, {
          cancel_at_period_end: true
        });
      }
    } catch (error) {
      console.error('Error canceling Stripe subscription:', error);
      throw new Error('Failed to cancel subscription');
    }
  }
  
  /**
   * Get payment methods for customer
   */
  async getPaymentMethods(customerId) {
    try {
      const paymentMethods = await stripe.paymentMethods.list({
        customer: customerId,
        type: 'card'
      });
      
      return paymentMethods.data;
    } catch (error) {
      console.error('Error fetching payment methods:', error);
      throw new Error('Failed to fetch payment methods');
    }
  }
  
  /**
   * Add payment method
   */
  async addPaymentMethod(customerId, paymentMethodId) {
    try {
      await stripe.paymentMethods.attach(paymentMethodId, {
        customer: customerId
      });
      
      return await stripe.paymentMethods.retrieve(paymentMethodId);
    } catch (error) {
      console.error('Error adding payment method:', error);
      throw new Error('Failed to add payment method');
    }
  }
  
  /**
   * Set default payment method
   */
  async setDefaultPaymentMethod(customerId, paymentMethodId) {
    try {
      await stripe.customers.update(customerId, {
        invoice_settings: {
          default_payment_method: paymentMethodId
        }
      });
      
      return true;
    } catch (error) {
      console.error('Error setting default payment method:', error);
      throw new Error('Failed to set default payment method');
    }
  }
  
  /**
   * Remove payment method
   */
  async removePaymentMethod(paymentMethodId) {
    try {
      await stripe.paymentMethods.detach(paymentMethodId);
      return true;
    } catch (error) {
      console.error('Error removing payment method:', error);
      throw new Error('Failed to remove payment method');
    }
  }
  
  /**
   * Get invoices for customer
   */
  async getInvoices(customerId, limit = 10) {
    try {
      const invoices = await stripe.invoices.list({
        customer: customerId,
        limit: limit
      });
      
      return invoices.data;
    } catch (error) {
      console.error('Error fetching invoices:', error);
      throw new Error('Failed to fetch invoices');
    }
  }
  
  /**
   * Get upcoming invoice
   */
  async getUpcomingInvoice(customerId) {
    try {
      const invoice = await stripe.invoices.retrieveUpcoming({
        customer: customerId
      });
      
      return invoice;
    } catch (error) {
      console.error('Error fetching upcoming invoice:', error);
      return null;
    }
  }
}

module.exports = new StripeSubscriptionService();
