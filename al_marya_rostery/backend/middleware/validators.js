/**
 * Input Validation Middleware
 * Comprehensive validation rules for all API endpoints
 * 
 * Usage:
 * const { validateOrder, validateReview } = require('../middleware/validators');
 * router.post('/orders', protect, validateOrder, createOrder);
 */

const { body, param, query, validationResult } = require('express-validator');
const logger = require('../utils/logger');

/**
 * Validation error handler middleware
 * Must be used after validation rules
 */
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    logger.warn('Validation failed', {
      endpoint: req.originalUrl,
      method: req.method,
      errors: errors.array(),
      userId: req.user?.userId
    });
    
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array().map(err => ({
        field: err.param,
        message: err.msg,
        value: err.value
      }))
    });
  }
  
  next();
};

// ============================================
// COMMON VALIDATORS
// ============================================

const validateMongoId = [
  param('id')
    .isMongoId()
    .withMessage('Invalid ID format')
];

const validatePagination = [
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100')
];

// ============================================
// USER & AUTH VALIDATORS
// ============================================

const validateRegistration = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ min: 2, max: 50 })
    .withMessage('Name must be between 2 and 50 characters'),
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Password must contain at least 1 uppercase, 1 lowercase, 1 number, and 1 special character'),
  body('phone')
    .optional()
    .isMobilePhone()
    .withMessage('Please provide a valid phone number')
];

const validateLogin = [
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
];

const validateProfileUpdate = [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Name must be between 2 and 50 characters'),
  body('phone')
    .optional()
    .isMobilePhone()
    .withMessage('Please provide a valid phone number'),
  body('email')
    .optional()
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email')
];

// ============================================
// ORDER VALIDATORS
// ============================================

const validateOrder = [
  body('items')
    .isArray({ min: 1 })
    .withMessage('Order must contain at least one item'),
  body('items.*.productId')
    .isMongoId()
    .withMessage('Invalid product ID'),
  body('items.*.quantity')
    .isInt({ min: 1, max: 100 })
    .withMessage('Quantity must be between 1 and 100'),
  body('items.*.price')
    .isFloat({ min: 0 })
    .withMessage('Price must be a positive number'),
  body('deliveryAddress')
    .trim()
    .notEmpty()
    .withMessage('Delivery address is required')
    .isLength({ min: 10, max: 500 })
    .withMessage('Address must be between 10 and 500 characters'),
  body('paymentMethod')
    .isIn(['cash', 'card', 'wallet', 'stripe'])
    .withMessage('Invalid payment method'),
  body('totalAmount')
    .isFloat({ min: 0 })
    .withMessage('Total amount must be a positive number')
];

const validateOrderStatus = [
  param('id').isMongoId().withMessage('Invalid order ID'),
  body('status')
    .isIn(['pending', 'confirmed', 'preparing', 'out-for-delivery', 'delivered', 'cancelled'])
    .withMessage('Invalid order status')
];

// ============================================
// PRODUCT VALIDATORS
// ============================================

const validateProduct = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Product name is required')
    .isLength({ min: 3, max: 100 })
    .withMessage('Name must be between 3 and 100 characters'),
  body('description')
    .trim()
    .notEmpty()
    .withMessage('Description is required')
    .isLength({ min: 10, max: 2000 })
    .withMessage('Description must be between 10 and 2000 characters'),
  body('price')
    .isFloat({ min: 0 })
    .withMessage('Price must be a positive number'),
  body('category')
    .isMongoId()
    .withMessage('Invalid category ID'),
  body('stock')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Stock must be a non-negative integer')
];

// ============================================
// REVIEW VALIDATORS
// ============================================

const validateReview = [
  body('rating')
    .isInt({ min: 1, max: 5 })
    .withMessage('Rating must be between 1 and 5'),
  body('comment')
    .trim()
    .notEmpty()
    .withMessage('Comment is required')
    .isLength({ min: 10, max: 500 })
    .withMessage('Comment must be between 10 and 500 characters'),
  body('productId')
    .optional()
    .isMongoId()
    .withMessage('Invalid product ID')
];

// ============================================
// SUBSCRIPTION VALIDATORS
// ============================================

const validateSubscription = [
  body('planId')
    .isMongoId()
    .withMessage('Invalid plan ID'),
  body('frequency')
    .isIn(['weekly', 'biweekly', 'monthly'])
    .withMessage('Invalid frequency'),
  body('deliveryDay')
    .optional()
    .isIn(['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'])
    .withMessage('Invalid delivery day'),
  body('deliveryAddress')
    .trim()
    .notEmpty()
    .withMessage('Delivery address is required')
    .isLength({ min: 10, max: 500 })
    .withMessage('Address must be between 10 and 500 characters')
];

const validateSubscriptionUpdate = [
  param('id').isMongoId().withMessage('Invalid subscription ID'),
  body('frequency')
    .optional()
    .isIn(['weekly', 'biweekly', 'monthly'])
    .withMessage('Invalid frequency'),
  body('deliveryDay')
    .optional()
    .isIn(['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'])
    .withMessage('Invalid delivery day'),
  body('status')
    .optional()
    .isIn(['active', 'paused', 'cancelled'])
    .withMessage('Invalid status')
];

