const mongoose = require('mongoose');

/**
 * Driver Model
 * Represents delivery drivers who handle order deliveries with GPS tracking
 * Used by Driver App for delivery management and real-time tracking
 */
const driverSchema = new mongoose.Schema({
  // Firebase Authentication
  firebaseUid: {
    type: String,
    required: true,
    unique: true,
    index: true,
    trim: true
  },

  // Basic Information
  name: {
    type: String,
    required: [true, 'Driver name is required'],
    trim: true,
    minlength: [2, 'Name must be at least 2 characters'],
    maxlength: [100, 'Name cannot exceed 100 characters']
  },

  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\S+@\S+\.\S+$/, 'Please enter a valid email address']
  },

  phone: {
    type: String,
    required: [true, 'Phone number is required'],
    trim: true,
    match: [/^[\d\s\-\+\(\)]+$/, 'Please enter a valid phone number']
  },

  // Vehicle Information
  vehicleType: {
    type: String,
    required: [true, 'Vehicle type is required'],
    enum: {
      values: ['bike', 'car', 'scooter', 'bicycle'],
      message: '{VALUE} is not a valid vehicle type'
    },
    index: true
  },

  vehicleNumber: {
    type: String,
    required: [true, 'Vehicle number is required'],
    trim: true,
    uppercase: true
  },

  vehicleColor: {
    type: String,
    trim: true,
    default: null
  },

  vehicleMake: {
    type: String,
    trim: true,
    default: null
  },

  // Push Notifications
  fcmToken: {
    type: String,
    default: null,
    trim: true
  },

  // Driver Status
  status: {
    type: String,
    enum: {
      values: ['available', 'on_delivery', 'offline'],
      message: '{VALUE} is not a valid driver status'
    },
    default: 'offline',
    index: true
  },

  // Real-time Location
  currentLocation: {
    latitude: {
      type: Number,
      min: -90,
      max: 90,
      default: null
    },
    longitude: {
      type: Number,
      min: -180,
      max: 180,
      default: null
    },
    accuracy: {
      type: Number, // in meters
      default: null
    },
    heading: {
      type: Number, // direction in degrees
      min: 0,
      max: 360,
      default: null
    },
    speed: {
      type: Number, // in km/h
      min: 0,
      default: null
    },
    updatedAt: {
      type: Date,
      default: null
    }
  },

  // Active Delivery
  activeDelivery: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order',
    default: null,
    index: true
  },

  // Delivery Statistics
  stats: {
    totalDeliveries: {
      type: Number,
      default: 0,
      min: 0
    },
    completedToday: {
      type: Number,
      default: 0,
      min: 0
    },
    completedThisWeek: {
      type: Number,
      default: 0,
      min: 0
    },
    completedThisMonth: {
      type: Number,
      default: 0,
      min: 0
    },
    totalEarnings: {
      type: Number,
      default: 0,
      min: 0
    },
    earningsToday: {
      type: Number,
      default: 0,
      min: 0
    },
    earningsThisWeek: {
      type: Number,
      default: 0,
      min: 0
    },
    earningsThisMonth: {
      type: Number,
      default: 0,
      min: 0
    },
    averageDeliveryTime: {
      type: Number, // in minutes
      default: 0,
      min: 0
    },
    averageRating: {
      type: Number,
      default: 0,
      min: 0,
      max: 5
    },
    totalRatings: {
      type: Number,
      default: 0,
      min: 0
    },
    lastDeliveryAt: {
      type: Date,
      default: null
    }
  },

  // Ratings & Reviews
  ratings: [{
    orderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order'
    },
    rating: {
      type: Number,
      required: true,
      min: 1,
      max: 5
    },
    comment: String,
    createdAt: {
      type: Date,
      default: Date.now
    }
  }],

  // Working Hours
  availability: {
    monday: { start: String, end: String, available: { type: Boolean, default: true } },
    tuesday: { start: String, end: String, available: { type: Boolean, default: true } },
    wednesday: { start: String, end: String, available: { type: Boolean, default: true } },
    thursday: { start: String, end: String, available: { type: Boolean, default: true } },
    friday: { start: String, end: String, available: { type: Boolean, default: true } },
    saturday: { start: String, end: String, available: { type: Boolean, default: true } },
    sunday: { start: String, end: String, available: { type: Boolean, default: true } }
  },

  // Employment Details
  hireDate: {
    type: Date,
    default: Date.now
  },

  // Account Verification
  isEmailVerified: {
    type: Boolean,
    default: false
  },

  isPhoneVerified: {
    type: Boolean,
    default: false
  },

  isDocumentsVerified: {
    type: Boolean,
    default: false
  },

  // Documents
  documents: {
    licenseNumber: String,
    licenseExpiryDate: Date,
    insuranceNumber: String,
    insuranceExpiryDate: Date
  },

  // Soft Delete
  isDeleted: {
    type: Boolean,
    default: false,
    index: true
  },

  deletedAt: {
    type: Date,
    default: null
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better query performance
driverSchema.index({ email: 1, isDeleted: 1 });
driverSchema.index({ status: 1, isDeleted: 1 });
driverSchema.index({ 'currentLocation.latitude': 1, 'currentLocation.longitude': 1 });
driverSchema.index({ vehicleType: 1, status: 1 });
driverSchema.index({ createdAt: -1 });

// Virtual: Is driver currently delivering
driverSchema.virtual('isDelivering').get(function() {
  return this.status === 'on_delivery' && this.activeDelivery !== null;
});

// Virtual: Is location recent (updated within last 2 minutes)
driverSchema.virtual('isLocationRecent').get(function() {
  if (!this.currentLocation.updatedAt) return false;
  const twoMinutesAgo = new Date(Date.now() - 2 * 60 * 1000);
  return this.currentLocation.updatedAt > twoMinutesAgo;
});

// Instance method: Update location
driverSchema.methods.updateLocation = function(latitude, longitude, accuracy, heading, speed) {
  this.currentLocation = {
    latitude,
    longitude,
    accuracy: accuracy || null,
    heading: heading || null,
    speed: speed || null,
    updatedAt: new Date()
  };
  return this.save();
};

// Instance method: Start delivery
driverSchema.methods.startDelivery = function(orderId) {
  this.status = 'on_delivery';
  this.activeDelivery = orderId;
  return this.save();
};

// Instance method: Complete delivery
driverSchema.methods.completeDelivery = function(deliveryTime, earnings) {
  // Update stats
  this.stats.totalDeliveries += 1;
  this.stats.completedToday += 1;
  this.stats.completedThisWeek += 1;
  this.stats.completedThisMonth += 1;
  
  this.stats.totalEarnings += earnings || 0;
  this.stats.earningsToday += earnings || 0;
  this.stats.earningsThisWeek += earnings || 0;
  this.stats.earningsThisMonth += earnings || 0;
  
  // Calculate average delivery time
  const currentAvg = this.stats.averageDeliveryTime || 0;
  const totalDeliveries = this.stats.totalDeliveries;
  this.stats.averageDeliveryTime = 
    ((currentAvg * (totalDeliveries - 1)) + deliveryTime) / totalDeliveries;
  
  this.stats.lastDeliveryAt = new Date();
  
  // Reset status
  this.status = 'available';
  this.activeDelivery = null;
  
  return this.save();
};

// Instance method: Add rating
driverSchema.methods.addRating = function(orderId, rating, comment) {
  this.ratings.push({
    orderId,
    rating,
    comment: comment || '',
    createdAt: new Date()
  });
  
  // Update average rating
  this.stats.totalRatings += 1;
  const totalRatings = this.stats.totalRatings;
  const currentAvg = this.stats.averageRating || 0;
  this.stats.averageRating = 
    ((currentAvg * (totalRatings - 1)) + rating) / totalRatings;
  
  return this.save();
};

// Instance method: Update status
driverSchema.methods.updateStatus = function(newStatus) {
  this.status = newStatus;
  
  // If going offline, clear active delivery
  if (newStatus === 'offline') {
    this.activeDelivery = null;
  }
  
  return this.save();
};

// Instance method: Reset daily stats (call at midnight)
driverSchema.methods.resetDailyStats = function() {
  this.stats.completedToday = 0;
  this.stats.earningsToday = 0;
  return this.save();
};

// Instance method: Reset weekly stats (call every Monday)
driverSchema.methods.resetWeeklyStats = function() {
  this.stats.completedThisWeek = 0;
  this.stats.earningsThisWeek = 0;
  return this.save();
};

// Instance method: Reset monthly stats (call on 1st of month)
driverSchema.methods.resetMonthlyStats = function() {
  this.stats.completedThisMonth = 0;
  this.stats.earningsThisMonth = 0;
  return this.save();
};

// Instance method: Update FCM token
driverSchema.methods.updateFcmToken = function(token) {
  this.fcmToken = token;
  return this.save();
};

// Static method: Find available drivers
driverSchema.statics.findAvailable = function() {
  return this.find({ 
    status: 'available', 
    isDeleted: false,
    isDocumentsVerified: true
  }).sort({ 'stats.totalDeliveries': 1 }); // Sort by least busy
};

// Static method: Find drivers near location (requires coordinates)
driverSchema.statics.findNearby = function(latitude, longitude, radiusInKm = 10) {
  // Simple distance calculation (for more accuracy, use geospatial queries)
  const radiusInDegrees = radiusInKm / 111; // Rough conversion
  
  return this.find({
    status: 'available',
    isDeleted: false,
    'currentLocation.latitude': {
      $gte: latitude - radiusInDegrees,
      $lte: latitude + radiusInDegrees
    },
    'currentLocation.longitude': {
      $gte: longitude - radiusInDegrees,
      $lte: longitude + radiusInDegrees
    }
  }).sort({ 'stats.averageRating': -1 });
};

// Static method: Get driver statistics
driverSchema.statics.getStatistics = async function() {
  const stats = await this.aggregate([
    { $match: { isDeleted: false } },
    {
      $group: {
        _id: null,
        totalDrivers: { $sum: 1 },
        availableDrivers: {
          $sum: { $cond: [{ $eq: ['$status', 'available'] }, 1, 0] }
        },
        onDeliveryDrivers: {
          $sum: { $cond: [{ $eq: ['$status', 'on_delivery'] }, 1, 0] }
        },
        offlineDrivers: {
          $sum: { $cond: [{ $eq: ['$status', 'offline'] }, 1, 0] }
        },
        totalDeliveries: { $sum: '$stats.totalDeliveries' },
        totalEarnings: { $sum: '$stats.totalEarnings' },
        avgDeliveryTime: { $avg: '$stats.averageDeliveryTime' },
        avgRating: { $avg: '$stats.averageRating' }
      }
    }
  ]);

  return stats.length > 0 ? stats[0] : {
    totalDrivers: 0,
    availableDrivers: 0,
    onDeliveryDrivers: 0,
    offlineDrivers: 0,
    totalDeliveries: 0,
    totalEarnings: 0,
    avgDeliveryTime: 0,
    avgRating: 0
  };
};

// Static method: Get top performers
driverSchema.statics.getTopPerformers = function(limit = 10) {
  return this.find({ isDeleted: false })
    .sort({ 'stats.averageRating': -1, 'stats.totalDeliveries': -1 })
    .limit(limit)
    .select('name email vehicleType stats');
};

// Pre-save middleware: Validate location if status is not offline
driverSchema.pre('save', function(next) {
  if (this.status !== 'offline' && (!this.currentLocation.latitude || !this.currentLocation.longitude)) {
    console.warn(`Driver ${this.name} is ${this.status} but has no location`);
  }
  next();
});

// Method to safely delete (soft delete)
driverSchema.methods.softDelete = function() {
  this.isDeleted = true;
  this.deletedAt = new Date();
  this.status = 'offline';
  this.activeDelivery = null;
  this.fcmToken = null;
  return this.save();
};

const Driver = mongoose.model('Driver', driverSchema);

module.exports = Driver;
