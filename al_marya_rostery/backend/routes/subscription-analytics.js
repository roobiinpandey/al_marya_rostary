const express = require('express');
const router = express.Router();
const { Subscription } = require('../models/Subscription');
const Order = require('../models/Order');
const { protect } = require('../middleware/auth');

/**
 * Subscription Analytics Routes
 * Provides detailed analytics for subscription insights
 */

// Get subscription analytics overview
router.get('/overview', protect, async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    
    const dateFilter = {};
    if (startDate) dateFilter.$gte = new Date(startDate);
    if (endDate) dateFilter.$lte = new Date(endDate);
    
    const filter = {};
    if (Object.keys(dateFilter).length > 0) {
      filter.createdAt = dateFilter;
    }
    
    // Basic counts
    const [
      totalSubscriptions,
      activeSubscriptions,
      pausedSubscriptions,
      cancelledSubscriptions,
      trialSubscriptions
    ] = await Promise.all([
      Subscription.countDocuments(filter),
      Subscription.countDocuments({ ...filter, status: 'active' }),
      Subscription.countDocuments({ ...filter, status: 'paused' }),
      Subscription.countDocuments({ ...filter, status: 'cancelled' }),
      Subscription.countDocuments({ ...filter, trialEndsAt: { $exists: true, $ne: null } })
    ]);
    
    // Revenue metrics
    const revenueMetrics = await Subscription.aggregate([
      { $match: { status: 'active' } },
      {
        $group: {
          _id: null,
          mrr: { $sum: '$subscriptionPrice' },
          arr: { $sum: { $multiply: ['$subscriptionPrice', 12] } },
          totalRevenue: { $sum: '$totalAmount' },
          avgSubscriptionValue: { $avg: '$subscriptionPrice' }
        }
      }
    ]);
    
    const revenue = revenueMetrics[0] || {
      mrr: 0,
      arr: 0,
      totalRevenue: 0,
      avgSubscriptionValue: 0
    };
    
    // Churn calculation (cancelled in last 30 days)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    const churned = await Subscription.countDocuments({
      status: 'cancelled',
      cancelledAt: { $gte: thirtyDaysAgo }
    });
    
    const churnRate = activeSubscriptions > 0 
      ? (churned / (activeSubscriptions + churned)) * 100 
      : 0;
    
    // Retention rate
    const retentionRate = totalSubscriptions > 0
      ? ((activeSubscriptions / totalSubscriptions) * 100)
      : 0;
    
    // New subscriptions (last 30 days)
    const newSubscriptions = await Subscription.countDocuments({
      createdAt: { $gte: thirtyDaysAgo }
    });
    
    res.json({
      success: true,
      data: {
        subscriptions: {
          total: totalSubscriptions,
          active: activeSubscriptions,
          paused: pausedSubscriptions,
          cancelled: cancelledSubscriptions,
          trial: trialSubscriptions,
          new: newSubscriptions
        },
        revenue: {
          mrr: Math.round(revenue.mrr * 100) / 100,
          arr: Math.round(revenue.arr * 100) / 100,
          totalRevenue: Math.round(revenue.totalRevenue * 100) / 100,
          avgSubscriptionValue: Math.round(revenue.avgSubscriptionValue * 100) / 100
        },
        metrics: {
          churnRate: Math.round(churnRate * 100) / 100,
          retentionRate: Math.round(retentionRate * 100) / 100,
          growthRate: newSubscriptions > 0 && activeSubscriptions > 0
            ? Math.round((newSubscriptions / activeSubscriptions) * 100 * 100) / 100
            : 0
        }
      }
    });
  } catch (error) {
    console.error('Error fetching analytics overview:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch analytics overview',
      error: error.message
    });
  }
});

// Get frequency distribution
router.get('/frequency-distribution', protect, async (req, res) => {
  try {
    const distribution = await Subscription.aggregate([
      { $match: { status: { $in: ['active', 'paused'] } } },
      {
        $group: {
          _id: '$frequency',
          count: { $sum: 1 },
          revenue: { $sum: '$subscriptionPrice' }
        }
      },
      { $sort: { count: -1 } }
    ]);
    
    res.json({
      success: true,
      data: distribution.map(item => ({
        frequency: item._id,
        count: item.count,
        revenue: Math.round(item.revenue * 100) / 100
      }))
    });
  } catch (error) {
    console.error('Error fetching frequency distribution:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch frequency distribution',
      error: error.message
    });
  }
});

// Get plan distribution
router.get('/plan-distribution', protect, async (req, res) => {
  try {
    const distribution = await Subscription.aggregate([
      { $match: { status: { $in: ['active', 'paused'] } } },
      {
        $group: {
          _id: '$planId',
          planName: { $first: '$planName' },
          count: { $sum: 1 },
          revenue: { $sum: '$subscriptionPrice' }
        }
      },
      { $sort: { count: -1 } }
    ]);
    
    res.json({
      success: true,
      data: distribution.map(item => ({
        planId: item._id,
        planName: item.planName,
        count: item.count,
        revenue: Math.round(item.revenue * 100) / 100
      }))
    });
  } catch (error) {
    console.error('Error fetching plan distribution:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch plan distribution',
      error: error.message
    });
  }
});

