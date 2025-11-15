const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
  coffee: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Coffee',
    required: true
  },
  name: {
    type: String,
    required: true // Store name at time of order
  },
  quantity: {
    type: Number,
    required: true,
    min: [1, 'Quantity must be at least 1']
  },
  price: {
    type: Number,
    required: true,
    min: [0, 'Price cannot be negative']
  },
  selectedSize: {
    type: String,
    enum: ['250g', '500g', '1kg']
  },
  subtotal: {
    type: Number,
    required: true,
    min: [0, 'Subtotal cannot be negative']
  }
}, { _id: false });

const orderSchema = new mongoose.Schema({
  orderNumber: {
    type: String,
    unique: true, // This automatically creates an index    flutter run
    required: true
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null // null for guest orders
  },
  guestInfo: {
    name: {
      type: String,
      trim: true
    },
    email: {
      type: String,
      lowercase: true,
      trim: true
    },
    phone: {
      type: String,
      trim: true
    },
    address: {
      street: String,
      city: String,
      state: String,
      zipCode: String,
      country: {
        type: String,
        default: 'UAE'
      }
    }
  },
  items: [orderItemSchema],
  subtotal: {
    type: Number,
    required: true,
    min: [0, 'Subtotal cannot be negative']
  },
  tax: {
    type: Number,
    default: 0,
    min: [0, 'Tax cannot be negative']
  },
  shipping: {
    type: Number,
    default: 0,
    min: [0, 'Shipping cannot be negative']
  },
  discount: {
    type: Number,
    default: 0,
    min: [0, 'Discount cannot be negative']
  },
  totalAmount: {
    type: Number,
    required: true,
    min: [0, 'Total amount cannot be negative']
  },
  currency: {
    type: String,
    default: 'AED',
    enum: ['AED', 'USD', 'EUR']
  },
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'accepted', 'preparing', 'ready', 'out-for-delivery', 'delivered', 'completed', 'cancelled', 'rejected', 'on-hold'],
    default: 'pending'
  },
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'failed', 'refunded'],
    default: 'pending'
  },
  paymentMethod: {
    type: String,
    enum: ['cash', 'card', 'apple_pay', 'google_pay', 'bank_transfer'],
    default: 'cash'
  },
  // Stripe payment fields
  stripePaymentIntentId: {
    type: String,
    sparse: true
  },
  transactionId: {
    type: String,
    sparse: true
  },
  paidAt: Date,
  refundedAt: Date,
  refundAmount: Number,
  refundReason: String,
  paymentFailureReason: String,
  deliveryMethod: {
    type: String,
    enum: ['pickup', 'delivery'],
    default: 'pickup'
  },
  deliveryAddress: {
    street: String,
    city: String,
    state: String,
    zipCode: String,
    country: {
      type: String,
      default: 'UAE'
    },
    instructions: String
  },
  estimatedDeliveryTime: Date,
  actualDeliveryTime: Date,
  notes: {
    type: String,
    maxlength: [500, 'Notes cannot be more than 500 characters']
  },
  tracking: {
    status: String,
    location: String,
    updatedAt: Date
  },

  // ===== PHASE 6: STAFF & DRIVER INTEGRATION =====
  
  // Staff Assignment
  assignedStaff: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Staff',
    default: null,
    index: true
  },

  // Driver Assignment
  assignedDriver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver',
    default: null,
    index: true
  },

  // Real-time Driver Location Tracking
  driverTracking: {
    currentLocation: {
      latitude: {
        type: Number,
        min: -90,
        max: 90
      },
      longitude: {
        type: Number,
        min: -180,
        max: 180
      },
      accuracy: Number, // in meters
      heading: Number,  // direction in degrees (0-360)
      speed: Number,    // in km/h
      updatedAt: Date
    },
    estimatedArrival: Date,
    distanceRemaining: Number, // in kilometers
    routePolyline: String // Encoded polyline for route display
  },

  // Order Status Timestamps (for analytics and tracking)
  statusTimestamps: {
    placed: {
      type: Date,
      default: Date.now
    },
    confirmed: Date,
    acceptedByStaff: Date,
    preparationStarted: Date,
    preparationCompleted: Date,
    markedReady: Date,
    acceptedByDriver: Date,
    pickedUpByDriver: Date,
    outForDelivery: Date,
    delivered: Date,
    cancelled: Date
  },

  // Preparation Time Tracking
  preparationTime: {
    estimatedMinutes: {
      type: Number,
      default: 15
    },
    actualMinutes: Number
  },

  // Delivery Time Tracking
  deliveryTime: {
    estimatedMinutes: {
      type: Number,
      default: 30
    },
    actualMinutes: Number
  },

  // Staff Notes (internal use)
  staffNotes: {
    type: String,
    maxlength: [500, 'Staff notes cannot exceed 500 characters']
  },

  // Driver Notes (internal use)
  driverNotes: {
    type: String,
    maxlength: [500, 'Driver notes cannot exceed 500 characters']
  },

  // ===== ORDER CANCELLATION FEATURE =====
  
  cancellation: {
    isCancelled: {
      type: Boolean,
      default: false
    },
    reason: String,
    cancelledAt: Date,
    cancelledBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    refundStatus: {
      type: String,
      enum: ['pending', 'processing', 'completed', 'failed'],
      default: null
    },
    refundAmount: Number,
    refundTransactionId: String,
    refundedAt: Date
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
  autoIndex: true // Allow automatic index creation in development
});

