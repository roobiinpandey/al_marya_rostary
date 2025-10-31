const express = require('express');
const { body } = require('express-validator');
const {
  getUsers,
  getUser,
  updateUser,
  deleteUser,
  getUserStats
} = require('../controllers/userController');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');
const Order = require('../models/Order');

const router = express.Router();

// Validation rules
const userUpdateValidation = [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters'),
  body('email')
    .optional()
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('phone')
    .optional()
    .matches(/^[\+]?[1-9][\d]{0,15}$/)
    .withMessage('Please provide a valid phone number'),
  body('role')
    .optional()
    .isIn(['customer', 'admin'])
    .withMessage('Role must be either customer or admin'),
  body('isActive')
    .optional()
    .isBoolean()
    .withMessage('isActive must be a boolean value')
];

// User-specific routes (with Firebase auth)
// @route   GET /api/users/me/orders
// @desc    Get current user's orders
// @access  Private (Firebase authenticated users)
router.get('/me/orders', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.id;
    
    console.log(`📦 Fetching orders for user: ${req.user.email} (ID: ${userId})`);

    // Find orders for this user
    const orders = await Order.find({ userId })
      .sort({ createdAt: -1 }) // Newest first
      .lean();

    console.log(`✅ Found ${orders.length} orders for user ${req.user.email}`);

    // Return orders with proper structure
    const response = {
      success: true,
      count: orders.length,
      orders: orders.map(order => ({
        _id: order._id.toString(),
        userId: order.userId,
        items: order.items || {},
        total: order.total || 0,
        status: order.status || 'pending',
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
        notes: order.notes,
        deliveryAddress: order.deliveryAddress
      }))
    };
    
    console.log('📤 Sending response:', JSON.stringify(response));
    res.json(response);
  } catch (error) {
    console.error('❌ Error fetching user orders:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching orders',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Admin routes
router.get('/stats', getUserStats);
router.get('/', getUsers);
router.get('/:id', getUser);
router.put('/:id', userUpdateValidation, updateUser);
router.delete('/:id', deleteUser);

module.exports = router;
