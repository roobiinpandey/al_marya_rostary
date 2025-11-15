const express = require('express');
const router = express.Router();
const { Referral, ReferralCode } = require('../models/Referral');
const { body, validationResult, param, query } = require('express-validator');
const { protect } = require('../middleware/auth');

// Get user's referral information
router.get('/user/:userId', [
  param('userId').notEmpty().withMessage('User ID is required')
], async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Get or create referral code
    const userEmail = req.user?.email || req.query.email;
    const userName = req.user?.displayName || req.query.name;
    
    if (!userEmail || !userName) {
      return res.status(400).json({
        success: false,
        message: 'User email and name are required'
      });
    }
    
    let referralCode = await ReferralCode.findOne({ userId });
    if (!referralCode) {
      const code = await Referral.generateUniqueCode(userEmail);
      referralCode = new ReferralCode({
        userId,
        userEmail,
        code
      });
      await referralCode.save();
    }
    
    // Get referral statistics
    const stats = await Referral.getReferralStats(userId);
    
    // Get recent referrals
    const referrals = await Referral.find({ referrerUserId: userId })
      .sort({ createdAt: -1 })
      .limit(10)
      .lean();
    
    // Calculate total points earned
    const completedReferrals = referrals.filter(r => r.status === 'completed');
    const totalPointsEarned = completedReferrals.length * 500; // 500 points per referral
    
    const referralsWithDates = referrals.map(referral => ({
      ...referral,
      formattedDate: formatRelativeDate(referral.createdAt)
    }));
    
    res.json({
      success: true,
      data: {
        referralCode: referralCode.code,
        stats: {
          total: stats.total,
          pending: stats.pending,
          completed: stats.completed,
          pointsEarned: totalPointsEarned
        },
        referrals: referralsWithDates,
        program: {
          referrerReward: {
            points: 500,
            description: 'Earn 500 points for each successful referral'
          },
          refereeReward: {
            discount: 10,
            type: 'fixed',
            description: 'Your friend gets $10 off their first order'
          }
        }
      }
    });

  } catch (error) {
    console.error('Error fetching referral info:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch referral information',
      error: error.message
    });
  }
});

// Create a new referral
router.post('/create', [
  body('referrerUserId').notEmpty().withMessage('Referrer user ID is required'),
  body('referrerEmail').isEmail().withMessage('Valid referrer email is required'),
  body('referrerName').notEmpty().withMessage('Referrer name is required'),
  body('refereeEmail').isEmail().withMessage('Valid referee email is required')
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

    const { referrerUserId, referrerEmail, referrerName, refereeEmail } = req.body;
    
    // Check if referee is not the same as referrer
    if (referrerEmail.toLowerCase() === refereeEmail.toLowerCase()) {
      return res.status(400).json({
        success: false,
        message: 'You cannot refer yourself'
      });
    }
    
    // Create referral
    const referral = await Referral.createReferral(
      referrerUserId,
      referrerEmail,
      referrerName,
      refereeEmail
    );
    
    res.status(201).json({
      success: true,
      message: 'Referral created successfully',
      data: {
        referralId: referral._id,
        referralCode: referral.referralCode,
        refereeEmail: referral.refereeEmail,
        status: referral.status,
        refereeReward: referral.refereeReward
      }
    });

  } catch (error) {
    console.error('Error creating referral:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create referral',
      error: error.message
    });
  }
});

// Track referral click
router.post('/click/:referralCode', [
  param('referralCode').notEmpty().withMessage('Referral code is required')
], async (req, res) => {
  try {
    const { referralCode } = req.params;
    
    const referral = await Referral.findOne({ 
      referralCode: referralCode.toUpperCase(),
      status: { $in: ['pending', 'registered'] },
      expiresAt: { $gt: new Date() }
    });
    
    if (!referral) {
      return res.status(404).json({
        success: false,
        message: 'Referral code not found or expired'
      });
    }
    
    // Track the click
    await referral.trackClick();
    
    res.json({
      success: true,
      message: 'Referral click tracked',
      data: {
        referralCode: referral.referralCode,
        referrerName: referral.referrerName,
        discount: referral.refereeReward.discount
      }
    });

  } catch (error) {
    console.error('Error tracking referral click:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to track referral click',
      error: error.message
    });
  }
});