// ⚡ OPTIMIZED INDEXES - No duplicates, explicit definitions only

// Virtual for order age
orderSchema.virtual('orderAge').get(function() {
  return Math.floor((Date.now() - this.createdAt) / (1000 * 60 * 60)); // hours
});

// Virtual for formatted total
orderSchema.virtual('formattedTotal').get(function() {
  return `${this.currency} ${this.totalAmount.toFixed(2)}`;
});

// Note: Order number is now generated by orderNumberGenerator utility before save
// This ensures consistent format: ALM-YYYYMMDD-XXXXXX across all apps

// Instance method to calculate totals
orderSchema.methods.calculateTotals = function() {
  this.subtotal = this.items.reduce((sum, item) => sum + item.subtotal, 0);
  this.totalAmount = this.subtotal + this.tax + this.shipping - this.discount;
  return this.totalAmount;
};

// Instance method to update status
orderSchema.methods.updateStatus = function(newStatus, trackingInfo = null) {
  this.status = newStatus;

  if (trackingInfo) {
    this.tracking = {
      ...this.tracking,
      ...trackingInfo,
      updatedAt: new Date()
    };
  }

  if (newStatus === 'delivered') {
    this.actualDeliveryTime = new Date();
  }

  // Update status timestamps
  const timestampField = this._getTimestampField(newStatus);
  if (timestampField) {
    this.statusTimestamps[timestampField] = new Date();
  }

  return this.save();
};

// Helper method to get timestamp field name
orderSchema.methods._getTimestampField = function(status) {
  const statusMap = {
    'confirmed': 'confirmed',
    'preparing': 'preparationStarted',
    'ready': 'markedReady',
    'delivered': 'delivered',
    'cancelled': 'cancelled'
  };
  return statusMap[status];
};

// ===== PHASE 6: STAFF & DRIVER METHODS =====

// Instance method: Assign to staff
orderSchema.methods.assignToStaff = function(staffId) {
  this.assignedStaff = staffId;
  this.statusTimestamps.acceptedByStaff = new Date();
  return this.save();
};

// Instance method: Start preparation
orderSchema.methods.startPreparation = function() {
  this.status = 'preparing';
  this.statusTimestamps.preparationStarted = new Date();
  return this.save();
};

// Instance method: Mark as ready
orderSchema.methods.markReady = function() {
  this.status = 'ready';
  this.statusTimestamps.preparationCompleted = new Date();
  this.statusTimestamps.markedReady = new Date();
  
  // Calculate actual preparation time
  if (this.statusTimestamps.preparationStarted) {
    const startTime = this.statusTimestamps.preparationStarted;
    const endTime = this.statusTimestamps.preparationCompleted;
    this.preparationTime.actualMinutes = Math.round((endTime - startTime) / (1000 * 60));
  }
  
  return this.save();
};

