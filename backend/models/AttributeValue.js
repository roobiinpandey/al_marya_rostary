const mongoose = require('mongoose');

/**
 * AttributeValue Model
 * Individual values within each attribute group
 * Examples: "Ethiopia" in Origins, "Light Roast" in Roast Levels, "Fruity" in Flavor Profiles
 */
const attributeValueSchema = new mongoose.Schema({
  // Reference to parent attribute group
  attributeGroup: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'AttributeGroup',
    required: [true, 'Attribute group is required'],
    index: true
  },
  
  // Bilingual name for the attribute value
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
  
  // Internal value used in code and database (e.g., 'ethiopia', 'light_roast')
  value: {
    type: String,
    required: [true, 'Value is required'],
    trim: true,
    maxlength: [100, 'Value cannot be more than 100 characters']
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
  
  // Icon (emoji or CSS class) for visual identification
  icon: {
    type: String,
    default: null,
    maxlength: [50, 'Icon cannot be more than 50 characters']
  },
  
  // Color code for visual styling
  color: {
    type: String,
    default: null,
    match: [/^#[0-9A-Fa-f]{6}$|^$/, 'Color must be a valid hex color code']
  },
  
  // Display order within the attribute group
  displayOrder: {
    type: Number,
    default: 0,
    min: 0
  },
  
  // Active status
  isActive: {
    type: Boolean,
    default: true
    // index defined below with compound indexes
  },
  
  // Parent value for hierarchical grouping (e.g., "Africa" is parent of "Ethiopia")
  parentValue: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'AttributeValue',
    default: null
    // index defined below with schema.index()
  },
  
  // Additional metadata specific to this value
  metadata: {
    type: Map,
    of: mongoose.Schema.Types.Mixed,
    default: {}
    // Examples:
    // For countries: { region: 'Africa', altitude: '1500-2200m', climate: 'Tropical' }
    // For roasts: { temperature: '220-230°C', duration: '12-15min' }
    // For flavors: { intensity: 'medium', category: 'fruity' }
  },
  
  // Alternative names/aliases
  aliases: [{
    type: String,
    trim: true
  }],
  
  // Image URL if applicable
  image: {
    type: String,
    default: null
  },
  
  // Usage count (how many products use this value)
  usageCount: {
    type: Number,
    default: 0,
    min: 0
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Compound index for uniqueness within attribute group
attributeValueSchema.index({ attributeGroup: 1, value: 1 }, { unique: true });
attributeValueSchema.index({ attributeGroup: 1, displayOrder: 1 });
attributeValueSchema.index({ attributeGroup: 1, isActive: 1 });
attributeValueSchema.index({ parentValue: 1 });

// Virtual for child values (if this is a parent)
attributeValueSchema.virtual('children', {
  ref: 'AttributeValue',
  localField: '_id',
  foreignField: 'parentValue',
  options: { sort: { displayOrder: 1 } }
});

// Instance method to get localized content
attributeValueSchema.methods.getLocalizedContent = function(language = 'en') {
  const lang = ['en', 'ar'].includes(language) ? language : 'en';
  return {
    ...this.toObject(),
    localizedName: this.name[lang],
    localizedDescription: this.description?.[lang] || ''
  };
};

// Instance method to get full hierarchy path
attributeValueSchema.methods.getHierarchyPath = async function() {
  const path = [this.name.en];
  let current = this;
  
  while (current.parentValue) {
    current = await this.model('AttributeValue').findById(current.parentValue);
    if (current) {
      path.unshift(current.name.en);
    } else {
      break;
    }
  }
  
  return path.join(' > ');
};

// Instance method to check if has children
attributeValueSchema.methods.hasChildren = async function() {
  const count = await this.model('AttributeValue').countDocuments({
    parentValue: this._id
  });
  return count > 0;
};

// Static method to find active values by group
attributeValueSchema.statics.findByGroup = function(groupId, includeInactive = false) {
  const query = { attributeGroup: groupId };
  if (!includeInactive) {
    query.isActive = true;
  }
  return this.find(query).sort({ displayOrder: 1, 'name.en': 1 });
};

// Static method to find by group key
attributeValueSchema.statics.findByGroupKey = async function(groupKey, includeInactive = false) {
  const AttributeGroup = mongoose.model('AttributeGroup');
  const group = await AttributeGroup.findOne({ key: groupKey.toLowerCase() });
  
  if (!group) {
    throw new Error(`Attribute group with key "${groupKey}" not found`);
  }
  
  return this.findByGroup(group._id, includeInactive);
};

// Static method to find root values (no parent)
attributeValueSchema.statics.findRootValues = function(groupId) {
  return this.find({
    attributeGroup: groupId,
    parentValue: null,
    isActive: true
  }).sort({ displayOrder: 1, 'name.en': 1 });
};

// Static method to find values with children (hierarchical structure)
attributeValueSchema.statics.findHierarchical = async function(groupId) {
  const rootValues = await this.findRootValues(groupId);
  
  // Populate children for each root value
  const hierarchical = await Promise.all(
    rootValues.map(async (root) => {
      const children = await this.find({
        parentValue: root._id,
        isActive: true
      }).sort({ displayOrder: 1, 'name.en': 1 });
      
      return {
        ...root.toObject(),
        children: children
      };
    })
  );
  
  return hierarchical;
};

// Static method to search values
attributeValueSchema.statics.search = function(groupId, searchTerm, language = 'en') {
  const searchRegex = new RegExp(searchTerm, 'i');
  const nameField = `name.${language}`;
  
  return this.find({
    attributeGroup: groupId,
    isActive: true,
    [nameField]: searchRegex
  }).sort({ displayOrder: 1, 'name.en': 1 });
};

// Pre-save middleware to normalize value
attributeValueSchema.pre('save', function(next) {
  if (this.isModified('value')) {
    // Normalize value to lowercase and replace spaces with hyphens
    this.value = this.value.toLowerCase().trim().replace(/\s+/g, '-');
  }
  next();
});

// Pre-remove middleware to check if value is used in products
attributeValueSchema.pre('remove', async function(next) {
  if (this.usageCount > 0) {
    throw new Error(
      `Cannot delete attribute value "${this.name.en}" because it is used in ${this.usageCount} product(s). ` +
      'Please remove it from products first or deactivate instead.'
    );
  }
  
  // Check if it has children
  const hasChildren = await this.hasChildren();
  if (hasChildren) {
    throw new Error(
      `Cannot delete attribute value "${this.name.en}" because it has child values. ` +
      'Delete child values first.'
    );
  }
  
  next();
});

// Post-save middleware to update group's value count
attributeValueSchema.post('save', async function(doc) {
  const AttributeGroup = mongoose.model('AttributeGroup');
  const group = await AttributeGroup.findById(doc.attributeGroup);
  if (group) {
    const count = await doc.model('AttributeValue').countDocuments({
      attributeGroup: group._id,
      isActive: true
    });
    // Note: We could add a valueCount field to AttributeGroup if needed
  }
});

module.exports = mongoose.model('AttributeValue', attributeValueSchema);
