const mongoose = require('mongoose');

const coffeeSchema = new mongoose.Schema({
  // Bilingual name and description support
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
  price: {
    type: Number,
    required: function() {
      // Price is only required if no variants are provided
      return !this.variants || this.variants.length === 0;
    },
    min: [0, 'Price cannot be negative'],
    default: function() {
      // If variants exist, use the minimum variant price as default
      if (this.variants && this.variants.length > 0) {
        return Math.min(...this.variants.map(v => v.price));
      }
      return undefined;
    }
  },
  image: {
    type: String,
    required: [true, 'Image is required']
  },
  origin: {
    type: String,
    required: [true, 'Origin is required'],
    trim: true
  },
  roastLevel: {
    type: String,
    required: [true, 'Roast level is required'],
    enum: ['Light', 'Medium-Light', 'Medium', 'Medium-Dark', 'Dark'],
    default: 'Medium'
  },
  stock: {
    type: Number,
    required: [true, 'Stock quantity is required'],
    min: [0, 'Stock cannot be negative'],
    default: 0
  },
  categories: [{
    type: String,
    trim: true
  }],
  variants: [{
    size: {
      type: String,
      required: true,
      enum: ['250gm', '500gm', '1kg']
    },
    weight: {
      type: Number,
      required: true
    },
    price: {
      type: Number,
      required: true,
      min: [0, 'Variant price cannot be negative']
    },
    stock: {
      type: Number,
      min: [0, 'Variant stock cannot be negative'],
      default: 0
    },
    description: {
      en: {
        type: String,
        default: function() {
          return `${this.size} pack - Perfect for ${this.size === '250gm' ? 'trying new flavors' : this.size === '500gm' ? 'regular consumption' : 'bulk purchase and sharing'}`;
        }
      },
      ar: {
        type: String,
        default: function() {
          const arabicDesc = {
            '250gm': 'عبوة ٢٥٠ جرام - مثالية لتجربة النكهات الجديدة',
            '500gm': 'عبوة ٥٠٠ جرام - مثالية للاستهلاك المنتظم',
            '1kg': 'عبوة كيلو جرام - مثالية للشراء بالجملة والمشاركة'
          };
          return arabicDesc[this.size] || `عبوة ${this.size}`;
        }
      }
    },
    displayName: {
      en: {
        type: String,
        default: function() {
          return `${this.size} Pack`;
        }
      },
      ar: {
        type: String,
        default: function() {
          const arabicNames = {
            '250gm': 'عبوة ٢٥٠ جرام',
            '500gm': 'عبوة ٥٠٠ جرام', 
            '1kg': 'عبوة كيلو جرام'
          };
          return arabicNames[this.size] || `عبوة ${this.size}`;
        }
      }
    },
    isActive: {
      type: Boolean,
      default: true
    }
  }],
  tastingNotes: [String],
  brewingMethods: [{
    type: String,
    enum: ['Drip', 'Pour Over', 'French Press', 'Espresso', 'Cold Brew', 'Turkish']
  }],
  certifications: [String], // Organic, Fair Trade, etc.
  rating: {
    type: Number,
    min: [0, 'Rating cannot be less than 0'],
    max: [5, 'Rating cannot be more than 5'],
    default: 0
  },
  reviewCount: {
    type: Number,
    min: [0, 'Review count cannot be negative'],
    default: 0
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isFeatured: {
    type: Boolean,
    default: false
  },
  tags: [String], // For search and filtering
  seo: {
    metaTitle: String,
    metaDescription: String,
    slug: {
      type: String,
      unique: true,
      sparse: true
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better query performance
coffeeSchema.index({ 
  'name.en': 'text', 
  'name.ar': 'text', 
  'description.en': 'text', 
  'description.ar': 'text' 
});
coffeeSchema.index({ categories: 1 });
coffeeSchema.index({ roastLevel: 1 });
coffeeSchema.index({ price: 1 });
coffeeSchema.index({ rating: -1 });
coffeeSchema.index({ isActive: 1 });
coffeeSchema.index({ isFeatured: 1 });

// Virtual for formatted price
coffeeSchema.virtual('formattedPrice').get(function() {
  return `$${this.price.toFixed(2)}`;
});

// Virtual for availability status
coffeeSchema.virtual('availabilityStatus').get(function() {
  if (this.stock === 0) return 'Out of Stock';
  if (this.stock < 10) return 'Low Stock';
  return 'In Stock';
});

// Method to get localized content
coffeeSchema.methods.getLocalizedContent = function(language = 'en') {
  const lang = ['en', 'ar'].includes(language) ? language : 'en';
  return {
    ...this.toObject(),
    localizedName: this.name[lang],
    localizedDescription: this.description[lang]
  };
};

// Instance method to check if coffee is available
coffeeSchema.methods.isAvailable = function() {
  return this.isActive && this.stock > 0;
};

// Instance method to update stock
coffeeSchema.methods.updateStock = function(quantity) {
  this.stock = Math.max(0, this.stock + quantity);
  return this.save();
};

// Instance method to update variant stock
coffeeSchema.methods.updateVariantStock = function(size, quantity) {
  const variant = this.variants.find(v => v.size === size);
  if (variant) {
    variant.stock = Math.max(0, variant.stock + quantity);
    return this.save();
  }
  throw new Error(`Variant with size ${size} not found`);
};

// Instance method to get variant by size
coffeeSchema.methods.getVariant = function(size) {
  return this.variants.find(v => v.size === size && v.isActive);
};

// Instance method to get available variants
coffeeSchema.methods.getAvailableVariants = function() {
  return this.variants.filter(v => v.isActive && v.stock > 0);
};

// Instance method to get price range
coffeeSchema.methods.getPriceRange = function() {
  const activeVariants = this.variants.filter(v => v.isActive);
  if (activeVariants.length === 0) return { min: this.price, max: this.price };
  
  const prices = activeVariants.map(v => v.price);
  return {
    min: Math.min(...prices),
    max: Math.max(...prices)
  };
};

// Static method to find featured coffees
coffeeSchema.statics.findFeatured = function(limit = 10) {
  return this.find({ isActive: true, isFeatured: true })
    .sort({ createdAt: -1 })
    .limit(limit);
};

// Static method to find coffees by category
coffeeSchema.statics.findByCategory = function(category, limit = 20) {
  return this.find({
    isActive: true,
    categories: { $in: [category] }
  })
  .sort({ rating: -1, createdAt: -1 })
  .limit(limit);
};

// Pre-save middleware to generate slug
coffeeSchema.pre('save', function(next) {
  if ((this.isModified('name') || this.isNew) && !this.seo.slug) {
    const englishName = this.name?.en || 'coffee';
    this.seo.slug = englishName
      .toLowerCase()
      .replace(/[^a-zA-Z0-9]/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '');
  }
  next();
});

module.exports = mongoose.model('Coffee', coffeeSchema);
