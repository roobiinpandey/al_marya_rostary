const mongoose = require('mongoose');

const productAnalyticsSchema = new mongoose.Schema({
  product: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Coffee',
    required: [true, 'Product is required'],
    index: true
  },
  date: {
    type: Date,
    required: [true, 'Date is required']
  },
  // Daily aggregated metrics
  metrics: {
    views: {
      type: Number,
      default: 0,
      min: [0, 'Views cannot be negative']
    },
    uniqueViews: {
      type: Number,
      default: 0,
      min: [0, 'Unique views cannot be negative']
    },
    addToCart: {
      type: Number,
      default: 0,
      min: [0, 'Add to cart cannot be negative']
    },
    purchases: {
      type: Number,
      default: 0,
      min: [0, 'Purchases cannot be negative']
    },
    revenue: {
      type: Number,
      default: 0,
      min: [0, 'Revenue cannot be negative']
    },
    averageRating: {
      type: Number,
      default: 0,
      min: [0, 'Average rating cannot be negative'],
      max: [5, 'Average rating cannot exceed 5']
    },
    reviewsCount: {
      type: Number,
      default: 0,
      min: [0, 'Reviews count cannot be negative']
    },
    wishlistAdds: {
      type: Number,
      default: 0,
      min: [0, 'Wishlist adds cannot be negative']
    },
    shares: {
      type: Number,
      default: 0,
      min: [0, 'Shares cannot be negative']
    },
    searchImpressions: {
      type: Number,
      default: 0,
      min: [0, 'Search impressions cannot be negative']
    },
    searchClicks: {
      type: Number,
      default: 0,
      min: [0, 'Search clicks cannot be negative']
    }
  },
  // Conversion rates (calculated fields)
  conversions: {
    viewToCart: {
      type: Number,
      default: 0,
      min: [0, 'Conversion rate cannot be negative'],
      max: [100, 'Conversion rate cannot exceed 100%']
    },
    cartToPurchase: {
      type: Number,
      default: 0,
      min: [0, 'Conversion rate cannot be negative'],
      max: [100, 'Conversion rate cannot exceed 100%']
    },
    viewToPurchase: {
      type: Number,
      default: 0,
      min: [0, 'Conversion rate cannot be negative'],
      max: [100, 'Conversion rate cannot exceed 100%']
    },
    searchClickRate: {
      type: Number,
      default: 0,
      min: [0, 'Click rate cannot be negative'],
      max: [100, 'Click rate cannot exceed 100%']
    }
  },
  // Traffic sources
  traffic: {
    direct: { type: Number, default: 0 },
    search: { type: Number, default: 0 },
    category: { type: Number, default: 0 },
    featured: { type: Number, default: 0 },
    recommendations: { type: Number, default: 0 },
    social: { type: Number, default: 0 },
    email: { type: Number, default: 0 },
    other: { type: Number, default: 0 }
  },
  // Device breakdown
  devices: {
    mobile: { type: Number, default: 0 },
    tablet: { type: Number, default: 0 },
    desktop: { type: Number, default: 0 }
  },
  // Platform breakdown
  platforms: {
    ios: { type: Number, default: 0 },
    android: { type: Number, default: 0 },
    web: { type: Number, default: 0 }
  },
  // Geographic data (top countries)
  geography: [{
    country: {
      type: String,
      required: true
    },
    views: {
      type: Number,
      default: 0
    },
    purchases: {
      type: Number,
      default: 0
    }
  }],
  // Additional metadata
  metadata: {
    stockLevel: Number,
    price: Number,
    discountPercentage: Number,
    categoryIds: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Category'
    }],
    isFeatured: Boolean,
    isActive: Boolean
  }
}, {
  timestamps: true
});

// Compound index for efficient querying
productAnalyticsSchema.index({ product: 1, date: -1 });
productAnalyticsSchema.index({ date: -1 });
productAnalyticsSchema.index({ 'metrics.views': -1 });
productAnalyticsSchema.index({ 'metrics.revenue': -1 });

// TTL index to automatically delete old analytics data (1 year)
productAnalyticsSchema.index({ date: 1 }, { expireAfterSeconds: 31536000 });

// Virtual for overall conversion rate
productAnalyticsSchema.virtual('overallConversionRate').get(function() {
  return this.metrics.views > 0 ? (this.metrics.purchases / this.metrics.views) * 100 : 0;
});

// Method to calculate conversion rates
productAnalyticsSchema.methods.calculateConversions = function() {
  const { views, addToCart, purchases } = this.metrics;
  
  this.conversions.viewToCart = views > 0 ? (addToCart / views) * 100 : 0;
  this.conversions.cartToPurchase = addToCart > 0 ? (purchases / addToCart) * 100 : 0;
  this.conversions.viewToPurchase = views > 0 ? (purchases / views) * 100 : 0;
  
  const { searchImpressions, searchClicks } = this.metrics;
  this.conversions.searchClickRate = searchImpressions > 0 ? (searchClicks / searchImpressions) * 100 : 0;
  
  return this;
};

