const Order = require('../models/Order');
const Coffee = require('../models/Coffee');
const User = require('../models/User');
const { logAudit } = require('../utils/auditLogger');
const emailService = require('../services/emailService');
const { generateOrderNumber } = require('../utils/orderNumberGenerator');

/**
 * Create a new order
 * POST /api/orders
 * Access: Protected (requires authentication)
 */
const createOrder = async (req, res) => {
  try {
    const {
      items,
      shippingAddress,
      paymentMethod,
      paymentStatus = 'pending',
      totalAmount,
      deliveryMethod = 'standard',
      preferredDeliveryDate,
      preferredDeliveryTime,
      specialInstructions
    } = req.body;

    // Validate required fields
    if (!items || items.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Order must contain at least one item'
      });
    }

    if (!shippingAddress) {
      return res.status(400).json({
        success: false,
        message: 'Shipping address is required'
      });
    }

    if (!totalAmount || totalAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Total amount must be greater than zero'
      });
    }

    // Get user ID from auth middleware (sets req.user.userId)
    const userId = req.user?.userId || req.user?._id || req.user?.id;

    // Generate unique order number using centralized generator
    // Format: ALM-YYYYMMDD-XXXXXX (e.g., ALM-20251106-000123)
    const orderNumber = await generateOrderNumber();

    // Map payment status (Flutter uses 'completed', model uses 'paid')
    const mappedPaymentStatus = paymentStatus === 'completed' ? 'paid' : paymentStatus;

    // Map delivery method (Flutter uses 'express'/'standard', model uses 'delivery'/'pickup')
    const mappedDeliveryMethod = deliveryMethod === 'express' || deliveryMethod === 'standard' 
      ? 'delivery' 
      : deliveryMethod;

    // Calculate order subtotal
    const orderSubtotal = items.reduce((sum, item) => 
      sum + (item.price * item.quantity), 0);

    // Create order data
    const orderData = {
      user: userId,
      orderNumber,
      items: items.map(item => ({
        coffee: item.productId || item.coffeeId || null, // ObjectId reference
        name: item.productName || item.name,
        quantity: item.quantity,
        price: item.price,
        subtotal: item.price * item.quantity,
        selectedSize: item.selectedSize || item.size || '250g', // Must be 250g, 500g, or 1kg
      })),
      subtotal: orderSubtotal,
      totalAmount,
      deliveryAddress: shippingAddress, // Map shippingAddress to deliveryAddress
      paymentMethod,
      paymentStatus: mappedPaymentStatus,
      deliveryMethod: mappedDeliveryMethod,
      status: 'pending',
      notes: specialInstructions
    };

    // Create order
    const order = await Order.create(orderData);

    console.log('✅ Order created:', order.orderNumber);

    // Send order confirmation email (non-blocking)
    console.log('📝 Checking user for email. req.user:', req.user, 'userId:', userId);
    
    if (userId) {
      const user = await User.findById(userId);
      if (user && user.email) {
        console.log('📧 Sending order confirmation email to:', user.email);
        emailService.sendOrderConfirmation(order, user)
          .then(result => {
            if (result.success) {
              console.log('✅ Order confirmation email sent successfully to:', user.email);
            } else {
              console.error('❌ Failed to send order confirmation email:', result.error);
            }
          })
          .catch(err => {
            console.error('❌ Error sending order confirmation email:', err);
          });
      } else {
        console.log('⚠️  No user or email found for userId:', userId);
      }
    } else {
      console.log('❌ No user ID found in request. req.user:', req.user);
    }

    // Log order creation
    if (userId) {
      await logAudit(userId, 'CREATE_ORDER', 'Order', order._id.toString(), {
        orderNumber: order.orderNumber,
        totalAmount: order.totalAmount,
        paymentMethod: order.paymentMethod
      });
    }

    res.status(201).json({
      success: true,
      message: 'Order created successfully',
      order: order
    });
  } catch (error) {
    console.error('❌ Create order error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create order',
      error: error.message
    });
  }
};

