const express = require('express');
const { body, param, query } = require('express-validator');
const {
  // User Analytics
  trackUserEvent,
  getUserActivity,
  getUserJourney,
  
  // Product Analytics
  getProductPerformance,
  getPopularProducts,
  getTopPerformers,
  getConversionFunnel,
  
  // Admin Analytics
  getDashboardOverview,
  getUserAnalyticsReport,
  getProductAnalyticsReport
} = require('../controllers/analyticsController');
const { protect } = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth');

const router = express.Router();

// Validation rules
const trackEventValidation = [
  body('sessionId')
    .isString()
    .isLength({ min: 1 })
    .withMessage('Session ID is required'),
  body('eventType')
    .isIn([
      'page_view',
      'product_view',
      'product_search',
      'add_to_cart',
      'remove_from_cart',
      'checkout_started',
      'checkout_completed',
      'order_placed',
      'user_registration',
      'user_login',
      'user_logout',
      'review_submitted',
      'wishlist_add',
      'wishlist_remove',
      'category_browse',
      'app_launch',
      'app_background',
      'push_notification_opened',
      'email_opened',
      'coupon_used',
      'social_share',
      'support_contact',
      'profile_updated'
    ])
    .withMessage('Invalid event type'),
  body('eventData')
    .optional()
    .isObject()
    .withMessage('Event data must be an object'),
  body('deviceType')
    .optional()
    .isIn(['mobile', 'tablet', 'desktop', 'unknown'])
    .withMessage('Invalid device type'),
  body('platform')
    .optional()
    .isIn(['ios', 'android', 'web', 'unknown'])
    .withMessage('Invalid platform'),
  body('appVersion')
    .optional()
    .isString()
    .withMessage('App version must be a string')
];

const productIdValidation = [
  param('productId')
    .isMongoId()
    .withMessage('Valid product ID is required')
];

// Public routes
router.get('/products/popular', getPopularProducts);
router.get('/products/top-performers', getTopPerformers);
router.get('/conversion-funnel', getConversionFunnel);
router.get('/product/:productId', productIdValidation, getProductPerformance);

// Protected routes (require authentication)
router.post('/track', protect, trackEventValidation, trackUserEvent);
router.get('/user/activity', protect, getUserActivity);
router.get('/user/journey', protect, getUserJourney);

// Admin routes (require authentication + admin role)
router.get('/admin/dashboard', protect, adminAuth, getDashboardOverview);
router.get('/admin/users', protect, adminAuth, getUserAnalyticsReport);
router.get('/admin/products', protect, adminAuth, getProductAnalyticsReport);

module.exports = router;
