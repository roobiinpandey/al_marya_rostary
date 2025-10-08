const UserFeedback = require('../models/UserFeedback');
const Coffee = require('../models/Coffee');
const Order = require('../models/Order');
const { logAdminAction } = require('../utils/auditLogger');
const mongoose = require('mongoose');

// @desc    Create new feedback/review
// @route   POST /api/feedback
// @access  Private
const createFeedback = async (req, res) => {
  try {
    const {
      productId,
      orderId,
      rating,
      title,
      comment,
      pros,
      cons,
      images,
      brewingMethod,
      flavorProfile,
      wouldRecommend
    } = req.body;

    // Validate product exists
    const product = await Coffee.findById(productId);
    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    // Check if user already reviewed this product
    const existingFeedback = await UserFeedback.findOne({
      user: req.user.userId,
      product: productId
    });

    if (existingFeedback) {
      return res.status(400).json({
        success: false,
        message: 'You have already reviewed this product'
      });
    }

    // Verify order if provided
    let isVerifiedPurchase = false;
    if (orderId) {
      const order = await Order.findOne({
        _id: orderId,
        user: req.user.userId,
        'items.coffee': productId
      });
      isVerifiedPurchase = !!order;
    }

    const feedback = new UserFeedback({
      user: req.user.userId,
      product: productId,
      order: orderId || null,
      rating,
      title,
      comment,
      pros: pros || [],
      cons: cons || [],
      images: images || [],
      brewingMethod,
      flavorProfile,
      wouldRecommend: wouldRecommend !== undefined ? wouldRecommend : true,
      isVerifiedPurchase
    });

    await feedback.save();

    // Populate user data for response
    await feedback.populate('user', 'name avatar');
    await feedback.populate('product', 'name image price');

    res.status(201).json({
      success: true,
      message: 'Review submitted successfully',
      data: feedback
    });
  } catch (error) {
    console.error('Create feedback error:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating feedback',
      error: error.message
    });
  }
};

// @desc    Get feedback for a product
// @route   GET /api/feedback/product/:productId
// @access  Public
const getProductFeedback = async (req, res) => {
  try {
    const { productId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const sortBy = req.query.sortBy || 'createdAt';
    const sortOrder = req.query.sortOrder === 'asc' ? 1 : -1;
    const rating = req.query.rating ? parseInt(req.query.rating) : null;
    const verifiedOnly = req.query.verifiedOnly === 'true';

    const skip = (page - 1) * limit;

    // Build filter query
    const filter = {
      product: productId,
      isApproved: true,
      isHidden: false
    };

    if (rating) {
      filter.rating = rating;
    }

    if (verifiedOnly) {
      filter.isVerifiedPurchase = true;
    }

    const feedback = await UserFeedback.find(filter)
      .populate('user', 'name avatar')
      .sort({ [sortBy]: sortOrder })
      .skip(skip)
      .limit(limit);

    const total = await UserFeedback.countDocuments(filter);

    // Get rating summary
    const ratingSummary = await UserFeedback.getProductRatingSummary(productId);

    res.json({
      success: true,
      data: {
        feedback,
        ratingSummary,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get product feedback error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching product feedback',
      error: error.message
    });
  }
};

// @desc    Get user's feedback
// @route   GET /api/feedback/user
// @access  Private
const getUserFeedback = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const feedback = await UserFeedback.find({ user: req.user.userId })
      .populate('product', 'name image price')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await UserFeedback.countDocuments({ user: req.user.userId });

    res.json({
      success: true,
      data: {
        feedback,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get user feedback error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user feedback',
      error: error.message
    });
  }
};

// @desc    Update feedback
// @route   PUT /api/feedback/:id
// @access  Private
const updateFeedback = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      rating,
      title,
      comment,
      pros,
      cons,
      images,
      brewingMethod,
      flavorProfile,
      wouldRecommend
    } = req.body;

    const feedback = await UserFeedback.findOne({
      _id: id,
      user: req.user.userId
    });

    if (!feedback) {
      return res.status(404).json({
        success: false,
        message: 'Feedback not found or not authorized'
      });
    }

    // Update fields
    if (rating !== undefined) feedback.rating = rating;
    if (title) feedback.title = title;
    if (comment) feedback.comment = comment;
    if (pros) feedback.pros = pros;
    if (cons) feedback.cons = cons;
    if (images) feedback.images = images;
    if (brewingMethod) feedback.brewingMethod = brewingMethod;
    if (flavorProfile) feedback.flavorProfile = flavorProfile;
    if (wouldRecommend !== undefined) feedback.wouldRecommend = wouldRecommend;

    await feedback.save();
    await feedback.populate('user', 'name avatar');
    await feedback.populate('product', 'name image price');

    res.json({
      success: true,
      message: 'Review updated successfully',
      data: feedback
    });
  } catch (error) {
    console.error('Update feedback error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating feedback',
      error: error.message
    });
  }
};

