const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  action: {
    type: String,
    required: true,
    enum: [
      'USER_CREATED',
      'USER_UPDATED', 
      'USER_DELETED',
      'USER_ACTIVATED',
      'USER_DEACTIVATED',
      'USER_ROLE_CHANGED',
      'USER_LOGIN',
      'USER_LOGOUT',
      'USER_PASSWORD_RESET',
      'USER_EMAIL_VERIFIED',
      'PRODUCT_CREATED',
      'PRODUCT_UPDATED',
      'PRODUCT_DELETED',
      'ORDER_CREATED',
      'ORDER_UPDATED',
      'SETTINGS_UPDATED',
      'ADMIN_LOGIN',
      'ADMIN_LOGOUT'
    ]
  },
  targetUserId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null // For actions on other users
  },
  details: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },
  ipAddress: {
    type: String,
    default: null
  },
  userAgent: {
    type: String,
    default: null
  },
  timestamp: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Index for better query performance
auditLogSchema.index({ userId: 1, timestamp: -1 });
auditLogSchema.index({ action: 1, timestamp: -1 });
auditLogSchema.index({ targetUserId: 1, timestamp: -1 });

module.exports = mongoose.model('AuditLog', auditLogSchema);