// Admin: Get order statistics for dashboard
const getOrderStats = async (req, res) => {
  try {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);

    // Get order counts by status
    const statusStats = await Order.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      }
    ]);

    // Get today's revenue
    const todayRevenue = await Order.aggregate([
      {
        $match: {
          createdAt: { $gte: todayStart, $lte: todayEnd },
          status: { $in: ['delivered', 'completed'] }
        }
      },
      {
        $group: {
          _id: null,
          revenue: { $sum: '$totalAmount' }
        }
      }
    ]);

    // Get monthly order trends
    const monthlyOrders = await Order.aggregate([
      {
        $match: {
          createdAt: { 
            $gte: new Date(new Date().getFullYear(), new Date().getMonth() - 5, 1)
          }
        }
      },
      {
        $group: {
          _id: {
            year: { $year: '$createdAt' },
            month: { $month: '$createdAt' }
          },
          count: { $sum: 1 },
          revenue: { $sum: '$totalAmount' }
        }
      },
      {
        $sort: { '_id.year': 1, '_id.month': 1 }
      }
    ]);

    // Format status counts
    const stats = {
      pending: 0,
      confirmed: 0,
      preparing: 0,
      ready: 0,
      delivered: 0,
      cancelled: 0,
      todayRevenue: todayRevenue[0]?.revenue || 0,
      monthlyTrends: monthlyOrders
    };

    statusStats.forEach(stat => {
      if (stats.hasOwnProperty(stat._id)) {
        stats[stat._id] = stat.count;
      }
    });

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Get order stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching order statistics',
      error: error.message
    });
  }
};

// Get all orders with pagination and filtering
const getOrders = async (req, res) => {
  try {
    console.log('📋 GET ORDERS - User:', req.user);
    console.log('📋 GET ORDERS - User ID:', req.user?.userId);
    console.log('📋 GET ORDERS - Is Admin:', req.user?.isAdmin);
    console.log('📋 GET ORDERS - Roles:', req.user?.roles);
    
    const {
      page = 1,
      limit = 10,
      status,
      paymentStatus,
      deliveryMethod,
      startDate,
      endDate,
      search,
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    // Build query
    const query = {};
    
    // If not an admin, filter by user
    if (req.user && !req.user.isAdmin && !req.user.roles?.includes('admin')) {
      query.user = req.user.userId;
      console.log('📋 Filtering orders for user:', req.user.userId);
    } else {
      console.log('📋 Not filtering - admin user or no user');
    }
    
    if (status) query.status = status;
    if (paymentStatus) query.paymentStatus = paymentStatus;
    if (deliveryMethod) query.deliveryMethod = deliveryMethod;
    
    if (startDate && endDate) {
      query.createdAt = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }

    if (search) {
      query.$or = [
        { orderNumber: { $regex: search, $options: 'i' } },
        { 'guestInfo.name': { $regex: search, $options: 'i' } },
        { 'guestInfo.email': { $regex: search, $options: 'i' } },
        { 'guestInfo.phone': { $regex: search, $options: 'i' } }
      ];
    }

    // Sort options
    const sortOptions = {};
    sortOptions[sortBy] = sortOrder === 'desc' ? -1 : 1;

    console.log('📋 Final query:', JSON.stringify(query));
    console.log('📋 Pagination - page:', pageNum, 'limit:', limitNum, 'skip:', skip);

    // Execute query
    const orders = await Order.find(query)
      .populate('user', 'name email phone')
      .populate('items.coffee', 'name image price')
      .sort(sortOptions)
      .skip(skip)
      .limit(limitNum)
      .lean(); // Convert Mongoose documents to plain JavaScript objects

    const totalOrders = await Order.countDocuments(query);
    const totalPages = Math.ceil(totalOrders / limitNum);

    console.log('📋 Query returned', orders.length, 'orders, total count:', totalOrders);

    res.json({
      success: true,
      data: {
        orders,
        pagination: {
          currentPage: pageNum,
          totalPages,
          totalOrders,
          limit: limitNum,
          hasNextPage: pageNum < totalPages,
          hasPrevPage: pageNum > 1
        }
      }
    });
  } catch (error) {
    console.error('Get orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve orders',
      error: error.message
    });
  }
};

// Get single order by ID
const getOrder = async (req, res) => {
  try {
    const { id } = req.params;

    const order = await Order.findById(id)
      .populate('user', 'name email phone')
      .populate('items.coffee', 'name image price variants')
      .lean(); // Convert Mongoose document to plain JavaScript object

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    res.json({
      success: true,
      data: order
    });
  } catch (error) {
    console.error('Get order error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve order',
      error: error.message
    });
  }
};

