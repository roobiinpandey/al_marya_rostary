const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  // Core Review Data
  productId: {
    type: String,
    required: true,
    index: true
  },
  productName: {
    type: String,
    required: true
  },
  userId: {
    type: String,  // Firebase UID from User.firebaseUid
    required: true,
    index: true,
    ref: 'User'
  },
  userName: {
    type: String,
    required: true
  },
  userEmail: {
    type: String,
    required: true
  },
  
  // Review Content
  rating: {
    type: Number,
    required: true,
    min: 1,
    max: 5
  },
  title: {
    type: String,
    maxlength: 100
  },
  comment: {
    type: String,
    required: true,
    minlength: 10,
    maxlength: 500
  },
  
  // Interaction Metrics
  helpfulCount: {
    type: Number,
    default: 0
  },
  helpfulVotes: [{
    userId: String,
    voteType: {
      type: String,
      enum: ['helpful', 'not_helpful']
    },
    createdAt: {
      type: Date,
      default: Date.now
    }
  }],
  
  // Review Status
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'flagged'],
    default: 'pending'
  },
  moderationNotes: {
    type: String
  },
  moderatedBy: {
    type: String
  },
  moderatedAt: {
    type: Date
  },
  
  // Verification
  isVerifiedPurchase: {
    type: Boolean,
    default: false
  },
  orderNumber: {
    type: String
  },
  
  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now,
    index: true
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Indexes for efficient queries
reviewSchema.index({ productId: 1, createdAt: -1 });
reviewSchema.index({ userId: 1, createdAt: -1 });
reviewSchema.index({ status: 1, createdAt: -1 });
reviewSchema.index({ rating: 1 });

// Virtual for formatted date
reviewSchema.virtual('formattedDate').get(function() {
  const now = new Date();
  const diffTime = Math.abs(now - this.createdAt);
  const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
  
  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return '1 day ago';
  if (diffDays < 7) return `${diffDays} days ago`;
  if (diffDays < 14) return '1 week ago';
  if (diffDays < 30) return `${Math.floor(diffDays / 7)} weeks ago`;
  if (diffDays < 60) return '1 month ago';
  return `${Math.floor(diffDays / 30)} months ago`;
});

// Methods
reviewSchema.methods.markHelpful = function(userId, helpful = true) {
  // Remove existing vote
  this.helpfulVotes = this.helpfulVotes.filter(vote => vote.userId !== userId);
  
  // Add new vote
  this.helpfulVotes.push({
    userId,
    voteType: helpful ? 'helpful' : 'not_helpful'
  });
  
  // Update count
  this.helpfulCount = this.helpfulVotes.filter(vote => vote.voteType === 'helpful').length;
  
  return this.save();
};

reviewSchema.methods.approve = function(moderatorId, notes = '') {
  this.status = 'approved';
  this.moderatedBy = moderatorId;
  this.moderatedAt = new Date();
  this.moderationNotes = notes;
  return this.save();
};

reviewSchema.methods.reject = function(moderatorId, notes = '') {
  this.status = 'rejected';
  this.moderatedBy = moderatorId;
  this.moderatedAt = new Date();
  this.moderationNotes = notes;
  return this.save();
};

// Static methods
reviewSchema.statics.getProductAverageRating = async function(productId) {
  const result = await this.aggregate([
    { $match: { productId, status: 'approved' } },
    {
      $group: {
        _id: null,
        averageRating: { $avg: '$rating' },
        totalReviews: { $sum: 1 },
        ratingDistribution: {
          $push: '$rating'
        }
      }
    }
  ]);
  
  if (!result.length) {
    return {
      averageRating: 0,
      totalReviews: 0,
      ratingDistribution: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 }
    };
  }
  
  const data = result[0];
  const distribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
  data.ratingDistribution.forEach(rating => {
    distribution[rating]++;
  });
  
  return {
    averageRating: Math.round(data.averageRating * 10) / 10,
    totalReviews: data.totalReviews,
    ratingDistribution: distribution
  };
};

reviewSchema.statics.getUserReviewForProduct = async function(userId, productId) {
  return this.findOne({ userId, productId });
};

module.exports = mongoose.model('Review', reviewSchema);
