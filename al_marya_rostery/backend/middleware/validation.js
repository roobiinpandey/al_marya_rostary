const { body, validationResult } = require('express-validator');

/**
 * Order validation middleware
 * Validates incoming order data
 */
const orderValidation = [
  // Validate items
  body('items')
    .isArray({ min: 1 })
    .withMessage('Order must contain at least one item'),
  
  body('items.*.productId')
    .optional()
    .trim(),
  
  body('items.*.quantity')
    .isInt({ min: 1 })
    .withMessage('Quantity must be at least 1'),
  
  body('items.*.price')
    .isFloat({ min: 0 })
    .withMessage('Price must be a positive number'),

  // Validate shipping address
  body('shippingAddress')
    .notEmpty()
    .withMessage('Shipping address is required'),

  body('shippingAddress.phone')
    .matches(/^\+971 5\d{8}$/)
    .withMessage('Phone must be in format +971 5XXXXXXXX'),

  body('shippingAddress.address')
    .notEmpty()
    .trim()
    .withMessage('Address is required'),

  body('shippingAddress.city')
    .notEmpty()
    .trim()
    .withMessage('City is required'),

  body('shippingAddress.emirate')
    .notEmpty()
    .trim()
    .withMessage('Emirate is required'),

  // Validate payment method
  body('paymentMethod')
    .isIn(['credit_card', 'debit_card', 'cash', 'wallet', 'bank_transfer', 'apple_pay', 'google_pay', 'stripe'])
    .withMessage('Invalid payment method'),

  // Validate total amount
  body('totalAmount')
    .isFloat({ min: 0.01 })
    .withMessage('Total amount must be greater than zero'),

  // Optional fields
  body('deliveryMethod')
    .optional()
    .isIn(['standard', 'express', 'same-day'])
    .withMessage('Invalid delivery method'),

  body('specialInstructions')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Special instructions must not exceed 500 characters'),

  // Validate guest info for guest orders
  body('guestInfo.name')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Guest name is required for guest orders'),

  body('guestInfo.email')
    .optional()
    .isEmail()
    .normalizeEmail()
    .withMessage('Valid email is required for guest orders'),

  body('guestInfo.phone')
    .optional()
    .matches(/^\+971 5\d{8}$/)
    .withMessage('Phone must be in format +971 5XXXXXXXX'),

  // Middleware to handle validation errors
  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.error('❌ Order validation errors:', errors.array());
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
  }
];

/**
 * User feedback validation middleware
 */
const createFeedbackValidation = [
  body('rating')
    .isInt({ min: 1, max: 5 })
    .withMessage('Rating must be between 1 and 5'),

  body('title')
    .trim()
    .notEmpty()
    .withMessage('Title is required')
    .isLength({ max: 200 })
    .withMessage('Title must not exceed 200 characters'),

  body('comment')
    .optional()
    .trim()
    .isLength({ max: 1000 })
    .withMessage('Comment must not exceed 1000 characters'),

  body('productId')
    .optional()
    .trim(),

  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }
    next();
  }
];

module.exports = {
  orderValidation,
  createFeedbackValidation
};
