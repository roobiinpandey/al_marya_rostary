const mongoose = require('mongoose');

/**
 * AccessoryType Model
 * Manages dynamic accessory types (e.g., mug, grinder, filter, machine, etc.)
 * Allows adding new accessory categories without code changes
 */
const accessoryTypeSchema = new mongoose.Schema({
  // Type identifier (slug format)
  slug: {
    type: String,
    required: [true, 'Type slug is required'],
    unique: true,
    trim: true,
    lowercase: true,
    match: [/^[a-z0-9-]+$/, 'Slug can only contain lowercase letters, numbers, and hyphens']
  },
  
  // Display names
  name: {
    en: {
      type: String,
      required: [true, 'English name is required'],
      trim: true
    },
    ar: {
      type: String,
      required: [true, 'Arabic name is required'],
      trim: true
    }
  },
  
  // Description
  description: {
    en: {
      type: String,
      trim: true
    },
    ar: {
      type: String,
      trim: true
    }
  },
  
  // Icon information
  icon: {
    name: {
      type: String,
      default: 'settings' // Default Material icon name
    },
    color: {
      type: String,
      default: '#8C8C8C' // Hex color code
    }
  },
  
  // Route for dedicated page (optional)
  route: {
    type: String,
    trim: true,
    // e.g., '/accessories/machines' for nespresso machines
  },
  
  // Display order
  displayOrder: {
    type: Number,
    default: 0
  },
  
  // Status
  isActive: {
    type: Boolean,
    default: true
  },
  
  // Show on main accessories page
  showOnMainPage: {
    type: Boolean,
    default: true
  },
  
  // Product count (auto-calculated)
  productCount: {
    type: Number,
    default: 0
  },
  
  // Metadata
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
// Note: slug index is already created by unique: true on line 13
accessoryTypeSchema.index({ displayOrder: 1 });
accessoryTypeSchema.index({ isActive: 1 });

// Pre-save middleware to update timestamps
accessoryTypeSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Static method to get active types
accessoryTypeSchema.statics.getActiveTypes = function() {
  return this.find({ isActive: true })
    .sort({ displayOrder: 1, 'name.en': 1 })
    .lean();
};

// Static method to update product count for a type
accessoryTypeSchema.statics.updateProductCount = async function(typeSlug) {
  const Accessory = mongoose.model('Accessory');
  const count = await Accessory.countDocuments({ type: typeSlug, isActive: true });
  
  await this.updateOne(
    { slug: typeSlug },
    { $set: { productCount: count } }
  );
  
  return count;
};

// Static method to seed default types
accessoryTypeSchema.statics.seedDefaultTypes = async function() {
  const defaultTypes = [
    {
      slug: 'mug',
      name: { en: 'Mugs & Cups', ar: 'أكواب وفناجين' },
      description: { 
        en: 'Premium coffee mugs and cups',
        ar: 'أكواب وفناجين قهوة فاخرة'
      },
      icon: { name: 'local_cafe', color: '#D32F2F' },
      route: '/accessories/mugs',
      displayOrder: 1
    },
    {
      slug: 'grinder',
      name: { en: 'Grinders', ar: 'مطاحن' },
      description: { 
        en: 'Manual and electric coffee grinders',
        ar: 'مطاحن قهوة يدوية وكهربائية'
      },
      icon: { name: 'grain', color: '#F57C00' },
      route: '/accessories/grinders',
      displayOrder: 2
    },
    {
      slug: 'filter',
      name: { en: 'Filters & Papers', ar: 'فلاتر وأوراق' },
      description: { 
        en: 'Coffee filters for all brewing methods',
        ar: 'فلاتر قهوة لجميع طرق التحضير'
      },
      icon: { name: 'filter_alt', color: '#1976D2' },
      route: '/accessories/filters',
      displayOrder: 3
    },
    {
      slug: 'scale',
      name: { en: 'Scales & Measuring', ar: 'موازين وقياس' },
      description: { 
        en: 'Precision scales and measuring tools',
        ar: 'موازين دقيقة وأدوات قياس'
      },
      icon: { name: 'balance', color: '#388E3C' },
      displayOrder: 4
    },
    {
      slug: 'kettle',
      name: { en: 'Kettles', ar: 'غلايات' },
      description: { 
        en: 'Electric and stovetop kettles',
        ar: 'غلايات كهربائية وعلى الموقد'
      },
      icon: { name: 'water_drop', color: '#0097A7' },
      displayOrder: 5
    },
    {
      slug: 'dripper',
      name: { en: 'Drippers', ar: 'أدوات التقطير' },
      description: { 
        en: 'Pour-over drippers and accessories',
        ar: 'أدوات التقطير والإكسسوارات'
      },
      icon: { name: 'water', color: '#5E35B1' },
      displayOrder: 6
    },
    {
      slug: 'press',
      name: { en: 'French Press', ar: 'الكبس الفرنسي' },
      description: { 
        en: 'French press coffee makers',
        ar: 'صانعات قهوة الكبس الفرنسي'
      },
      icon: { name: 'coffee_maker', color: '#6D4C41' },
      displayOrder: 7
    },
    {
      slug: 'machine',
      name: { en: 'Coffee Machines', ar: 'ماكينات القهوة' },
      description: { 
        en: 'Espresso machines, Nespresso, and more',
        ar: 'ماكينات إسبريسو، نسبريسو، والمزيد'
      },
      icon: { name: 'coffee', color: '#795548' },
      displayOrder: 8
    },
    {
      slug: 'storage',
      name: { en: 'Storage Solutions', ar: 'حلول التخزين' },
      description: { 
        en: 'Airtight containers and storage jars',
        ar: 'حاويات محكمة الإغلاق وبرطمانات التخزين'
      },
      icon: { name: 'inventory_2', color: '#7B1FA2' },
      displayOrder: 9
    },
    {
      slug: 'other',
      name: { en: 'Other Accessories', ar: 'إكسسوارات أخرى' },
      description: { 
        en: 'Other coffee accessories and tools',
        ar: 'إكسسوارات وأدوات قهوة أخرى'
      },
      icon: { name: 'more_horiz', color: '#616161' },
      displayOrder: 99
    }
  ];

  for (const typeData of defaultTypes) {
    await this.updateOne(
      { slug: typeData.slug },
      { $setOnInsert: typeData },
      { upsert: true }
    );
  }

  console.log('✅ Default accessory types seeded');
};

const AccessoryType = mongoose.model('AccessoryType', accessoryTypeSchema);

module.exports = AccessoryType;