// Instance method: Assign to driver
orderSchema.methods.assignToDriver = function(driverId) {
  this.assignedDriver = driverId;
  this.statusTimestamps.acceptedByDriver = new Date();
  return this.save();
};

// Instance method: Mark as picked up by driver
orderSchema.methods.markPickedUp = function() {
  this.statusTimestamps.pickedUpByDriver = new Date();
  this.statusTimestamps.outForDelivery = new Date();
  return this.save();
};

// Instance method: Update driver location
orderSchema.methods.updateDriverLocation = function(latitude, longitude, accuracy, heading, speed) {
  if (!this.driverTracking) {
    this.driverTracking = { currentLocation: {} };
  }
  
  this.driverTracking.currentLocation = {
    latitude,
    longitude,
    accuracy: accuracy || null,
    heading: heading || null,
    speed: speed || null,
    updatedAt: new Date()
  };
  
  return this.save();
};

// Instance method: Complete delivery
orderSchema.methods.completeDelivery = function() {
  this.status = 'delivered';
  this.statusTimestamps.delivered = new Date();
  this.actualDeliveryTime = new Date();
  
  // Calculate actual delivery time
  if (this.statusTimestamps.pickedUpByDriver) {
    const pickupTime = this.statusTimestamps.pickedUpByDriver;
    const deliveryTime = this.statusTimestamps.delivered;
    this.deliveryTime.actualMinutes = Math.round((deliveryTime - pickupTime) / (1000 * 60));
  }
  
  return this.save();
};

// Static method to find orders by user
orderSchema.statics.findByUser = function(userId, limit = 20) {
  return this.find({ user: userId })
    .sort({ createdAt: -1 })
    .limit(limit)
    .populate('items.coffee', 'name imageUrl');
};

// Static method to find recent orders
orderSchema.statics.findRecent = function(limit = 10) {
  return this.find({})
    .sort({ createdAt: -1 })
    .limit(limit)
    .populate('user', 'name email')
    .populate('items.coffee', 'name price');
};

// ===== PHASE 6: STAFF & DRIVER STATIC METHODS =====

// Static method: Find pending orders for staff
orderSchema.statics.findPendingForStaff = function() {
  return this.find({ 
    status: { $in: ['pending', 'confirmed'] },
    assignedStaff: null
  })
    .sort({ createdAt: 1 }) // Oldest first
    .populate('user', 'name email phone')
    .populate('items.coffee', 'name price');
};

// Static method: Find orders assigned to specific staff
orderSchema.statics.findByStaff = function(staffId) {
  return this.find({ 
    assignedStaff: staffId,
    status: { $in: ['pending', 'confirmed', 'accepted', 'preparing', 'ready', 'on-hold', 'out-for-delivery'] }
  })
    .sort({ createdAt: 1 })
    .populate('user', 'name email phone')
    .populate('items.coffee', 'name price');
};

// Static method: Find ready orders for drivers
orderSchema.statics.findReadyForDriver = function() {
  return this.find({ 
    status: 'ready',
    assignedDriver: null,
    deliveryMethod: 'delivery'
  })
    .sort({ 'statusTimestamps.markedReady': 1 }) // Oldest ready orders first
    .populate('user', 'name email phone')
    .populate('items.coffee', 'name price')
    .populate('assignedStaff', 'name');
};

// Static method: Find orders assigned to specific driver
orderSchema.statics.findByDriver = function(driverId) {
  return this.find({ 
    assignedDriver: driverId,
    status: { $in: ['ready', 'preparing', 'delivered'] }
  })
    .sort({ createdAt: -1 })
    .populate('user', 'name email phone')
    .populate('items.coffee', 'name price');
};

