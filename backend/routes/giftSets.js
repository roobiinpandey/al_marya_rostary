const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const giftSetController = require('../controllers/giftSetController');
const { protect, authorize } = require('../middleware/auth');

// Validation middleware
const validateGiftSet = [
  body('name.en').notEmpty().withMessage('English name is required'),
  body('name.ar').notEmpty().withMessage('Arabic name is required'),
  body('description.en').notEmpty().withMessage('English description is required'),
  body('description.ar').notEmpty().withMessage('Arabic description is required'),
  body('occasion').isIn(['birthday', 'anniversary', 'wedding', 'corporate', 'holiday', 'thank-you', 'housewarming', 'graduation', 'general']).withMessage('Invalid occasion'),
  body('targetAudience').isIn(['beginner', 'enthusiast', 'professional', 'corporate', 'family', 'couple', 'individual']).withMessage('Invalid target audience'),
  body('price.regular').isFloat({ min: 0 }).withMessage('Regular price must be a positive number'),
  body('contents').isArray({ min: 1 }).withMessage('Gift set must contain at least one item')
];

const validateReview = [
  body('rating').isInt({ min: 1, max: 5 }).withMessage('Rating must be between 1 and 5'),
  body('comment').optional().isLength({ max: 500 }).withMessage('Comment cannot exceed 500 characters')
];

// Public routes
router.get('/', giftSetController.getAllGiftSets);
router.get('/occasion/:occasion', giftSetController.getGiftSetsByOccasion);
router.get('/audience/:audience', giftSetController.getGiftSetsByAudience);
router.get('/featured', giftSetController.getFeaturedGiftSets);
router.get('/popular', giftSetController.getPopularGiftSets);
router.get('/:id', giftSetController.getGiftSetById);

// User routes (require authentication)
router.post('/:id/review', protect, validateReview, giftSetController.addReview);

// Admin routes (require authentication and admin role)
router.post('/', protect, authorize('admin'), validateGiftSet, giftSetController.createGiftSet);
router.put('/:id', protect, authorize('admin'), validateGiftSet, giftSetController.updateGiftSet);
router.delete('/:id', protect, authorize('admin'), giftSetController.deleteGiftSet);
router.patch('/:id/toggle-status', protect, authorize('admin'), giftSetController.toggleGiftSetStatus);
router.patch('/:id/limited-quantity', protect, authorize('admin'), giftSetController.updateLimitedQuantity);
router.get('/admin/analytics', protect, authorize('admin'), giftSetController.getGiftSetAnalytics);

module.exports = router;
