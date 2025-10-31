const mongoose = require('mongoose');

/**
 * AttributeGroup Model
 * Manages groups of related attributes (Origins, Roasts, Processing Methods, Flavors, etc.)
 * This replaces hardcoded dropdowns with dynamic, manageable attributes
 */
const attributeGroupSchema = new mongoose.Schema({
  // Bilingual name for the attribute group
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
  
  // Unique key for programmatic access (e.g., 'origin_countries', 'roast_levels')
  key: {
    type: String,
    required: [true, 'Key is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^[a-z0-9_]+$/, 'Key must contain only lowercase letters, numbers, and underscores']
  },
  
  // Bilingual description
  description: {
    en: {
      type: String,
      maxlength: [500, 'English description cannot be more than 500 characters']
    },
    ar: {
      type: String,
      maxlength: [500, 'Arabic description cannot be more than 500 characters']
    }
  },
  
  // Control type for rendering in UI
  type: {
    type: String,
    enum: {
      values: ['single-select', 'multi-select', 'checkbox-group', 'radio-group', 'text-input'],
      message: '{VALUE} is not a valid attribute type'
    },
    default: 'single-select'
  },
  
  // Where this attribute is used
  scope: {
    type: String,
    enum: {
      values: ['product-attribute', 'product-category', 'filter-only', 'both'],
      message: '{VALUE} is not a valid scope'
    },
    default: 'product-attribute'
  },
  
  // Whether this field is required when creating/editing products
  isRequired: {
    type: Boolean,
    default: false
  },
  
  // Display order in forms and lists
  displayOrder: {
    type: Number,
    default: 0,
    min: 0
  },
  
  // Icon (emoji or CSS class) for visual identification
  icon: {
    type: String,
    default: null,
    maxlength: [50, 'Icon cannot be more than 50 characters']
  },
  
  // Color code for visual styling
  color: {
    type: String,
    default: '#A89A6A',
    match: [/^#[0-9A-Fa-f]{6}$/, 'Color must be a valid hex color code']
  },
  
  // Active status
  isActive: {
    type: Boolean,
    default: true
    // index defined below with schema.index()
  },
  
  // Allow users to add custom values not in predefined list
  allowCustomValues: {
    type: Boolean,
    default: false
  },
  
  // Whether to use in SKU generation (e.g., origin and roast for COF-ETHIOPIA-MEDIUM-250GM)
  usedInSKU: {
    type: Boolean,
    default: false
  },
  
  // Validation rules for the attribute
  validation: {
    minValues: {
      type: Number,
      default: 0,
      min: 0
    },
    maxValues: {
      type: Number,
      default: null,
      min: 1
    },
    pattern: {
      type: String,
      default: null
    }
  },
  
  // Help text to display in forms
  helpText: {
    en: String,
    ar: String
  },
  
  // Placeholder text for inputs
  placeholder: {
    en: String,
    ar: String
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better query performance
// Note: 'key' already has unique index from schema definition
attributeGroupSchema.index({ isActive: 1 });
attributeGroupSchema.index({ displayOrder: 1 });
attributeGroupSchema.index({ scope: 1 });

// Virtual for value count
attributeGroupSchema.virtual('values', {
  ref: 'AttributeValue',
  localField: '_id',
  foreignField: 'attributeGroup',
  options: { sort: { displayOrder: 1 } }
});

// Instance method to get active values
attributeGroupSchema.methods.getActiveValues = async function(language = 'en') {
  const AttributeValue = mongoose.model('AttributeValue');
  const values = await AttributeValue.find({
    attributeGroup: this._id,
    isActive: true
  }).sort({ displayOrder: 1, 'name.en': 1 });
  
  if (language) {
    return values.map(val => ({
      ...val.toObject(),
      localizedName: val.name[language] || val.name.en,
      localizedDescription: val.description?.[language] || val.description?.en || ''
    }));
  }
  
  return values;
};

// Instance method to get value count
attributeGroupSchema.methods.getValueCount = async function() {
  const AttributeValue = mongoose.model('AttributeValue');
  return await AttributeValue.countDocuments({
    attributeGroup: this._id,
    isActive: true
  });
};

// Method to get localized content
attributeGroupSchema.methods.getLocalizedContent = function(language = 'en') {
  const lang = ['en', 'ar'].includes(language) ? language : 'en';
  return {
    ...this.toObject(),
    localizedName: this.name[lang],
    localizedDescription: this.description?.[lang] || '',
    localizedHelpText: this.helpText?.[lang] || '',
    localizedPlaceholder: this.placeholder?.[lang] || ''
  };
};

// Static method to find active attribute groups
attributeGroupSchema.statics.findActive = function() {
  return this.find({ isActive: true }).sort({ displayOrder: 1, 'name.en': 1 });
};

// Static method to find by key
attributeGroupSchema.statics.findByKey = function(key) {
  return this.findOne({ key: key.toLowerCase() });
};

// Static method to find groups by scope
attributeGroupSchema.statics.findByScope = function(scope) {
  return this.find({ 
    isActive: true, 
    $or: [{ scope: scope }, { scope: 'both' }]
  }).sort({ displayOrder: 1 });
};

// Pre-save middleware for key normalization
attributeGroupSchema.pre('save', function(next) {
  if (this.isModified('key')) {
    this.key = this.key.toLowerCase().replace(/[^a-z0-9_]/g, '_');
  }
  next();
});

// Pre-remove middleware to prevent deletion if values exist
attributeGroupSchema.pre('remove', async function(next) {
  const AttributeValue = mongoose.model('AttributeValue');
  const valueCount = await AttributeValue.countDocuments({ attributeGroup: this._id });
  
  if (valueCount > 0) {
    throw new Error(`Cannot delete attribute group "${this.name.en}" because it has ${valueCount} associated values. Delete values first.`);
  }
  
  next();
});

module.exports = mongoose.model('AttributeGroup', attributeGroupSchema);
