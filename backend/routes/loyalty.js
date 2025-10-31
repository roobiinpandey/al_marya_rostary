const express = require('express');
const router = express.Router();
const { LoyaltyAccount, LoyaltyPoint, LoyaltyTier } = require('../models/Loyalty');
const { body, validationResult, param, query } = require('express-validator');
const { protect } = require('../middleware/auth');

// Get user's loyalty account
router.get('/account/:userId', [
  param('userId').notEmpty().withMessage('User ID is required')
], async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Get or create loyalty account
    const userEmail = req.user?.email || req.query.email;
    if (!userEmail) {
      return res.status(400).json({
        success: false,
        message: 'User email is required'
      });
    }
    
    const account = await LoyaltyAccount.getOrCreateAccount(userId, userEmail);
    
    // Get recent transactions
    const recentTransactions = await LoyaltyPoint.find({ userId })
      .sort({ createdAt: -1 })
      .limit(10)
      .lean();
    
    // Get tier information
    const allTiers = await LoyaltyTier.find().sort({ minPoints: 1 }).lean(); // Convert to plain objects
    const currentTierInfo = allTiers.find(tier => tier.name === account.currentTier);
    const nextTierInfo = allTiers.find(tier => tier.name === account.nextTier);
    
    res.json({
      success: true,
      data: {
        account: {
          ...account.toObject(),
          currentTierInfo,
          nextTierInfo
        },
        recentTransactions: recentTransactions.map(transaction => ({
          ...transaction,
          formattedDate: formatRelativeDate(transaction.createdAt)
        })),
        tiers: allTiers
      }
    });

  } catch (error) {
    console.error('Error fetching loyalty account:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch loyalty account',
      error: error.message
    });
  }
});

// Get user's loyalty points history
router.get('/points/:userId', [
  param('userId').notEmpty().withMessage('User ID is required'),
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 50 }),
  query('type').optional().isIn([
    'earned_purchase', 'earned_referral', 'earned_review', 'earned_birthday',
    'earned_signup', 'earned_social', 'earned_bonus', 'redeemed_reward',
    'expired', 'admin_adjustment'
  ])
], async (req, res) => {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 20, type } = req.query;
    
    const query = { userId };
    if (type) {
      query.transactionType = type;
    }
    
    const transactions = await LoyaltyPoint.find(query)
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .lean();
    
    const total = await LoyaltyPoint.countDocuments(query);
    
    const transactionsWithDates = transactions.map(transaction => ({
      ...transaction,
      formattedDate: formatRelativeDate(transaction.createdAt)
    }));
    
    res.json({
      success: true,
      data: {
        transactions: transactionsWithDates,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          totalTransactions: total
        }
      }
    });

  } catch (error) {
    console.error('Error fetching points history:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch points history',
      error: error.message
    });
  }
});

// Award points (for purchases, reviews, etc.)
router.post('/points/award', [
  body('userId').notEmpty().withMessage('User ID is required'),
  body('userEmail').isEmail().withMessage('Valid email is required'),
  body('points').isInt({ min: 1 }).withMessage('Points must be a positive integer'),
  body('type').isIn([
    'earned_purchase', 'earned_referral', 'earned_review', 'earned_birthday',
    'earned_signup', 'earned_social', 'earned_bonus'
  ]).withMessage('Invalid point type'),
  body('description').notEmpty().withMessage('Description is required'),
  body('relatedOrderNumber').optional().isString(),
  body('relatedProductId').optional().isString()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const { userId, userEmail, points, type, description, relatedOrderNumber, relatedProductId } = req.body;
    
    const account = await LoyaltyAccount.getOrCreateAccount(userId, userEmail);
    
    const relatedData = {};
    if (relatedOrderNumber) relatedData.relatedOrderNumber = relatedOrderNumber;
    if (relatedProductId) relatedData.relatedProductId = relatedProductId;
    
    await account.addPoints(points, type, description, relatedData);
    
    res.json({
      success: true,
      message: 'Points awarded successfully',
      data: {
        pointsAwarded: points,
        newBalance: account.currentBalance,
        tier: account.currentTier
      }
    });

  } catch (error) {
    console.error('Error awarding points:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to award points',
      error: error.message
    });
  }
});

