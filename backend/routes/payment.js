const express = require('express');
const router = express.Router();
const { 
  createPaymentIntent, 
  handleStripeWebhook,
  processRefund,
  getPaymentDetails
} = require('../controllers/paymentController');
const { protect, authorize } = require('../middleware/auth');

/**
 * @route   POST /api/payment/create-intent
 * @desc    Create Stripe payment intent for an order
 * @access  Private (Customer or Admin)
 */
router.post('/create-intent', protect, createPaymentIntent);

/**
 * @route   POST /api/payment/webhook
 * @desc    Stripe webhook endpoint (receives payment events)
 * @access  Public (Stripe signature verification)
 * @note    This route should NOT use body parser middleware
 */
router.post('/webhook', express.raw({ type: 'application/json' }), handleStripeWebhook);

/**
 * @route   POST /api/payment/refund/:orderId
 * @desc    Process refund for an order
 * @access  Private (Admin only)
 */
router.post('/refund/:orderId', protect, authorize('admin'), processRefund);

/**
 * @route   GET /api/payment/details/:orderId
 * @desc    Get payment details for an order
 * @access  Private (Customer owns order or Admin)
 */
router.get('/details/:orderId', protect, getPaymentDetails);

module.exports = router;
