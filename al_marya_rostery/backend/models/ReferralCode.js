const mongoose = require('mongoose');

const referralCodeSchema = new mongoose.Schema({
  code: {
    type: String,
    required: true,
    unique: true,
    uppercase: true,
    trim: true
  },
  
  // Owner of the referral code
  userId: {
    type: String,
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
  
  // Discount configuration
  discountType: {
    type: String,
    enum: ['percentage', 'fixed'],
    default: 'percentage'
  },
  discountValue: {
    type: Number,
    required: true,
    min: 0
  },
  
  // Referrer reward
  referrerRewardType: {
    type: String,
    enum: ['percentage', 'fixed', 'points'],
    default: 'percentage'
  },
  referrerRewardValue: {
    type: Number,
    default: 10
  },
  
  // Usage limits
  maxUses: {
    type: Number,
    default: null // null = unlimited
  },
  currentUses: {
    type: Number,
    default: 0
  },
  
  // Validity period
  expiresAt: {
    type: Date,
    default: null // null = never expires
  },
  
  // Status
  isActive: {
    type: Boolean,
    default: true
  },
  
  // Applicable to
  applicableToPlans: [{
    type: String
  }], // Empty array = applicable to all plans
  
  minSubscriptionValue: {
    type: Number,
    default: 0
  },
  
  // Statistics
  totalUsed: {
    type: Number,
    default: 0
  },
  totalRevenue: {
    type: Number,
    default: 0
  },
  totalSavings: {
    type: Number,
    default: 0
  },
  
  // Referred users
  referredUsers: [{
    userId: String,
    userName: String,
    userEmail: String,
    subscriptionId: mongoose.Schema.Types.ObjectId,
    usedAt: Date,
    orderValue: Number,
    discountApplied: Number
  }],
  
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

// Indexes
referralCodeSchema.index({ code: 1, isActive: 1 });
referralCodeSchema.index({ userId: 1 });
referralCodeSchema.index({ expiresAt: 1 });

// Methods
referralCodeSchema.methods.isValid = function() {
  if (!this.isActive) return false;
  if (this.expiresAt && this.expiresAt < new Date()) return false;
  if (this.maxUses && this.currentUses >= this.maxUses) return false;
  return true;
};

referralCodeSchema.methods.canBeUsedBy = function(userId) {
  // Check if user already used this code
  return !this.referredUsers.some(ref => ref.userId === userId);
};

referralCodeSchema.methods.applyDiscount = function(amount) {
  if (this.discountType === 'percentage') {
    return amount * (this.discountValue / 100);
  } else {
    return Math.min(this.discountValue, amount);
  }
};

referralCodeSchema.methods.recordUsage = async function(subscriptionData) {
  this.currentUses++;
  this.totalUsed++;
  this.totalRevenue += subscriptionData.orderValue;
  this.totalSavings += subscriptionData.discountApplied;
  
  this.referredUsers.push({
    userId: subscriptionData.userId,
    userName: subscriptionData.userName,
    userEmail: subscriptionData.userEmail,
    subscriptionId: subscriptionData.subscriptionId,
    usedAt: new Date(),
    orderValue: subscriptionData.orderValue,
    discountApplied: subscriptionData.discountApplied
  });
  
  this.updatedAt = new Date();
  await this.save();
};

// Static methods
referralCodeSchema.statics.generateCode = function(prefix = 'REF') {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = prefix;
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
};

referralCodeSchema.statics.createUserReferralCode = async function(userId, userEmail, userName) {
  let code;
  let attempts = 0;
  const maxAttempts = 10;
  
  while (attempts < maxAttempts) {
    code = this.generateCode('REF');
    const existing = await this.findOne({ code });
    if (!existing) break;
    attempts++;
  }
  
  if (attempts === maxAttempts) {
    throw new Error('Failed to generate unique referral code');
  }
  
  const referralCode = new this({
    code,
    userId,
    userEmail,
    userName,
    discountType: 'percentage',
    discountValue: 15, // 15% discount for new users
    referrerRewardType: 'percentage',
    referrerRewardValue: 10, // 10% discount for referrer
    isActive: true
  });
  
  await referralCode.save();
  return referralCode;
};

const ReferralCode = mongoose.model('ReferralCode', referralCodeSchema);

module.exports = ReferralCode;