// Get available rewards
router.get('/rewards', async (req, res) => {
  try {
    // Define available rewards (could be moved to database)
    const rewards = [
      {
        id: 'free_coffee_250g',
        title: 'Free 250g Coffee',
        description: 'Get any 250g coffee bag for free',
        pointsCost: 500,
        category: 'product',
        image: '/images/rewards/free-coffee.jpg',
        isAvailable: true,
        validityDays: 30
      },
      {
        id: 'discount_10_percent',
        title: '10% Off Next Purchase',
        description: 'Get 10% discount on your next order',
        pointsCost: 300,
        category: 'discount',
        discountPercent: 10,
        isAvailable: true,
        validityDays: 14
      },
      {
        id: 'free_shipping',
        title: 'Free Shipping',
        description: 'Free delivery on your next order',
        pointsCost: 200,
        category: 'shipping',
        isAvailable: true,
        validityDays: 30
      },
      {
        id: 'premium_tasting_set',
        title: 'Premium Tasting Set',
        description: 'Curated selection of our finest coffee samples',
        pointsCost: 1000,
        category: 'product',
        image: '/images/rewards/tasting-set.jpg',
        isAvailable: true,
        validityDays: 60
      },
      {
        id: 'coffee_masterclass',
        title: 'Coffee Brewing Masterclass',
        description: 'Online session with our coffee expert',
        pointsCost: 1500,
        category: 'experience',
        isAvailable: true,
        validityDays: 90
      }
    ];
    
    res.json({
      success: true,
      data: {
        rewards
      }
    });

  } catch (error) {
    console.error('Error fetching rewards:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch rewards',
      error: error.message
    });
  }
});

// Redeem a reward
router.post('/rewards/redeem', [
  body('userId').notEmpty().withMessage('User ID is required'),
  body('rewardId').notEmpty().withMessage('Reward ID is required'),
  body('pointsCost').isInt({ min: 1 }).withMessage('Points cost must be a positive integer')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const { userId, rewardId, pointsCost } = req.body;
    
    const account = await LoyaltyAccount.findOne({ userId });
    if (!account) {
      return res.status(404).json({
        success: false,
        message: 'Loyalty account not found'
      });
    }
    
    if (account.currentBalance < pointsCost) {
      return res.status(400).json({
        success: false,
        message: 'Insufficient points balance',
        data: {
          required: pointsCost,
          available: account.currentBalance
        }
      });
    }
    
    // Create reward redemption record (you might want a separate model for this)
    const rewardDescription = getRewardDescription(rewardId);
    await account.spendPoints(pointsCost, rewardId, `Redeemed: ${rewardDescription}`);
    
    // Generate redemption code
    const redemptionCode = generateRedemptionCode();
    
    res.json({
      success: true,
      message: 'Reward redeemed successfully',
      data: {
        redemptionCode,
        pointsSpent: pointsCost,
        newBalance: account.currentBalance,
        rewardId,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days
      }
    });

  } catch (error) {
    console.error('Error redeeming reward:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to redeem reward',
      error: error.message
    });
  }
});

// Get loyalty tiers
router.get('/tiers', async (req, res) => {
  try {
    const tiers = await LoyaltyTier.find().sort({ minPoints: 1 }).lean(); // Convert to plain objects
    
    res.json({
      success: true,
      data: {
        tiers
      }
    });

  } catch (error) {
    console.error('Error fetching tiers:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch tiers',
      error: error.message
    });
  }
});

