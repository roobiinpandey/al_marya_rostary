const mongoose = require('mongoose');

const ticketMessageSchema = new mongoose.Schema({
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  senderType: {
    type: String,
    enum: ['customer', 'admin'],
    required: true
  },
  message: {
    type: String,
    required: [true, 'Message is required'],
    maxlength: [2000, 'Message cannot be more than 2000 characters']
  },
  attachments: [{
    filename: String,
    originalName: String,
    mimetype: String,
    size: Number,
    path: String
  }],
  isInternal: {
    type: Boolean,
    default: false // Internal notes between admin staff
  },
  readBy: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    readAt: {
      type: Date,
      default: Date.now
    }
  }]
}, {
  timestamps: true
});

const supportTicketSchema = new mongoose.Schema({
  ticketNumber: {
    type: String,
    unique: true,
    required: true
  },
  title: {
    type: String,
    required: [true, 'Ticket title is required'],
    trim: true,
    maxlength: [150, 'Title cannot be more than 150 characters']
  },
  description: {
    type: String,
    required: [true, 'Description is required'],
    maxlength: [1000, 'Description cannot be more than 1000 characters']
  },
  customer: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null // null for guest tickets
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
    }
  },
  category: {
    type: String,
    enum: [
      'general', 'order-issue', 'payment-problem', 'delivery-issue', 
      'product-quality', 'account-problem', 'feature-request', 'bug-report', 'other'
    ],
    default: 'general'
  },
  priority: {
    type: String,
    enum: ['low', 'normal', 'high', 'urgent'],
    default: 'normal'
  },
  status: {
    type: String,
    enum: ['open', 'in-progress', 'waiting-customer', 'resolved', 'closed'],
    default: 'open'
  },
  assignedTo: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  tags: [String],
  relatedOrder: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order',
    default: null
  },
  messages: [ticketMessageSchema],
  resolution: {
    summary: String,
    resolvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    resolvedAt: Date,
    satisfactionRating: {
      type: Number,
      min: 1,
      max: 5
    },
    feedback: String
  },
  metadata: {
    source: {
      type: String,
      enum: ['web', 'mobile', 'email', 'phone', 'admin'],
      default: 'web'
    },
    userAgent: String,
    ipAddress: String,
    firstResponseAt: Date,
    lastCustomerReplyAt: Date,
    lastAdminReplyAt: Date
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better query performance
supportTicketSchema.index({ ticketNumber: 1 });
supportTicketSchema.index({ customer: 1 });
supportTicketSchema.index({ 'guestInfo.email': 1 });
supportTicketSchema.index({ status: 1 });
supportTicketSchema.index({ priority: 1 });
supportTicketSchema.index({ category: 1 });
supportTicketSchema.index({ assignedTo: 1 });
supportTicketSchema.index({ createdAt: -1 });
supportTicketSchema.index({ tags: 1 });

// Virtual for response time in hours
supportTicketSchema.virtual('responseTimeHours').get(function() {
  if (!this.metadata.firstResponseAt) return null;
  return Math.round((this.metadata.firstResponseAt - this.createdAt) / (1000 * 60 * 60));
});

// Virtual for resolution time in hours
supportTicketSchema.virtual('resolutionTimeHours').get(function() {
  if (!this.resolution?.resolvedAt) return null;
  return Math.round((this.resolution.resolvedAt - this.createdAt) / (1000 * 60 * 60));
});

// Virtual for unread message count
supportTicketSchema.virtual('unreadCount').get(function() {
  return this.messages.filter(msg => 
    msg.senderType === 'customer' && 
    !msg.readBy.some(read => read.user.toString() !== this.customer?.toString())
  ).length;
});

// Virtual for last activity
supportTicketSchema.virtual('lastActivity').get(function() {
  if (this.messages.length === 0) return this.createdAt;
  return this.messages[this.messages.length - 1].createdAt;
});

// Pre-save middleware to generate ticket number
supportTicketSchema.pre('save', function(next) {
  if (this.isNew && !this.ticketNumber) {
    const timestamp = Date.now().toString().slice(-6);
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    this.ticketNumber = `QA-${timestamp}-${random}`;
  }
  next();
});

// Instance method to add message
supportTicketSchema.methods.addMessage = function(messageData) {
  this.messages.push(messageData);
  
  // Update metadata
  if (messageData.senderType === 'admin') {
    this.metadata.lastAdminReplyAt = new Date();
    if (!this.metadata.firstResponseAt) {
      this.metadata.firstResponseAt = new Date();
    }
  } else {
    this.metadata.lastCustomerReplyAt = new Date();
  }
  
  return this.save();
};

// Instance method to assign ticket
supportTicketSchema.methods.assignTo = function(adminId) {
  this.assignedTo = adminId;
  this.status = 'in-progress';
  return this.save();
};

// Instance method to resolve ticket
supportTicketSchema.methods.resolve = function(resolutionData) {
  this.status = 'resolved';
  this.resolution = {
    ...resolutionData,
    resolvedAt: new Date()
  };
  return this.save();
};

// Instance method to close ticket
supportTicketSchema.methods.close = function() {
  this.status = 'closed';
  return this.save();
};

// Instance method to update priority
supportTicketSchema.methods.updatePriority = function(priority) {
  this.priority = priority;
  return this.save();
};

// Static method to find tickets by customer
supportTicketSchema.statics.findByCustomer = function(customerId, limit = 20) {
  return this.find({ customer: customerId })
    .sort({ createdAt: -1 })
    .limit(limit)
    .populate('assignedTo', 'name email');
};

// Static method to find unassigned tickets
supportTicketSchema.statics.findUnassigned = function() {
  return this.find({ 
    assignedTo: null, 
    status: { $in: ['open', 'in-progress'] } 
  })
  .sort({ priority: -1, createdAt: 1 });
};

// Static method to find tickets by status
supportTicketSchema.statics.findByStatus = function(status, limit = 50) {
  return this.find({ status })
    .sort({ updatedAt: -1 })
    .limit(limit)
    .populate('customer', 'name email')
    .populate('assignedTo', 'name email');
};

// Static method to get ticket statistics
supportTicketSchema.statics.getStats = async function() {
  const stats = await this.aggregate([
    {
      $group: {
        _id: null,
        totalTickets: { $sum: 1 },
        openTickets: {
          $sum: { $cond: [{ $eq: ['$status', 'open'] }, 1, 0] }
        },
        inProgressTickets: {
          $sum: { $cond: [{ $eq: ['$status', 'in-progress'] }, 1, 0] }
        },
        resolvedTickets: {
          $sum: { $cond: [{ $eq: ['$status', 'resolved'] }, 1, 0] }
        },
        closedTickets: {
          $sum: { $cond: [{ $eq: ['$status', 'closed'] }, 1, 0] }
        },
        avgSatisfactionRating: { $avg: '$resolution.satisfactionRating' }
      }
    }
  ]);

  // Get priority breakdown
  const priorityStats = await this.aggregate([
    { $match: { status: { $in: ['open', 'in-progress'] } } },
    {
      $group: {
        _id: '$priority',
        count: { $sum: 1 }
      }
    }
  ]);

  // Get category breakdown
  const categoryStats = await this.aggregate([
    {
      $group: {
        _id: '$category',
        count: { $sum: 1 }
      }
    },
    { $sort: { count: -1 } }
  ]);

  return {
    overview: stats[0] || {
      totalTickets: 0,
      openTickets: 0,
      inProgressTickets: 0,
      resolvedTickets: 0,
      closedTickets: 0,
      avgSatisfactionRating: 0
    },
    priorityBreakdown: priorityStats,
    categoryBreakdown: categoryStats
  };
};

// Static method to find overdue tickets (no response in 24 hours)
supportTicketSchema.statics.findOverdue = function() {
  const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
  return this.find({
    status: { $in: ['open', 'in-progress'] },
    'metadata.lastAdminReplyAt': { $lt: twentyFourHoursAgo },
    createdAt: { $lt: twentyFourHoursAgo }
  }).populate('customer', 'name email');
};

module.exports = mongoose.model('SupportTicket', supportTicketSchema);
