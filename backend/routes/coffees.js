const express = require('express');
const multer = require('multer');
const { body } = require('express-validator');
const {
  getCoffees,
  getCoffee,
  createCoffee,
  updateCoffee,
  deleteCoffee,
  getCoffeeStats
} = require('../controllers/coffeeController');
const { productStorage } = require('../config/cloudinary');

const router = express.Router();

// Configure multer for file uploads with Cloudinary
const upload = multer({
  storage: productStorage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  }
});

// Validation rules - supporting both old (name/description) and new (nameEn/nameAr) formats
const coffeeValidation = [
  body('nameEn')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('English name must be between 2 and 100 characters'),
  body('nameAr')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Arabic name must be between 2 and 100 characters'),
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters'),
  body('descriptionEn')
    .optional()
    .trim()
    .isLength({ min: 10, max: 1000 })
    .withMessage('English description must be between 10 and 1000 characters'),
  body('descriptionAr')
    .optional()
    .trim()
    .isLength({ min: 10, max: 1000 })
    .withMessage('Arabic description must be between 10 and 1000 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ min: 10, max: 1000 })
    .withMessage('Description must be between 10 and 1000 characters'),
  body('price')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Price must be a positive number'),
  body('origin')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Origin must be between 2 and 100 characters'),
  body('roastLevel')
    .optional()
    .isIn(['Light', 'Medium-Light', 'Medium', 'Medium-Dark', 'Dark'])
    .withMessage('Invalid roast level'),
  body('stock')
    .optional()
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
