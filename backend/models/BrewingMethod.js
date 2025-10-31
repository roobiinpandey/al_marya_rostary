const mongoose = require('mongoose');

const brewingMethodSchema = new mongoose.Schema({
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
      maxlength: [500, 'English description cannot be more than 500 characters']
    },
    ar: {
      type: String,
      required: [true, 'Arabic description is required'],
      maxlength: [500, 'Arabic description cannot be more than 500 characters']
    }
  },
  // Detailed brewing instructions
  instructions: {
    en: {
      type: String,
      required: [true, 'English instructions are required'],
      maxlength: [2000, 'English instructions cannot be more than 2000 characters']
    },
    ar: {
      type: String,
      required: [true, 'Arabic instructions are required'],
      maxlength: [2000, 'Arabic instructions cannot be more than 2000 characters']
    }
  },
  // Equipment needed
  equipment: [{
    name: {
      en: String,
      ar: String
    },
    required: {
      type: Boolean,
      default: true
    },
    description: {
      en: String,
      ar: String
    }
  }],
  // Brewing parameters
  parameters: {
    grindSize: {
      type: String,
      enum: ['Extra Fine', 'Fine', 'Medium-Fine', 'Medium', 'Medium-Coarse', 'Coarse', 'Extra Coarse'],
      required: [true, 'Grind size is required']
    },
    coffeeToWaterRatio: {
      type: String,
      required: [true, 'Coffee to water ratio is required'],
      trim: true
    },
    waterTemperature: {
      celsius: {
        type: Number,
        min: [10, 'Water temperature cannot be less than 10°C'],
        max: [100, 'Water temperature cannot be more than 100°C']
      },
      fahrenheit: {
        type: Number,
        min: [50, 'Water temperature cannot be less than 50°F'],
        max: [212, 'Water temperature cannot be more than 212°F']
      }
    },
    brewTime: {
      minutes: {
        type: Number,
        min: [0, 'Brew time cannot be negative']
      },
      description: {
        en: String,
        ar: String
      }
    }
  },
  // Visual elements
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
    default: '#A89A6A', // Default coffee brown color
    validate: {
      validator: function(v) {
        return /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(v);
      },
      message: 'Color must be a valid hex color code'
    }
  },
  // Difficulty and timing
  difficulty: {
    type: String,
    enum: ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
    required: [true, 'Difficulty level is required']
  },
  totalTime: {
    type: Number, // in minutes
    required: [true, 'Total time is required'],
    min: [1, 'Total time must be at least 1 minute']
  },
  servings: {
    type: Number,
    default: 1,
    min: [1, 'Servings must be at least 1']
  },
  // Categories and tags
  categories: [{
    type: String,
    trim: true
  }],
  tags: [{
    type: String,
    trim: true,
    lowercase: true
  }],
  // Status and ordering
  isActive: {
    type: Boolean,
    default: true
  },
  displayOrder: {
    type: Number,
    default: 0
  },
  isPopular: {
    type: Boolean,
    default: false
  },
  // Tips and notes
  tips: [{
    tip: {
      en: String,
      ar: String
    },
    importance: {
      type: String,
      enum: ['Low', 'Medium', 'High'],
      default: 'Medium'
    }
  }],
  variations: [{
    name: {
      en: String,
      ar: String
    },
    description: {
      en: String,
      ar: String
    },
    modifications: [String] // List of modifications from base method
  }],
  // Analytics
  analytics: {
    viewCount: {
      type: Number,
      default: 0
    },
    likeCount: {
      type: Number,
      default: 0
    },
    shareCount: {
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
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better query performance
brewingMethodSchema.index({ isActive: 1 });
brewingMethodSchema.index({ displayOrder: 1 });
brewingMethodSchema.index({ difficulty: 1 });
brewingMethodSchema.index({ totalTime: 1 });
brewingMethodSchema.index({ categories: 1 });
brewingMethodSchema.index({ tags: 1 });
brewingMethodSchema.index({ isPopular: 1 });
brewingMethodSchema.index({ 'analytics.avgRating': -1 });

// Text search index
brewingMethodSchema.index({
  'name.en': 'text',
  'name.ar': 'text',
  'description.en': 'text',
  'description.ar': 'text'
});

// Virtual for formatted total time
brewingMethodSchema.virtual('formattedTotalTime').get(function() {
  if (this.totalTime < 60) {
    return `${this.totalTime} min`;
  } else {
    const hours = Math.floor(this.totalTime / 60);
    const minutes = this.totalTime % 60;
    return minutes > 0 ? `${hours}h ${minutes}min` : `${hours}h`;
  }
});

// Virtual for status
brewingMethodSchema.virtual('status').get(function() {
  return this.isActive ? 'Active' : 'Inactive';
});

// Virtual for rating display
brewingMethodSchema.virtual('formattedRating').get(function() {
  return this.analytics.avgRating.toFixed(1);
});

// Instance method to increment view count
brewingMethodSchema.methods.incrementViews = function() {
  this.analytics.viewCount += 1;
  return this.save();
};

// Instance method to add rating
brewingMethodSchema.methods.addRating = function(rating) {
  const totalRatings = this.analytics.totalRatings;
  const currentAvg = this.analytics.avgRating;
  
  this.analytics.totalRatings += 1;
  this.analytics.avgRating = ((currentAvg * totalRatings) + rating) / this.analytics.totalRatings;
  
  return this.save();
};

// Instance method to toggle active status
brewingMethodSchema.methods.toggleActive = function() {
  this.isActive = !this.isActive;
  return this.save();
};

// Static method to find active brewing methods
brewingMethodSchema.statics.findActive = function(limit = 20) {
  return this.find({ isActive: true })
    .sort({ displayOrder: 1, createdAt: -1 })
    .limit(limit);
};

// Static method to find by difficulty
brewingMethodSchema.statics.findByDifficulty = function(difficulty) {
  return this.find({
    isActive: true,
    difficulty: difficulty
  })
  .sort({ displayOrder: 1 })
  .lean();
};

// Static method to find popular methods
brewingMethodSchema.statics.findPopular = function(limit = 10) {
  return this.find({
    isActive: true,
    isPopular: true
  })
  .sort({ 'analytics.avgRating': -1, 'analytics.viewCount': -1 })
  .limit(limit)
  .lean();
};

// Static method to find by category
brewingMethodSchema.statics.findByCategory = function(category) {
  return this.find({
    isActive: true,
    categories: { $in: [category] }
  })
  .sort({ displayOrder: 1 })
  .lean();
};

// Static method to search methods
brewingMethodSchema.statics.search = function(query, options = {}) {
  const {
    difficulty,
    maxTime,
    category,
    limit = 20
  } = options;
  
  let searchCriteria = {
    isActive: true,
    $text: { $search: query }
  };
  
  if (difficulty) {
    searchCriteria.difficulty = difficulty;
  }
  
  if (maxTime) {
    searchCriteria.totalTime = { $lte: maxTime };
  }
  
  if (category) {
    searchCriteria.categories = { $in: [category] };
  }
  
  return this.find(searchCriteria, { score: { $meta: 'textScore' } })
    .sort({ score: { $meta: 'textScore' } })
    .limit(limit)
    .lean();
};

// Pre-save middleware to generate slug
brewingMethodSchema.pre('save', function(next) {
  if ((this.isModified('name') || this.isNew) && !this.seo.slug) {
    const englishName = this.name?.en || 'brewing-method';
    this.seo.slug = englishName
      .toLowerCase()
      .replace(/[^a-zA-Z0-9]/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '');
  }
  
  // Auto-calculate Fahrenheit from Celsius
  if (this.parameters.waterTemperature.celsius && !this.parameters.waterTemperature.fahrenheit) {
    this.parameters.waterTemperature.fahrenheit = Math.round((this.parameters.waterTemperature.celsius * 9/5) + 32);
  }
  
  // Auto-calculate Celsius from Fahrenheit
  if (this.parameters.waterTemperature.fahrenheit && !this.parameters.waterTemperature.celsius) {
    this.parameters.waterTemperature.celsius = Math.round((this.parameters.waterTemperature.fahrenheit - 32) * 5/9);
  }
  
  next();
});

// Pre-validate middleware
brewingMethodSchema.pre('validate', function(next) {
  // Ensure tags are lowercase and trimmed
  if (this.tags && this.tags.length > 0) {
    this.tags = this.tags.map(tag => tag.toLowerCase().trim()).filter(tag => tag.length > 0);
  }
  
  // Ensure categories are trimmed
  if (this.categories && this.categories.length > 0) {
    this.categories = this.categories.map(cat => cat.trim()).filter(cat => cat.length > 0);
  }
  
  next();
});

module.exports = mongoose.model('BrewingMethod', brewingMethodSchema);