// Static method to record product event
productAnalyticsSchema.statics.recordEvent = async function(productId, eventType, eventData = {}) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  try {
    let analytics = await this.findOne({ product: productId, date: today });
    
    if (!analytics) {
      // Get product metadata
      const Coffee = mongoose.model('Coffee');
      const product = await Coffee.findById(productId);
      
      analytics = new this({
        product: productId,
        date: today,
        metadata: {
          stockLevel: product?.stock || 0,
          price: product?.price || 0,
          categoryIds: product?.categories || [],
          isFeatured: product?.isFeatured || false,
          isActive: product?.isActive || true
        }
      });
    }
    
    // Update metrics based on event type
    switch (eventType) {
      case 'view':
        analytics.metrics.views += 1;
        if (eventData.isUnique) analytics.metrics.uniqueViews += 1;
        break;
      case 'add_to_cart':
        analytics.metrics.addToCart += 1;
        break;
      case 'purchase':
        analytics.metrics.purchases += 1;
        analytics.metrics.revenue += eventData.amount || 0;
        break;
      case 'review':
        analytics.metrics.reviewsCount += 1;
        if (eventData.rating) {
          // Recalculate average rating
          const totalRating = (analytics.metrics.averageRating * (analytics.metrics.reviewsCount - 1)) + eventData.rating;
          analytics.metrics.averageRating = totalRating / analytics.metrics.reviewsCount;
        }
        break;
      case 'wishlist_add':
        analytics.metrics.wishlistAdds += 1;
        break;
      case 'share':
        analytics.metrics.shares += 1;
        break;
      case 'search_impression':
        analytics.metrics.searchImpressions += 1;
        break;
      case 'search_click':
        analytics.metrics.searchClicks += 1;
        break;
    }
    
    // Update traffic source
    if (eventData.source && analytics.traffic.hasOwnProperty(eventData.source)) {
      analytics.traffic[eventData.source] += 1;
    }
    
    // Update device type
    if (eventData.device && analytics.devices.hasOwnProperty(eventData.device)) {
      analytics.devices[eventData.device] += 1;
    }
    
    // Update platform
    if (eventData.platform && analytics.platforms.hasOwnProperty(eventData.platform)) {
      analytics.platforms[eventData.platform] += 1;
    }
    
    // Update geography
    if (eventData.country) {
      const geoIndex = analytics.geography.findIndex(g => g.country === eventData.country);
      if (geoIndex >= 0) {
        if (eventType === 'view') analytics.geography[geoIndex].views += 1;
        if (eventType === 'purchase') analytics.geography[geoIndex].purchases += 1;
      } else {
        analytics.geography.push({
          country: eventData.country,
          views: eventType === 'view' ? 1 : 0,
          purchases: eventType === 'purchase' ? 1 : 0
        });
      }
    }
    
    // Calculate conversion rates
    analytics.calculateConversions();
    
    return await analytics.save();
  } catch (error) {
    console.error('Error recording product event:', error);
    return null;
  }
};

// Static method to get product performance summary
productAnalyticsSchema.statics.getProductPerformance = async function(productId, days = 30) {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);
  
  return this.aggregate([
    {
      $match: {
        product: new mongoose.Types.ObjectId(productId),
        date: { $gte: startDate }
      }
    },
    {
      $group: {
        _id: null,
        totalViews: { $sum: '$metrics.views' },
        totalUniqueViews: { $sum: '$metrics.uniqueViews' },
        totalAddToCart: { $sum: '$metrics.addToCart' },
        totalPurchases: { $sum: '$metrics.purchases' },
        totalRevenue: { $sum: '$metrics.revenue' },
        averageRating: { $avg: '$metrics.averageRating' },
        totalReviews: { $sum: '$metrics.reviewsCount' },
        totalWishlistAdds: { $sum: '$metrics.wishlistAdds' },
        totalShares: { $sum: '$metrics.shares' }
      }
    },
    {
      $addFields: {
        conversionRate: {
          $cond: {
            if: { $gt: ['$totalViews', 0] },
            then: { $multiply: [{ $divide: ['$totalPurchases', '$totalViews'] }, 100] },
            else: 0
          }
        }
      }
    }
  ]);
};

// Static method to get top performing products
productAnalyticsSchema.statics.getTopPerformers = async function(metric = 'revenue', days = 30, limit = 10) {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);
  
  const sortField = `metrics.${metric}`;
  
  return this.aggregate([
    {
      $match: {
        date: { $gte: startDate }
      }
    },
    {
      $group: {
        _id: '$product',
        totalMetric: { $sum: `$${sortField}` },
        totalViews: { $sum: '$metrics.views' },
        totalRevenue: { $sum: '$metrics.revenue' }
      }
    },
    {
      $sort: { totalMetric: -1 }
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

// Static method to get analytics trend
productAnalyticsSchema.statics.getTrend = async function(productId, days = 30) {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);
  
  return this.find({
    product: productId,
    date: { $gte: startDate }
  })
  .sort({ date: 1 })
  .select('date metrics conversions');
};

module.exports = mongoose.model('ProductAnalytics', productAnalyticsSchema);
