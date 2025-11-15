const express = require('express');
const router = express.Router();
const { stripe, webhookSecret } = require('../config/stripe');
const { Subscription } = require('../models/Subscription');
const stripeSubscriptionService = require('../services/stripeSubscriptionService');
const notificationService = require('../services/notificationService');

/**
 * Stripe Webhook Handler for Subscription Events
 * Handles all Stripe webhook events for subscription management
 */

// Webhook endpoint (must use raw body)
router.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  
  let event;
  
  try {
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err) {
    console.error('⚠️  Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }
  
  console.log(`📨 Received webhook event: ${event.type}`);
  
  // Handle the event
  try {
    switch (event.type) {
      case 'customer.subscription.created':
        await handleSubscriptionCreated(event.data.object);
        break;
        
      case 'customer.subscription.updated':
        await handleSubscriptionUpdated(event.data.object);
        break;
        
      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(event.data.object);
        break;
        
      case 'invoice.paid':
        await handleInvoicePaid(event.data.object);
        break;
        
      case 'invoice.payment_failed':
        await handleInvoicePaymentFailed(event.data.object);
        break;
        
      case 'customer.subscription.trial_will_end':
        await handleTrialWillEnd(event.data.object);
        break;
        
      case 'payment_method.attached':
        await handlePaymentMethodAttached(event.data.object);
        break;
        
      case 'payment_method.detached':
        await handlePaymentMethodDetached(event.data.object);
        break;
        
      default:
        console.log(`Unhandled event type: ${event.type}`);
    }
    
    res.json({ received: true });
  } catch (error) {
    console.error('Error processing webhook:', error);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
});

/**
 * Handle subscription created
 */
async function handleSubscriptionCreated(stripeSubscription) {
  console.log('✅ Subscription created:', stripeSubscription.id);
  
  try {
    // Find subscription by metadata
    const subscription = await Subscription.findOne({
      userId: stripeSubscription.metadata.userId,
      planId: stripeSubscription.metadata.planId,
      status: 'pending_payment'
    });
    
    if (subscription) {
      subscription.stripeSubscriptionId = stripeSubscription.id;
      subscription.stripeCustomerId = stripeSubscription.customer;
      subscription.status = stripeSubscription.status === 'active' ? 'active' : 'pending';
      subscription.currentPeriodEnd = new Date(stripeSubscription.current_period_end * 1000);
      subscription.currentPeriodStart = new Date(stripeSubscription.current_period_start * 1000);
      
      await subscription.save();
      
      // Send notification
      await notificationService.sendSubscriptionCreated(subscription);
    }
  } catch (error) {
    console.error('Error handling subscription created:', error);
  }
}

/**
 * Handle subscription updated
 */
async function handleSubscriptionUpdated(stripeSubscription) {
  console.log('🔄 Subscription updated:', stripeSubscription.id);
  
  try {
    const subscription = await Subscription.findOne({
      stripeSubscriptionId: stripeSubscription.id
    });
    
    if (subscription) {
      // Update status
      const statusMap = {
        'active': 'active',
        'past_due': 'past_due',
        'canceled': 'cancelled',
        'unpaid': 'payment_failed',
        'paused': 'paused'
      };
      
      subscription.status = statusMap[stripeSubscription.status] || subscription.status;
      subscription.currentPeriodEnd = new Date(stripeSubscription.current_period_end * 1000);
      subscription.currentPeriodStart = new Date(stripeSubscription.current_period_start * 1000);
      
      // Handle cancellation
      if (stripeSubscription.cancel_at_period_end) {
        subscription.cancelAtPeriodEnd = true;
        subscription.cancelAt = new Date(stripeSubscription.cancel_at * 1000);
      }
      
      await subscription.save();
      
      // Send notification if status changed significantly
      if (['cancelled', 'past_due', 'payment_failed'].includes(subscription.status)) {
        await notificationService.sendSubscriptionStatusChanged(subscription);
      }
    }
  } catch (error) {
    console.error('Error handling subscription updated:', error);
  }
}

/**
 * Handle subscription deleted
 */
async function handleSubscriptionDeleted(stripeSubscription) {
  console.log('❌ Subscription deleted:', stripeSubscription.id);
  
  try {
    const subscription = await Subscription.findOne({
      stripeSubscriptionId: stripeSubscription.id
    });
    
    if (subscription) {
      subscription.status = 'cancelled';
      subscription.cancelledAt = new Date();
      subscription.cancellationReason = 'Cancelled via Stripe';
      
      await subscription.save();
      
      // Send notification
      await notificationService.sendSubscriptionCancelled(subscription);
    }
  } catch (error) {
    console.error('Error handling subscription deleted:', error);
  }
}

/**
 * Handle invoice paid
 */
async function handleInvoicePaid(invoice) {
  console.log('💰 Invoice paid:', invoice.id);
  
  try {
    if (invoice.subscription) {
      const subscription = await Subscription.findOne({
        stripeSubscriptionId: invoice.subscription
      });
      
      if (subscription) {
        // Update subscription
        subscription.lastPaymentDate = new Date();
        subscription.lastPaymentAmount = invoice.amount_paid / 100; // Convert from fils
        subscription.totalAmount += invoice.amount_paid / 100;
        
        // Reset past_due status
        if (subscription.status === 'past_due') {
          subscription.status = 'active';
        }
        
        await subscription.save();
        
        // Create invoice record
        subscription.invoices = subscription.invoices || [];
        subscription.invoices.push({
          invoiceId: invoice.id,
          amount: invoice.amount_paid / 100,
          currency: invoice.currency,
          status: 'paid',
          paidAt: new Date(invoice.status_transitions.paid_at * 1000),
          invoiceUrl: invoice.hosted_invoice_url,
          invoicePdf: invoice.invoice_pdf
        });
        
        await subscription.save();
        
        // Send notification
        await notificationService.sendPaymentSuccess(subscription, invoice);
      }
    }
  } catch (error) {
    console.error('Error handling invoice paid:', error);
  }
}

/**
 * Handle invoice payment failed
 */
async function handleInvoicePaymentFailed(invoice) {
  console.log('⚠️ Invoice payment failed:', invoice.id);
  
  try {
    if (invoice.subscription) {
      const subscription = await Subscription.findOne({
        stripeSubscriptionId: invoice.subscription
      });
      
      if (subscription) {
        subscription.status = 'payment_failed';
        subscription.lastPaymentAttempt = new Date();
        subscription.paymentFailureCount = (subscription.paymentFailureCount || 0) + 1;
        
        await subscription.save();
        
        // Send notification
        await notificationService.sendPaymentFailed(subscription, invoice);
      }
    }
  } catch (error) {
    console.error('Error handling invoice payment failed:', error);
  }
}

/**
 * Handle trial will end
 */
async function handleTrialWillEnd(stripeSubscription) {
  console.log('⏰ Trial will end:', stripeSubscription.id);
  
  try {
    const subscription = await Subscription.findOne({
      stripeSubscriptionId: stripeSubscription.id
    });
    
    if (subscription) {
      const trialEndDate = new Date(stripeSubscription.trial_end * 1000);
      
      // Send notification 3 days before trial ends
      await notificationService.sendTrialEndingReminder(subscription, trialEndDate);
    }
  } catch (error) {
    console.error('Error handling trial will end:', error);
  }
}

/**
 * Handle payment method attached
 */
async function handlePaymentMethodAttached(paymentMethod) {
  console.log('💳 Payment method attached:', paymentMethod.id);
  // No action needed, payment method is automatically used
}

/**
 * Handle payment method detached
 */
async function handlePaymentMethodDetached(paymentMethod) {
  console.log('💳 Payment method detached:', paymentMethod.id);
  // No action needed unless it was the default payment method
}

module.exports = router;
