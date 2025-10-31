const mongoose = require('mongoose');

const quickCategorySchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Quick category title is required'],
    trim: true,
    maxlength: [50, 'Title cannot be more than 50 characters']
  },
  subtitle: {
    type: String,
    required: [true, 'Subtitle is required'],
    trim: true,
    maxlength: [100, 'Subtitle cannot be more than 100 characters']
  },
  imageUrl: {
    type: String,
    required: [true, 'Image URL is required'],
    trim: true
  },
  color: {
    type: String,
    required: [true, 'Color is required'],
    default: '#A89A6A', // Default coffee brown
    validate: {
      validator: function(v) {
        return /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(v);
      },
      message: 'Color must be a valid hex color code'
    }
  },
  displayOrder: {
    type: Number,
    required: true,
    default: 0,
    min: [0, 'Display order cannot be negative']
  },
  isActive: {
    type: Boolean,
    default: true
  },
  clickCount: {
    type: Number,
    default: 0,
    min: 0
  },
  viewCount: {
    type: Number,
    default: 0,
    min: 0
  },
  linkTo: {
    type: String,
    enum: ['category', 'product', 'external', 'none'],
    default: 'category'
  },
  linkValue: {
    type: String,
    trim: true,
    default: ''
  },
  description: {
    type: String,
    maxlength: [200, 'Description cannot be more than 200 characters'],
    trim: true
  },
  tags: [{
    type: String,
    trim: true,
    lowercase: true
  }],
  seo: {
    altText: {
      type: String,
      maxlength: [100, 'Alt text cannot be more than 100 characters']
    }
  },
  analytics: {
    lastClicked: {
      type: Date,
      default: null
    },
    totalInteractions: {
      type: Number,
      default: 0
    },
    conversionRate: {
      type: Number,
      default: 0,
      min: 0,
      max: 100
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better query performance
quickCategorySchema.index({ isActive: 1 });
quickCategorySchema.index({ displayOrder: 1 });
quickCategorySchema.index({ tags: 1 });
quickCategorySchema.index({ clickCount: -1 });
quickCategorySchema.index({ createdAt: -1 });

// Compound index for active categories ordered by display order
quickCategorySchema.index({ isActive: 1, displayOrder: 1 });

// Virtual for formatted creation date
quickCategorySchema.virtual('formattedCreatedAt').get(function() {
  return this.createdAt ? this.createdAt.toLocaleDateString() : null;
});

// Virtual for status
quickCategorySchema.virtual('status').get(function() {
  return this.isActive ? 'Active' : 'Inactive';
});

// Virtual for click-through rate
quickCategorySchema.virtual('clickThroughRate').get(function() {
  if (this.viewCount === 0) return 0;
  return ((this.clickCount / this.viewCount) * 100).toFixed(2);
});

// Instance method to increment click count
quickCategorySchema.methods.incrementClicks = function() {
  this.clickCount += 1;
  this.analytics.totalInteractions += 1;
  this.analytics.lastClicked = new Date();
  return this.save();
};

// Instance method to increment view count
quickCategorySchema.methods.incrementViews = function() {
  this.viewCount += 1;
  return this.save();
};

// Instance method to toggle active status
quickCategorySchema.methods.toggleActive = function() {
  this.isActive = !this.isActive;
  return this.save();
};

// Static method to find active quick categories
quickCategorySchema.statics.findActive = function(limit = 10) {
  return this.find({ isActive: true })
    .sort({ displayOrder: 1, createdAt: -1 })
    .limit(limit);
};

// Static method to find by tag
quickCategorySchema.statics.findByTag = function(tag) {
  return this.find({
    isActive: true,
    tags: { $in: [tag.toLowerCase()] }
  })
  .sort({ displayOrder: 1 });
};

// Static method to get analytics summary
quickCategorySchema.statics.getAnalyticsSummary = function() {
  return this.aggregate([
    {
      $match: { isActive: true }
    },
    {
      $group: {
        _id: null,
        totalCategories: { $sum: 1 },
        totalClicks: { $sum: '$clickCount' },
        totalViews: { $sum: '$viewCount' },
        avgClickThroughRate: {
          $avg: {
            $cond: [
              { $eq: ['$viewCount', 0] },
              0,
              { $multiply: [{ $divide: ['$clickCount', '$viewCount'] }, 100] }
            ]
          }
        }
      }
    }
  ]);
};

// Static method to reorder categories
quickCategorySchema.statics.reorderCategories = async function(orderedIds) {
  const bulkOps = orderedIds.map((id, index) => ({
    updateOne: {
      filter: { _id: id },
      update: { displayOrder: index }
    }
  }));
  
  return this.bulkWrite(bulkOps);
};

// Pre-save middleware to set default alt text
quickCategorySchema.pre('save', function(next) {
  if (!this.seo.altText && this.title) {
    this.seo.altText = `${this.title} - ${this.subtitle}`;
  }
  
  // Ensure tags are lowercase and trimmed
  if (this.tags && this.tags.length > 0) {
    this.tags = this.tags.map(tag => tag.toLowerCase().trim()).filter(tag => tag.length > 0);
  }
  
  next();
});

// Pre-validate middleware
quickCategorySchema.pre('validate', function(next) {
  // If linkTo is set but linkValue is empty, reset linkTo to 'none'
  if (this.linkTo && this.linkTo !== 'none' && !this.linkValue) {
    this.linkTo = 'none';
  }
  
  next();
});

module.exports = mongoose.model('QuickCategory', quickCategorySchema);
