const mongoose = require('mongoose');

const coffeeSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Coffee name is required'],
    trim: true,
    maxlength: [100, 'Name cannot be more than 100 characters']
  },
  description: {
    type: String,
    required: [true, 'Description is required'],
    maxlength: [1000, 'Description cannot be more than 1000 characters']
  },
  price: {
    type: Number,
    required: [true, 'Price is required'],
    min: [0, 'Price cannot be negative']
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
      enum: ['250g', '500g', '1kg']
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
coffeeSchema.index({ name: 'text', description: 'text' });
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

// Instance method to check if coffee is available
coffeeSchema.methods.isAvailable = function() {
  return this.isActive && this.stock > 0;
};

// Instance method to update stock
coffeeSchema.methods.updateStock = function(quantity) {
  this.stock = Math.max(0, this.stock + quantity);
  return this.save();
};

// Instance method to update rating from reviews
coffeeSchema.methods.updateRatingFromReviews = async function() {
  const UserFeedback = mongoose.model('UserFeedback');
  
  const ratingStats = await UserFeedback.getCoffeeRatingStats(this._id);
  
  this.rating = Math.round(ratingStats.averageRating * 10) / 10; // Round to 1 decimal
  this.reviewCount = ratingStats.totalReviews;
  
  return this.save();
};

// Instance method to get detailed rating breakdown
coffeeSchema.methods.getRatingBreakdown = async function() {
  const UserFeedback = mongoose.model('UserFeedback');
  return UserFeedback.getCoffeeRatingStats(this._id);
};

// Instance method to get recent reviews
coffeeSchema.methods.getRecentReviews = async function(limit = 5) {
  const UserFeedback = mongoose.model('UserFeedback');
  return UserFeedback.getReviewsForCoffee(this._id, {
    limit,
    status: 'approved'
  });
};

// Static method to find featured coffees
coffeeSchema.statics.findFeatured = function(limit = 10) {
  return this.find({ isActive: true, isFeatured: true })
    .sort({ rating: -1, createdAt: -1 })
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

// Static method to find top-rated coffees
coffeeSchema.statics.findTopRated = function(limit = 10, minReviews = 3) {
  return this.find({
    isActive: true,
    reviewCount: { $gte: minReviews }
  })
  .sort({ rating: -1, reviewCount: -1 })
  .limit(limit);
};

// Static method to search coffees with filters
coffeeSchema.statics.searchCoffees = function(options = {}) {
  const {
    query,
    categories,
    roastLevels,
    minRating = 0,
    maxRating = 5,
    minPrice,
    maxPrice,
    sortBy = 'rating',
    sortOrder = 'desc',
    page = 1,
    limit = 20
  } = options;

  let searchQuery = { isActive: true };

  // Text search
  if (query) {
    searchQuery.$text = { $search: query };
  }

  // Category filter
  if (categories && categories.length > 0) {
    searchQuery.categories = { $in: categories };
  }

  // Roast level filter
  if (roastLevels && roastLevels.length > 0) {
    searchQuery.roastLevel = { $in: roastLevels };
  }

  // Rating filter
  if (minRating > 0 || maxRating < 5) {
    searchQuery.rating = { $gte: minRating, $lte: maxRating };
  }

  // Price filter
  if (minPrice !== undefined || maxPrice !== undefined) {
    searchQuery.price = {};
    if (minPrice !== undefined) searchQuery.price.$gte = minPrice;
    if (maxPrice !== undefined) searchQuery.price.$lte = maxPrice;
  }

  const sortOptions = {};
  sortOptions[sortBy] = sortOrder === 'desc' ? -1 : 1;

  const skip = (page - 1) * limit;

  return this.find(searchQuery)
    .sort(sortOptions)
    .skip(skip)
    .limit(limit);
};

// Static method to get coffee recommendations based on user preferences
coffeeSchema.statics.getRecommendations = async function(userId, limit = 10) {
  const User = mongoose.model('User');
  const UserFeedback = mongoose.model('UserFeedback');
  
  const user = await User.findById(userId);
  if (!user) return [];

  const preferences = user.preferences;
  
  // Build recommendation query based on user preferences
  let query = { isActive: true };
  
  // Preferred categories
  if (preferences.favoriteCategories && preferences.favoriteCategories.length > 0) {
    query.categories = { $in: preferences.favoriteCategories };
  }
  
  // Preferred roast levels
  if (preferences.roastLevels && preferences.roastLevels.length > 0) {
    query.roastLevel = { $in: preferences.roastLevels };
  }
  
  // Price range
  if (preferences.priceRange) {
    query.price = {
      $gte: preferences.priceRange.min,
      $lte: preferences.priceRange.max
    };
  }

  // Exclude already reviewed coffees
  const reviewedCoffees = await UserFeedback.find({ user: userId }).distinct('coffee');
  if (reviewedCoffees.length > 0) {
    query._id = { $nin: reviewedCoffees };
  }

  return this.find(query)
    .sort({ rating: -1, reviewCount: -1 })
    .limit(limit);
};

// Pre-save middleware to generate slug
coffeeSchema.pre('save', function(next) {
  if (this.isModified('name') && !this.seo.slug) {
    this.seo.slug = this.name
      .toLowerCase()
      .replace(/[^a-zA-Z0-9]/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '');
  }
  next();
});

module.exports = mongoose.model('Coffee', coffeeSchema);
