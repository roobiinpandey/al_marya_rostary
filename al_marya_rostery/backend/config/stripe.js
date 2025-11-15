const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

/**
 * Stripe Configuration for Subscription Payments
 * Handles recurring billing, payment methods, and webhooks
 */

module.exports = {
  stripe,
  
  // Webhook secret for signature verification
  webhookSecret: process.env.STRIPE_WEBHOOK_SECRET,
  
  // Subscription configuration
  subscriptionConfig: {
    // Trial period (days)
    trialPeriodDays: 7,
    
    // Grace period for failed payments (days)
    gracePeriodDays: 3,
    
    // Billing cycles
    billingCycles: {
      weekly: 'week',
      'bi-weekly': 'week',
      monthly: 'month',
      quarterly: 'month'
    },
    
    // Intervals
    intervals: {
      weekly: { interval: 'week', interval_count: 1 },
      'bi-weekly': { interval: 'week', interval_count: 2 },
      monthly: { interval: 'month', interval_count: 1 },
      quarterly: { interval: 'month', interval_count: 3 }
    },
    
    // Default currency
    currency: 'aed',
    
    // Automatic tax calculation
    automaticTax: {
      enabled: false
    }
  },
  
  // Payment method types
  paymentMethodTypes: ['card'],
  
  // Invoice settings
  invoiceSettings: {
    defaultPaymentMethod: true,
    customFields: [
      {
        name: 'subscription_id',
        value: 'Subscription ID'
      }
    ]
  }
};
