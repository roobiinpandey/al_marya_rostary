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
    unique: true,
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
    enum: ['pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled'],
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
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better query performance
orderSchema.index({ user: 1, createdAt: -1 });
// orderNumber index is already created by unique: true, no need for duplicate
orderSchema.index({ status: 1 });
orderSchema.index({ paymentStatus: 1 });
orderSchema.index({ createdAt: -1 });
orderSchema.index({ 'guestInfo.email': 1 });

// Virtual for order age
orderSchema.virtual('orderAge').get(function() {
  return Math.floor((Date.now() - this.createdAt) / (1000 * 60 * 60)); // hours
});

// Virtual for formatted total
orderSchema.virtual('formattedTotal').get(function() {
  return `${this.currency} ${this.totalAmount.toFixed(2)}`;
});

// Pre-save middleware to generate order number
orderSchema.pre('save', function(next) {
  if (this.isNew && !this.orderNumber) {
    const timestamp = Date.now().toString().slice(-6);
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    this.orderNumber = `QA${timestamp}${random}`;
  }
  next();
});

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

module.exports = mongoose.model('Order', orderSchema);
