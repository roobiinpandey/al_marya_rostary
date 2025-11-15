const express = require('express');
const multer = require('multer');
const path = require('path');
const { body } = require('express-validator');
const {
  getQuickCategories,
  getQuickCategory,
  createQuickCategory,
  updateQuickCategory,
  deleteQuickCategory,
  getQuickCategoryStats,
  trackQuickCategoryClick,
  trackQuickCategoryView,
  reorderQuickCategories,
  toggleQuickCategoryStatus,
  getActiveQuickCategories
} = require('../controllers/quickCategoryController');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '../uploads'));
  },
  filename: (req, file, cb) => {
    // Generate unique filename with timestamp
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'quick-category-' + uniqueSuffix + path.extname(file.originalname));
  }
});

// File filter to allow only images
const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed!'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit for category images
  }
});

// Validation rules
const quickCategoryValidation = [
  body('title')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Title must be between 2 and 50 characters'),
  body('subtitle')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Subtitle must be between 2 and 100 characters'),
  body('color')
    .matches(/^#[0-9A-F]{6}$/i)
    .withMessage('Color must be a valid hex color code'),
  body('displayOrder')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Display order must be a non-negative integer'),
  body('linkTo')
    .optional()
    .isIn(['category', 'product', 'external', 'none'])
    .withMessage('Link type must be category, product, external, or none'),
  body('linkValue')
    .optional()
    .trim()
    .isLength({ max: 200 })
    .withMessage('Link value cannot be more than 200 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ max: 200 })
    .withMessage('Description cannot be more than 200 characters'),
  body('tags')
    .optional()
    .isArray()
    .withMessage('Tags must be an array'),
  body('tags.*')
    .optional()
    .trim()
    .isLength({ min: 1, max: 30 })
    .withMessage('Each tag must be between 1 and 30 characters')
];

// Reorder validation
const reorderValidation = [
  body('orderedIds')
    .isArray({ min: 1 })
    .withMessage('Ordered IDs must be a non-empty array'),
  body('orderedIds.*')
    .isMongoId()
    .withMessage('Each ID must be a valid MongoDB ObjectId')
];

// Public routes (no authentication required)
router.get('/active', getActiveQuickCategories);

// Admin routes (authentication would be added here in middleware)
router.get('/stats', getQuickCategoryStats);
router.get('/', getQuickCategories);
router.get('/:id', getQuickCategory);

router.post('/', 
  upload.single('image'), 
  quickCategoryValidation, 
  createQuickCategory
);

router.put('/:id', 
  upload.single('image'), 
  quickCategoryValidation, 
  updateQuickCategory
);

router.delete('/:id', deleteQuickCategory);

// Special action routes
router.put('/:id/toggle-status', toggleQuickCategoryStatus);
router.put('/reorder', reorderValidation, reorderQuickCategories);

// Tracking routes
router.post('/:id/click', trackQuickCategoryClick);
router.post('/:id/view', trackQuickCategoryView);

module.exports = router;