// @desc    Delete feedback
// @route   DELETE /api/feedback/:id
// @access  Private
const deleteFeedback = async (req, res) => {
  try {
    const { id } = req.params;

    const feedback = await UserFeedback.findOne({
      _id: id,
      user: req.user.userId
    });

    if (!feedback) {
      return res.status(404).json({
        success: false,
        message: 'Feedback not found or not authorized'
      });
    }

    await feedback.deleteOne();

    res.json({
      success: true,
      message: 'Review deleted successfully'
    });
  } catch (error) {
    console.error('Delete feedback error:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting feedback',
      error: error.message
    });
  }
};

// @desc    Vote on feedback helpfulness
// @route   POST /api/feedback/:id/vote
// @access  Private
const voteFeedback = async (req, res) => {
  try {
    const { id } = req.params;
    const { isHelpful } = req.body;

    const feedback = await UserFeedback.findById(id);
    if (!feedback) {
      return res.status(404).json({
        success: false,
        message: 'Feedback not found'
      });
    }

    // Prevent users from voting on their own reviews
    if (feedback.user.toString() === req.user.userId) {
      return res.status(400).json({
        success: false,
        message: 'Cannot vote on your own review'
      });
    }

    await feedback.addVote(isHelpful);

    res.json({
      success: true,
      message: 'Vote recorded successfully',
      data: {
        helpfulVotes: feedback.helpfulVotes,
        totalVotes: feedback.totalVotes,
        helpfulnessRatio: feedback.helpfulnessRatio
      }
    });
  } catch (error) {
    console.error('Vote feedback error:', error);
    res.status(500).json({
      success: false,
      message: 'Error recording vote',
      error: error.message
    });
  }
};

// @desc    Get top-rated products
// @route   GET /api/feedback/top-rated
// @access  Public
const getTopRatedProducts = async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    const topRated = await UserFeedback.getTopRatedProducts(limit);

    res.json({
      success: true,
      data: topRated
    });
  } catch (error) {
    console.error('Get top rated products error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching top-rated products',
      error: error.message
    });
  }
};

// Admin Functions

// @desc    Get all feedback (admin)
// @route   GET /api/admin/feedback
// @access  Private/Admin
const getAllFeedback = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    const status = req.query.status; // 'pending', 'approved', 'hidden'
    const rating = req.query.rating ? parseInt(req.query.rating) : null;

    const filter = {};
    if (status === 'pending') {
      filter.isApproved = false;
    } else if (status === 'approved') {
      filter.isApproved = true;
      filter.isHidden = false;
    } else if (status === 'hidden') {
      filter.isHidden = true;
    }

    if (rating) {
      filter.rating = rating;
    }

    const feedback = await UserFeedback.find(filter)
      .populate('user', 'name email avatar')
      .populate('product', 'name image price')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await UserFeedback.countDocuments(filter);

    res.json({
      success: true,
      data: {
        feedback,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get all feedback error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching feedback',
      error: error.message
    });
  }
};

// @desc    Moderate feedback (approve/hide)
// @route   PUT /api/admin/feedback/:id/moderate
// @access  Private/Admin
const moderateFeedback = async (req, res) => {
  try {
    const { id } = req.params;
    const { action, moderationNotes } = req.body; // 'approve', 'hide'

    const feedback = await UserFeedback.findById(id);
    if (!feedback) {
      return res.status(404).json({
        success: false,
        message: 'Feedback not found'
      });
    }

    if (action === 'approve') {
      feedback.isApproved = true;
      feedback.isHidden = false;
    } else if (action === 'hide') {
      feedback.isHidden = true;
    }

    if (moderationNotes) {
      feedback.moderationNotes = moderationNotes;
    }

    await feedback.save();

    // Log admin action
    await logAdminAction(
      req.user.id,
      `FEEDBACK_${action.toUpperCase()}`,
      feedback.user,
      {
        feedbackId: feedback._id,
        productId: feedback.product,
        action,
        moderationNotes
      }
    );

    res.json({
      success: true,
      message: `Feedback ${action}d successfully`,
      data: feedback
    });
  } catch (error) {
    console.error('Moderate feedback error:', error);
    res.status(500).json({
      success: false,
      message: 'Error moderating feedback',
      error: error.message
    });
  }
};

module.exports = {
  createFeedback,
  getProductFeedback,
  getUserFeedback,
  updateFeedback,
  deleteFeedback,
  voteFeedback,
  getTopRatedProducts,
  // Admin functions
  getAllFeedback,
  moderateFeedback
};
