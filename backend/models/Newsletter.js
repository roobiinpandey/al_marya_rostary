const mongoose = require('mongoose');

const newsletterSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Newsletter title is required'],
    trim: true,
    maxlength: [100, 'Title cannot be more than 100 characters']
  },
  subject: {
    type: String,
    required: [true, 'Email subject is required'],
    trim: true,
    maxlength: [150, 'Subject cannot be more than 150 characters']
  },
  content: {
    html: {
      type: String,
      required: [true, 'HTML content is required']
    },
    text: {
      type: String,
      default: ''
    }
  },
  targetAudience: [{
    type: String,
    enum: ['all', 'new-customers', 'returning-customers', 'loyal-customers', 'specific-emails'],
    default: ['all']
  }],
  recipientEmails: [{
    type: String,
    lowercase: true,
    trim: true
  }],
  status: {
    type: String,
    enum: ['draft', 'scheduled', 'sending', 'sent', 'failed'],
    default: 'draft'
  },
  scheduledDate: {
    type: Date,
    default: null
  },
  sentDate: {
    type: Date,
    default: null
  },
  deliveryStats: {
    totalSent: {
      type: Number,
      default: 0
    },
    successCount: {
      type: Number,
      default: 0
    },
    failureCount: {
      type: Number,
      default: 0
    },
    openRate: {
      type: Number,
      default: 0
    },
    clickRate: {
      type: Number,
      default: 0
    }
  },
  template: {
    type: String,
    enum: ['default', 'promotion', 'announcement', 'welcome', 'custom'],
    default: 'default'
  },
  tags: [String],
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  metadata: {
    campaignType: {
      type: String,
      enum: ['newsletter', 'promotional', 'transactional', 'announcement'],
      default: 'newsletter'
    },
    priority: {
      type: String,
      enum: ['low', 'normal', 'high'],
      default: 'normal'
    },
    testEmails: [String] // For testing before sending
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better query performance
newsletterSchema.index({ status: 1 });
newsletterSchema.index({ scheduledDate: 1 });
newsletterSchema.index({ sentDate: 1 });
newsletterSchema.index({ createdBy: 1 });
newsletterSchema.index({ targetAudience: 1 });
newsletterSchema.index({ tags: 1 });

// Virtual for formatted dates
newsletterSchema.virtual('formattedScheduledDate').get(function() {
  return this.scheduledDate ? this.scheduledDate.toLocaleString() : null;
});

newsletterSchema.virtual('formattedSentDate').get(function() {
  return this.sentDate ? this.sentDate.toLocaleString() : null;
});

// Virtual for success rate
newsletterSchema.virtual('successRate').get(function() {
  if (this.deliveryStats.totalSent === 0) return 0;
  return Math.round((this.deliveryStats.successCount / this.deliveryStats.totalSent) * 100);
});

// Instance method to mark as sent
newsletterSchema.methods.markAsSent = function(totalSent = 0, successCount = 0, failureCount = 0) {
  this.status = 'sent';
  this.sentDate = new Date();
  this.deliveryStats.totalSent = totalSent;
  this.deliveryStats.successCount = successCount;
  this.deliveryStats.failureCount = failureCount;
  return this.save();
};

// Instance method to update delivery stats
newsletterSchema.methods.updateDeliveryStats = function(stats) {
  if (stats.openRate !== undefined) this.deliveryStats.openRate = stats.openRate;
  if (stats.clickRate !== undefined) this.deliveryStats.clickRate = stats.clickRate;
  return this.save();
};

// Instance method to check if newsletter should be sent
newsletterSchema.methods.shouldSend = function() {
  if (this.status !== 'scheduled') return false;
  if (!this.scheduledDate) return false;
  return new Date() >= this.scheduledDate;
};

// Static method to find newsletters ready to send
newsletterSchema.statics.findReadyToSend = function() {
  const now = new Date();
  return this.find({
    status: 'scheduled',
    scheduledDate: { $lte: now }
  }).sort({ scheduledDate: 1 });
};

// Static method to get newsletter statistics
newsletterSchema.statics.getStats = async function() {
  const stats = await this.aggregate([
    {
      $group: {
        _id: null,
        totalNewsletters: { $sum: 1 },
        sentNewsletters: {
          $sum: { $cond: [{ $eq: ['$status', 'sent'] }, 1, 0] }
        },
        scheduledNewsletters: {
          $sum: { $cond: [{ $eq: ['$status', 'scheduled'] }, 1, 0] }
        },
        totalEmailsSent: { $sum: '$deliveryStats.totalSent' },
        totalSuccessful: { $sum: '$deliveryStats.successCount' },
        avgOpenRate: { $avg: '$deliveryStats.openRate' },
        avgClickRate: { $avg: '$deliveryStats.clickRate' }
      }
    }
  ]);

  return stats[0] || {
    totalNewsletters: 0,
    sentNewsletters: 0,
    scheduledNewsletters: 0,
    totalEmailsSent: 0,
    totalSuccessful: 0,
    avgOpenRate: 0,
    avgClickRate: 0
  };
};

// Pre-save middleware to set sent date when status changes to sent
newsletterSchema.pre('save', function(next) {
  if (this.isModified('status') && this.status === 'sent' && !this.sentDate) {
    this.sentDate = new Date();
  }
  next();
});

// Pre-save middleware to generate text content from HTML if empty
newsletterSchema.pre('save', function(next) {
  if (this.content.html && !this.content.text) {
    // Basic HTML to text conversion
    this.content.text = this.content.html
      .replace(/<[^>]*>/g, '')
      .replace(/\s+/g, ' ')
      .trim();
  }
  next();
});

module.exports = mongoose.model('Newsletter', newsletterSchema);
