const mongoose = require('mongoose');

const accessorySchema = new mongoose.Schema({
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
  // Accessory type and category
  type: {
    type: String,
    required: [true, 'Accessory type is required'],
    trim: true,
    lowercase: true
    // Removed enum to allow dynamic types
    // Types are now managed through AccessoryType collection
  },
  category: {
    type: String,
    required: [true, 'Category is required'],
    trim: true
  },
  subCategory: {
    type: String,
    trim: true
  },
  // Product details
  brand: {
    type: String,
    trim: true
  },
  model: {
    type: String,
    trim: true
  },
  sku: {
    type: String,
    unique: true,
    sparse: true,
    trim: true
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
  // Specifications
  specifications: {
    material: [String],
    dimensions: {
      length: Number,
      width: Number,
      height: Number,
      weight: Number,
      unit: {
        type: String,
        enum: ['cm', 'inch', 'mm'],
        default: 'cm'
      }
    },
    capacity: {
      value: Number,
      unit: {
        type: String,
        enum: ['ml', 'oz', 'cup', 'gram'],
        default: 'ml'
      }
    },
    features: [{
      name: {
        en: String,
        ar: String
      },
      description: {
        en: String,
        ar: String
      }
    }]
  },
  // Usage information
  usageInstructions: {
    en: String,
    ar: String
  },
  careInstructions: {
    en: String,
    ar: String
  },
  compatibility: [String], // Compatible with which brewing methods
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
    }
  }],
  color: {
    type: String,
    default: '#A89A6A'
  },
  // Inventory
  stock: {
    quantity: {
      type: Number,
      default: 0,
      min: [0, 'Stock quantity cannot be negative']
    },
    lowStockThreshold: {
      type: Number,
      default: 5
    },
    isInStock: {
      type: Boolean,
      default: true
    }
  },
  // Status and visibility
  isActive: {
    type: Boolean,
    default: true
  },
  isFeatured: {
    type: Boolean,
    default: false
  },
  displayOrder: {
    type: Number,
    default: 0
  },
  // SEO and tags
  tags: [{
    type: String,
    trim: true,
    lowercase: true
  }],
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
    }
  },
  // Vendor information
  vendor: {
    name: String,
    contact: String,
    website: String
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
accessorySchema.index({ type: 1, isActive: 1 });
accessorySchema.index({ category: 1, isActive: 1 });
accessorySchema.index({ isFeatured: 1, isActive: 1 });
accessorySchema.index({ 'price.regular': 1 });
accessorySchema.index({ displayOrder: 1 });
// Note: sku index is already created by unique: true in schema definition

// Text search index
accessorySchema.index({
  'name.en': 'text',
  'name.ar': 'text',
  'description.en': 'text',
  'description.ar': 'text',
  brand: 'text',
  model: 'text'
});

// Virtual for formatted price
accessorySchema.virtual('formattedPrice').get(function() {
  const salePrice = this.price.sale;
  const regularPrice = this.price.regular;
  const currency = this.price.currency;
  
  if (salePrice && salePrice < regularPrice) {
    return `${salePrice} ${currency} (was ${regularPrice} ${currency})`;
  }
  return `${regularPrice} ${currency}`;
});

// Virtual for discount percentage
accessorySchema.virtual('discountPercentage').get(function() {
  const salePrice = this.price.sale;
  const regularPrice = this.price.regular;
  
  if (salePrice && salePrice < regularPrice) {
    return Math.round(((regularPrice - salePrice) / regularPrice) * 100);
  }
  return 0;
});

// Virtual for stock status
accessorySchema.virtual('stockStatus').get(function() {
  if (!this.stock.isInStock || this.stock.quantity === 0) {
    return 'Out of Stock';
  } else if (this.stock.quantity <= this.stock.lowStockThreshold) {
    return 'Low Stock';
  }
  return 'In Stock';
});

// Instance methods
accessorySchema.methods.incrementViews = function() {
  this.analytics.viewCount += 1;
  return this.save();
};

accessorySchema.methods.addRating = function(rating) {
  const totalRatings = this.analytics.totalRatings;
  const currentAvg = this.analytics.avgRating;
  
  this.analytics.totalRatings += 1;
  this.analytics.avgRating = ((currentAvg * totalRatings) + rating) / this.analytics.totalRatings;
  
  return this.save();
};

accessorySchema.methods.updateStock = function(quantity) {
  this.stock.quantity = quantity;
  this.stock.isInStock = quantity > 0;
  return this.save();
};

// Static methods
accessorySchema.statics.findByType = function(type, limit = 20) {
  return this.find({ type, isActive: true })
    .sort({ displayOrder: 1, createdAt: -1 })
    .limit(limit)
    .lean();
};

accessorySchema.statics.findFeatured = function(limit = 10) {
  return this.find({ isActive: true, isFeatured: true })
    .sort({ displayOrder: 1 })
    .limit(limit)
    .lean();
};

accessorySchema.statics.findInStock = function() {
  return this.find({ 
    isActive: true, 
    'stock.isInStock': true,
    'stock.quantity': { $gt: 0 }
  })
  .lean();
};

// Pre-save middleware
accessorySchema.pre('save', function(next) {
  if ((this.isModified('name') || this.isNew) && !this.seo.slug) {
    const englishName = this.name?.en || 'accessory';
    this.seo.slug = englishName
      .toLowerCase()
      .replace(/[^a-zA-Z0-9]/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '');
  }
  
  // Update stock status
  this.stock.isInStock = this.stock.quantity > 0;
  
  next();
});

module.exports = mongoose.model('Accessory', accessorySchema);