// ============================================
// PAYMENT VALIDATORS
// ============================================

const validatePayment = [
  body('amount')
    .isFloat({ min: 0.01 })
    .withMessage('Amount must be greater than 0'),
  body('currency')
    .optional()
    .isIn(['usd', 'aed', 'sar'])
    .withMessage('Invalid currency'),
  body('orderId')
    .isMongoId()
    .withMessage('Invalid order ID'),
  body('paymentMethod')
    .isIn(['card', 'stripe', 'wallet'])
    .withMessage('Invalid payment method')
];

// ============================================
// GIFT SET VALIDATORS
// ============================================

const validateGiftSet = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Gift set name is required')
    .isLength({ min: 3, max: 100 })
    .withMessage('Name must be between 3 and 100 characters'),
  body('description')
    .trim()
    .notEmpty()
    .withMessage('Description is required')
    .isLength({ min: 10, max: 1000 })
    .withMessage('Description must be between 10 and 1000 characters'),
  body('price')
    .isFloat({ min: 0 })
    .withMessage('Price must be a positive number'),
  body('items')
    .isArray({ min: 1 })
    .withMessage('Gift set must contain at least one item'),
  body('items.*.productId')
    .isMongoId()
    .withMessage('Invalid product ID'),
  body('items.*.quantity')
    .isInt({ min: 1 })
    .withMessage('Quantity must be at least 1')
];

// ============================================
// CONTACT & SUPPORT VALIDATORS
// ============================================

const validateContactInquiry = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters'),
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('subject')
    .trim()
    .notEmpty()
    .withMessage('Subject is required')
    .isLength({ min: 5, max: 200 })
    .withMessage('Subject must be between 5 and 200 characters'),
  body('message')
    .trim()
    .notEmpty()
    .withMessage('Message is required')
    .isLength({ min: 20, max: 2000 })
    .withMessage('Message must be between 20 and 2000 characters')
];

const validateSupportTicket = [
  body('subject')
    .trim()
    .notEmpty()
    .withMessage('Subject is required')
    .isLength({ min: 5, max: 200 })
    .withMessage('Subject must be between 5 and 200 characters'),
  body('description')
    .trim()
    .notEmpty()
    .withMessage('Description is required')
    .isLength({ min: 20, max: 2000 })
    .withMessage('Description must be between 20 and 2000 characters'),
  body('priority')
    .optional()
    .isIn(['low', 'medium', 'high', 'urgent'])
    .withMessage('Invalid priority level')
];

// ============================================
// STAFF & DRIVER VALIDATORS
// ============================================

const validateStaffCreate = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters'),
  body('employeeId')
    .trim()
    .notEmpty()
    .withMessage('Employee ID is required')
    .matches(/^[A-Z0-9-]+$/)
    .withMessage('Employee ID must contain only uppercase letters, numbers, and hyphens'),
  body('pin')
    .matches(/^\d{4}$/)
    .withMessage('PIN must be exactly 4 digits'),
  body('role')
    .isIn(['barista', 'cashier', 'manager', 'supervisor'])
    .withMessage('Invalid role')
];

const validateDriverCreate = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters'),
  body('driverId')
    .trim()
    .notEmpty()
    .withMessage('Driver ID is required')
    .matches(/^DRV-\d{4}$/)
    .withMessage('Driver ID must be in format DRV-####'),
  body('phone')
    .isMobilePhone()
    .withMessage('Please provide a valid phone number'),
  body('licenseNumber')
    .trim()
    .notEmpty()
    .withMessage('License number is required')
];

const validatePinChange = [
  body('currentPin')
    .matches(/^\d{4}$/)
    .withMessage('Current PIN must be exactly 4 digits'),
  body('newPin')
    .matches(/^\d{4}$/)
    .withMessage('New PIN must be exactly 4 digits')
    .custom((value) => {
      // Reject weak PINs
      const weakPins = ['0000', '1234', '1111', '2222', '3333', '4444', '5555', '6666', '7777', '8888', '9999'];
      if (weakPins.includes(value)) {
        throw new Error('PIN is too weak. Please choose a different PIN');
      }
      return true;
    })
];

// ============================================
// EXPORT ALL VALIDATORS
// ============================================

module.exports = {
  // Error handler
  handleValidationErrors,
  
  // Common
  validateMongoId,
  validatePagination,
  
  // Auth & User
  validateRegistration,
  validateLogin,
  validateProfileUpdate,
  
  // Orders
  validateOrder,
  validateOrderStatus,
  
  // Products
  validateProduct,
  
  // Reviews
  validateReview,
  
  // Subscriptions
  validateSubscription,
  validateSubscriptionUpdate,
  
  // Payments
  validatePayment,
  
  // Gift Sets
  validateGiftSet,
  
  // Contact & Support
  validateContactInquiry,
  validateSupportTicket,
  
  // Staff & Drivers
  validateStaffCreate,
  validateDriverCreate,
  validatePinChange
};
