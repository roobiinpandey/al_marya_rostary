const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const accessoryController = require('../controllers/accessoryController');
const { protect, authorize } = require('../middleware/auth');

// Validation middleware
const validateAccessory = [
  body('name.en').notEmpty().withMessage('English name is required'),
  body('name.ar').notEmpty().withMessage('Arabic name is required'),
  body('description.en').notEmpty().withMessage('English description is required'),
  body('description.ar').notEmpty().withMessage('Arabic description is required'),
  body('type').isIn(['grinder', 'mug', 'filter', 'scale', 'kettle', 'dripper', 'press', 'other']).withMessage('Invalid accessory type'),
  body('category').notEmpty().withMessage('Category is required'),
  body('price.regular').isFloat({ min: 0 }).withMessage('Regular price must be a positive number')
];

// Public routes
router.get('/', accessoryController.getAllAccessories);
router.get('/type/:type', accessoryController.getAccessoriesByType);
router.get('/featured', accessoryController.getFeaturedAccessories);
router.get('/in-stock', accessoryController.getInStockAccessories);
router.get('/:id', accessoryController.getAccessoryById);

// User routes (require authentication)
router.post('/:id/rating', protect, accessoryController.addRating);

// Admin routes (require authentication and admin role)
router.post('/', protect, authorize('admin'), validateAccessory, accessoryController.createAccessory);
router.put('/:id', protect, authorize('admin'), validateAccessory, accessoryController.updateAccessory);
router.delete('/:id', protect, authorize('admin'), accessoryController.deleteAccessory);
router.patch('/:id/toggle-status', protect, authorize('admin'), accessoryController.toggleAccessoryStatus);
router.patch('/:id/stock', protect, authorize('admin'), accessoryController.updateStock);
router.get('/admin/analytics', protect, authorize('admin'), accessoryController.getAccessoryAnalytics);

module.exports = router;
