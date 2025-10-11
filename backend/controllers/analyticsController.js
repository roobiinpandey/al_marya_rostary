const UserAnalytics = require('../models/UserAnalytics');
const ProductAnalytics = require('../models/ProductAnalytics');
const User = require('../models/User');
const Coffee = require('../models/Coffee');
const Order = require('../models/Order');
const mongoose = require('mongoose');

// User Analytics Functions

// @desc    Track user event
// @route   POST /api/analytics/track
// @access  Private
const trackUserEvent = async (req, res) => {
  try {
    const {
      sessionId,
      eventType,
      eventData = {},
      deviceType,
      platform,
      appVersion
    } = req.body;

    const ipAddress = req.ip || req.connection.remoteAddress;
    const userAgent = req.get('User-Agent');

    // Enhance event data with additional context
    const enhancedEventData = {
      ...eventData,
      deviceType,
      platform,
      appVersion,
      timestamp: new Date()
    };

    const analytics = await UserAnalytics.trackEvent(
      req.user.userId,
      sessionId,
      eventType,
      enhancedEventData,
      ipAddress,
      userAgent
    );

    // Also track product-specific events
    if (eventData.productId && ['product_view', 'add_to_cart', 'purchase', 'wishlist_add', 'share'].includes(eventType)) {
      let productEventType = eventType;
      if (eventType === 'product_view') productEventType = 'view';
      if (eventType === 'add_to_cart') productEventType = 'add_to_cart';
      if (eventType === 'wishlist_add') productEventType = 'wishlist_add';
      
      await ProductAnalytics.recordEvent(eventData.productId, productEventType, {
        source: eventData.source || 'direct',
        device: deviceType,
        platform,
        country: eventData.country,
        amount: eventData.amount,
        isUnique: eventData.isUnique
      });
    }

    res.json({
      success: true,
      message: 'Event tracked successfully',
      data: analytics ? { eventId: analytics._id } : null
    });
  } catch (error) {
    console.error('Track user event error:', error);
    // Don't return error to avoid breaking user experience
    res.json({
      success: true,
      message: 'Event processed'
    });
  }
};

// @desc    Get user activity summary
// @route   GET /api/analytics/user/activity
// @access  Private
const getUserActivity = async (req, res) => {
  try {
    const days = parseInt(req.query.days) || 30;
    const activity = await UserAnalytics.getUserActivitySummary(req.user.userId, days);

    res.json({
      success: true,
      data: {
        period: `${days} days`,
        activity
      }
    });
  } catch (error) {
    console.error('Get user activity error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user activity',
      error: error.message
    });
  }
};

// @desc    Get user journey
// @route   GET /api/analytics/user/journey
// @access  Private
const getUserJourney = async (req, res) => {
  try {
    const { sessionId } = req.query;
    const limit = parseInt(req.query.limit) || 50;
    
    const journey = await UserAnalytics.getUserJourney(
      req.user.userId,
      sessionId,
      limit
    );

    res.json({
      success: true,
      data: journey
    });
  } catch (error) {
    console.error('Get user journey error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user journey',
      error: error.message
    });
  }
};

// Product Analytics Functions

// @desc    Get product performance
// @route   GET /api/analytics/product/:productId
// @access  Public
const getProductPerformance = async (req, res) => {
  try {
    const { productId } = req.params;
    const days = parseInt(req.query.days) || 30;

    const performance = await ProductAnalytics.getProductPerformance(productId, days);
    const trend = await ProductAnalytics.getTrend(productId, days);

    res.json({
      success: true,
      data: {
        period: `${days} days`,
        performance: performance[0] || {},
        trend
      }
    });
  } catch (error) {
    console.error('Get product performance error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching product performance',
      error: error.message
    });
  }
};

// @desc    Get popular products
// @route   GET /api/analytics/products/popular
// @access  Public
const getPopularProducts = async (req, res) => {
  try {
    const days = parseInt(req.query.days) || 30;
    const limit = parseInt(req.query.limit) || 10;

    const popularProducts = await UserAnalytics.getPopularProducts(days, limit);

    res.json({
      success: true,
      data: {
        period: `${days} days`,
        products: popularProducts
      }
    });
  } catch (error) {
    console.error('Get popular products error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching popular products',
      error: error.message
    });
  }
};

