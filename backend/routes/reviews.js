/**
 * ⚠️ DEPRECATION NOTICE ⚠️
 * 
 * This route is DEPRECATED and will be removed in a future version.
 * 
 * The Review model has been merged with UserFeedback model for consistency.
 * All review functionality now uses /api/feedback endpoints.
 * 
 * Migration Status:
 * - ✅ Admin panel updated to use /api/feedback
 * - ✅ Migration script created: backend/scripts/migrate-reviews-to-feedback.js
 * - ⚠️ This route kept for backward compatibility only
 * 
 * Please update your code to use /api/feedback instead:
 * - GET /api/feedback/product/:productId (was /api/reviews/product/:productId)
 * - POST /api/feedback (was /api/reviews)
 * - GET /api/feedback/admin/all (was /api/reviews/admin/list)
 * - GET /api/feedback/stats (was /api/reviews/admin/stats)
 * - PUT /api/feedback/admin/:id/moderate (was /api/reviews/:id/approve or /api/reviews/:id/reject)
 * 
 * Date: November 3, 2025
 */

const express = require('express');
const router = express.Router();
const Review = require('../models/Review');
const { body, validationResult, param, query } = require('express-validator');
const { protect } = require('../middleware/auth');

// Deprecation warning middleware
const deprecationWarning = (req, res, next) => {
  console.warn(`⚠️  DEPRECATION WARNING: ${req.method} ${req.originalUrl} is deprecated. Use /api/feedback instead.`);
  res.setHeader('X-API-Deprecated', 'true');
  res.setHeader('X-API-Deprecation-Info', 'Use /api/feedback endpoints instead. See route comments for details.');
  next();
};

// Apply deprecation warning to all routes
router.use(deprecationWarning);

// Validation middleware
const validateReview = [
  body('productId').notEmpty().withMessage('Product ID is required'),
  body('productName').notEmpty().withMessage('Product name is required'),
  body('rating').isInt({ min: 1, max: 5 }).withMessage('Rating must be between 1 and 5'),
  body('comment').isLength({ min: 10, max: 500 }).withMessage('Comment must be between 10 and 500 characters'),
  body('title').optional().isLength({ max: 100 }).withMessage('Title must be less than 100 characters')
];

// Get reviews for a product
router.get('/product/:productId', [
  param('productId').notEmpty().withMessage('Product ID is required'),
  query('sort').optional().isIn(['newest', 'oldest', 'highest', 'lowest', 'helpful'])
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

    const { productId } = req.params;
    const { sort = 'newest', page = 1, limit = 10 } = req.query;

    // Build sort criteria
    let sortCriteria = {};
    switch (sort) {
      case 'newest':
        sortCriteria = { createdAt: -1 };
        break;
      case 'oldest':
        sortCriteria = { createdAt: 1 };
        break;
      case 'highest':
        sortCriteria = { rating: -1, createdAt: -1 };
        break;
      case 'lowest':
        sortCriteria = { rating: 1, createdAt: -1 };
        break;
      case 'helpful':
        sortCriteria = { helpfulCount: -1, createdAt: -1 };
        break;
      default:
        sortCriteria = { createdAt: -1 };
    }

    // Get reviews
    const reviews = await Review.find({
      productId,
      status: 'approved'
    })
    .sort(sortCriteria)
    .limit(limit * 1)
    .skip((page - 1) * limit)
    .lean();

    // Get total count
    const total = await Review.countDocuments({
      productId,
      status: 'approved'
    });

    // Get product rating summary
    const ratingSummary = await Review.getProductAverageRating(productId);

    // Add formatted dates to reviews
    const reviewsWithDates = reviews.map(review => ({
      ...review,
      formattedDate: formatRelativeDate(review.createdAt)
    }));

    res.json({
      success: true,
      data: {
        reviews: reviewsWithDates,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          totalReviews: total,
          hasMore: page * limit < total
        },
        ratingSummary
      }
    });

  } catch (error) {
    console.error('Error fetching reviews:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch reviews',
      error: error.message
    });
  }
});

