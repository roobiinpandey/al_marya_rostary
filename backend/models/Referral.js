const mongoose = require('mongoose');
const { LoyaltyAccount } = require('./Loyalty');

const referralSchema = new mongoose.Schema({
  // Referrer Information (person making the referral)
  // Uses Firebase UID from User.firebaseUid
  referrerUserId: {
    type: String,  // Firebase UID
    required: true,
    index: true,
    ref: 'User'
  },
  referrerEmail: {
    type: String,
    required: true
  },
  referrerName: {
    type: String,
    required: true
  },
  
  // Referee Information (person being referred)
  // Uses Firebase UID from User.firebaseUid
  refereeEmail: {
    type: String,
    required: true,
    index: true
  },
  refereeName: {
    type: String
  },
  refereeUserId: {
    type: String,  // Firebase UID (set when referee registers)
    index: true,
    ref: 'User'
  },
  
  // Referral Details
  referralCode: {
    type: String,
    required: true,
    unique: true // Automatically creates an index, no need for index: true
  },
  status: {
    type: String,
    enum: ['pending', 'registered', 'completed', 'cancelled'],
    default: 'pending'
  },
  
  // Rewards
  referrerReward: {
    points: {
      type: Number,
      default: 500
    },
    discount: {
      amount: Number,
      type: { type: String, enum: ['percentage', 'fixed'] }
    },
    awarded: {
      type: Boolean,
      default: false
    },
    awardedAt: {
      type: Date
    }
  },
  refereeReward: {
    discount: {
      amount: {
        type: Number,
        default: 10
      },
      type: {
        type: String,
        enum: ['percentage', 'fixed'],
        default: 'fixed'
      }
    },
    used: {
      type: Boolean,
      default: false
    },
    usedAt: {
      type: Date
    },
    orderNumber: {
      type: String
    }
  },
  
  // Tracking
  clickCount: {
    type: Number,
    default: 0
  },
  lastClickedAt: {
    type: Date
  },
  registeredAt: {
    type: Date
  },
  firstPurchaseAt: {
    type: Date
  },
  completedAt: {
    type: Date
  },
  
  // Campaign Information
  campaign: {
    type: String,
    default: 'general'
  },
  source: {
    type: String, // email, social, direct, etc.
    default: 'direct'
  },
  
  // Notes
  notes: {
    type: String
  },
  adminNotes: {
    type: String
  },
  
  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now,
    index: true
  },
  expiresAt: {
    type: Date,
    // Index created explicitly below
  }
}, {
  timestamps: true
});

const referralCodeSchema = new mongoose.Schema({
  userId: {
    type: String,  // Firebase UID from User.firebaseUid
    required: true,
    unique: true, // Automatically creates an index
    ref: 'User'
  },
  userEmail: {
    type: String,
    required: true
  },
  code: {
    type: String,
    required: true,
    unique: true,
    uppercase: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  usageCount: {
    type: Number,
    default: 0
  },
  maxUsage: {
    type: Number,
    default: 100 // Max number of people this code can refer
  },
  totalEarned: {
    points: {
      type: Number,
      default: 0
    },
    referrals: {
      type: Number,
      default: 0
    }
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Indexes
referralSchema.index({ referrerUserId: 1, status: 1 });
referralSchema.index({ refereeEmail: 1, status: 1 });
referralSchema.index({ createdAt: -1 });
referralSchema.index({ expiresAt: 1 });

// Methods
referralSchema.methods.markRegistered = function(refereeUserId, refereeName) {
  this.status = 'registered';
  this.refereeUserId = refereeUserId;
  this.refereeName = refereeName;
  this.registeredAt = new Date();
  return this.save();
};

referralSchema.methods.markCompleted = async function(orderNumber) {
  this.status = 'completed';
  this.completedAt = new Date();
  this.firstPurchaseAt = new Date();
  this.refereeReward.used = true;
  this.refereeReward.usedAt = new Date();
  this.refereeReward.orderNumber = orderNumber;
  
  // Award referrer points
  if (!this.referrerReward.awarded) {
    const loyaltyAccount = await LoyaltyAccount.findOne({ userId: this.referrerUserId });
    
    if (loyaltyAccount) {
      await loyaltyAccount.addPoints(
        this.referrerReward.points,
        'earned_referral',
        `Referral reward for ${this.refereeEmail}`,
        { relatedReferralId: this._id }
      );
    }
    
    this.referrerReward.awarded = true;
    this.referrerReward.awardedAt = new Date();
  }
  
  return this.save();
};

referralSchema.methods.trackClick = function() {
  this.clickCount++;
  this.lastClickedAt = new Date();
  return this.save();
};

// Static methods
referralSchema.statics.createReferral = async function(referrerUserId, referrerEmail, referrerName, refereeEmail) {
  const ReferralCode = mongoose.model('ReferralCode');
  
  // Get or create referral code for referrer
  let referralCode = await ReferralCode.findOne({ userId: referrerUserId });
  if (!referralCode) {
    const code = await this.generateUniqueCode(referrerEmail);
    referralCode = new ReferralCode({
      userId: referrerUserId,
      userEmail: referrerEmail,
      code
    });
    await referralCode.save();
  }
  
  // Check if referral already exists
  const existingReferral = await this.findOne({
    referrerUserId,
    refereeEmail,
    status: { $in: ['pending', 'registered'] }
  });
  
  if (existingReferral) {
    return existingReferral;
  }
  
  // Create new referral
  const referral = new this({
    referrerUserId,
    referrerEmail,
    referrerName,
    refereeEmail,
    referralCode: referralCode.code,
    expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days
  });
  
  await referral.save();
  
  // Update referral code usage
  referralCode.usageCount++;
  await referralCode.save();
  
  return referral;
};

referralSchema.statics.generateUniqueCode = async function(email) {
  const ReferralCode = mongoose.model('ReferralCode');
  const base = email.split('@')[0].toUpperCase().slice(0, 6);
  let code = base;
  let counter = 1;
  
  while (await ReferralCode.findOne({ code })) {
    code = `${base}${counter}`;
    counter++;
  }
  
  return code;
};

referralSchema.statics.getReferralStats = async function(userId) {
  const stats = await this.aggregate([
    { $match: { referrerUserId: userId } },
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 }
      }
    }
  ]);
  
  const result = {
    total: 0,
    pending: 0,
    registered: 0,
    completed: 0,
    cancelled: 0
  };
  
  stats.forEach(stat => {
    result[stat._id] = stat.count;
    result.total += stat.count;
  });
  
  return result;
};

// Create models
const Referral = mongoose.model('Referral', referralSchema);
const ReferralCode = mongoose.model('ReferralCode', referralCodeSchema);

module.exports = {
  Referral,
  ReferralCode
};
