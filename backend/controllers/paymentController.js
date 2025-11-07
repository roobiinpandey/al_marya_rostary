const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const Order = require('../models/Order');
const { logAudit } = require('../utils/auditLogger');

/**
 * Create Stripe Payment Intent
 * Called when user is ready to pay for an order
 */
const createPaymentIntent = async (req, res) => {
  try {
    const { orderId } = req.body;

    // Find the order
    const order = await Order.findById(orderId).populate('user');
    
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Verify order belongs to user (unless admin)
    if (!req.user.roles.includes('admin') && order.user && order.user._id.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized access to this order'
      });
    }

    // Check if order already paid
    if (order.paymentStatus === 'paid') {
      return res.status(400).json({
        success: false,
        message: 'Order is already paid'
      });
    }

    // Convert amount to smallest currency unit (fils for AED)
    const amount = Math.round(order.totalAmount * 100);
    
    // Create payment intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency: order.currency.toLowerCase(),
      metadata: {
        orderId: order._id.toString(),
        orderNumber: order.orderNumber,
        userId: order.user ? order.user._id.toString() : 'guest',
        customerEmail: order.user ? order.user.email : order.guestInfo?.email || 'guest'
      },
      description: `Al Marya Rostery - Order ${order.orderNumber}`,
      // Add customer email for receipt
      receipt_email: order.user ? order.user.email : order.guestInfo?.email
    }, {
      // Idempotency to prevent duplicate charges (passed as request option)
      idempotencyKey: `order_${orderId}_${Date.now()}`
    });

    // Store payment intent ID in order
    order.stripePaymentIntentId = paymentIntent.id;
    await order.save();

    // Log the action
    await logAudit(
      req.user.id, 
      'CREATE_PAYMENT_INTENT', 
      'Order', 
      order._id, 
      {
        orderNumber: order.orderNumber,
        amount: order.totalAmount,
        currency: order.currency,
        paymentIntentId: paymentIntent.id
      }
    );

    res.json({
      success: true,
      message: 'Payment intent created',
      data: {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        amount: order.totalAmount,
        currency: order.currency
      }
    });

  } catch (error) {
    console.error('Create payment intent error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create payment intent',
      error: error.message
    });
  }
};

/**
 * Stripe Webhook Handler
 * Automatically updates order status when payment succeeds/fails
 */
const handleStripeWebhook = async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;

  try {
    // Verify webhook signature
    event = stripe.webhooks.constructEvent(
      req.body,
      sig,
      webhookSecret
    );
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).json({
      success: false,
      message: `Webhook Error: ${err.message}`
    });
  }

  // Handle the event
  try {
    switch (event.type) {
      case 'payment_intent.succeeded':
        await handlePaymentSuccess(event.data.object);
        break;

      case 'payment_intent.payment_failed':
        await handlePaymentFailed(event.data.object);
        break;

      case 'payment_intent.canceled':
        await handlePaymentCanceled(event.data.object);
        break;

      case 'charge.refunded':
        await handleRefund(event.data.object);
        break;

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.json({ received: true });

  } catch (error) {
    console.error('Webhook handler error:', error);
    res.status(500).json({
      success: false,
      message: 'Webhook processing failed',
      error: error.message
    });
  }
};

/**
 * Handle successful payment
 */
async function handlePaymentSuccess(paymentIntent) {
  const orderId = paymentIntent.metadata.orderId;
  
  const order = await Order.findById(orderId);
  if (!order) {
    console.error(`Order ${orderId} not found for successful payment`);
    return;
  }

  // Update order payment status
  order.paymentStatus = 'paid';
  order.transactionId = paymentIntent.id;
  order.paidAt = new Date();

  // Auto-confirm order if it's pending
  if (order.status === 'pending') {
    order.status = 'confirmed';
  }

  await order.save();

  console.log(`✅ Payment successful for order ${order.orderNumber}`);

  // TODO: Send order confirmation email
  // TODO: Send notification to admin
}

/**
 * Handle failed payment
 */
async function handlePaymentFailed(paymentIntent) {
  const orderId = paymentIntent.metadata.orderId;
  
  const order = await Order.findById(orderId);
  if (!order) {
    console.error(`Order ${orderId} not found for failed payment`);
    return;
  }

  order.paymentStatus = 'failed';
  order.paymentFailureReason = paymentIntent.last_payment_error?.message || 'Payment failed';
  await order.save();

  console.log(`❌ Payment failed for order ${order.orderNumber}`);

  // TODO: Send payment failure notification to customer
}