// Update order status
const updateOrderStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes, trackingInfo } = req.body;

    const order = await Order.findById(id);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    const oldStatus = order.status;
    
    // Update order status
    order.status = status;
    if (notes) order.notes = notes;
    
    if (trackingInfo) {
      order.tracking = {
        ...order.tracking,
        ...trackingInfo,
        updatedAt: new Date()
      };
    }

    // Update specific timestamps based on status
    switch (status) {
      case 'delivered':
        order.actualDeliveryTime = new Date();
        break;
      case 'cancelled':
        order.paymentStatus = 'refunded'; // Auto-refund cancelled orders
        break;
    }

    await order.save();

    // Log the status change
    await logAudit(req.user.id, 'UPDATE_ORDER_STATUS', 'Order', id, {
      orderNumber: order.orderNumber,
      oldStatus,
      newStatus: status,
      notes
    });

    const updatedOrder = await Order.findById(id)
      .populate('user', 'name email phone')
      .populate('items.coffee', 'name image price')
      .lean(); // Convert to plain JavaScript object

    // Send status update email notification (non-blocking)
    const user = await User.findById(order.user);
    if (user && user.email) {
      const statusMessages = {
        confirmed: 'Your order has been confirmed and is being prepared.',
        preparing: 'Your order is being prepared with care.',
        ready: 'Your order is ready for delivery!',
        delivered: 'Your order has been delivered. Enjoy!',
        cancelled: 'Your order has been cancelled.'
      };

      const subject = `Order ${order.orderNumber} - ${status.charAt(0).toUpperCase() + status.slice(1)}`;
      const html = `
        <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
          <div style="text-align: center; margin-bottom: 30px;">
            <h1 style="color: #A89A6A;">Al Marya Rostery</h1>
          </div>
          <h2 style="color: #333;">Order Status Update</h2>
          <p>Dear ${user.name},</p>
          <p>${statusMessages[status] || 'Your order status has been updated.'}</p>
          
          <div style="background: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0;">
            <h3 style="margin-top: 0;">Order #${order.orderNumber}</h3>
            <p><strong>Status:</strong> <span style="color: #A89A6A;">${status.toUpperCase()}</span></p>
            <p><strong>Total:</strong> AED ${order.totalAmount.toFixed(2)}</p>
            ${notes ? `<p><strong>Note:</strong> ${notes}</p>` : ''}
          </div>

          <p>Thank you for choosing Al Marya Rostery!</p>
          
          <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
          <p style="color: #999; font-size: 12px; text-align: center;">
            Al Marya Rostery - Premium Coffee Experience<br>
            UAE
          </p>
        </div>
      `;

      emailService.sendEmail({
        to: user.email,
        subject,
        html
      }).then(result => {
        if (result.success) {
          console.log('📧 Status update email sent to:', user.email);
        }
      }).catch(err => {
        console.error('❌ Error sending status update email:', err);
      });
    }

    res.json({
      success: true,
      message: 'Order status updated successfully',
      data: updatedOrder
    });
  } catch (error) {
    console.error('Update order status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update order status',
      error: error.message
    });
  }
};

// Update payment status
const updatePaymentStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { paymentStatus, paymentMethod, transactionId } = req.body;

    const order = await Order.findById(id);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    const oldPaymentStatus = order.paymentStatus;
    
    order.paymentStatus = paymentStatus;
    if (paymentMethod) order.paymentMethod = paymentMethod;
    if (transactionId) order.transactionId = transactionId;

    await order.save();

    // Log the payment status change
    await logAudit(req.user.id, 'UPDATE_PAYMENT_STATUS', 'Order', id, {
      orderNumber: order.orderNumber,
      oldPaymentStatus,
      newPaymentStatus: paymentStatus,
      paymentMethod,
      transactionId
    });

    res.json({
      success: true,
      message: 'Payment status updated successfully',
      data: order
    });
  } catch (error) {
    console.error('Update payment status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update payment status',
      error: error.message
    });
  }
};

// Delete order (admin only - for test/invalid orders)
const deleteOrder = async (req, res) => {
  try {
    const { id } = req.params;

    const order = await Order.findById(id);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Only allow deletion of pending or cancelled orders
    if (!['pending', 'cancelled'].includes(order.status)) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete orders that are being processed or completed'
      });
    }

    await Order.findByIdAndDelete(id);

    // Log the deletion
    await logAudit(req.user.id, 'DELETE_ORDER', 'Order', id, {
      orderNumber: order.orderNumber,
      status: order.status,
      totalAmount: order.totalAmount
    });

    res.json({
      success: true,
      message: 'Order deleted successfully'
    });
  } catch (error) {
    console.error('Delete order error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete order',
      error: error.message
    });
  }
};

