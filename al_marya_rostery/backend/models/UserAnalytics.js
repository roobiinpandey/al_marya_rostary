const mongoose = require('mongoose');

const userAnalyticsSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User is required']
  },
  sessionId: {
    type: String,
    required: [true, 'Session ID is required'],
    index: true
  },
  eventType: {
    type: String,
    required: [true, 'Event type is required'],
    enum: [
      'page_view',
      'product_view',
      'product_search',
      'add_to_cart',
      'remove_from_cart',
      'checkout_started',
      'checkout_completed',
      'order_placed',
      'user_registration',
      'user_login',
      'user_logout',
      'review_submitted',
      'wishlist_add',
      'wishlist_remove',
      'category_browse',
      'app_launch',
      'app_background',
      'push_notification_opened',
      'email_opened',
      'coupon_used',
      'social_share',
      'support_contact',
      'profile_updated'
    ]
  },
  eventData: {
    // Flexible data structure for different event types
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Coffee'
    },
    categoryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Category'
    },
    orderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order'
    },
    searchQuery: String,
    pageUrl: String,
    referrer: String,
    cartValue: Number,
    orderValue: Number,
    couponCode: String,
    deviceType: {
      type: String,
      enum: ['mobile', 'tablet', 'desktop', 'unknown']
    },
    platform: {
      type: String,
      enum: ['ios', 'android', 'web', 'unknown']
    },
    appVersion: String,
    location: {
      country: String,
      city: String,
      latitude: Number,
      longitude: Number
    },
    duration: Number, // Duration in milliseconds for time-based events
    customAttributes: {
      type: mongoose.Schema.Types.Mixed,
      default: {}
    }
  },
  timestamp: {
    type: Date,
    default: Date.now
  },
  ipAddress: {
    type: String,
    default: null
  },
  userAgent: {
    type: String,
    default: null
  }
}, {
  timestamps: false, // Using custom timestamp field
  collection: 'useranalytics' // Explicit collection name
});

// Indexes for efficient querying
userAnalyticsSchema.index({ user: 1, timestamp: -1 });
userAnalyticsSchema.index({ eventType: 1, timestamp: -1 });
userAnalyticsSchema.index({ sessionId: 1, timestamp: 1 });
userAnalyticsSchema.index({ 'eventData.productId': 1, eventType: 1 });
userAnalyticsSchema.index({ timestamp: -1 }); // For time-based queries

// TTL index to automatically delete old analytics data (90 days)
userAnalyticsSchema.index({ timestamp: 1 }, { expireAfterSeconds: 7776000 });

// Static method to track user event
userAnalyticsSchema.statics.trackEvent = async function(userId, sessionId, eventType, eventData = {}, ipAddress = null, userAgent = null) {
  try {
    const analytics = new this({
      user: userId,
      sessionId,
      eventType,
      eventData,
      ipAddress,
      userAgent,
      timestamp: new Date()
    });
    
    return await analytics.save();
  } catch (error) {
    console.error('Error tracking user event:', error);
    // Don't throw error to avoid breaking main application flow
    return null;
  }
};

// Static method to get user activity summary
userAnalyticsSchema.statics.getUserActivitySummary = async function(userId, days = 30) {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);
  
  return this.aggregate([
    {
      $match: {
        user: new mongoose.Types.ObjectId(userId),
        timestamp: { $gte: startDate }
      }
    },
    {
      $group: {
        _id: '$eventType',
        count: { $sum: 1 },
        lastOccurrence: { $max: '$timestamp' }
      }
    },
    {
      $sort: { count: -1 }
    }
  ]);
};

// Static method to get daily active users
userAnalyticsSchema.statics.getDailyActiveUsers = async function(days = 7) {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);
  
  return this.aggregate([
    {
      $match: {
        timestamp: { $gte: startDate },
        eventType: { $in: ['app_launch', 'user_login', 'page_view'] }
      }
    },
    {
      $group: {
        _id: {
          date: { $dateToString: { format: '%Y-%m-%d', date: '$timestamp' } },
          user: '$user'
        }
      }
    },
    {
      $group: {
        _id: '$_id.date',
        activeUsers: { $sum: 1 }
      }
    },
    {
      $sort: { _id: 1 }
    }
  ]);
};

// Static method to get popular products
userAnalyticsSchema.statics.getPopularProducts = async function(days = 30, limit = 10) {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);
  
  return this.aggregate([
    {
      $match: {
        timestamp: { $gte: startDate },
        eventType: 'product_view',
        'eventData.productId': { $exists: true }
      }
    },
    {
      $group: {
        _id: '$eventData.productId',
        viewCount: { $sum: 1 },
        uniqueUsers: { $addToSet: '$user' }
      }
    },
    {
      $addFields: {
        uniqueUserCount: { $size: '$uniqueUsers' }
      }
    },
    {
      $sort: { viewCount: -1 }
    },
    {
      $limit: limit
    },
    {
      $lookup: {
        from: 'coffees',
        localField: '_id',
        foreignField: '_id',
        as: 'product'
      }
    },
    {
      $unwind: '$product'
    }
  ]);
};

// Static method to get conversion funnel
userAnalyticsSchema.statics.getConversionFunnel = async function(days = 30) {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);
  
  const funnelSteps = [
    'product_view',
    'add_to_cart',
    'checkout_started',
    'checkout_completed',
    'order_placed'
  ];
  
  const results = {};
  
  for (const step of funnelSteps) {
    const count = await this.countDocuments({
      timestamp: { $gte: startDate },
      eventType: step
    });
    results[step] = count;
  }
  
  return results;
};

// Static method to get user journey
userAnalyticsSchema.statics.getUserJourney = function(userId, sessionId = null, limit = 50) {
  const query = { user: userId };
  if (sessionId) {
    query.sessionId = sessionId;
  }
  
  return this.find(query)
    .sort({ timestamp: -1 })
    .limit(limit)
    .populate('eventData.productId', 'name price image')
    .populate('eventData.categoryId', 'name')
    .populate('eventData.orderId', 'orderNumber totalAmount');
};

module.exports = mongoose.model('UserAnalytics', userAnalyticsSchema);
