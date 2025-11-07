/**
 * User Orders Routes
 * Handles order creation and management for authenticated users
 */

const express = require('express');
const router = express.Router();
const { createOrder, getOrders, getOrder } = require('../controllers/orderController');
const { protect } = require('../middleware/auth');
const Order = require('../models/Order');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

/**
 * @route   POST /api/orders
 * @desc    Create a new order
 * @access  Private (requires authentication)
 * @body    {
 *            items: Array<{name, quantity, price, roastLevel, grindSize}>,
 *            shippingAddress: {street, city, state, zipCode, country, phone},
 *            paymentMethod: String (card|cash_on_delivery|apple_pay|google_pay),
 *            paymentStatus: String (pending|completed|failed),
 *            totalAmount: Number,
 *            deliveryMethod: String (standard|express),
 *            preferredDeliveryDate: Date,
 *            preferredDeliveryTime: String,
 *            specialInstructions: String
 *          }
 */
router.post('/', protect, createOrder);

/**
 * @route   GET /api/orders
 * @desc    Get all orders for authenticated user
 * @access  Private
 */
router.get('/', protect, getOrders);

/**
 * @route   GET /api/orders/:id
 * @desc    Get specific order by ID
 * @access  Private
 */
router.get('/:id', protect, getOrder);

/**
 * @route   POST /api/orders/:id/cancel
 * @desc    Cancel an order (within 15 min of placement)
 * @access  Private
 * @body    { reason: String }
 */
router.post('/:id/cancel', protect, async (req, res) => {
  try {
    const { reason } = req.body;
    
    const order = await Order.findById(req.params.id);
    
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }
    
    // Check ownership
    if (order.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to cancel this order' });
    }
    
    // Check if already cancelled
    if (order.cancellation?.isCancelled) {
      return res.status(400).json({ message: 'Order is already cancelled' });
    }
    
    // Check status - can only cancel pending/preparing orders
    if (!['pending', 'preparing'].includes(order.status)) {
      return res.status(400).json({ 
        message: `Cannot cancel order with status: ${order.status}` 
      });
    }
    
    // Check time limit (15 minutes)
    const minutesSinceOrder = (Date.now() - order.createdAt) / 1000 / 60;
    if (minutesSinceOrder > 15) {
      return res.status(400).json({ 
        message: 'Cancellation window expired. Orders can only be cancelled within 15 minutes.' 
      });
    }
    
    // Update order
    order.status = 'cancelled';
    order.cancellation = {
      isCancelled: true,
      reason: reason || 'Customer requested cancellation',
      cancelledAt: new Date(),
      cancelledBy: req.user._id
    };
    
    // Update status timestamp
    order.statusTimestamps.cancelled = new Date();
    
    // Process refund if payment was made
    if (order.paymentStatus === 'paid' && order.paymentMethod === 'card' && order.stripePaymentIntentId) {
      try {
        const refund = await stripe.refunds.create({
          payment_intent: order.stripePaymentIntentId,
          reason: 'requested_by_customer'
        });
        
        order.cancellation.refundStatus = 'completed';
        order.cancellation.refundAmount = order.totalAmount;
        order.cancellation.refundTransactionId = refund.id;
        order.cancellation.refundedAt = new Date();
        order.paymentStatus = 'refunded';
        
        console.log(`Refund processed: ${refund.id} for order ${order.orderNumber}`);
      } catch (refundError) {
        order.cancellation.refundStatus = 'failed';
        console.error('Refund failed:', refundError);
        // Continue with cancellation even if refund fails - will need manual processing
      }
    } else if (order.paymentStatus === 'paid' && order.paymentMethod === 'cash') {
      // Cash orders don't need refund processing
      order.cancellation.refundStatus = 'completed';
      order.cancellation.refundAmount = order.totalAmount;
    }
    
    await order.save();
    
    // TODO: Send notifications to staff/driver if assigned
    // This will be implemented with Push Notifications feature
    if (order.assignedStaff) {
      console.log(`TODO: Notify staff ${order.assignedStaff} about cancellation`);
    }
    if (order.assignedDriver) {
      console.log(`TODO: Notify driver ${order.assignedDriver} about cancellation`);
    }
    
    res.json({
      success: true,
      message: 'Order cancelled successfully',
      order,
      refund: order.cancellation.refundStatus === 'completed' ? {
        amount: order.cancellation.refundAmount,
        status: 'completed',
        transactionId: order.cancellation.refundTransactionId
      } : null
    });
    
  } catch (error) {
    console.error('Cancel order error:', error);
    res.status(500).json({ message: 'Server error while cancelling order' });
  }
});

module.exports = router;
