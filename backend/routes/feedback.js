const express = require('express');
const { body, param } = require('express-validator');
const {
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
} = require('../controllers/feedbackController');
const { protect } = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth');

const router = express.Router();

// Validation rules
const createFeedbackValidation = [
  body('productId')
    .isMongoId()
    .withMessage('Valid product ID is required'),
  body('rating')
    .isInt({ min: 1, max: 5 })
    .withMessage('Rating must be between 1 and 5'),
  body('title')
    .trim()
    .isLength({ min: 5, max: 100 })
    .withMessage('Title must be between 5 and 100 characters'),
  body('comment')
    .trim()
    .isLength({ min: 10, max: 1000 })
    .withMessage('Comment must be between 10 and 1000 characters'),
  body('orderId')
    .optional()
    .isMongoId()
    .withMessage('Valid order ID is required'),
  body('pros')
    .optional()
    .isArray()
    .withMessage('Pros must be an array'),
  body('cons')
    .optional()
    .isArray()
    .withMessage('Cons must be an array'),
  body('images')
    .optional()
    .isArray()
    .withMessage('Images must be an array'),
  body('brewingMethod')
    .optional()
    .isIn(['Drip', 'Pour Over', 'French Press', 'Espresso', 'Cold Brew', 'Turkish', 'Other'])
    .withMessage('Invalid brewing method'),
  body('wouldRecommend')
    .optional()
    .isBoolean()
    .withMessage('Would recommend must be a boolean')
];

const updateFeedbackValidation = [
  param('id')
    .isMongoId()
    .withMessage('Valid feedback ID is required'),
  body('rating')
    .optional()
    .isInt({ min: 1, max: 5 })
    .withMessage('Rating must be between 1 and 5'),
  body('title')
    .optional()
    .trim()
    .isLength({ min: 5, max: 100 })
    .withMessage('Title must be between 5 and 100 characters'),
  body('comment')
    .optional()
    .trim()
    .isLength({ min: 10, max: 1000 })
    .withMessage('Comment must be between 10 and 1000 characters')
];

const voteValidation = [
  param('id')
    .isMongoId()
    .withMessage('Valid feedback ID is required'),
  body('isHelpful')
    .isBoolean()
    .withMessage('isHelpful must be a boolean')
];

const moderateValidation = [
  param('id')
    .isMongoId()
    .withMessage('Valid feedback ID is required'),
  body('action')
    .isIn(['approve', 'hide'])
    .withMessage('Action must be approve or hide'),
  body('moderationNotes')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Moderation notes cannot exceed 500 characters')
];

// Public routes
router.get('/product/:productId', getProductFeedback);
router.get('/top-rated', getTopRatedProducts);

// Protected routes (require authentication)
router.use(protect);

router.post('/', createFeedbackValidation, createFeedback);
router.get('/user', getUserFeedback);
router.put('/:id', updateFeedbackValidation, updateFeedback);
router.delete('/:id', deleteFeedback);
router.post('/:id/vote', voteValidation, voteFeedback);

// Admin routes
router.get('/admin/all', adminAuth, getAllFeedback);
router.put('/admin/:id/moderate', adminAuth, moderateValidation, moderateFeedback);

module.exports = router;
