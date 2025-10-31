const mongoose = require('mongoose');

const loyaltyPointSchema = new mongoose.Schema({
  // User Information
  userId: {
    type: String,
    required: true,
    index: true
  },
  userEmail: {
    type: String,
    required: true
  },
  
  // Transaction Details
  transactionType: {
    type: String,
    enum: [
      'earned_purchase',     // Points earned from purchases
      'earned_referral',     // Points from successful referrals
      'earned_review',       // Points from writing reviews
      'earned_birthday',     // Birthday bonus points
      'earned_signup',       // Welcome bonus points
      'earned_social',       // Social media engagement
      'earned_bonus',        // Admin bonus points
      'redeemed_reward',     // Points spent on rewards
      'expired',             // Points expired
      'admin_adjustment'     // Manual admin adjustment
    ],
    required: true
  },
  
  // Points
  pointsEarned: {
    type: Number,
    default: 0,
    min: 0
  },
  pointsSpent: {
    type: Number,
    default: 0,
    min: 0
  },
  pointsBalance: {
    type: Number,
    required: true
  },
  
  // Related Information
  relatedOrderNumber: {
    type: String
  },
  relatedProductId: {
    type: String
  },
  relatedReferralId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Referral'
  },
  relatedRewardId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Reward'
  },
  
  // Transaction Description
  description: {
    type: String,
    required: true
  },
  adminNotes: {
    type: String
  },
  
  // Expiry Information
  expiresAt: {
    type: Date,
    // Index will be created explicitly below, removed duplicate index: true
  },
  isExpired: {
    type: Boolean,
    default: false
  },
  
  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now,
    index: true
  }
}, {
  timestamps: true
});

const loyaltyTierSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    enum: ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond']
  },
  minPoints: {
    type: Number,
    required: true
  },
  maxPoints: {
    type: Number
  },
  benefits: [{
    type: String
  }],
  pointsMultiplier: {
    type: Number,
    default: 1.0
  },
  color: {
    type: String,
    default: '#8B4513'
  },
  icon: {
    type: String
  }
});

const loyaltyAccountSchema = new mongoose.Schema({
  // User Information (FIREBASE INTEGRATION)
  userId: {
    type: String,  // Firebase UID from User.firebaseUid
    required: true,
    unique: true, // Automatically creates an index
    ref: 'User'  // Reference to User model
  },
  userEmail: {
    type: String,
    required: true
  },
  userName: {
    type: String
  },
  
  // Points Summary
  totalPointsEarned: {
    type: Number,
    default: 0,
    min: 0
  },
  totalPointsSpent: {
    type: Number,
    default: 0,
    min: 0
  },
  currentBalance: {
    type: Number,
    default: 0,
    min: 0
  },
  pendingPoints: {
    type: Number,
    default: 0,
    min: 0
  },
  
  // Tier Information
  currentTier: {
    type: String,
    enum: ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'],
    default: 'Bronze'
  },
  tierProgress: {
    type: Number,
    default: 0,
    min: 0,
    max: 100
  },
  nextTier: {
    type: String,
    enum: ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond']
  },
  pointsToNextTier: {
    type: Number,
    default: 0
  },
  
  // Activity Stats
  totalPurchases: {
    type: Number,
    default: 0
  },
  totalReferrals: {
    type: Number,
    default: 0
  },
  totalReviews: {
    type: Number,
    default: 0
  },
  
  // Settings
  emailNotifications: {
    type: Boolean,
    default: true
  },
  smsNotifications: {
    type: Boolean,
    default: false
  },
  
  // Timestamps
  joinedAt: {
    type: Date,
    default: Date.now
  },
  lastActivity: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Indexes
loyaltyPointSchema.index({ userId: 1, createdAt: -1 });
loyaltyPointSchema.index({ transactionType: 1 });
loyaltyPointSchema.index({ expiresAt: 1 });

// Methods for LoyaltyAccount
loyaltyAccountSchema.methods.addPoints = async function(points, type, description, relatedData = {}) {
  // Use the model that will be defined at the end of this file
  const LoyaltyPoint = mongoose.models.LoyaltyPoint || mongoose.model('LoyaltyPoint');
  
  // Create point transaction
  const pointTransaction = new LoyaltyPoint({
    userId: this.userId,
    userEmail: this.userEmail,
    transactionType: type,
    pointsEarned: points,
    pointsBalance: this.currentBalance + points,
    description,
    ...relatedData
  });
  
  await pointTransaction.save();
  
  // Update account
  this.totalPointsEarned += points;
  this.currentBalance += points;
  this.lastActivity = new Date();
  
  // Update tier if needed
  await this.updateTier();
  
  return this.save();
};

loyaltyAccountSchema.methods.spendPoints = async function(points, rewardId, description) {
  if (this.currentBalance < points) {
    throw new Error('Insufficient points balance');
  }
  
  // Use the model that will be defined at the end of this file
  const LoyaltyPoint = mongoose.models.LoyaltyPoint || mongoose.model('LoyaltyPoint');
  
  // Create point transaction
  const pointTransaction = new LoyaltyPoint({
    userId: this.userId,
    userEmail: this.userEmail,
    transactionType: 'redeemed_reward',
    pointsSpent: points,
    pointsBalance: this.currentBalance - points,
    description,
    relatedRewardId: rewardId
  });
  
  await pointTransaction.save();
  
  // Update account
  this.totalPointsSpent += points;
  this.currentBalance -= points;
  this.lastActivity = new Date();
  
  // Update tier if needed
  await this.updateTier();
  
  return this.save();
};

loyaltyAccountSchema.methods.updateTier = async function() {
  // Use the model that will be defined at the end of this file
  const LoyaltyTier = mongoose.models.LoyaltyTier || mongoose.model('LoyaltyTier');
  const tiers = await LoyaltyTier.find().sort({ minPoints: 1 });
  
  let newTier = 'Bronze';
  let nextTier = 'Silver';
  let pointsToNext = 0;
  let progress = 0;
  
  for (let i = 0; i < tiers.length; i++) {
    const tier = tiers[i];
    if (this.totalPointsEarned >= tier.minPoints) {
      newTier = tier.name;
      if (i < tiers.length - 1) {
        nextTier = tiers[i + 1].name;
        pointsToNext = tiers[i + 1].minPoints - this.totalPointsEarned;
        progress = ((this.totalPointsEarned - tier.minPoints) / (tiers[i + 1].minPoints - tier.minPoints)) * 100;
      } else {
        nextTier = tier.name; // Max tier reached
        pointsToNext = 0;
        progress = 100;
      }
    }
  }
  
  this.currentTier = newTier;
  this.nextTier = nextTier;
  this.pointsToNextTier = pointsToNext;
  this.tierProgress = Math.min(100, Math.max(0, progress));
};

// Static methods
loyaltyAccountSchema.statics.getOrCreateAccount = async function(userId, userEmail) {
  let account = await this.findOne({ userId });
  
  if (!account) {
    account = new this({
      userId,
      userEmail
    });
    await account.save();
    
    // Welcome bonus
    await account.addPoints(100, 'earned_signup', 'Welcome bonus for joining!');
  }
  
  return account;
};

// Create models
const LoyaltyPoint = mongoose.model('LoyaltyPoint', loyaltyPointSchema);
const LoyaltyTier = mongoose.model('LoyaltyTier', loyaltyTierSchema);
const LoyaltyAccount = mongoose.model('LoyaltyAccount', loyaltyAccountSchema);

module.exports = {
  LoyaltyPoint,
  LoyaltyTier,
  LoyaltyAccount
};
