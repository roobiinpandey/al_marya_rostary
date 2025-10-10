const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema({
  // Bilingual name and description support
  name: {
    en: {
      type: String,
      required: [true, 'English name is required'],
      trim: true,
      maxlength: [50, 'English name cannot be more than 50 characters']
    },
    ar: {
      type: String,
      required: [true, 'Arabic name is required'],
      trim: true,
      maxlength: [50, 'Arabic name cannot be more than 50 characters']
    }
  },
  description: {
    en: {
      type: String,
      maxlength: [200, 'English description cannot be more than 200 characters']
    },
    ar: {
      type: String,
      maxlength: [200, 'Arabic description cannot be more than 200 characters']
    }
  },
  image: {
    type: String,
    default: null
  },
  icon: {
    type: String,
    default: null // Icon class name or URL
  },
  color: {
    type: String,
    default: '#8B4513' // Default coffee brown color
  },
  isActive: {
    type: Boolean,
    default: true
  },
  displayOrder: {
    type: Number,
    default: 0
  },
  parentCategory: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category',
    default: null
  },
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
categorySchema.index({ isActive: 1 });
categorySchema.index({ displayOrder: 1 });
categorySchema.index({ parentCategory: 1 });

// Virtual for full slug path (for nested categories)
categorySchema.virtual('fullSlug').get(function() {
  const englishName = this.name?.en || 'category';
  return this.seo.slug || englishName.toLowerCase().replace(/[^a-zA-Z0-9]/g, '-').replace(/-+/g, '-').replace(/^-|-$/g, '');
});

// Virtual for subcategories
categorySchema.virtual('subcategories', {
  ref: 'Category',
  localField: '_id',
  foreignField: 'parentCategory'
});

// Instance method to get product count in this category
categorySchema.methods.getProductCount = async function() {
  const Coffee = mongoose.model('Coffee');
  return await Coffee.countDocuments({
    categories: { $in: [this.name.en, this.name.ar] },
    isActive: true
  });
};

// Method to get localized content
categorySchema.methods.getLocalizedContent = function(language = 'en') {
  const lang = ['en', 'ar'].includes(language) ? language : 'en';
  return {
    ...this.toObject(),
    localizedName: this.name[lang],
    localizedDescription: this.description[lang] || ''
  };
};

// Static method to find active categories
categorySchema.statics.findActive = function() {
  return this.find({ isActive: true }).sort({ displayOrder: 1, name: 1 });
};

// Static method to find root categories (no parent)
categorySchema.statics.findRootCategories = function() {
  return this.find({ parentCategory: null, isActive: true }).sort({ displayOrder: 1, name: 1 });
};

// Pre-save middleware to generate slug
categorySchema.pre('save', function(next) {
  if ((this.isModified('name') || this.isNew) && !this.seo.slug) {
    const englishName = this.name?.en || 'category';
    this.seo.slug = englishName
      .toLowerCase()
      .replace(/[^a-zA-Z0-9]/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '');
  }
  next();
});

module.exports = mongoose.model('Category', categorySchema);