// Static method: Find active delivery for driver
orderSchema.statics.findActiveDelivery = function(driverId) {
  return this.findOne({ 
    assignedDriver: driverId,
    status: { $ne: 'delivered' }
  })
    .populate('user', 'name email phone')
    .populate('items.coffee', 'name price')
    .populate('assignedStaff', 'name');
};

// ===== PHASE 6: VIRTUAL PROPERTIES =====

// Virtual: Check if order is assigned to staff
orderSchema.virtual('isAssignedToStaff').get(function() {
  return this.assignedStaff !== null && this.assignedStaff !== undefined;
});

// Virtual: Check if order is assigned to driver
orderSchema.virtual('isAssignedToDriver').get(function() {
  return this.assignedDriver !== null && this.assignedDriver !== undefined;
});

// Virtual: Check if driver location is available
orderSchema.virtual('hasDriverLocation').get(function() {
  return this.driverTracking && 
         this.driverTracking.currentLocation &&
         this.driverTracking.currentLocation.latitude !== null &&
         this.driverTracking.currentLocation.longitude !== null;
});

// Virtual: Get preparation duration in human-readable format
orderSchema.virtual('preparationDuration').get(function() {
  if (!this.preparationTime.actualMinutes) {
    return `Est. ${this.preparationTime.estimatedMinutes} min`;
  }
  return `${this.preparationTime.actualMinutes} min`;
});

// Virtual: Get delivery duration in human-readable format
orderSchema.virtual('deliveryDuration').get(function() {
  if (!this.deliveryTime.actualMinutes) {
    return `Est. ${this.deliveryTime.estimatedMinutes} min`;
  }
  return `${this.deliveryTime.actualMinutes} min`;
});

// Virtual: Calculate total preparation + delivery time
orderSchema.virtual('totalFulfillmentTime').get(function() {
  const prepTime = this.preparationTime.actualMinutes || this.preparationTime.estimatedMinutes;
  const delivTime = this.deliveryTime.actualMinutes || this.deliveryTime.estimatedMinutes;
  return prepTime + delivTime;
});

// Virtual: Get driver location last updated (human-readable)
orderSchema.virtual('driverLocationAge').get(function() {
  if (!this.hasDriverLocation) {
    return 'No location';
  }
  
  const updatedAt = this.driverTracking.currentLocation.updatedAt;
  if (!updatedAt) return 'Unknown';
  
  const seconds = Math.floor((Date.now() - new Date(updatedAt).getTime()) / 1000);
  
  if (seconds < 60) return `${seconds}s ago`;
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  return `${Math.floor(seconds / 3600)}h ago`;
});

// ⚡ PERFORMANCE OPTIMIZED INDEXES - No duplicates
orderSchema.index({ user: 1, createdAt: -1 }); // User's order history (most common query)
// orderNumber unique index is automatically created by schema definition
orderSchema.index({ status: 1, paymentStatus: 1 }); // Admin filtering by status  
orderSchema.index({ status: 1, createdAt: -1 }); // Status-based timeline queries
orderSchema.index({ user: 1, status: 1 }); // User's orders by status
orderSchema.index({ 'guestInfo.email': 1 }); // Guest order lookup

// Compound index for comprehensive admin dashboard queries
orderSchema.index({ status: 1, paymentStatus: 1, createdAt: -1 });

// ===== PHASE 6: STAFF & DRIVER INDEXES =====

// Index for staff queries (find pending, assigned orders)
orderSchema.index({ assignedStaff: 1, status: 1 });

// Index for driver queries (find ready, assigned orders)
orderSchema.index({ assignedDriver: 1, status: 1 });

// Index for finding ready orders for drivers
orderSchema.index({ status: 1, 'statusTimestamps.markedReady': -1, assignedDriver: 1 });

// Index for delivery method + status queries
orderSchema.index({ deliveryMethod: 1, status: 1 });

// Compound index for staff dashboard (active orders by staff)
orderSchema.index({ assignedStaff: 1, status: 1, createdAt: -1 });

// Compound index for driver dashboard (active deliveries by driver)
orderSchema.index({ assignedDriver: 1, status: 1, createdAt: -1 });

module.exports = mongoose.model('Order', orderSchema);
