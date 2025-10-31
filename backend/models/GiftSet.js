const mongoose = require('mongoose');

const giftSetSchema = new mongoose.Schema({
  // Bilingual name and description
  name: {
    en: {
      type: String,
      required: [true, 'English name is required'],
      trim: true,
      maxlength: [100, 'English name cannot be more than 100 characters']
    },
    ar: {
      type: String,
      required: [true, 'Arabic name is required'],
      trim: true,
      maxlength: [100, 'Arabic name cannot be more than 100 characters']
    }
  },
  description: {
    en: {
      type: String,
      required: [true, 'English description is required'],
      maxlength: [1000, 'English description cannot be more than 1000 characters']
    },
    ar: {
      type: String,
      required: [true, 'Arabic description is required'],
      maxlength: [1000, 'Arabic description cannot be more than 1000 characters']
    }
  },
  // Gift set details
  occasion: {
    type: String,
    enum: ['birthday', 'anniversary', 'wedding', 'corporate', 'holiday', 'thank-you', 'housewarming', 'graduation', 'general'],
    required: [true, 'Occasion is required']
  },
  targetAudience: {
    type: String,
    enum: ['beginner', 'enthusiast', 'professional', 'corporate', 'family', 'couple', 'individual'],
    required: [true, 'Target audience is required']
  },
  // Pricing information
  price: {
    regular: {
      type: Number,
      required: [true, 'Regular price is required'],
      min: [0, 'Price cannot be negative']
    },
    sale: {
      type: Number,
      min: [0, 'Sale price cannot be negative']
    },
    currency: {
      type: String,
      default: 'AED',
      enum: ['AED', 'USD', 'EUR']
    }
  },
  // Contents of the gift set
  contents: [{
    item: {
      itemType: {
        type: String,
        enum: ['coffee', 'accessory', 'merchandise', 'voucher', 'custom'],
        required: true
      },
      itemId: {
        type: mongoose.Schema.Types.ObjectId,
        refPath: 'contents.item.itemType'
      },
      customItem: {
        name: {
          en: String,
          ar: String
        },
        description: {
          en: String,
          ar: String
        }
      }
    },
    quantity: {
      type: Number,
      default: 1,
      min: [1, 'Quantity must be at least 1']
    },
    isHighlight: {
      type: Boolean,
      default: false
    }
  }],
  // Package details
  packaging: {
    type: {
      type: String,
      enum: ['box', 'bag', 'basket', 'tin', 'custom'],
      default: 'box'
    },
    material: String,
    dimensions: {
      length: Number,
      width: Number,
      height: Number,
      unit: {
        type: String,
        enum: ['cm', 'inch'],
        default: 'cm'
      }
    },
    weight: {
      value: Number,
      unit: {
        type: String,
        enum: ['kg', 'g', 'lb'],
        default: 'kg'
      }
    },
    color: String,
    customization: {
      allowPersonalization: {
        type: Boolean,
        default: false
      },
      personalizationOptions: [String]
    }
  },
  // Customization options
  customization: {
    allowCustomization: {
      type: Boolean,
      default: false
    },
    customizableItems: [String],
    additionalCost: {
      type: Number,
      default: 0
    }
  },
  // Visual elements
  images: [{
    url: String,
    alt: {
      en: String,
      ar: String
    },
    isPrimary: {
      type: Boolean,
      default: false
    },
    showsContents: {
      type: Boolean,
      default: false
    }
  }],
  // Availability and status
  availability: {
    isAvailable: {
      type: Boolean,
      default: true
    },
    seasonalAvailability: {
      startDate: Date,
      endDate: Date
    },
    limitedQuantity: {
      total: Number,
      remaining: Number
    }
  },
  // Status
  isActive: {
    type: Boolean,
    default: true
  },
  isFeatured: {
    type: Boolean,
    default: false
  },
  isPopular: {
    type: Boolean,
    default: false
  },
  displayOrder: {
    type: Number,
    default: 0
  },
  // Marketing
  tags: [{
    type: String,
    trim: true,
    lowercase: true
  }],
  marketingMessages: {
    shortDescription: {
      en: String,
      ar: String
    },
    highlights: [{
      en: String,
      ar: String
    }],
    giftMessage: {
      en: String,
      ar: String
    }
  },
  // SEO
  seo: {
    metaTitle: {
      en: String,
      ar: String
    },
    metaDescription: {
      en: String,
      ar: String
    },
    slug: {
      type: String,
      unique: true,
      sparse: true
    },
    keywords: [String]
  },
  // Analytics
  analytics: {
    viewCount: {
      type: Number,
      default: 0
    },
    purchaseCount: {
      type: Number,
      default: 0
    },
    avgRating: {
      type: Number,
      default: 0,
      min: 0,
      max: 5
    },
    totalRatings: {
      type: Number,
      default: 0
    },
    conversionRate: {
      type: Number,
      default: 0
    }
  },
  // Reviews and ratings
  reviews: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    rating: {
      type: Number,
      min: 1,
      max: 5,
      required: true
    },
    comment: String,
    occasion: String,
    recipientType: String,
    wouldRecommend: {
      type: Boolean,
      default: true
    },
    createdAt: {
      type: Date,
      default: Date.now
    }
  }]
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
giftSetSchema.index({ occasion: 1, isActive: 1 });
giftSetSchema.index({ targetAudience: 1, isActive: 1 });
giftSetSchema.index({ isFeatured: 1, isActive: 1 });
giftSetSchema.index({ isPopular: 1, isActive: 1 });
giftSetSchema.index({ 'price.regular': 1 });
giftSetSchema.index({ displayOrder: 1 });
giftSetSchema.index({ 'availability.isAvailable': 1 });

