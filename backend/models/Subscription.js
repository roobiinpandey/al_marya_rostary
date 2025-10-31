const mongoose = require('mongoose');

const subscriptionSchema = new mongoose.Schema({
  // User Information
  userId: {
    type: String,  // Firebase UID from User.firebaseUid
    required: true,
    index: true,
    ref: 'User'
  },
  userEmail: {
    type: String,
    required: true
  },
  userName: {
    type: String,
    required: true
  },
  
  // Subscription Details
  planId: {
    type: String,
    required: true
  },
  planName: {
    type: String,
    required: true
  },
  productId: {
    type: String,
    required: true
  },
  productName: {
    type: String,
    required: true
  },
  productSize: {
    type: String,
    required: true
  },
  
  // Frequency & Delivery
  frequency: {
    type: String,
    enum: ['weekly', 'bi-weekly', 'monthly', 'quarterly'],
    required: true
  },
  frequencyDisplay: {
    type: String,
    required: true
  },
  quantity: {
    type: Number,
    default: 1,
    min: 1
  },
  
  // Pricing
  originalPrice: {
    type: Number,
    required: true
  },
  discountPercentage: {
    type: Number,
    default: 0,
    min: 0,
    max: 50
  },
  subscriptionPrice: {
    type: Number,
    required: true
  },
  currency: {
    type: String,
    default: 'AED'
  },
  
  // Delivery Information
  deliveryAddress: {
    name: String,
    phone: String,
    street: String,
    city: String,
    emirate: String,
    area: String,
    building: String,
    apartment: String,
    landmark: String,
    isDefault: Boolean
  },
  deliveryInstructions: {
    type: String
  },
  
  // Schedule
  startDate: {
    type: Date,
    required: true
  },
  nextDelivery: {
    type: Date,
    required: true,
    index: true
  },
  lastDelivery: {
    type: Date
  },
  
  // Status
  status: {
    type: String,
    enum: ['active', 'paused', 'cancelled', 'expired'],
    default: 'active',
    index: true
  },
  pauseReason: {
    type: String
  },
  pausedUntil: {
    type: Date
  },
  cancellationReason: {
    type: String
  },
  cancelledAt: {
    type: Date
  },
  
  // Payment
  paymentMethod: {
    type: String,
    enum: ['card', 'cash_on_delivery', 'wallet'],
    default: 'cash_on_delivery'
  },
  paymentDetails: {
    cardLast4: String,
    cardType: String
  },
  
  // Statistics
  totalDeliveries: {
    type: Number,
    default: 0
  },
  totalAmount: {
    type: Number,
    default: 0
  },
  skippedDeliveries: {
    type: Number,
    default: 0
  },
  
  // Settings
  autoRenew: {
    type: Boolean,
    default: true
  },
  emailNotifications: {
    type: Boolean,
    default: true
  },
  smsNotifications: {
    type: Boolean,
    default: true
  },
  
  // Admin
  adminNotes: {
    type: String
  },
  createdBy: {
    type: String
  },
  
  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

const subscriptionPlanSchema = new mongoose.Schema({
  planId: {
    type: String,
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  frequency: {
    type: String,
    enum: ['weekly', 'bi-weekly', 'monthly', 'quarterly'],
    required: true
  },
  discountPercentage: {
    type: Number,
    required: true,
    min: 0,
    max: 50
  },
  minCommitmentMonths: {
    type: Number,
    default: 1
  },
  benefits: [{
    type: String
  }],
  isActive: {
    type: Boolean,
    default: true
  },
  sortOrder: {
    type: Number,
    default: 0
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

const subscriptionDeliverySchema = new mongoose.Schema({
  subscriptionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Subscription',
    required: true,
    index: true
  },
  userId: {
    type: String,  // Firebase UID from User.firebaseUid
    required: true,
    index: true,
    ref: 'User'
  },
  
  // Delivery Details
  deliveryDate: {
    type: Date,
    required: true,
    index: true
  },
  orderNumber: {
    type: String,
    unique: true // Automatically creates an index
  },
  
  // Status
  status: {
    type: String,
    enum: ['scheduled', 'preparing', 'out_for_delivery', 'delivered', 'failed', 'skipped'],
    default: 'scheduled',
    index: true
  },
  
  // Product Details
  productDetails: {
    productId: String,
    productName: String,
    size: String,
    quantity: Number,
    price: Number
  },
  
  // Delivery Tracking
  trackingInfo: {
    courierName: String,
    trackingNumber: String,
    estimatedDelivery: Date,
    actualDelivery: Date,
    deliveryNotes: String
  },
  
  // Payment
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'failed', 'refunded'],
    default: 'pending'
  },
  amount: {
    type: Number,
    required: true
  },
  
  // Admin
  processedBy: {
    type: String
  },
  adminNotes: {
    type: String
  },
  
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Indexes
subscriptionSchema.index({ userId: 1, status: 1 });
subscriptionSchema.index({ nextDelivery: 1, status: 1 });
subscriptionSchema.index({ productId: 1 });

subscriptionDeliverySchema.index({ subscriptionId: 1, deliveryDate: -1 });
subscriptionDeliverySchema.index({ status: 1, deliveryDate: 1 });

// Methods
subscriptionSchema.methods.pause = function(reason, until) {
  this.status = 'paused';
  this.pauseReason = reason;
  this.pausedUntil = until;
  this.updatedAt = new Date();
  return this.save();
};

subscriptionSchema.methods.resume = function() {
  this.status = 'active';
  this.pauseReason = undefined;
  this.pausedUntil = undefined;
  
  // Calculate next delivery date
  this.calculateNextDelivery();
  this.updatedAt = new Date();
  return this.save();
};

subscriptionSchema.methods.cancel = function(reason) {
  this.status = 'cancelled';
  this.cancellationReason = reason;
  this.cancelledAt = new Date();
  this.updatedAt = new Date();
  return this.save();
};

subscriptionSchema.methods.calculateNextDelivery = function() {
  const now = new Date();
  let nextDate = new Date(this.nextDelivery || this.startDate);
  
  // If next delivery is in the past, calculate from now
  if (nextDate < now) {
    nextDate = new Date(now);
  }
  
  switch (this.frequency) {
    case 'weekly':
      nextDate.setDate(nextDate.getDate() + 7);
      break;
    case 'bi-weekly':
      nextDate.setDate(nextDate.getDate() + 14);
      break;
    case 'monthly':
      nextDate.setMonth(nextDate.getMonth() + 1);
      break;
    case 'quarterly':
      nextDate.setMonth(nextDate.getMonth() + 3);
      break;
  }
  
  this.nextDelivery = nextDate;
};

subscriptionSchema.methods.createDelivery = async function() {
  const SubscriptionDelivery = mongoose.model('SubscriptionDelivery');
  
  // Generate order number
  const orderNumber = `SUB-${Date.now()}-${Math.random().toString(36).substr(2, 5).toUpperCase()}`;
  
  const delivery = new SubscriptionDelivery({
    subscriptionId: this._id,
    userId: this.userId,
    deliveryDate: this.nextDelivery,
    orderNumber,
    productDetails: {
      productId: this.productId,
      productName: this.productName,
      size: this.productSize,
      quantity: this.quantity,
      price: this.subscriptionPrice
    },
    amount: this.subscriptionPrice * this.quantity
  });
  
  await delivery.save();
  
  // Update subscription
  this.lastDelivery = this.nextDelivery;
  this.calculateNextDelivery();
  this.totalDeliveries++;
  this.totalAmount += delivery.amount;
  
  await this.save();
  
  return delivery;
};

// Static methods
subscriptionSchema.statics.getDueDeliveries = function(date = new Date()) {
  return this.find({
    status: 'active',
    nextDelivery: { $lte: date }
  });
};

subscriptionSchema.statics.getUserSubscriptions = function(userId, status = null) {
  const query = { userId };
  if (status) {
    query.status = status;
  }
  return this.find(query).sort({ createdAt: -1 });
};

// Create models
const Subscription = mongoose.model('Subscription', subscriptionSchema);
const SubscriptionPlan = mongoose.model('SubscriptionPlan', subscriptionPlanSchema);
const SubscriptionDelivery = mongoose.model('SubscriptionDelivery', subscriptionDeliverySchema);

module.exports = {
  Subscription,
  SubscriptionPlan,
  SubscriptionDelivery
};