// Get subscription growth over time
router.get('/growth', protect, async (req, res) => {
  try {
    const { period = 'month' } = req.query; // day, week, month
    
    let groupBy;
    switch (period) {
      case 'day':
        groupBy = { 
          year: { $year: '$createdAt' },
          month: { $month: '$createdAt' },
          day: { $dayOfMonth: '$createdAt' }
        };
        break;
      case 'week':
        groupBy = { 
          year: { $year: '$createdAt' },
          week: { $week: '$createdAt' }
        };
        break;
      default:
        groupBy = { 
          year: { $year: '$createdAt' },
          month: { $month: '$createdAt' }
        };
    }
    
    const growth = await Subscription.aggregate([
      {
        $group: {
          _id: groupBy,
          newSubscriptions: { $sum: 1 },
          revenue: { $sum: '$subscriptionPrice' }
        }
      },
      { $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 } },
      { $limit: 12 }
    ]);
    
    res.json({
      success: true,
      data: growth.map(item => ({
        period: item._id,
        newSubscriptions: item.newSubscriptions,
        revenue: Math.round(item.revenue * 100) / 100
      }))
    });
  } catch (error) {
    console.error('Error fetching growth data:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch growth data',
      error: error.message
    });
  }
});

// Get customer lifetime value (LTV)
router.get('/ltv', protect, async (req, res) => {
  try {
    const ltvData = await Subscription.aggregate([
      { $match: { status: { $in: ['active', 'cancelled'] } } },
      {
        $group: {
          _id: null,
          avgTotalAmount: { $avg: '$totalAmount' },
          avgDeliveries: { $avg: '$totalDeliveries' },
          avgLifetimeMonths: { 
            $avg: {
              $divide: [
                { $subtract: ['$updatedAt', '$createdAt'] },
                1000 * 60 * 60 * 24 * 30 // Convert to months
              ]
            }
          }
        }
      }
    ]);
    
    const ltv = ltvData[0] || {
      avgTotalAmount: 0,
      avgDeliveries: 0,
      avgLifetimeMonths: 0
    };
    
    res.json({
      success: true,
      data: {
        avgLifetimeValue: Math.round(ltv.avgTotalAmount * 100) / 100,
        avgDeliveries: Math.round(ltv.avgDeliveries * 10) / 10,
        avgLifetimeMonths: Math.round(ltv.avgLifetimeMonths * 10) / 10
      }
    });
  } catch (error) {
    console.error('Error fetching LTV data:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch LTV data',
      error: error.message
    });
  }
});

// Get cancellation reasons
router.get('/cancellation-reasons', protect, async (req, res) => {
  try {
    const reasons = await Subscription.aggregate([
      { $match: { status: 'cancelled', cancellationReason: { $exists: true, $ne: null } } },
      {
        $group: {
          _id: '$cancellationReason',
          count: { $sum: 1 }
        }
      },
      { $sort: { count: -1 } },
      { $limit: 10 }
    ]);
    
    res.json({
      success: true,
      data: reasons.map(item => ({
        reason: item._id,
        count: item.count
      }))
    });
  } catch (error) {
    console.error('Error fetching cancellation reasons:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch cancellation reasons',
      error: error.message
    });
  }
});

// Get payment method distribution
router.get('/payment-methods', protect, async (req, res) => {
  try {
    const distribution = await Subscription.aggregate([
      { $match: { status: { $in: ['active', 'paused'] } } },
      {
        $group: {
          _id: '$paymentMethod',
          count: { $sum: 1 }
        }
      },
      { $sort: { count: -1 } }
    ]);
    
    res.json({
      success: true,
      data: distribution.map(item => ({
        paymentMethod: item._id || 'Not Set',
        count: item.count
      }))
    });
  } catch (error) {
    console.error('Error fetching payment method distribution:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch payment method distribution',
      error: error.message
    });
  }
});

// Get upcoming deliveries forecast
router.get('/upcoming-deliveries', protect, async (req, res) => {
  try {
    const { days = 7 } = req.query;
    
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + parseInt(days));
    
    const upcomingDeliveries = await Subscription.aggregate([
      {
        $match: {
          status: 'active',
          nextDelivery: {
            $gte: new Date(),
            $lte: endDate
          }
        }
      },
      {
        $group: {
          _id: {
            $dateToString: { format: '%Y-%m-%d', date: '$nextDelivery' }
          },
          count: { $sum: 1 },
          products: { $push: '$productName' }
        }
      },
      { $sort: { _id: 1 } }
    ]);
    
    res.json({
      success: true,
      data: upcomingDeliveries.map(item => ({
        date: item._id,
        deliveryCount: item.count,
        topProducts: [...new Set(item.products)].slice(0, 5)
      }))
    });
  } catch (error) {
    console.error('Error fetching upcoming deliveries:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch upcoming deliveries',
      error: error.message
    });
  }
});

// Get cohort analysis
router.get('/cohorts', protect, async (req, res) => {
  try {
    const cohorts = await Subscription.aggregate([
      {
        $group: {
          _id: {
            year: { $year: '$startDate' },
            month: { $month: '$startDate' }
          },
          totalSubscriptions: { $sum: 1 },
          activeSubscriptions: {
            $sum: { $cond: [{ $eq: ['$status', 'active'] }, 1, 0] }
          },
          totalRevenue: { $sum: '$totalAmount' }
        }
      },
      { $sort: { '_id.year': -1, '_id.month': -1 } },
      { $limit: 12 }
    ]);
    
    res.json({
      success: true,
      data: cohorts.map(cohort => ({
        period: `${cohort._id.year}-${String(cohort._id.month).padStart(2, '0')}`,
        totalSubscriptions: cohort.totalSubscriptions,
        activeSubscriptions: cohort.activeSubscriptions,
        retentionRate: cohort.totalSubscriptions > 0
          ? Math.round((cohort.activeSubscriptions / cohort.totalSubscriptions) * 100 * 100) / 100
          : 0,
        totalRevenue: Math.round(cohort.totalRevenue * 100) / 100
      }))
    });
  } catch (error) {
    console.error('Error fetching cohort analysis:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch cohort analysis',
      error: error.message
    });
  }
});

module.exports = router;
