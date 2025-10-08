const express = require('express');
const multer = require('multer');
const path = require('path');
const { body } = require('express-validator');
const {
  getCoffees,
  getCoffee,
  createCoffee,
  updateCoffee,
  deleteCoffee,
  getCoffeeStats
} = require('../controllers/coffeeController');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '../uploads'));
  },
  filename: (req, file, cb) => {
    // Generate unique filename with timestamp
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'coffee-' + uniqueSuffix + path.extname(file.originalname));
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
    fileSize: 5 * 1024 * 1024 // 5MB limit
  }
});

// Validation rules
const coffeeValidation = [
  body('name')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters'),
  body('description')
    .trim()
    .isLength({ min: 10, max: 1000 })
    .withMessage('Description must be between 10 and 1000 characters'),
  body('price')
    .isFloat({ min: 0 })
    .withMessage('Price must be a positive number'),
  body('origin')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Origin must be between 2 and 100 characters'),
  body('roastLevel')
    .isIn(['Light', 'Medium-Light', 'Medium', 'Medium-Dark', 'Dark'])
    .withMessage('Invalid roast level'),
  body('stock')
    .isInt({ min: 0 })
    .withMessage('Stock must be a non-negative integer')
];

// Routes
router.get('/stats', getCoffeeStats);
router.get('/', getCoffees);
router.get('/:id', getCoffee);
router.post('/', upload.single('image'), coffeeValidation, createCoffee);
router.put('/:id', upload.single('image'), coffeeValidation, updateCoffee);
router.delete('/:id', deleteCoffee);

module.exports = router;