// Admin: Get loyalty statistics
router.get('/admin/stats', protect, async (req, res) => {
  try {
    const totalAccounts = await LoyaltyAccount.countDocuments();
    const totalPointsAwarded = await LoyaltyPoint.aggregate([
      { $match: { pointsEarned: { $gt: 0 } } },
      { $group: { _id: null, total: { $sum: '$pointsEarned' } } }
    ]);
    const totalPointsRedeemed = await LoyaltyPoint.aggregate([
      { $match: { pointsSpent: { $gt: 0 } } },
      { $group: { _id: null, total: { $sum: '$pointsSpent' } } }
    ]);
    
    const tierDistribution = await LoyaltyAccount.aggregate([
      { $group: { _id: '$currentTier', count: { $sum: 1 } } }
    ]);
    
    res.json({
      success: true,
      data: {
        totalAccounts,
        totalPointsAwarded: totalPointsAwarded[0]?.total || 0,
        totalPointsRedeemed: totalPointsRedeemed[0]?.total || 0,
        tierDistribution
      }
    });

  } catch (error) {
    console.error('Error fetching loyalty stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch loyalty statistics',
      error: error.message
    });
  }
});

// Admin: Get all loyalty members (REAL FIREBASE USERS - NO MOCK DATA)
router.get('/admin/members', protect, async (req, res) => {
  try {
    const User = require('../models/User');
    
    // Get all active users with Firebase accounts
    const users = await User.find({ 
      firebaseUid: { $exists: true, $ne: null },
      isActive: true 
    })
    .select('name email firebaseUid loyaltyProgram statistics avatar createdAt lastLogin')
    .sort({ 'statistics.totalSpent': -1 })
    .lean();
    
    // Get loyalty accounts for each user
    const membersWithLoyalty = await Promise.all(
      users.map(async (user) => {
        const loyaltyAccount = await LoyaltyAccount.findOne({ 
          userId: user.firebaseUid 
        }).lean();
        
        // Get recent transactions
        const recentTransactions = await LoyaltyPoint.find({ 
          userId: user.firebaseUid 
        })
        .sort({ createdAt: -1 })
        .limit(5)
        .lean();
        
        return {
          _id: user._id,
          userId: user.firebaseUid, // Firebase UID
          userEmail: user.email,
          userName: user.name,
          avatar: user.avatar,
          currentBalance: loyaltyAccount?.currentBalance || 0,
          totalEarned: loyaltyAccount?.totalPointsEarned || 0,
          totalSpent: loyaltyAccount?.totalPointsSpent || 0,
          currentTier: loyaltyAccount?.currentTier || 'Bronze',
          tierProgress: loyaltyAccount?.tierProgress || 0,
          totalPurchases: loyaltyAccount?.totalPurchases || user.statistics?.totalOrders || 0,
          totalReferrals: loyaltyAccount?.totalReferrals || 0,
          totalSpentMoney: user.statistics?.totalSpent || 0,
          joinedAt: loyaltyAccount?.joinedAt || user.createdAt,
          lastActivity: loyaltyAccount?.lastActivity || user.lastLogin,
          qrCode: user.loyaltyProgram?.qrCode || null, // PERMANENT QR CODE
          recentTransactions
        };
      })
    );
    
    res.json({
      success: true,
      data: {
        members: membersWithLoyalty,
        total: membersWithLoyalty.length
      }
    });
    
  } catch (error) {
    console.error('Error fetching loyalty members:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch loyalty members',
      error: error.message
    });
  }
});

// Helper functions
function formatRelativeDate(date) {
  const now = new Date();
  const diffTime = Math.abs(now - date);
  const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
  
  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return '1 day ago';
  if (diffDays < 7) return `${diffDays} days ago`;
  if (diffDays < 14) return '1 week ago';
  if (diffDays < 30) return `${Math.floor(diffDays / 7)} weeks ago`;
  if (diffDays < 60) return '1 month ago';
  return `${Math.floor(diffDays / 30)} months ago`;
}

function getRewardDescription(rewardId) {
  const rewards = {
    'free_coffee_250g': 'Free 250g Coffee',
    'discount_10_percent': '10% Off Next Purchase',
    'free_shipping': 'Free Shipping',
    'premium_tasting_set': 'Premium Tasting Set',
    'coffee_masterclass': 'Coffee Brewing Masterclass'
  };
  return rewards[rewardId] || 'Unknown Reward';
}

function generateRedemptionCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = '';
  for (let i = 0; i < 8; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return `RWD-${result}`;
}

module.exports = router;
