const mongoose = require('mongoose');

const userFeedbackSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User is required']
  },
  product: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Coffee',
    required: [true, 'Product is required']
  },
  order: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order',
    default: null // Optional: link to specific order
  },
  rating: {
    type: Number,
    required: [true, 'Rating is required'],
    min: [1, 'Rating must be at least 1'],
    max: [5, 'Rating cannot exceed 5']
  },
  title: {
    type: String,
    required: [true, 'Review title is required'],
    trim: true,
    maxlength: [100, 'Title cannot exceed 100 characters']
  },
  comment: {
    type: String,
    required: [true, 'Review comment is required'],
    trim: true,
    maxlength: [1000, 'Comment cannot exceed 1000 characters']
  },
  pros: [{
    type: String,
    trim: true,
    maxlength: [200, 'Pro cannot exceed 200 characters']
  }],
  cons: [{
    type: String,
    trim: true,
    maxlength: [200, 'Con cannot exceed 200 characters']
  }],
  images: [{
    type: String, // URL to uploaded review images
    validate: {
      validator: function(v) {
        return /^https?:\/\/.+/.test(v);
      },
      message: 'Invalid image URL format'
    }
  }],
  helpfulVotes: {
    type: Number,
    default: 0,
    min: [0, 'Helpful votes cannot be negative']
  },
  totalVotes: {
    type: Number,
    default: 0,
    min: [0, 'Total votes cannot be negative']
  },
  isVerifiedPurchase: {
    type: Boolean,
    default: false
  },
  isApproved: {
    type: Boolean,
    default: true // Auto-approve by default, can be moderated
  },
  moderationNotes: {
    type: String,
    trim: true,
    maxlength: [500, 'Moderation notes cannot exceed 500 characters']
  },
  isHidden: {
    type: Boolean,
    default: false
  },
  tags: [{
    type: String,
    trim: true,
    lowercase: true
  }],
  brewingMethod: {
    type: String,
    enum: ['Drip', 'Pour Over', 'French Press', 'Espresso', 'Cold Brew', 'Turkish', 'Other']
  },
  flavorProfile: {
    acidity: {
      type: Number,
      min: 1,
      max: 5
    },
    body: {
      type: Number,
      min: 1,
      max: 5
    },
    sweetness: {
      type: Number,
      min: 1,
      max: 5
    },
    bitterness: {
      type: Number,
      min: 1,
      max: 5
    }
  },
  wouldRecommend: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Compound indexes for better query performance
userFeedbackSchema.index({ product: 1, rating: -1 });
userFeedbackSchema.index({ user: 1, createdAt: -1 });
userFeedbackSchema.index({ isApproved: 1, isHidden: 1, createdAt: -1 });
userFeedbackSchema.index({ product: 1, isApproved: 1, isHidden: 1 });
userFeedbackSchema.index({ helpfulVotes: -1 });

// Ensure one review per user per product (unless multiple orders)
userFeedbackSchema.index({ user: 1, product: 1 }, { unique: true });

// Virtual for helpfulness ratio
userFeedbackSchema.virtual('helpfulnessRatio').get(function() {
  return this.totalVotes > 0 ? (this.helpfulVotes / this.totalVotes) * 100 : 0;
});

// Virtual for review age in days
userFeedbackSchema.virtual('reviewAge').get(function() {
  return Math.floor((Date.now() - this.createdAt) / (1000 * 60 * 60 * 24));
});

// Instance method to vote helpful/unhelpful
userFeedbackSchema.methods.addVote = function(isHelpful = true) {
  this.totalVotes += 1;
  if (isHelpful) {
    this.helpfulVotes += 1;
  }
  return this.save();
};

// Instance method to update approval status
userFeedbackSchema.methods.updateApproval = function(isApproved, moderationNotes = '') {
  this.isApproved = isApproved;
  if (moderationNotes) {
    this.moderationNotes = moderationNotes;
  }
  return this.save();
};

// Static method to get product ratings summary
userFeedbackSchema.statics.getProductRatingSummary = async function(productId) {
  const summary = await this.aggregate([
    {
      $match: {
        product: new mongoose.Types.ObjectId(productId),
        isApproved: true,
        isHidden: false
      }
    },
    {
      $group: {
        _id: null,
        averageRating: { $avg: '$rating' },
        totalReviews: { $sum: 1 },
        ratingDistribution: {
          $push: '$rating'
        }
      }
    },
    {
      $addFields: {
        ratingBreakdown: {
          5: { $size: { $filter: { input: '$ratingDistribution', cond: { $eq: ['$$this', 5] } } } },
          4: { $size: { $filter: { input: '$ratingDistribution', cond: { $eq: ['$$this', 4] } } } },
          3: { $size: { $filter: { input: '$ratingDistribution', cond: { $eq: ['$$this', 3] } } } },
          2: { $size: { $filter: { input: '$ratingDistribution', cond: { $eq: ['$$this', 2] } } } },
          1: { $size: { $filter: { input: '$ratingDistribution', cond: { $eq: ['$$this', 1] } } } }
        }
      }
    }
  ]);

  return summary[0] || {
    averageRating: 0,
    totalReviews: 0,
    ratingBreakdown: { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 }
  };
};

// Static method to get user's reviews
userFeedbackSchema.statics.getUserReviews = function(userId, limit = 10) {
  return this.find({ user: userId })
    .populate('product', 'name image price')
    .sort({ createdAt: -1 })
    .limit(limit);
};

// Static method to get top-rated products
userFeedbackSchema.statics.getTopRatedProducts = async function(limit = 10) {
  return this.aggregate([
    {
      $match: {
        isApproved: true,
        isHidden: false
      }
    },
    {
      $group: {
        _id: '$product',
        averageRating: { $avg: '$rating' },
        reviewCount: { $sum: 1 }
      }
    },
    {
      $match: {
        reviewCount: { $gte: 3 } // At least 3 reviews
      }
    },
    {
      $sort: {
        averageRating: -1,
        reviewCount: -1
      }
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

// Pre-save middleware to verify purchase if order is provided
userFeedbackSchema.pre('save', async function(next) {
  if (this.order && this.isNew) {
    const Order = mongoose.model('Order');
    const order = await Order.findOne({
      _id: this.order,
      user: this.user,
      'items.coffee': this.product
    });
    
    if (order) {
      this.isVerifiedPurchase = true;
    }
  }
  next();
});

// Post-save middleware to update product rating
userFeedbackSchema.post('save', async function() {
  const Coffee = mongoose.model('Coffee');
  const summary = await this.constructor.getProductRatingSummary(this.product);
  
  await Coffee.findByIdAndUpdate(this.product, {
    rating: Math.round(summary.averageRating * 10) / 10, // Round to 1 decimal
    reviewCount: summary.totalReviews
  });
});

module.exports = mongoose.model('UserFeedback', userFeedbackSchema);