/**
 * Handle canceled payment
 */
async function handlePaymentCanceled(paymentIntent) {
  const orderId = paymentIntent.metadata.orderId;
  
  const order = await Order.findById(orderId);
  if (!order) {
    console.error(`Order ${orderId} not found for canceled payment`);
    return;
  }

  order.paymentStatus = 'pending';
  await order.save();

  console.log(`⚠️ Payment canceled for order ${order.orderNumber}`);
}

/**
 * Handle refund
 */
async function handleRefund(charge) {
  const paymentIntentId = charge.payment_intent;
  
  const order = await Order.findOne({ transactionId: paymentIntentId });
  if (!order) {
    console.error(`Order not found for refund of payment intent ${paymentIntentId}`);
    return;
  }

  order.paymentStatus = 'refunded';
  order.refundedAt = new Date();
  order.refundAmount = charge.amount_refunded / 100; // Convert from cents
  await order.save();

  console.log(`💰 Refund processed for order ${order.orderNumber}`);

  // TODO: Send refund confirmation email
}

/**
 * Process refund for an order
 * Admin only
 */
const processRefund = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { amount, reason } = req.body;

    const order = await Order.findById(orderId);
    
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    if (order.paymentStatus !== 'paid') {
      return res.status(400).json({
        success: false,
        message: 'Order is not paid, cannot process refund'
      });
    }

    if (!order.transactionId) {
      return res.status(400).json({
        success: false,
        message: 'No transaction ID found for this order'
      });
    }

    // Process refund in Stripe
    const refund = await stripe.refunds.create({
      payment_intent: order.transactionId,
      amount: amount ? Math.round(amount * 100) : undefined, // Partial or full refund
      reason: reason || 'requested_by_customer',
      metadata: {
        orderId: order._id.toString(),
        orderNumber: order.orderNumber,
        processedBy: req.user.id
      }
    });

    // Update order
    order.paymentStatus = 'refunded';
    order.refundedAt = new Date();
    order.refundAmount = refund.amount / 100;
    order.refundReason = reason;
    await order.save();

    // Log the action
    await logAudit(
      req.user.id,
      'PROCESS_REFUND',
      'Order',
      order._id,
      {
        orderNumber: order.orderNumber,
        refundAmount: refund.amount / 100,
        reason
      }
    );

    res.json({
      success: true,
      message: 'Refund processed successfully',
      data: {
        refundId: refund.id,
        amount: refund.amount / 100,
        currency: refund.currency,
        status: refund.status
      }
    });

  } catch (error) {
    console.error('Process refund error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to process refund',
      error: error.message
    });
  }
};

/**
 * Get payment details for an order
 */
const getPaymentDetails = async (req, res) => {
  try {
    const { orderId } = req.params;

    const order = await Order.findById(orderId);
    
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Verify access
    if (!req.user.roles.includes('admin') && order.user && order.user.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized access'
      });
    }

    let stripeDetails = null;
    
    // Get Stripe payment intent details if available
    if (order.stripePaymentIntentId) {
      try {
        const paymentIntent = await stripe.paymentIntents.retrieve(order.stripePaymentIntentId);
        stripeDetails = {
          id: paymentIntent.id,
          amount: paymentIntent.amount / 100,
          currency: paymentIntent.currency,
          status: paymentIntent.status,
          created: new Date(paymentIntent.created * 1000),
          paymentMethod: paymentIntent.payment_method_types
        };
      } catch (error) {
        console.error('Failed to retrieve Stripe details:', error);
      }
    }

    res.json({
      success: true,
      data: {
        order: {
          orderNumber: order.orderNumber,
          totalAmount: order.totalAmount,
          currency: order.currency,
          paymentStatus: order.paymentStatus,
          paymentMethod: order.paymentMethod,
          transactionId: order.transactionId,
          paidAt: order.paidAt,
          refundedAt: order.refundedAt,
          refundAmount: order.refundAmount
        },
        stripeDetails
      }
    });

  } catch (error) {
    console.error('Get payment details error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get payment details',
      error: error.message
    });
  }
};

module.exports = {
  createPaymentIntent,
  handleStripeWebhook,
  processRefund,
  getPaymentDetails
};
