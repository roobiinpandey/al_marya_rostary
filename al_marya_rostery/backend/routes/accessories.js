const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const accessoryController = require('../controllers/accessoryController');
const { protect, authorize } = require('../middleware/auth');

// Multer configuration for image uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = path.join(__dirname, '../public/uploads/accessories');
    // Create directory if it doesn't exist
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'accessory-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const fileFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|webp/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedTypes.test(file.mimetype);
  
  if (mimetype && extname) {
    return cb(null, true);
  } else {
    cb(new Error('Only images are allowed (jpeg, jpg, png, webp)'));
  }
};

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: fileFilter
});

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

// Image upload route
router.post('/upload/image', protect, authorize('admin'), upload.single('image'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image file provided'
      });
    }

    const imageUrl = `/uploads/accessories/${req.file.filename}`;
    
    res.json({
      success: true,
      message: 'Image uploaded successfully',
      url: imageUrl,
      imageUrl: imageUrl,
      data: {
        url: imageUrl,
        filename: req.file.filename,
        size: req.file.size,
        mimetype: req.file.mimetype
      }
    });
  } catch (error) {
    console.error('Error uploading accessory image:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload image',
      error: error.message
    });
  }
});

module.exports = router;
