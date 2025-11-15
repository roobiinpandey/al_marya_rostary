const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Notification title is required'],
    trim: true,
    maxlength: [100, 'Title cannot be more than 100 characters']
  },
  message: {
    type: String,
    required: [true, 'Notification message is required'],
    maxlength: [500, 'Message cannot be more than 500 characters']
  },
  type: {
    type: String,
    enum: ['info', 'success', 'warning', 'error', 'promotion', 'update', 'reminder'],
    default: 'info'
  },
  targetAudience: [{
    type: String,
    enum: ['all', 'new-customers', 'returning-customers', 'loyal-customers', 'specific-users'],
    default: ['all']
  }],
  specificUsers: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  image: {
    type: String,
    default: null
  },
  actionButton: {
    text: {
      type: String,
      maxlength: [50, 'Button text cannot be more than 50 characters']
    },
    link: {
      type: String,
      trim: true
    }
  },
  scheduledDate: {
    type: Date,
    default: null
  },
  sentDate: {
    type: Date,
    default: null
  },
  status: {
    type: String,
    enum: ['draft', 'scheduled', 'sending', 'sent', 'failed'],
    default: 'draft'
  },
  priority: {
    type: String,
    enum: ['low', 'normal', 'high', 'urgent'],
    default: 'normal'
  },
  deliveryStats: {
    totalSent: {
      type: Number,
      default: 0
    },
    totalDelivered: {
      type: Number,
      default: 0
    },
    totalClicked: {
      type: Number,
      default: 0
    },
    totalFailed: {
      type: Number,
      default: 0
    }
  },
  categories: [{
    type: String,
    trim: true
  }],
  tags: [String], // For analytics and filtering
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  metadata: {
    platform: {
      type: String,
      enum: ['web', 'mobile', 'all'],
      default: 'all'
    },
    userAgent: String,
    ipAddress: String
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better query performance
notificationSchema.index({ status: 1 });
notificationSchema.index({ scheduledDate: 1 });
notificationSchema.index({ sentDate: 1 });
notificationSchema.index({ type: 1 });
notificationSchema.index({ priority: 1 });
notificationSchema.index({ targetAudience: 1 });
notificationSchema.index({ categories: 1 });
notificationSchema.index({ createdBy: 1 });

// Virtual for formatted dates
notificationSchema.virtual('formattedScheduledDate').get(function() {
  return this.scheduledDate ? this.scheduledDate.toLocaleString() : null;
});

notificationSchema.virtual('formattedSentDate').get(function() {
  return this.sentDate ? this.sentDate.toLocaleString() : null;
});

// Virtual for delivery rate
notificationSchema.virtual('deliveryRate').get(function() {
  if (this.deliveryStats.totalSent === 0) return 0;
  return Math.round((this.deliveryStats.totalDelivered / this.deliveryStats.totalSent) * 100);
});

// Virtual for click rate
notificationSchema.virtual('clickRate').get(function() {
  if (this.deliveryStats.totalDelivered === 0) return 0;
  return Math.round((this.deliveryStats.totalClicked / this.deliveryStats.totalDelivered) * 100);
});

// Instance method to mark as sent
notificationSchema.methods.markAsSent = function(sentCount = 0, deliveredCount = 0) {
  this.status = 'sent';
  this.sentDate = new Date();
  this.deliveryStats.totalSent = sentCount;
  this.deliveryStats.totalDelivered = deliveredCount;
  return this.save();
};

// Instance method to update delivery stats
notificationSchema.methods.updateDeliveryStats = function(delivered = 0, clicked = 0, failed = 0) {
  this.deliveryStats.totalDelivered += delivered;
  this.deliveryStats.totalClicked += clicked;
  this.deliveryStats.totalFailed += failed;
  return this.save();
};

// Instance method to check if notification should be sent
notificationSchema.methods.shouldSend = function() {
  if (this.status !== 'scheduled') return false;
  if (!this.scheduledDate) return false;
  return new Date() >= this.scheduledDate;
};

// Static method to find notifications ready to send
notificationSchema.statics.findReadyToSend = function() {
  const now = new Date();
  return this.find({
    status: 'scheduled',
    scheduledDate: { $lte: now }
  }).sort({ priority: -1, scheduledDate: 1 });
};

// Static method to find sent notifications
notificationSchema.statics.findSent = function(limit = 50) {
  return this.find({ status: 'sent' })
    .sort({ sentDate: -1 })
    .limit(limit)
    .populate('createdBy', 'name email');
};

// Static method to get notification statistics
notificationSchema.statics.getStats = async function() {
  const stats = await this.aggregate([
    {
      $group: {
        _id: null,
        totalNotifications: { $sum: 1 },
        sentNotifications: {
          $sum: { $cond: [{ $eq: ['$status', 'sent'] }, 1, 0] }
        },
        scheduledNotifications: {
          $sum: { $cond: [{ $eq: ['$status', 'scheduled'] }, 1, 0] }
        },
        totalSent: { $sum: '$deliveryStats.totalSent' },
        totalDelivered: { $sum: '$deliveryStats.totalDelivered' },
        totalClicked: { $sum: '$deliveryStats.totalClicked' }
      }
    }
  ]);

  return stats[0] || {
    totalNotifications: 0,
    sentNotifications: 0,
    scheduledNotifications: 0,
    totalSent: 0,
    totalDelivered: 0,
    totalClicked: 0
  };
};

// Pre-save middleware to set sent date when status changes to sent
notificationSchema.pre('save', function(next) {
  if (this.isModified('status') && this.status === 'sent' && !this.sentDate) {
    this.sentDate = new Date();
  }
  next();
});

module.exports = mongoose.model('Notification', notificationSchema);
