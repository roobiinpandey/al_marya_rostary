const Order = require('../models/Order');
const Coffee = require('../models/Coffee');
const User = require('../models/User');
const { logAudit } = require('../utils/auditLogger');

// Get all orders with pagination and filtering
const getOrders = async (req, res) => {
  try {
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

    // Execute query
    const orders = await Order.find(query)
      .populate('user', 'name email phone')
      .populate('items.coffee', 'name image price')
      .sort(sortOptions)
      .skip(skip)
      .limit(limitNum);

    const totalOrders = await Order.countDocuments(query);
    const totalPages = Math.ceil(totalOrders / limitNum);

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
      .populate('items.coffee', 'name image price variants');

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
      .populate('items.coffee', 'name image price');

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

// Get order statistics
const getOrderStats = async (req, res) => {
  try {
    const { period = '30d' } = req.query;
    
    // Calculate date range based on period
    let startDate = new Date();
    switch (period) {
      case '24h':
        startDate.setHours(startDate.getHours() - 24);
        break;
      case '7d':
        startDate.setDate(startDate.getDate() - 7);
        break;
      case '30d':
        startDate.setDate(startDate.getDate() - 30);
        break;
      case '3m':
        startDate.setMonth(startDate.getMonth() - 3);
        break;
      case '1y':
        startDate.setFullYear(startDate.getFullYear() - 1);
        break;
      default:
        startDate.setDate(startDate.getDate() - 30);
    }

    // Get basic stats
    const totalOrders = await Order.countDocuments();
    const totalRevenue = await Order.aggregate([
      { $match: { paymentStatus: 'paid' } },
      { $group: { _id: null, total: { $sum: '$totalAmount' } } }
    ]);

    // Get period stats
    const periodStats = await Order.aggregate([
      { $match: { createdAt: { $gte: startDate } } },
      {
        $group: {
          _id: null,
          totalOrders: { $sum: 1 },
          totalRevenue: { 
            $sum: { 
              $cond: [{ $eq: ['$paymentStatus', 'paid'] }, '$totalAmount', 0] 
            } 
          },
          averageOrderValue: { $avg: '$totalAmount' },
          pendingOrders: {
            $sum: { $cond: [{ $eq: ['$status', 'pending'] }, 1, 0] }
          },
          confirmedOrders: {
            $sum: { $cond: [{ $eq: ['$status', 'confirmed'] }, 1, 0] }
          },
          preparingOrders: {
            $sum: { $cond: [{ $eq: ['$status', 'preparing'] }, 1, 0] }
          },
          readyOrders: {
            $sum: { $cond: [{ $eq: ['$status', 'ready'] }, 1, 0] }
          },
          deliveredOrders: {
            $sum: { $cond: [{ $eq: ['$status', 'delivered'] }, 1, 0] }
          },
          cancelledOrders: {
            $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] }
          }
        }
      }
    ]);

    // Get payment method breakdown
    const paymentMethods = await Order.aggregate([
      { $match: { createdAt: { $gte: startDate }, paymentStatus: 'paid' } },
      {
        $group: {
          _id: '$paymentMethod',
          count: { $sum: 1 },
          revenue: { $sum: '$totalAmount' }
        }
      }
    ]);

    // Get delivery method breakdown
    const deliveryMethods = await Order.aggregate([
      { $match: { createdAt: { $gte: startDate } } },
      {
        $group: {
          _id: '$deliveryMethod',
          count: { $sum: 1 }
        }
      }
    ]);

    // Get recent orders
    const recentOrders = await Order.find({})
      .sort({ createdAt: -1 })
      .limit(5)
      .populate('user', 'name email')
      .select('orderNumber status totalAmount createdAt');

    const stats = periodStats[0] || {
      totalOrders: 0,
      totalRevenue: 0,
      averageOrderValue: 0,
      pendingOrders: 0,
      confirmedOrders: 0,
      preparingOrders: 0,
      readyOrders: 0,
      deliveredOrders: 0,
      cancelledOrders: 0
    };

    res.json({
      success: true,
      data: {
        overview: {
          totalOrdersAllTime: totalOrders,
          totalRevenueAllTime: totalRevenue[0]?.total || 0,
          ...stats
        },
        paymentMethods,
        deliveryMethods,
        recentOrders,
        period
      }
    });
  } catch (error) {
    console.error('Get order stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve order statistics',
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
      .sort({ createdAt: -1 });

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

module.exports = {
  getOrders,
  getOrder,
  updateOrderStatus,
  updatePaymentStatus,
  deleteOrder,
  getOrderStats,
  getOrderAnalytics,
  exportOrders
};