// Text search index
giftSetSchema.index({
  'name.en': 'text',
  'name.ar': 'text',
  'description.en': 'text',
  'description.ar': 'text'
});

// Virtual for formatted price
giftSetSchema.virtual('formattedPrice').get(function() {
  const salePrice = this.price.sale;
  const regularPrice = this.price.regular;
  const currency = this.price.currency;
  
  if (salePrice && salePrice < regularPrice) {
    return `${salePrice} ${currency} (was ${regularPrice} ${currency})`;
  }
  return `${regularPrice} ${currency}`;
});

// Virtual for discount percentage
giftSetSchema.virtual('discountPercentage').get(function() {
  const salePrice = this.price.sale;
  const regularPrice = this.price.regular;
  
  if (salePrice && salePrice < regularPrice) {
    return Math.round(((regularPrice - salePrice) / regularPrice) * 100);
  }
  return 0;
});

// Virtual for availability status
giftSetSchema.virtual('availabilityStatus').get(function() {
  if (!this.availability.isAvailable) {
    return 'Unavailable';
  }
  
  const now = new Date();
  const seasonal = this.availability.seasonalAvailability;
  
  if (seasonal && seasonal.startDate && seasonal.endDate) {
    if (now < seasonal.startDate || now > seasonal.endDate) {
      return 'Seasonal - Not Available';
    }
  }
  
  const limited = this.availability.limitedQuantity;
  if (limited && limited.remaining <= 0) {
    return 'Sold Out';
  }
  
  if (limited && limited.remaining <= 5) {
    return `Limited - ${limited.remaining} left`;
  }
  
  return 'Available';
});

// Virtual for total items count
giftSetSchema.virtual('totalItems').get(function() {
  return this.contents.reduce((total, item) => total + item.quantity, 0);
});

// Instance methods
giftSetSchema.methods.incrementViews = function() {
  this.analytics.viewCount += 1;
  return this.save();
};

giftSetSchema.methods.addRating = function(rating) {
  const totalRatings = this.analytics.totalRatings;
  const currentAvg = this.analytics.avgRating;
  
  this.analytics.totalRatings += 1;
  this.analytics.avgRating = ((currentAvg * totalRatings) + rating) / this.analytics.totalRatings;
  
  return this.save();
};

giftSetSchema.methods.addReview = function(reviewData) {
  this.reviews.push(reviewData);
  this.addRating(reviewData.rating);
  return this.save();
};

giftSetSchema.methods.updateLimitedQuantity = function(quantity) {
  if (this.availability.limitedQuantity) {
    this.availability.limitedQuantity.remaining = quantity;
    this.availability.isAvailable = quantity > 0;
  }
  return this.save();
};

// Static methods
giftSetSchema.statics.findByOccasion = function(occasion, limit = 20) {
  return this.find({ 
    occasion, 
    isActive: true, 
    'availability.isAvailable': true 
  })
    .sort({ displayOrder: 1, createdAt: -1 })
    .limit(limit);
};

giftSetSchema.statics.findByTargetAudience = function(audience, limit = 20) {
  return this.find({ 
    targetAudience: audience, 
    isActive: true, 
    'availability.isAvailable': true 
  })
    .sort({ displayOrder: 1 })
    .limit(limit);
};

giftSetSchema.statics.findFeatured = function(limit = 10) {
  return this.find({ 
    isActive: true, 
    isFeatured: true, 
    'availability.isAvailable': true 
  })
    .sort({ displayOrder: 1 })
    .limit(limit);
};

giftSetSchema.statics.findPopular = function(limit = 10) {
  return this.find({ 
    isActive: true, 
    isPopular: true, 
    'availability.isAvailable': true 
  })
    .sort({ 'analytics.avgRating': -1, 'analytics.purchaseCount': -1 })
    .limit(limit);
};

giftSetSchema.statics.findByPriceRange = function(minPrice, maxPrice) {
  return this.find({
    isActive: true,
    'availability.isAvailable': true,
    'price.regular': { $gte: minPrice, $lte: maxPrice }
  })
    .sort({ 'price.regular': 1 });
};

// Pre-save middleware
giftSetSchema.pre('save', function(next) {
  if ((this.isModified('name') || this.isNew) && !this.seo.slug) {
    const englishName = this.name?.en || 'gift-set';
    this.seo.slug = englishName
      .toLowerCase()
      .replace(/[^a-zA-Z0-9]/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '');
  }
  
  // Update conversion rate
  if (this.analytics.viewCount > 0) {
    this.analytics.conversionRate = (this.analytics.purchaseCount / this.analytics.viewCount) * 100;
  }
  
  next();
});

module.exports = mongoose.model('GiftSet', giftSetSchema);