// Register a referee (when they sign up)
router.post('/register', [
  body('referralCode').notEmpty().withMessage('Referral code is required'),
  body('refereeUserId').notEmpty().withMessage('Referee user ID is required'),
  body('refereeName').notEmpty().withMessage('Referee name is required'),
  body('refereeEmail').isEmail().withMessage('Valid referee email is required')
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

    const { referralCode, refereeUserId, refereeName, refereeEmail } = req.body;
    
    const referral = await Referral.findOne({ 
      referralCode: referralCode.toUpperCase(),
      refereeEmail: refereeEmail.toLowerCase(),
      status: 'pending'
    });
    
    if (!referral) {
      return res.status(404).json({
        success: false,
        message: 'Referral not found or already used'
      });
    }
    
    // Mark as registered
    await referral.markRegistered(refereeUserId, refereeName);
    
    res.json({
      success: true,
      message: 'Referral registered successfully',
      data: {
        discount: referral.refereeReward.discount,
        referrerName: referral.referrerName
      }
    });

  } catch (error) {
    console.error('Error registering referral:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to register referral',
      error: error.message
    });
  }
});

// Complete a referral (when referee makes first purchase)
router.post('/complete', [
  body('refereeUserId').notEmpty().withMessage('Referee user ID is required'),
  body('orderNumber').notEmpty().withMessage('Order number is required')
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

    const { refereeUserId, orderNumber } = req.body;
    
    const referral = await Referral.findOne({ 
      refereeUserId,
      status: 'registered'
    });
    
    if (!referral) {
      return res.status(404).json({
        success: false,
        message: 'Referral not found'
      });
    }
    
    // Mark as completed and award points
    await referral.markCompleted(orderNumber);
    
    res.json({
      success: true,
      message: 'Referral completed successfully',
      data: {
        referralId: referral._id,
        pointsAwarded: referral.referrerReward.points,
        referrerUserId: referral.referrerUserId
      }
    });

  } catch (error) {
    console.error('Error completing referral:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to complete referral',
      error: error.message
    });
  }
});

// Validate referral code for checkout
router.get('/validate/:referralCode', [
  param('referralCode').notEmpty().withMessage('Referral code is required'),
  query('userEmail').isEmail().withMessage('Valid user email is required')
], async (req, res) => {
  try {
    const { referralCode } = req.params;
    const { userEmail } = req.query;
    
    const referral = await Referral.findOne({ 
      referralCode: referralCode.toUpperCase(),
      refereeEmail: userEmail.toLowerCase(),
      status: { $in: ['pending', 'registered'] },
      expiresAt: { $gt: new Date() }
    }).lean();
    
    if (!referral) {
      return res.status(404).json({
        success: false,
        message: 'Invalid or expired referral code'
      });
    }
    
    res.json({
      success: true,
      message: 'Referral code is valid',
      data: {
        discount: referral.refereeReward.discount,
        discountType: referral.refereeReward.type,
        referrerName: referral.referrerName,
        canUse: !referral.refereeReward.used
      }
    });

  } catch (error) {
    console.error('Error validating referral code:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to validate referral code',
      error: error.message
    });
  }
});

// Get referral program details
router.get('/program', async (req, res) => {
  try {
    res.json({
      success: true,
      data: {
        title: 'Give $10, Get 500 Points',
        description: 'Refer friends and earn rewards for both of you!',
        referrerReward: {
          points: 500,
          description: 'You earn 500 points for each successful referral'
        },
        refereeReward: {
          discount: 10,
          type: 'fixed',
          currency: 'AED',
          description: 'Your friend gets $10 off their first order'
        },
        howItWorks: [
          {
            step: 1,
            title: 'Share Your Code',
            description: 'Send your unique referral code to friends'
          },
          {
            step: 2,
            title: 'Friend Orders',
            description: 'They use your code and get $10 off their first order'
          },
          {
            step: 3,
            title: 'You Earn Points',
            description: 'Get 500 reward points for each successful referral'
          }
        ],
        terms: [
          'Referral code expires after 30 days',
          'Discount applies to first order only',
          'Points awarded after successful purchase',
          'Cannot refer yourself',
          'One referral per email address'
        ]
      }
    });

  } catch (error) {
    console.error('Error fetching program details:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch program details',
      error: error.message
    });
  }
});

