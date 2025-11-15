const express = require('express');
const router = express.Router();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const Order = require('../models/Order');
const trackingService = require('../services/trackingService');

/**
 * Stripe Webhook Handler
 * Handles payment_intent.succeeded events and broadcasts payment updates via Socket.IO
 */
router.post('/stripe', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;

  try {
    // Verify webhook signature
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
    console.log('✅ Stripe webhook verified:', event.type);
  } catch (err) {
    console.error('❌ Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle different event types
  try {
    switch (event.type) {
      case 'payment_intent.succeeded':
        await handlePaymentSuccess(event.data.object);
        break;

      case 'payment_intent.payment_failed':
        await handlePaymentFailed(event.data.object);
        break;

      case 'charge.refunded':
        await handleRefund(event.data.object);
        break;

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.json({ received: true });
  } catch (error) {
    console.error('❌ Error processing webhook:', error);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
});

/**
 * Handle successful payment
 */
async function handlePaymentSuccess(paymentIntent) {
  try {
    console.log('💳 Processing successful payment:', paymentIntent.id);

    // Extract order ID from metadata
    const orderId = paymentIntent.metadata?.orderId;
    if (!orderId) {
      console.error('❌ No orderId in payment metadata');
      return;
    }

    // Find and update order
    const order = await Order.findById(orderId);
    if (!order) {
      console.error('❌ Order not found:', orderId);
      return;
    }

    // Update payment status
    order.paymentStatus = 'paid';
    order.paymentDetails = {
      method: 'card',
      stripePaymentIntentId: paymentIntent.id,
      amount: paymentIntent.amount / 100, // Convert from cents
      currency: paymentIntent.currency.toUpperCase(),
      paidAt: new Date(),
      cardBrand: paymentIntent.charges?.data[0]?.payment_method_details?.card?.brand,
      cardLast4: paymentIntent.charges?.data[0]?.payment_method_details?.card?.last4,
    };

    await order.save();

    console.log(`✅ Order ${order.orderNumber} payment confirmed`);

    // Emit real-time payment update via Socket.IO
    if (trackingService.emitPaymentUpdate) {
      trackingService.emitPaymentUpdate(orderId, {
        status: 'paid',
        amount: paymentIntent.amount / 100,
        method: 'card',
        paymentIntentId: paymentIntent.id,
        timestamp: new Date().toISOString(),
      });
      console.log('📡 Payment update broadcasted via WebSocket');
    }

    // Send payment confirmation email (optional)
    // await emailService.sendPaymentConfirmation(order);

  } catch (error) {
    console.error('❌ Error handling payment success:', error);
    throw error;
  }
}

/**
 * Handle failed payment
 */
async function handlePaymentFailed(paymentIntent) {
  try {
    console.log('❌ Processing failed payment:', paymentIntent.id);

    const orderId = paymentIntent.metadata?.orderId;
    if (!orderId) return;

    const order = await Order.findById(orderId);
    if (!order) return;

    // Update payment status
    order.paymentStatus = 'failed';
    order.paymentDetails = {
      method: 'card',
      stripePaymentIntentId: paymentIntent.id,
      failureMessage: paymentIntent.last_payment_error?.message || 'Payment failed',
      failedAt: new Date(),
    };

    await order.save();

    console.log(`❌ Order ${order.orderNumber} payment failed`);

    // Emit payment failure event
    if (trackingService.emitPaymentUpdate) {
      trackingService.emitPaymentUpdate(orderId, {
        status: 'failed',
        message: paymentIntent.last_payment_error?.message || 'Payment failed',
        timestamp: new Date().toISOString(),
      });
    }

    // Send payment failure notification (optional)
    // await emailService.sendPaymentFailure(order);

  } catch (error) {
    console.error('❌ Error handling payment failure:', error);
    throw error;
  }
}

/**
 * Handle refund
 */
async function handleRefund(charge) {
  try {
    console.log('💰 Processing refund:', charge.id);

    // Find order by payment intent ID
    const order = await Order.findOne({
      'paymentDetails.stripePaymentIntentId': charge.payment_intent,
    });

    if (!order) {
      console.error('❌ Order not found for refund');
      return;
    }

    // Update payment status
    order.paymentStatus = 'refunded';
    order.paymentDetails.refundedAt = new Date();
    order.paymentDetails.refundAmount = charge.amount_refunded / 100;

    await order.save();

    console.log(`💰 Order ${order.orderNumber} refunded`);

    // Emit refund event
    if (trackingService.emitPaymentUpdate) {
      trackingService.emitPaymentUpdate(order._id.toString(), {
        status: 'refunded',
        amount: charge.amount_refunded / 100,
        timestamp: new Date().toISOString(),
      });
    }

    // Send refund confirmation email (optional)
    // await emailService.sendRefundConfirmation(order);

  } catch (error) {
    console.error('❌ Error handling refund:', error);
    throw error;
  }
}

module.exports = router;