// Get review statistics for a product
router.get('/product/:productId/stats', [
  param('productId').notEmpty().withMessage('Product ID is required')
], async (req, res) => {
  try {
    const { productId } = req.params;
    const stats = await Review.getProductAverageRating(productId);
    
    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Error fetching review stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch review statistics',
      error: error.message
    });
  }
});

// Create a new review
router.post('/', validateReview, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const { productId, productName, rating, comment, title } = req.body;
    const userId = req.user?.uid || req.body.userId;
    const userName = req.user?.displayName || req.body.userName;
    const userEmail = req.user?.email || req.body.userEmail;

    if (!userId || !userName || !userEmail) {
      return res.status(401).json({
        success: false,
        message: 'User authentication required'
      });
    }

    // Check if user already reviewed this product
    const existingReview = await Review.getUserReviewForProduct(userId, productId);
    if (existingReview) {
      return res.status(400).json({
        success: false,
        message: 'You have already reviewed this product'
      });
    }

    // Create review
    const review = new Review({
      productId,
      productName,
      userId,
      userName,
      userEmail,
      rating,
      comment,
      title: title || `Review for ${productName}`,
      status: 'pending' // Reviews need moderation
    });

    await review.save();

    // Award loyalty points for writing a review
    try {
      const { LoyaltyAccount } = require('../models/Loyalty');
      const loyaltyAccount = await LoyaltyAccount.getOrCreateAccount(userId, userEmail);
      await loyaltyAccount.addPoints(50, 'earned_review', `Review for ${productName}`, {
        relatedProductId: productId
      });
    } catch (loyaltyError) {
      console.error('Error awarding loyalty points:', loyaltyError);
    }

    res.status(201).json({
      success: true,
      message: 'Review submitted successfully. It will be published after moderation.',
      data: {
        reviewId: review._id,
        status: 'pending'
      }
    });

  } catch (error) {
    console.error('Error creating review:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create review',
      error: error.message
    });
  }
});

// Mark review as helpful
router.post('/:reviewId/helpful', [
  param('reviewId').isMongoId().withMessage('Invalid review ID'),
  body('helpful').isBoolean().withMessage('Helpful must be true or false')
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

    const { reviewId } = req.params;
    const { helpful } = req.body;
    const userId = req.user?.uid || req.body.userId;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User authentication required'
      });
    }

    const review = await Review.findById(reviewId);
    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found'
      });
    }

    await review.markHelpful(userId, helpful);

    res.json({
      success: true,
      message: helpful ? 'Review marked as helpful' : 'Review marked as not helpful',
      data: {
        helpfulCount: review.helpfulCount
      }
    });

  } catch (error) {
    console.error('Error marking review helpful:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update review',
      error: error.message
    });
  }
});

// Get user's reviews
router.get('/user/:userId', [
  param('userId').notEmpty().withMessage('User ID is required')
], async (req, res) => {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 10 } = req.query;

    const reviews = await Review.find({ userId })
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .lean();

    const total = await Review.countDocuments({ userId });

    const reviewsWithDates = reviews.map(review => ({
      ...review,
      formattedDate: formatRelativeDate(review.createdAt)
    }));

    res.json({
      success: true,
      data: {
        reviews: reviewsWithDates,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          totalReviews: total
        }
      }
    });

  } catch (error) {
    console.error('Error fetching user reviews:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user reviews',
      error: error.message
    });
  }
});

// Admin routes
router.get('/admin/pending', protect, async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;

    const reviews = await Review.find({ status: 'pending' })
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .lean(); // Convert to plain JavaScript objects

    const total = await Review.countDocuments({ status: 'pending' });

    res.json({
      success: true,
      data: {
        reviews,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          totalReviews: total
        }
      }
    });

  } catch (error) {
    console.error('Error fetching pending reviews:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch pending reviews',
      error: error.message
    });
  }
});