// @desc    Get top performing products
// @route   GET /api/analytics/products/top-performers
// @access  Public
const getTopPerformers = async (req, res) => {
  try {
    const metric = req.query.metric || 'revenue'; // views, revenue, purchases
    const days = parseInt(req.query.days) || 30;
    const limit = parseInt(req.query.limit) || 10;

    const topPerformers = await ProductAnalytics.getTopPerformers(metric, days, limit);

    res.json({
      success: true,
      data: {
        period: `${days} days`,
        metric,
        products: topPerformers
      }
    });
  } catch (error) {
    console.error('Get top performers error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching top performers',
      error: error.message
    });
  }
};

// @desc    Get conversion funnel
// @route   GET /api/analytics/conversion-funnel
// @access  Public
const getConversionFunnel = async (req, res) => {
  try {
    const days = parseInt(req.query.days) || 30;
    const funnel = await UserAnalytics.getConversionFunnel(days);

    // Calculate conversion rates
    const funnelWithRates = {
      product_view: {
        count: funnel.product_view || 0,
        rate: 100 // Base rate
      },
      add_to_cart: {
        count: funnel.add_to_cart || 0,
        rate: funnel.product_view > 0 ? (funnel.add_to_cart / funnel.product_view) * 100 : 0
      },
      checkout_started: {
        count: funnel.checkout_started || 0,
        rate: funnel.add_to_cart > 0 ? (funnel.checkout_started / funnel.add_to_cart) * 100 : 0
      },
      checkout_completed: {
        count: funnel.checkout_completed || 0,
        rate: funnel.checkout_started > 0 ? (funnel.checkout_completed / funnel.checkout_started) * 100 : 0
      },
      order_placed: {
        count: funnel.order_placed || 0,
        rate: funnel.checkout_completed > 0 ? (funnel.order_placed / funnel.checkout_completed) * 100 : 0
      }
    };

    res.json({
      success: true,
      data: {
        period: `${days} days`,
        funnel: funnelWithRates,
        overallConversion: funnel.product_view > 0 ? (funnel.order_placed / funnel.product_view) * 100 : 0
      }
    });
  } catch (error) {
    console.error('Get conversion funnel error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching conversion funnel',
      error: error.message
    });
  }
};

// Admin Analytics Functions

// @desc    Get dashboard overview
// @route   GET /api/analytics/admin/dashboard
// @access  Private/Admin
const getDashboardOverview = async (req, res) => {
  try {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 30); // Last 30 days
    
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);

    // Get basic counts
    const totalUsers = await User.countDocuments();
    const totalProducts = await Coffee.countDocuments();
    const totalOrders = await Order.countDocuments({
      createdAt: { $gte: startDate, $lte: endDate }
    });

    // Get revenue data
    const revenueAggregation = await Order.aggregate([
      {
        $match: {
          createdAt: { $gte: startDate, $lte: endDate },
          status: { $in: ['delivered', 'completed'] }
        }
      },
      {
        $group: {
          _id: null,
          totalRevenue: { $sum: '$totalAmount' }
        }
      }
    ]);

    const totalRevenue = revenueAggregation[0]?.totalRevenue || 0;

    // Get monthly revenue data for chart
    const monthlyRevenue = await Order.aggregate([
      {
        $match: {
          createdAt: { $gte: new Date(new Date().getFullYear(), 0, 1) }, // This year
          status: { $in: ['delivered', 'completed'] }
        }
      },
      {
        $group: {
          _id: { 
            year: { $year: '$createdAt' },
            month: { $month: '$createdAt' }
          },
          revenue: { $sum: '$totalAmount' }
        }
      },
      {
        $sort: { '_id.year': 1, '_id.month': 1 }
      }
    ]);

    // Format monthly data for chart
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const revenueData = {
      labels: [],
      values: []
    };

    for (let i = 0; i < 12; i++) {
      revenueData.labels.push(months[i]);
      const monthData = monthlyRevenue.find(item => item._id.month === i + 1);
      revenueData.values.push(monthData ? monthData.revenue : 0);
    }

    // Get recent orders
    const recentOrders = await Order.find()
      .populate('user', 'name email')
      .sort({ createdAt: -1 })
      .limit(10)
      .select('_id user totalAmount status createdAt items');

    // Get today's stats
    const todayOrders = await Order.countDocuments({
      createdAt: { $gte: todayStart, $lte: todayEnd }
    });

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

    // Get order status stats
    const orderStats = await Order.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      }
    ]);

    const statusCounts = {
      pending: 0,
      confirmed: 0,
      preparing: 0,
      ready: 0,
      delivered: 0,
      cancelled: 0
    };

    orderStats.forEach(stat => {
      if (statusCounts.hasOwnProperty(stat._id)) {
        statusCounts[stat._id] = stat.count;
      }
    });

    res.json({
      success: true,
      data: {
        totalUsers,
        totalProducts,
        totalOrders,
        totalRevenue,
        todayOrders,
        todayRevenue: todayRevenue[0]?.revenue || 0,
        revenueData,
        recentOrders,
        orderStats: statusCounts
      }
    });
  } catch (error) {
    console.error('Get dashboard overview error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching dashboard overview',
      error: error.message
    });
  }
};

