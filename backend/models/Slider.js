const mongoose = require('mongoose');

const sliderSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Slider title is required'],
    trim: true,
    maxlength: [100, 'Title cannot be more than 100 characters']
  },
  description: {
    type: String,
    maxlength: [300, 'Description cannot be more than 300 characters']
  },
  image: {
    type: String,
    required: [true, 'Image is required']
  },
  mobileImage: {
    type: String,
    default: null // Separate image for mobile devices
  },
  buttonText: {
    type: String,
    maxlength: [50, 'Button text cannot be more than 50 characters']
  },
  buttonLink: {
    type: String,
    trim: true
  },
  backgroundColor: {
    type: String,
    default: '#8B4513' // Default coffee brown
  },
  textColor: {
    type: String,
    default: '#FFFFFF' // Default white
  },
  position: {
    type: String,
    enum: ['left', 'center', 'right'],
    default: 'center'
  },
  displayOrder: {
    type: Number,
    default: 0
  },
  isActive: {
    type: Boolean,
    default: true
  },
  startDate: {
    type: Date,
    default: null
  },
  endDate: {
    type: Date,
    default: null
  },
  clickCount: {
    type: Number,
    default: 0
  },
  viewCount: {
    type: Number,
    default: 0
  },
  targetAudience: [{
    type: String,
    enum: ['all', 'new-customers', 'returning-customers', 'loyal-customers']
  }],
  categories: [{
    type: String,
    trim: true
  }],
  tags: [String], // For analytics and filtering
  seo: {
    altText: {
      type: String,
      maxlength: [150, 'Alt text cannot be more than 150 characters']
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better query performance
sliderSchema.index({ isActive: 1 });
sliderSchema.index({ displayOrder: 1 });
sliderSchema.index({ startDate: 1, endDate: 1 });
sliderSchema.index({ categories: 1 });
sliderSchema.index({ targetAudience: 1 });

// Virtual for formatted dates
sliderSchema.virtual('formattedStartDate').get(function() {
  return this.startDate ? this.startDate.toLocaleDateString() : null;
});

sliderSchema.virtual('formattedEndDate').get(function() {
  return this.endDate ? this.endDate.toLocaleDateString() : null;
});

// Virtual for status
sliderSchema.virtual('status').get(function() {
  const now = new Date();
  if (!this.isActive) return 'Inactive';
  if (this.startDate && now < this.startDate) return 'Scheduled';
  if (this.endDate && now > this.endDate) return 'Expired';
  return 'Active';
});

// Instance method to check if slider is currently visible
sliderSchema.methods.isVisible = function() {
  const now = new Date();
  if (!this.isActive) return false;
  if (this.startDate && now < this.startDate) return false;
  if (this.endDate && now > this.endDate) return false;
  return true;
};

// Instance method to increment click count
sliderSchema.methods.incrementClicks = function() {
  this.clickCount += 1;
  return this.save();
};

// Instance method to increment view count
sliderSchema.methods.incrementViews = function() {
  this.viewCount += 1;
  return this.save();
};

// Static method to find active sliders
sliderSchema.statics.findActive = function(limit = 10) {
  const now = new Date();
  return this.find({
    isActive: true,
    $or: [
      { startDate: { $lte: now } },
      { startDate: null }
    ],
    $or: [
      { endDate: { $gte: now } },
      { endDate: null }
    ]
  })
  .sort({ displayOrder: 1, createdAt: -1 })
  .limit(limit);
};

// Static method to find sliders by category
sliderSchema.statics.findByCategory = function(category) {
  return this.find({
    isActive: true,
    categories: { $in: [category] }
  })
  .sort({ displayOrder: 1 });
};

// Pre-save middleware to set default alt text
sliderSchema.pre('save', function(next) {
  if (!this.seo.altText && this.title) {
    this.seo.altText = this.title;
  }
  next();
});

module.exports = mongoose.model('Slider', sliderSchema);