// Approve/reject review (admin only)
router.patch('/admin/:reviewId/moderate', [
  param('reviewId').isMongoId().withMessage('Invalid review ID'),
  body('action').isIn(['approve', 'reject']).withMessage('Action must be approve or reject'),
  body('notes').optional().isString()
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

    const { reviewId } = req.params;
    const { action, notes } = req.body;
    const moderatorId = req.user?.uid || 'admin';

    const review = await Review.findById(reviewId);
    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found'
      });
    }

    if (action === 'approve') {
      await review.approve(moderatorId, notes);
    } else {
      await review.reject(moderatorId, notes);
    }

    res.json({
      success: true,
      message: `Review ${action}d successfully`,
      data: {
        reviewId: review._id,
        status: review.status
      }
    });

  } catch (error) {
    console.error('Error moderating review:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to moderate review',
      error: error.message
    });
  }
});

// Admin: Get review statistics
router.get('/admin/stats', protect, async (req, res) => {
  try {
    const totalReviews = await Review.countDocuments();
    const pendingReviews = await Review.countDocuments({ status: 'pending' });
    const approvedReviews = await Review.countDocuments({ status: 'approved' });
    const rejectedReviews = await Review.countDocuments({ status: 'rejected' });
    const flaggedReviews = await Review.countDocuments({ status: 'flagged' });
    
    // Calculate average rating
    const ratingResult = await Review.aggregate([
      { $match: { status: 'approved' } },
      {
        $group: {
          _id: null,
          averageRating: { $avg: '$rating' }
        }
      }
    ]);
    
    const averageRating = ratingResult.length > 0 ? ratingResult[0].averageRating : 0;
    
    res.json({
      success: true,
      data: {
        total: totalReviews,
        pending: pendingReviews,
        approved: approvedReviews,
        rejected: rejectedReviews,
        flagged: flaggedReviews,
        averageRating: Math.round(averageRating * 10) / 10
      }
    });

  } catch (error) {
    console.error('Error fetching review stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch review statistics',
      error: error.message
    });
  }
});

// Admin: Get all reviews with user data
router.get('/admin/list', protect, async (req, res) => {
  try {
    const User = require('../models/User');
    const { status, page = 1, limit = 50 } = req.query;
    
    // Build query
    const query = {};
    if (status) {
      query.status = status;
    }
    
    // Fetch reviews
    const reviews = await Review.find(query)
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .lean();
    
    // Get unique user IDs
    const userIds = [...new Set(reviews.map(r => r.userId))];
    
    // Fetch all users in one query
    const users = await User.find({
      firebaseUid: { $in: userIds }
    }).lean();
    
    const usersMap = {};
    users.forEach(user => {
      usersMap[user.firebaseUid] = user;
    });
    
    // Enrich reviews with user data
    const enrichedReviews = reviews.map(review => {
      const user = usersMap[review.userId];
      
      return {
        _id: review._id,
        productId: review.productId,
        productName: review.productName,
        userId: review.userId,
        userName: user?.name || review.userName || 'Unknown',
        userEmail: user?.email || review.userEmail || 'Unknown',
        rating: review.rating,
        title: review.title,
        comment: review.comment,
        status: review.status,
        helpfulCount: review.helpfulCount,
        isVerifiedPurchase: review.isVerifiedPurchase,
        orderNumber: review.orderNumber,
        createdAt: review.createdAt,
        updatedAt: review.updatedAt,
        moderationNotes: review.moderationNotes,
        moderatedBy: review.moderatedBy,
        moderatedAt: review.moderatedAt
      };
    });
    
    // Get total count
    const total = await Review.countDocuments(query);
    
    res.json({
      success: true,
      data: {
        reviews: enrichedReviews,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          total
        }
      }
    });

  } catch (error) {
    console.error('Error fetching reviews list:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch reviews list',
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
