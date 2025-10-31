const mongoose = require('mongoose');

const contactInquirySchema = new mongoose.Schema({
  // Contact person information
  contactInfo: {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
      maxlength: [100, 'Name cannot be more than 100 characters']
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      trim: true,
      lowercase: true,
      validate: {
        validator: function(v) {
          return /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/.test(v);
        },
        message: 'Please enter a valid email address'
      }
    },
    phone: {
      type: String,
      trim: true,
      validate: {
        validator: function(v) {
          return !v || /^[\+]?[1-9][\d]{0,15}$/.test(v);
        },
        message: 'Please enter a valid phone number'
      }
    },
    company: {
      type: String,
      trim: true,
      maxlength: [200, 'Company name cannot be more than 200 characters']
    },
    position: {
      type: String,
      trim: true,
      maxlength: [100, 'Position cannot be more than 100 characters']
    }
  },
  // Inquiry details
  inquiry: {
    type: {
      type: String,
      enum: [
        'general', 
        'product-inquiry', 
        'bulk-order', 
        'partnership', 
        'complaint', 
        'feedback', 
        'technical-support', 
        'wholesale', 
        'franchise',
        'catering',
        'corporate-gifts',
        'return-refund',
        'other'
      ],
      required: [true, 'Inquiry type is required']
    },
    subject: {
      type: String,
      required: [true, 'Subject is required'],
      trim: true,
      maxlength: [200, 'Subject cannot be more than 200 characters']
    },
    message: {
      type: String,
      required: [true, 'Message is required'],
      trim: true,
      maxlength: [2000, 'Message cannot be more than 2000 characters']
    },
    priority: {
      type: String,
      enum: ['low', 'medium', 'high', 'urgent'],
      default: 'medium'
    },
    language: {
      type: String,
      enum: ['en', 'ar'],
      default: 'en'
    }
  },
  // Order/Product related (if applicable)
  relatedOrder: {
    orderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order'
    },
    orderNumber: String,
    productIds: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Coffee'
    }]
  },
  // Status and tracking
  status: {
    current: {
      type: String,
      enum: ['new', 'in-progress', 'pending-info', 'resolved', 'closed', 'escalated'],
      default: 'new'
    },
    history: [{
      status: {
        type: String,
        enum: ['new', 'in-progress', 'pending-info', 'resolved', 'closed', 'escalated']
      },
      timestamp: {
        type: Date,
        default: Date.now
      },
      updatedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      },
      note: String
    }]
  },
  // Assignment
  assignment: {
    assignedTo: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    assignedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    assignedAt: Date,
    department: {
      type: String,
      enum: ['customer-service', 'sales', 'technical', 'management', 'warehouse']
    }
  },
  // Response and resolution
  responses: [{
    respondedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    message: {
      type: String,
      required: true,
      maxlength: [2000, 'Response message cannot be more than 2000 characters']
    },
    isInternal: {
      type: Boolean,
      default: false
    },
    attachments: [{
      filename: String,
      url: String,
      size: Number,
      mimeType: String
    }],
    sentAt: {
      type: Date,
      default: Date.now
    },
    deliveryStatus: {
      type: String,
      enum: ['sent', 'delivered', 'failed'],
      default: 'sent'
    }
  }],
  // Customer satisfaction
  satisfaction: {
    rating: {
      type: Number,
      min: 1,
      max: 5
    },
    feedback: String,
    submittedAt: Date
  },
  // Metadata
  metadata: {
    source: {
      type: String,
      enum: ['website', 'app', 'phone', 'email', 'social-media', 'in-store'],
      default: 'website'
    },
    ipAddress: String,
    userAgent: String,
    referrer: String,
    sessionId: String
  },
  // Tags and categorization
  tags: [{
    type: String,
    trim: true,
    lowercase: true
  }],
  // Internal notes
  internalNotes: [{
    note: String,
    addedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    addedAt: {
      type: Date,
      default: Date.now
    },
    isPrivate: {
      type: Boolean,
      default: true
    }
  }],
  // Follow-up
  followUp: {
    isRequired: {
      type: Boolean,
      default: false
    },
    scheduledDate: Date,
    completedAt: Date,
    notes: String
  },
  // SLA tracking
  sla: {
    responseTime: {
      target: {
        type: Number, // in hours
        default: 24
      },
      actual: Number
    },
    resolutionTime: {
      target: {
        type: Number, // in hours
        default: 72
      },
      actual: Number
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better performance
contactInquirySchema.index({ 'contactInfo.email': 1 });
contactInquirySchema.index({ 'inquiry.type': 1 });
contactInquirySchema.index({ 'status.current': 1 });
contactInquirySchema.index({ 'assignment.assignedTo': 1 });
contactInquirySchema.index({ 'assignment.department': 1 });
contactInquirySchema.index({ createdAt: -1 });
contactInquirySchema.index({ 'inquiry.priority': 1, 'status.current': 1 });

// Text search index
contactInquirySchema.index({
  'contactInfo.name': 'text',
  'contactInfo.email': 'text',
  'inquiry.subject': 'text',
  'inquiry.message': 'text'
});

// Virtual for time since created
contactInquirySchema.virtual('timeSinceCreated').get(function() {
  const now = new Date();
  const diffInHours = Math.floor((now - this.createdAt) / (1000 * 60 * 60));
  
  if (diffInHours < 24) {
    return `${diffInHours} hours ago`;
  } else {
    const diffInDays = Math.floor(diffInHours / 24);
    return `${diffInDays} days ago`;
  }
});

// Virtual for SLA status
contactInquirySchema.virtual('slaStatus').get(function() {
  const now = new Date();
  const hoursSinceCreated = Math.floor((now - this.createdAt) / (1000 * 60 * 60));
  
  if (this.status.current === 'resolved' || this.status.current === 'closed') {
    return 'Met';
  }
  
  if (hoursSinceCreated > this.sla.responseTime.target && !this.responses.length) {
    return 'Response Overdue';
  }
  
  if (hoursSinceCreated > this.sla.resolutionTime.target) {
    return 'Resolution Overdue';
  }
  
  return 'On Track';
});

// Virtual for urgency score
contactInquirySchema.virtual('urgencyScore').get(function() {
  let score = 0;
  
  // Priority weight
  const priorityWeights = { low: 1, medium: 2, high: 3, urgent: 4 };
  score += priorityWeights[this.inquiry.priority] * 10;
  
  // Time weight
  const hoursSinceCreated = Math.floor((Date.now() - this.createdAt) / (1000 * 60 * 60));
  score += Math.min(hoursSinceCreated / 24, 5) * 10; // Max 5 days weight
  
  // Type weight
  const typeWeights = {
    'complaint': 15,
    'technical-support': 10,
    'return-refund': 10,
    'bulk-order': 8,
    'partnership': 5,
    'general': 3
  };
  score += typeWeights[this.inquiry.type] || 5;
  
  return Math.round(score);
});

// Instance methods
contactInquirySchema.methods.updateStatus = function(newStatus, updatedBy, note) {
  this.status.history.push({
    status: this.status.current,
    timestamp: new Date(),
    updatedBy,
    note
  });
  
  this.status.current = newStatus;
  
  if (newStatus === 'resolved') {
    const resolutionHours = Math.floor((new Date() - this.createdAt) / (1000 * 60 * 60));
    this.sla.resolutionTime.actual = resolutionHours;
  }
  
  return this.save();
};

contactInquirySchema.methods.assign = function(assignedTo, assignedBy, department) {
  this.assignment = {
    assignedTo,
    assignedBy,
    assignedAt: new Date(),
    department
  };
  
  if (this.status.current === 'new') {
    this.status.current = 'in-progress';
  }
  
  return this.save();
};

contactInquirySchema.methods.addResponse = function(responseData) {
  this.responses.push(responseData);
  
  // Update response SLA if this is the first response
  if (this.responses.length === 1) {
    const responseHours = Math.floor((new Date() - this.createdAt) / (1000 * 60 * 60));
    this.sla.responseTime.actual = responseHours;
  }
  
  return this.save();
};

contactInquirySchema.methods.addInternalNote = function(note, addedBy) {
  this.internalNotes.push({
    note,
    addedBy,
    addedAt: new Date()
  });
  
  return this.save();
};

contactInquirySchema.methods.setSatisfactionRating = function(rating, feedback) {
  this.satisfaction = {
    rating,
    feedback,
    submittedAt: new Date()
  };
  
  return this.save();
};

// Static methods
contactInquirySchema.statics.findByStatus = function(status, limit = 50) {
  return this.find({ 'status.current': status })
    .sort({ createdAt: -1 })
    .limit(limit)
    .populate('assignment.assignedTo', 'name email')
    .populate('relatedOrder.orderId', 'orderNumber');
};

contactInquirySchema.statics.findByDepartment = function(department, limit = 50) {
  return this.find({ 'assignment.department': department })
    .sort({ createdAt: -1 })
    .limit(limit)
    .populate('assignment.assignedTo', 'name email');
};

contactInquirySchema.statics.findByPriority = function(priority, limit = 50) {
  return this.find({ 'inquiry.priority': priority })
    .sort({ createdAt: -1 })
    .limit(limit);
};

contactInquirySchema.statics.findOverdue = function() {
  const twentyFourHoursAgo = new Date(Date.now() - (24 * 60 * 60 * 1000));
  const seventyTwoHoursAgo = new Date(Date.now() - (72 * 60 * 60 * 1000));
  
  return this.find({
    $or: [
      // No response in 24 hours
      {
        createdAt: { $lt: twentyFourHoursAgo },
        responses: { $size: 0 },
        'status.current': { $nin: ['resolved', 'closed'] }
      },
      // Not resolved in 72 hours
      {
        createdAt: { $lt: seventyTwoHoursAgo },
        'status.current': { $nin: ['resolved', 'closed'] }
      }
    ]
  }).sort({ createdAt: 1 });
};

contactInquirySchema.statics.getAnalytics = function(startDate, endDate) {
  const pipeline = [
    {
      $match: {
        createdAt: {
          $gte: startDate,
          $lte: endDate
        }
      }
    },
    {
      $group: {
        _id: null,
        totalInquiries: { $sum: 1 },
        avgResponseTime: { $avg: '$sla.responseTime.actual' },
        avgResolutionTime: { $avg: '$sla.resolutionTime.actual' },
        inquiriesByType: {
          $push: '$inquiry.type'
        },
        inquiriesByStatus: {
          $push: '$status.current'
        },
        inquiriesByPriority: {
          $push: '$inquiry.priority'
        }
      }
    }
  ];
  
  return this.aggregate(pipeline);
};

// Pre-save middleware
contactInquirySchema.pre('save', function(next) {
  // Add initial status to history if new
  if (this.isNew) {
    this.status.history.push({
      status: 'new',
      timestamp: this.createdAt || new Date()
    });
  }
  
  // Ensure tags are lowercase and trimmed
  if (this.tags && this.tags.length > 0) {
    this.tags = this.tags.map(tag => tag.toLowerCase().trim()).filter(tag => tag.length > 0);
  }
  
  next();
});

module.exports = mongoose.model('ContactInquiry', contactInquirySchema);
