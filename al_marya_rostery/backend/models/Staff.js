const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

/**
 * Staff Model
 * Represents cafe staff members who manage and prepare orders
 * Used by Staff App for order management
 * Authentication: Employee ID + 4-digit PIN or QR Badge scan
 */
const staffSchema = new mongoose.Schema({
  // ===== NEW: QR Badge + PIN Authentication =====
  
  // Employee ID (Primary authentication identifier)
  employeeId: {
    type: String,
    required: true,
    unique: true,
    uppercase: true,
    trim: true,
    index: true,
    match: [/^[A-Z]{3}\d{3}$/, 'Employee ID must be in format: ABC123 (e.g., BAR001)']
  },

  // PIN for login (BCrypt hashed, 4 digits)
  pin: {
    type: String,
    // Note: Can be 4 digits (raw) or 60 chars (BCrypt hash)
    // Pre-save middleware will hash 4-digit PINs automatically
    select: false // Don't return PIN in queries by default
  },

  // PIN security
  pinAttempts: {
    type: Number,
    default: 0,
    max: 3
  },

  pinLockedUntil: {
    type: Date,
    default: null
  },

  requirePinChange: {
    type: Boolean,
    default: true // Force PIN change on first login
  },

  // QR Badge Token (encrypted, unique per staff)
  qrBadgeToken: {
    type: String,
    unique: true,
    sparse: true // Allows multiple null values
  },

  qrBadgeGeneratedAt: {
    type: Date,
    default: null
  },

  qrBadgeExpiresAt: {
    type: Date,
    default: null // Optional: Rotate badges every 6 months
  },

  // Staff photo (for badge printing)
  photo: {
    type: String, // Cloudinary URL
    default: null
  },

  // Shift times
  shiftStartTime: {
    type: String,
    default: '08:00',
    match: [/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, 'Invalid time format (HH:MM)']
  },

  shiftEndTime: {
    type: String,
    default: '16:00',
    match: [/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, 'Invalid time format (HH:MM)']
  },

  // Login audit trail
  loginHistory: [{
    timestamp: {
      type: Date,
      default: Date.now
    },
    method: {
      type: String,
      enum: ['qr', 'pin', 'firebase', 'admin-web'],
      required: true
    },
    deviceInfo: String,
    ipAddress: String,
    success: {
      type: Boolean,
      required: true
    },
    failureReason: String
  }],

  lastLoginAt: {
    type: Date,
    default: null
  },

  // ===== Staff Admin Panel Credentials (Username/Password) =====
  
  // Admin panel username (separate from Employee ID)
  adminUsername: {
    type: String,
    unique: true,
    sparse: true, // Allows multiple null values
    trim: true,
    lowercase: true,
    minlength: [4, 'Admin username must be at least 4 characters'],
    maxlength: [50, 'Admin username cannot exceed 50 characters']
  },

  // Admin panel password (BCrypt hashed)
  adminPassword: {
    type: String,
    select: false, // Don't return password in queries by default
    minlength: [6, 'Admin password must be at least 6 characters']
  },

  // Flag indicating if staff has admin panel access
  hasAdminAccess: {
    type: Boolean,
    default: false,
    index: true
  },

  // Last admin login
  lastAdminLoginAt: {
    type: Date,
    default: null
  },

  // ===== Firebase Authentication (Optional/Deprecated) =====
  firebaseUid: {
    type: String,
    required: false, // Changed from true - now optional
    unique: true,
    sparse: true, // Allows multiple null values
    index: true,
    trim: true
  },

  // Basic Information
  name: {
    type: String,
    required: [true, 'Staff name is required'],
    trim: true,
    minlength: [2, 'Name must be at least 2 characters'],
    maxlength: [100, 'Name cannot exceed 100 characters']
  },

  email: {
    type: String,
    required: false, // Changed from true - now optional (for admin contact only)
    unique: true,
    sparse: true, // Allows multiple null values
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

  // Staff Role
  role: {
    type: String,
    enum: {
      values: ['barista', 'manager', 'cashier'],
      message: '{VALUE} is not a valid staff role'
    },
    default: 'barista',
    index: true
  },

  // Push Notifications
  fcmToken: {
    type: String,
    default: null,
    trim: true
  },

  // Staff Status
  status: {
    type: String,
    enum: {
      values: ['active', 'inactive', 'on_break'],
      message: '{VALUE} is not a valid status'
    },
    default: 'active',
    index: true
  },

  // Order Management
  assignedOrders: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order'
  }],

  // Statistics
  stats: {
    totalOrdersProcessed: {
      type: Number,
      default: 0,
      min: 0
    },
    ordersProcessedToday: {
      type: Number,
      default: 0,
      min: 0
    },
    averagePreparationTime: {
      type: Number, // in minutes
      default: 0,
      min: 0
    },
    lastOrderProcessedAt: {
      type: Date,
      default: null
    }
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
  timestamps: true, // Adds createdAt and updatedAt
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better query performance
staffSchema.index({ employeeId: 1, isDeleted: 1 }); // Primary lookup
// qrBadgeToken index created automatically by unique: true in schema
staffSchema.index({ email: 1, isDeleted: 1 });
staffSchema.index({ status: 1, isDeleted: 1 });
staffSchema.index({ role: 1, status: 1 });
staffSchema.index({ createdAt: -1 });

// ===== NEW: Virtual Fields =====

// Virtual: Check if staff is currently on shift
staffSchema.virtual('isOnShift').get(function() {
  const now = new Date();
  const currentTime = now.getHours() * 100 + now.getMinutes();
  const [startHour, startMin] = this.shiftStartTime.split(':').map(Number);
  const [endHour, endMin] = this.shiftEndTime.split(':').map(Number);
  const shiftStart = startHour * 100 + startMin;
  const shiftEnd = endHour * 100 + endMin;
  return currentTime >= shiftStart && currentTime <= shiftEnd;
});

// Virtual: Check if PIN is locked
staffSchema.virtual('isPinLocked').get(function() {
  if (!this.pinLockedUntil) return false;
  return new Date() < this.pinLockedUntil;
});

// Virtual: Check if QR badge is valid
staffSchema.virtual('isQrBadgeValid').get(function() {
  if (!this.qrBadgeToken) return false;
  if (!this.qrBadgeExpiresAt) return true; // No expiry set
  return new Date() < this.qrBadgeExpiresAt;
});

// Virtual: Active orders count
staffSchema.virtual('activeOrdersCount').get(function() {
  return this.assignedOrders ? this.assignedOrders.length : 0;
});

// Instance method: Assign order to staff
staffSchema.methods.assignOrder = function(orderId) {
  if (!this.assignedOrders.includes(orderId)) {
    this.assignedOrders.push(orderId);
  }
  return this.save();
};

// Instance method: Remove order from staff
staffSchema.methods.removeOrder = function(orderId) {
  this.assignedOrders = this.assignedOrders.filter(
    id => id.toString() !== orderId.toString()
  );
  return this.save();
};

// Instance method: Update statistics
staffSchema.methods.updateStats = function(preparationTime) {
  this.stats.totalOrdersProcessed += 1;
  this.stats.ordersProcessedToday += 1;
  this.stats.lastOrderProcessedAt = new Date();
  
  // Calculate average preparation time
  const currentAvg = this.stats.averagePreparationTime || 0;
  const totalOrders = this.stats.totalOrdersProcessed;
  this.stats.averagePreparationTime = 
    ((currentAvg * (totalOrders - 1)) + preparationTime) / totalOrders;
  
  return this.save();
};

// Instance method: Reset daily stats (call at midnight)
staffSchema.methods.resetDailyStats = function() {
  this.stats.ordersProcessedToday = 0;
  return this.save();
};

// Instance method: Update FCM token
staffSchema.methods.updateFcmToken = function(token) {
  this.fcmToken = token;
  return this.save();
};

// Instance method: Update status
staffSchema.methods.updateStatus = function(newStatus) {
  this.status = newStatus;
  return this.save();
};

// ===== NEW: PIN Authentication Methods =====

// Instance method: Validate PIN
staffSchema.methods.validatePin = async function(pin) {
  // Check if PIN is locked
  if (this.isPinLocked) {
    throw new Error('PIN is locked due to too many failed attempts');
  }
  
  const isValid = await bcrypt.compare(pin, this.pin);
  
  if (!isValid) {
    // Increment failed attempts
    this.pinAttempts += 1;
    
    // Lock PIN after 3 failed attempts
    if (this.pinAttempts >= 3) {
      this.pinLockedUntil = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes
    }
    
    await this.save();
    return false;
  }
  
  // Reset attempts on successful login
  this.pinAttempts = 0;
  this.pinLockedUntil = null;
  this.lastLoginAt = new Date();
  await this.save();
  
  return true;
};

// Instance method: Change PIN
staffSchema.methods.changePin = async function(newPin) {
  if (!/^\d{4}$/.test(newPin)) {
    throw new Error('PIN must be exactly 4 digits');
  }
  
  this.pin = newPin; // Will be hashed by pre-save middleware
  this.requirePinChange = false;
  this.pinAttempts = 0;
  this.pinLockedUntil = null;
  return this.save();
};

// Instance method: Reset PIN (admin only)
staffSchema.methods.resetPin = async function(newPin, requireChange = true) {
  if (!/^\d{4}$/.test(newPin)) {
    throw new Error('PIN must be exactly 4 digits');
  }
  
  this.pin = newPin; // Will be hashed by pre-save middleware
  this.requirePinChange = requireChange;
  this.pinAttempts = 0;
  this.pinLockedUntil = null;
  return this.save();
};

// Instance method: Unlock PIN (admin only)
staffSchema.methods.unlockPin = function() {
  this.pinAttempts = 0;
  this.pinLockedUntil = null;
  return this.save();
};

// Instance method: Add login history entry
staffSchema.methods.addLoginHistory = async function(method, deviceInfo, ipAddress, success, failureReason = null) {
  // Keep only last 50 login attempts
  if (this.loginHistory.length >= 50) {
    this.loginHistory = this.loginHistory.slice(-49);
  }
  
  this.loginHistory.push({
    timestamp: new Date(),
    method,
    deviceInfo,
    ipAddress,
    success,
    failureReason
  });
  
  if (success) {
    this.lastLoginAt = new Date();
    if (method === 'admin-web') {
      this.lastAdminLoginAt = new Date();
    }
  }
  
  return this.save({ validateBeforeSave: false });
};

// ===== Admin Panel Authentication Methods =====

// Instance method: Validate admin password
staffSchema.methods.validateAdminPassword = async function(password) {
  if (!this.hasAdminAccess || !this.adminPassword) {
    throw new Error('Staff member does not have admin panel access');
  }
  
  const isValid = await bcrypt.compare(password, this.adminPassword);
  
  if (isValid) {
    this.lastAdminLoginAt = new Date();
    await this.save();
  }
  
  return isValid;
};

// Instance method: Set admin credentials
staffSchema.methods.setAdminCredentials = async function(username, password) {
  if (!username || username.length < 4) {
    throw new Error('Admin username must be at least 4 characters');
  }
  
  if (!password || password.length < 6) {
    throw new Error('Admin password must be at least 6 characters');
  }
  
  this.adminUsername = username.toLowerCase().trim();
  this.adminPassword = password; // Will be hashed by pre-save middleware
  this.hasAdminAccess = true;
  return this.save();
};

// Instance method: Remove admin access
staffSchema.methods.removeAdminAccess = function() {
  this.adminUsername = null;
  this.adminPassword = null;
  this.hasAdminAccess = false;
  this.lastAdminLoginAt = null;
  return this.save();
};

// Static method: Find by admin username
staffSchema.statics.findByAdminUsername = function(username) {
  return this.findOne({ 
    adminUsername: username.toLowerCase().trim(),
    hasAdminAccess: true,
    isDeleted: false,
    status: 'active'
  }).select('+adminPassword');
};

// ===== NEW: Employee ID Generation =====

// Static method: Generate unique Employee ID based on role
staffSchema.statics.generateEmployeeId = async function(role) {
  const rolePrefix = {
    'barista': 'BAR',
    'manager': 'MNG',
    'cashier': 'CSH'
  };
  
  const prefix = rolePrefix[role] || 'EMP';
  
  // Find last Employee ID with this prefix
  const lastStaff = await this.findOne({ 
    employeeId: new RegExp(`^${prefix}`, 'i'),
    isDeleted: false
  }).sort('-employeeId');
  
  let newNumber = 1;
  if (lastStaff) {
    const lastNumber = parseInt(lastStaff.employeeId.slice(3));
    newNumber = lastNumber + 1;
  }
  
  const formattedNumber = newNumber.toString().padStart(3, '0');
  return `${prefix}${formattedNumber}`;
};

// Static method: Find by Employee ID
staffSchema.statics.findByEmployeeId = function(employeeId) {
  return this.findOne({ 
    employeeId: employeeId.toUpperCase(), 
    isDeleted: false 
  });
};

// Static method: Find by QR badge token
staffSchema.statics.findByQRToken = function(qrToken) {
  return this.findOne({ 
    qrBadgeToken: qrToken, 
    isDeleted: false 
  });
};

// Static method: Check if PIN is already taken (for uniqueness validation)
staffSchema.statics.isPinTaken = async function(pin, excludeStaffId = null) {
  // Find all staff with PINs (select PIN field explicitly)
  const allStaff = await this.find({ isDeleted: false }).select('+pin');
  
  for (const staff of allStaff) {
    // Skip checking against the same staff (for updates)
    if (excludeStaffId && staff._id.toString() === excludeStaffId.toString()) {
      continue;
    }
    
    // Compare PIN using bcrypt
    if (staff.pin && await bcrypt.compare(pin, staff.pin)) {
      return {
        taken: true,
        takenBy: {
          employeeId: staff.employeeId,
          name: staff.name
        }
      };
    }
  }
  
  return { taken: false };
};

// Static method: Find staff by PIN (for PIN-only login)
staffSchema.statics.findByPin = async function(pin) {
  // Get all active staff with PINs
  const allStaff = await this.find({ 
    isDeleted: false,
    status: { $ne: 'inactive' }
  }).select('+pin');
  
  // Compare PIN with each staff member's hashed PIN
  for (const staff of allStaff) {
    if (staff.pin && await bcrypt.compare(pin, staff.pin)) {
      return staff;
    }
  }
  
  return null;
};

// Static method: Find active staff
staffSchema.statics.findActive = function() {
  return this.find({ 
    status: 'active', 
    isDeleted: false 
  }).sort({ name: 1 });
};

// Static method: Find staff by role
staffSchema.statics.findByRole = function(role) {
  return this.find({ 
    role, 
    isDeleted: false 
  }).sort({ name: 1 });
};

// Static method: Find available staff (active and not on break)
staffSchema.statics.findAvailable = function() {
  return this.find({ 
    status: 'active', 
    isDeleted: false 
  }).sort({ 'stats.totalOrdersProcessed': 1 }); // Sort by least busy
};

// Static method: Get staff statistics
staffSchema.statics.getStatistics = async function() {
  const stats = await this.aggregate([
    { $match: { isDeleted: false } },
    {
      $group: {
        _id: null,
        totalStaff: { $sum: 1 },
        activeStaff: {
          $sum: { $cond: [{ $eq: ['$status', 'active'] }, 1, 0] }
        },
        inactiveStaff: {
          $sum: { $cond: [{ $eq: ['$status', 'inactive'] }, 1, 0] }
        },
        onBreakStaff: {
          $sum: { $cond: [{ $eq: ['$status', 'on_break'] }, 1, 0] }
        },
        totalOrdersProcessed: { $sum: '$stats.totalOrdersProcessed' },
        avgPreparationTime: { $avg: '$stats.averagePreparationTime' }
      }
    }
  ]);

  return stats.length > 0 ? stats[0] : {
    totalStaff: 0,
    activeStaff: 0,
    inactiveStaff: 0,
    onBreakStaff: 0,
    totalOrdersProcessed: 0,
    avgPreparationTime: 0
  };
};

// Static method: Get top performers
staffSchema.statics.getTopPerformers = function(limit = 10) {
  return this.find({ isDeleted: false })
    .sort({ 'stats.totalOrdersProcessed': -1 })
    .limit(limit)
    .select('name email role stats');
};

// ===== NEW: Pre-save Middleware for PIN and Admin Password Hashing =====

// Pre-save middleware: Hash PIN and admin password if modified
staffSchema.pre('save', async function(next) {
  try {
    // Hash PIN if modified and is exactly 4 digits (not already hashed)
    if (this.isModified('pin') && this.pin && /^\d{4}$/.test(this.pin)) {
      this.pin = await bcrypt.hash(this.pin, 10);
    }
    
    // Hash admin password if modified and not already hashed
    if (this.isModified('adminPassword') && this.adminPassword) {
      // Check if it's already hashed (BCrypt hashes are 60 chars and start with $2)
      if (!this.adminPassword.startsWith('$2') || this.adminPassword.length !== 60) {
        this.adminPassword = await bcrypt.hash(this.adminPassword, 10);
      }
    }
    
    next();
  } catch (error) {
    next(error);
  }
});

// Pre-save middleware: Clean up assigned orders
staffSchema.pre('save', function(next) {
  // Remove duplicate order IDs
  if (this.assignedOrders && this.assignedOrders.length > 0) {
    this.assignedOrders = [...new Set(this.assignedOrders.map(id => id.toString()))]
      .map(id => new mongoose.Types.ObjectId(id));
  }
  next();
});

// Pre-save middleware: Validate status change
staffSchema.pre('save', function(next) {
  // Skip validation if this is a soft delete operation
  if (this.isDeleted) {
    return next();
  }
  
  if (this.isModified('status') && this.status === 'inactive' && this.assignedOrders.length > 0) {
    const error = new Error('Cannot set status to inactive while orders are assigned');
    return next(error);
  }
  next();
});

// Method to safely delete (soft delete)
staffSchema.methods.softDelete = function() {
  this.isDeleted = true;
  this.deletedAt = new Date();
  this.status = 'inactive';
  this.fcmToken = null;
  return this.save();
};

const Staff = mongoose.model('Staff', staffSchema);

module.exports = Staff;