// @desc    Get user analytics report
// @route   GET /api/admin/analytics/users
// @access  Private/Admin
const getUserAnalyticsReport = async (req, res) => {
  try {
    const days = parseInt(req.query.days) || 30;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    // User registration trend
    const registrationTrend = await User.aggregate([
      {
        $match: {
          createdAt: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: {
            date: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } }
          },
          registrations: { $sum: 1 }
        }
      },
      {
        $sort: { '_id.date': 1 }
      }
    ]);

    // User activity breakdown
    const activityBreakdown = await UserAnalytics.aggregate([
      {
        $match: {
          timestamp: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: '$eventType',
          count: { $sum: 1 }
        }
      },
      {
        $sort: { count: -1 }
      }
    ]);

    // Device and platform breakdown
    const deviceBreakdown = await UserAnalytics.aggregate([
      {
        $match: {
          timestamp: { $gte: startDate },
          'eventData.deviceType': { $exists: true }
        }
      },
      {
        $group: {
          _id: '$eventData.deviceType',
          count: { $sum: 1 }
        }
      }
    ]);

    const platformBreakdown = await UserAnalytics.aggregate([
      {
        $match: {
          timestamp: { $gte: startDate },
          'eventData.platform': { $exists: true }
        }
      },
      {
        $group: {
          _id: '$eventData.platform',
          count: { $sum: 1 }
        }
      }
    ]);

    res.json({
      success: true,
      data: {
        period: `${days} days`,
        registrationTrend,
        activityBreakdown,
        deviceBreakdown,
        platformBreakdown
      }
    });
  } catch (error) {
    console.error('Get user analytics report error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user analytics report',
      error: error.message
    });
  }
};

// @desc    Get product analytics report
// @route   GET /api/admin/analytics/products
// @access  Private/Admin
const getProductAnalyticsReport = async (req, res) => {
  try {
    const days = parseInt(req.query.days) || 30;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    // Top performers by different metrics
    const topByViews = await ProductAnalytics.getTopPerformers('views', days, 10);
    const topByRevenue = await ProductAnalytics.getTopPerformers('revenue', days, 10);
    const topByPurchases = await ProductAnalytics.getTopPerformers('purchases', days, 10);

    // Category performance
    const categoryPerformance = await ProductAnalytics.aggregate([
      {
        $match: {
          date: { $gte: startDate }
        }
      },
      {
        $lookup: {
          from: 'coffees',
          localField: 'product',
          foreignField: '_id',
          as: 'productInfo'
        }
      },
      {
        $unwind: '$productInfo'
      },
      {
        $unwind: '$productInfo.categories'
      },
      {
        $group: {
          _id: '$productInfo.categories',
          totalViews: { $sum: '$metrics.views' },
          totalRevenue: { $sum: '$metrics.revenue' },
          totalPurchases: { $sum: '$metrics.purchases' }
        }
      },
      {
        $sort: { totalRevenue: -1 }
      }
    ]);

    res.json({
      success: true,
      data: {
        period: `${days} days`,
        topPerformers: {
          byViews: topByViews,
          byRevenue: topByRevenue,
          byPurchases: topByPurchases
        },
        categoryPerformance
      }
    });
  } catch (error) {
    console.error('Get product analytics report error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching product analytics report',
      error: error.message
    });
  }
};

module.exports = {
  // User Analytics
  trackUserEvent,
  getUserActivity,
  getUserJourney,
  
  // Product Analytics
  getProductPerformance,
  getPopularProducts,
  getTopPerformers,
  getConversionFunnel,
  
  // Admin Analytics
  getDashboardOverview,
  getUserAnalyticsReport,
  getProductAnalyticsReport
};