// Admin: Get referral statistics
router.get('/admin/stats', protect, async (req, res) => {
  try {
    const totalReferrals = await Referral.countDocuments();
    const completedReferrals = await Referral.countDocuments({ status: 'completed' });
    const pendingReferrals = await Referral.countDocuments({ status: 'pending' });
    const registeredReferrals = await Referral.countDocuments({ status: 'registered' });
    
    const conversionRate = totalReferrals > 0 ? (completedReferrals / totalReferrals) * 100 : 0;
    
    // Top referrers
    const topReferrers = await Referral.aggregate([
      { $match: { status: 'completed' } },
      {
        $group: {
          _id: '$referrerUserId',
          referrerName: { $first: '$referrerName' },
          referrerEmail: { $first: '$referrerEmail' },
          totalReferrals: { $sum: 1 },
          totalPointsEarned: { $sum: '$referrerReward.points' }
        }
      },
      { $sort: { totalReferrals: -1 } },
      { $limit: 10 }
    ]);
    
    res.json({
      success: true,
      data: {
        totalReferrals,
        completedReferrals,
        pendingReferrals,
        registeredReferrals,
        conversionRate: Math.round(conversionRate * 100) / 100,
        topReferrer: topReferrers.length > 0 ? topReferrers[0].referrerName : '-',
        topReferrers
      }
    });

  } catch (error) {
    console.error('Error fetching referral stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch referral statistics',
      error: error.message
    });
  }
});

// Admin: Get all referrals with user data
router.get('/admin/list', protect, async (req, res) => {
  try {
    const User = require('../models/User');
    
    // Fetch all referrals with populated data
    const referrals = await Referral.find()
      .sort({ createdAt: -1 })
      .lean();
    
    // Get unique user IDs (both referrers and referees)
    const userIds = new Set();
    referrals.forEach(ref => {
      if (ref.referrerUserId) userIds.add(ref.referrerUserId);
      if (ref.refereeUserId) userIds.add(ref.refereeUserId);
    });
    
    // Fetch all users in one query
    const users = await User.find({
      firebaseUid: { $in: Array.from(userIds) }
    }).lean();
    
    const usersMap = {};
    users.forEach(user => {
      usersMap[user.firebaseUid] = user;
    });
    
    // Enrich referrals with user data
    const enrichedReferrals = referrals.map(referral => {
      const referrer = usersMap[referral.referrerUserId];
      const referee = usersMap[referral.refereeUserId];
      
      return {
        _id: referral._id,
        referrerName: referrer?.name || referral.referrerName || 'Unknown',
        referrerEmail: referrer?.email || referral.referrerEmail || 'Unknown',
        referrerUserId: referral.referrerUserId,
        refereeName: referee?.name || referral.refereeName || null,
        refereeEmail: referral.refereeEmail,
        refereeUserId: referral.refereeUserId,
        referralCode: referral.referralCode,
        status: referral.status,
        createdAt: referral.createdAt,
        registeredAt: referral.registeredAt,
        completedAt: referral.completedAt,
        clickCount: referral.clickCount,
        referrerReward: referral.referrerReward,
        refereeReward: referral.refereeReward,
        campaign: referral.campaign,
        source: referral.source
      };
    });
    
    res.json({
      success: true,
      data: {
        referrals: enrichedReferrals,
        total: enrichedReferrals.length
      }
    });

  } catch (error) {
    console.error('Error fetching referrals list:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch referrals list',
      error: error.message
    });
  }
});

// Helper function
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

module.exports = router;
