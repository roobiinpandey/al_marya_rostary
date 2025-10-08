const express = require('express');
const multer = require('multer');
const path = require('path');
const { body } = require('express-validator');
const {
  getSliders,
  getSlider,
  createSlider,
  updateSlider,
  deleteSlider,
  getSliderStats,
  trackSliderClick,
  trackSliderView
} = require('../controllers/sliderController');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '../uploads'));
  },
  filename: (req, file, cb) => {
    // Generate unique filename with timestamp
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'slider-' + uniqueSuffix + path.extname(file.originalname));
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
    fileSize: 10 * 1024 * 1024 // 10MB limit for banner images
  }
});

// Validation rules
const sliderValidation = [
  body('title')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Title must be between 2 and 100 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ max: 300 })
    .withMessage('Description cannot be more than 300 characters'),
  body('buttonText')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Button text cannot be more than 50 characters'),
  body('buttonLink')
    .optional()
    .isURL()
    .withMessage('Button link must be a valid URL'),
  body('backgroundColor')
    .optional()
    .matches(/^#[0-9A-F]{6}$/i)
    .withMessage('Background color must be a valid hex color code'),
  body('textColor')
    .optional()
    .matches(/^#[0-9A-F]{6}$/i)
    .withMessage('Text color must be a valid hex color code'),
  body('position')
    .optional()
    .isIn(['left', 'center', 'right'])
    .withMessage('Position must be left, center, or right'),
  body('displayOrder')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Display order must be a non-negative integer'),
  body('startDate')
    .optional()
    .isISO8601()
    .withMessage('Start date must be a valid date'),
  body('endDate')
    .optional()
    .isISO8601()
    .withMessage('End date must be a valid date')
];

// Routes
router.get('/stats', getSliderStats);
router.get('/', getSliders);
router.get('/:id', getSlider);
router.post('/', upload.fields([
  { name: 'image', maxCount: 1 },
  { name: 'mobileImage', maxCount: 1 }
]), sliderValidation, createSlider);
router.put('/:id', upload.fields([
  { name: 'image', maxCount: 1 },
  { name: 'mobileImage', maxCount: 1 }
]), sliderValidation, updateSlider);
router.delete('/:id', deleteSlider);

// Tracking routes
router.post('/:id/click', trackSliderClick);
router.post('/:id/view', trackSliderView);

module.exports = router;