// Get daily order analytics for dashboard charts
const getOrderAnalytics = async (req, res) => {
  try {
    const { days = 30 } = req.query;
    const daysNum = parseInt(days);
    
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - daysNum);

    const analytics = await Order.aggregate([
      { $match: { createdAt: { $gte: startDate } } },
      {
        $group: {
          _id: {
            year: { $year: '$createdAt' },
            month: { $month: '$createdAt' },
            day: { $dayOfMonth: '$createdAt' }
          },
          orderCount: { $sum: 1 },
          revenue: { 
            $sum: { 
              $cond: [{ $eq: ['$paymentStatus', 'paid'] }, '$totalAmount', 0] 
            } 
          },
          averageOrderValue: { $avg: '$totalAmount' }
        }
      },
      {
        $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 }
      },
      {
        $project: {
          date: {
            $dateFromParts: {
              year: '$_id.year',
              month: '$_id.month',
              day: '$_id.day'
            }
          },
          orderCount: 1,
          revenue: 1,
          averageOrderValue: 1
        }
      }
    ]);

    res.json({
      success: true,
      data: analytics
    });
  } catch (error) {
    console.error('Get order analytics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve order analytics',
      error: error.message
    });
  }
};

// Export orders to CSV
const exportOrders = async (req, res) => {
  try {
    const {
      status,
      paymentStatus,
      startDate,
      endDate
    } = req.query;

    // Build query
    const query = {};
    if (status) query.status = status;
    if (paymentStatus) query.paymentStatus = paymentStatus;
    if (startDate && endDate) {
      query.createdAt = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }

    const orders = await Order.find(query)
      .populate('user', 'name email phone')
      .sort({ createdAt: -1 })
      .lean(); // Convert to plain JavaScript objects

    // Generate CSV content
    const csvHeaders = [
      'Order Number',
      'Customer Name',
      'Customer Email',
      'Customer Phone',
      'Status',
      'Payment Status',
      'Payment Method',
      'Delivery Method',
      'Items',
      'Subtotal',
      'Tax',
      'Shipping',
      'Discount',
      'Total Amount',
      'Currency',
      'Order Date',
      'Delivery Date',
      'Notes'
    ];

    const csvRows = orders.map(order => {
      const customerName = order.user?.name || order.guestInfo?.name || 'N/A';
      const customerEmail = order.user?.email || order.guestInfo?.email || 'N/A';
      const customerPhone = order.user?.phone || order.guestInfo?.phone || 'N/A';
      
      const items = order.items.map(item => 
        `${item.name} (${item.selectedSize || 'N/A'}) x${item.quantity}`
      ).join('; ');

      return [
        order.orderNumber,
        customerName,
        customerEmail,
        customerPhone,
        order.status,
        order.paymentStatus,
        order.paymentMethod,
        order.deliveryMethod,
        items,
        order.subtotal.toFixed(2),
        order.tax.toFixed(2),
        order.shipping.toFixed(2),
        order.discount.toFixed(2),
        order.totalAmount.toFixed(2),
        order.currency,
        order.createdAt.toISOString().split('T')[0],
        order.actualDeliveryTime ? order.actualDeliveryTime.toISOString().split('T')[0] : 'N/A',
        order.notes || 'N/A'
      ];
    });

    const csvContent = [csvHeaders, ...csvRows]
      .map(row => row.map(field => `"${field}"`).join(','))
      .join('\n');

    // Log the export
    await logAudit(req.user.id, 'EXPORT_ORDERS', 'Order', 'bulk', {
      totalExported: orders.length,
      filters: query
    });

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename=orders-${new Date().toISOString().split('T')[0]}.csv`);
    res.send(csvContent);
  } catch (error) {
    console.error('Export orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to export orders',
      error: error.message
    });
  }
};

/**
 * Get current user's orders
 * GET /api/orders/my-orders
 * Access: Protected (requires authentication)
 */
const getMyOrders = async (req, res) => {
  try {
    const userId = req.user?.userId || req.user?._id || req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    console.log(`📦 Fetching orders for user: ${userId}`);

    const orders = await Order.find({ user: userId })
      .sort({ createdAt: -1 })
      .populate('items.coffee', 'name imageUrl price')
      .lean();

    console.log(`✅ Found ${orders.length} orders for user ${userId}`);

    res.json({
      success: true,
      orders: orders,
      count: orders.length
    });
  } catch (error) {
    console.error('❌ Error fetching user orders:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch orders',
      error: error.message
    });
  }
};

/**
 * Create guest order (without authentication)
 * POST /api/orders/guest
 * Access: Public
 */
const createGuestOrder = async (req, res) => {
  try {
    const {
      items,
      shippingAddress,
      guestInfo,
      paymentMethod,
      paymentStatus = 'pending',
      totalAmount,
      deliveryMethod = 'standard',
      specialInstructions
    } = req.body;

    // Validate required fields
    if (!items || items.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Order must contain at least one item'
      });
    }

    if (!shippingAddress) {
      return res.status(400).json({
        success: false,
        message: 'Shipping address is required'
      });
    }

    if (!guestInfo || !guestInfo.email || !guestInfo.name || !guestInfo.phone) {
      return res.status(400).json({
        success: false,
        message: 'Guest information is required (email, name, phone)'
      });
    }

    if (!totalAmount || totalAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Total amount must be greater than zero'
      });
    }

    // Generate unique order number
    const orderNumber = await generateOrderNumber();

    // Calculate order subtotal
    const orderSubtotal = items.reduce((sum, item) => 
      sum + (item.price * item.quantity), 0);

    // Create order data
    const orderData = {
      orderNumber,
      guestInfo: {
        name: guestInfo.name,
        email: guestInfo.email,
        phone: guestInfo.phone
      },
      items: items.map(item => ({
        coffee: item.productId || item.coffeeId || null,
        name: item.productName || item.name,
        quantity: item.quantity,
        price: item.price,
        subtotal: item.price * item.quantity,
        selectedSize: item.selectedSize || item.size || '250g'
      })),
      subtotal: orderSubtotal,
      totalAmount,
      deliveryAddress: shippingAddress,
      paymentMethod,
      paymentStatus: paymentStatus === 'completed' ? 'paid' : paymentStatus,
      deliveryMethod: (deliveryMethod === 'express' || deliveryMethod === 'standard') ? 'delivery' : deliveryMethod,
      status: 'pending',
      notes: specialInstructions
    };

    // Create order
    const order = await Order.create(orderData);

    console.log('✅ Guest order created:', order.orderNumber);

    // Send guest order confirmation email (non-blocking)
    emailService.sendGuestOrderConfirmation(order, guestInfo)
      .catch(err => {
        console.error('⚠️  Failed to send guest order email:', err);
      });

    res.status(201).json({
      success: true,
      message: 'Guest order created successfully',
      order: order
    });
  } catch (error) {
    console.error('❌ Create guest order error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create guest order',
      error: error.message
    });
  }
};

/**
 * Cancel an order
 * PUT /api/orders/:id/cancel
 * Access: Protected (requires authentication)
 */
const cancelOrder = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const userId = req.user?.userId || req.user?._id || req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    // Find order and verify ownership
    const order = await Order.findById(id);

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Check if user owns this order
    if (order.user?.toString() !== userId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to cancel this order'
      });
    }

    // Check if order can be cancelled (only pending, confirmed, preparing orders)
    const cancellableStatuses = ['pending', 'confirmed', 'accepted', 'preparing'];
    if (!cancellableStatuses.includes(order.status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot cancel order with status: ${order.status}. Orders can only be cancelled if pending or being prepared.`
      });
    }

    console.log(`❌ Cancelling order: ${order.orderNumber} by user ${userId}`);

    // Update order
    order.status = 'cancelled';
    order.cancellation = {
      isCancelled: true,
      reason: reason || 'User requested cancellation',
      cancelledAt: new Date(),
      cancelledBy: userId,
      refundStatus: 'pending'
    };

    // If payment was completed, process refund
    if (order.paymentStatus === 'paid' || order.paymentStatus === 'completed') {
      order.cancellation.refundAmount = order.totalAmount;
      order.cancellation.refundStatus = 'processing';
      order.paymentStatus = 'refunded';

      console.log(`💰 Processing refund of ${order.totalAmount} AED for cancelled order`);
    }

    await order.save();

    // Log cancellation
    await logAudit(userId, 'CANCEL_ORDER', 'Order', id, {
      orderNumber: order.orderNumber,
      reason: reason || 'User requested',
      refundAmount: order.cancellation.refundAmount
    });

    // Send cancellation email
    const user = await User.findById(userId);
    if (user && user.email) {
      emailService.sendOrderCancellation(order, user)
        .catch(err => {
          console.error('⚠️  Failed to send cancellation email:', err);
        });
    }

    res.json({
      success: true,
      message: 'Order cancelled successfully',
      order: order
    });
  } catch (error) {
    console.error('❌ Cancel order error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to cancel order',
      error: error.message
    });
  }
};

module.exports = {
  createOrder,
  createGuestOrder,
  getMyOrders,
  cancelOrder,
  getOrders,
  getOrder,
  updateOrderStatus,
  updatePaymentStatus,
  deleteOrder,
  getOrderStats,
  getOrderAnalytics,
  exportOrders
};
