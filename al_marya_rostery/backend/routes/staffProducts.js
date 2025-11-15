const express = require('express');
const router = express.Router();
const multer = require('multer');
const { body, validationResult } = require('express-validator');
const { protectStaffAdmin } = require('../middleware/staffAuth');
const { productStorage } = require('../config/cloudinary');

// Import models
const Coffee = require('../models/Coffee');
const Accessory = require('../models/Accessory');
const GiftSet = require('../models/GiftSet');

// Configure multer for file uploads with Cloudinary
const upload = multer({
  storage: productStorage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  }
});

// Validation rules for products (matching admin panel)
const productValidation = [
  body('nameEn')
    .optional({ checkFalsy: true })
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('English name must be between 2 and 100 characters'),
  body('nameAr')
    .optional({ checkFalsy: true })
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Arabic name must be between 2 and 100 characters'),
  body('descriptionEn')
    .optional({ checkFalsy: true })
    .trim()
    .isLength({ min: 10, max: 1000 })
    .withMessage('English description must be between 10 and 1000 characters'),
  body('descriptionAr')
    .optional({ checkFalsy: true })
    .trim()
    .isLength({ min: 10, max: 1000 })
    .withMessage('Arabic description must be between 10 and 1000 characters'),
  body('price')
    .optional({ checkFalsy: true })
    .isFloat({ min: 0 })
    .withMessage('Price must be a positive number'),
  body('productType')
    .optional()
    .isIn(['Coffee', 'Accessory', 'GiftSet'])
    .withMessage('Product type must be Coffee, Accessory, or GiftSet')
];

// Helper function to get model based on product type
const getModelByType = (type) => {
  switch (type) {
    case 'Coffee':
      return Coffee;
    case 'Accessory':
      return Accessory;
    case 'GiftSet':
      return GiftSet;
    default:
      return Coffee;
  }
};

// @desc    Get all products (Coffee, Accessories, Gift Sets)
// @route   GET /api/staff/products
// @access  Private (Staff Admin)
router.get('/', protectStaffAdmin, async (req, res) => {
  try {
    const { type, category, search, isActive, page = 1, limit = 50 } = req.query;
    
    const options = {
      page: parseInt(page),
      limit: parseInt(limit),
      sort: { createdAt: -1 }
    };

    let products = [];

    // If type specified, get only that type
    if (type) {
      const Model = getModelByType(type);
      let query = {};

      if (category) query.categories = category;
      if (search) {
        query.$or = [
          { 'name.en': { $regex: search, $options: 'i' } },
          { 'name.ar': { $regex: search, $options: 'i' } }
        ];
      }
      if (isActive !== undefined) query.isActive = isActive === 'true';

      products = await Model.find(query)
        .sort(options.sort)
        .limit(options.limit)
        .skip((options.page - 1) * options.limit)
        .lean();
      
      // Add productType field
      products = products.map(p => ({ ...p, productType: type }));
    } else {
      // Get all product types
      const coffeeQuery = {};
      const accessoryQuery = {};
      const giftSetQuery = {};

      if (search) {
        const searchCondition = {
          $or: [
            { 'name.en': { $regex: search, $options: 'i' } },
            { 'name.ar': { $regex: search, $options: 'i' } }
          ]
        };
        Object.assign(coffeeQuery, searchCondition);
        Object.assign(accessoryQuery, searchCondition);
        Object.assign(giftSetQuery, searchCondition);
      }

      if (isActive !== undefined) {
        coffeeQuery.isActive = isActive === 'true';
        accessoryQuery.isActive = isActive === 'true';
        giftSetQuery.isActive = isActive === 'true';
      }

      const [coffees, accessories, giftSets] = await Promise.all([
        Coffee.find(coffeeQuery).sort(options.sort).lean(),
        Accessory.find(accessoryQuery).sort(options.sort).lean(),
        GiftSet.find(giftSetQuery).sort(options.sort).lean()
      ]);

      // Add productType to each item
      products = [
        ...coffees.map(c => ({ ...c, productType: 'Coffee' })),
        ...accessories.map(a => ({ ...a, productType: 'Accessory' })),
        ...giftSets.map(g => ({ ...g, productType: 'GiftSet' }))
      ];

      // Sort combined results by createdAt
      products.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

      // Apply pagination
      const startIndex = (options.page - 1) * options.limit;
      products = products.slice(startIndex, startIndex + options.limit);
    }

    res.json({
      success: true,
      count: products.length,
      data: products,
      staff: req.staff.name
    });
  } catch (error) {
    console.error('Get products error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// @desc    Get single product by ID
// @route   GET /api/staff/products/:id
// @access  Private (Staff Admin)
router.get('/:id', protectStaffAdmin, async (req, res) => {
  try {
    const { type } = req.query;
    
    if (!type) {
      return res.status(400).json({
        success: false,
        message: 'Product type is required (Coffee, Accessory, or GiftSet)'
      });
    }

    const Model = getModelByType(type);
    const product = await Model.findById(req.params.id).lean();

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    res.json({
      success: true,
      data: { ...product, productType: type }
    });
  } catch (error) {
    console.error('Get product error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// @desc    Create new product
// @route   POST /api/staff/products
// @access  Private (Staff Admin)
router.post('/', protectStaffAdmin, upload.single('image'), productValidation, async (req, res) => {
  try {
    console.log('=== STAFF CREATE PRODUCT ===');
    console.log('Staff:', req.staff.name);
    console.log('Product type:', req.body.productType);
    console.log('Has image:', !!req.file);
    console.log('============================');

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const { productType = 'Coffee' } = req.body;
    const Model = getModelByType(productType);

    // Prepare product data
    let productData = {
      name: {
        en: req.body.nameEn || req.body.name,
        ar: req.body.nameAr || req.body.name
      },
      description: {
        en: req.body.descriptionEn || req.body.description,
        ar: req.body.descriptionAr || req.body.description
      },
      price: parseFloat(req.body.price),
      isActive: req.body.isActive !== undefined ? req.body.isActive === 'true' : true,
      isFeatured: req.body.isFeatured === 'true'
    };

    // Handle image upload
    if (req.file) {
      productData.image = req.file.path; // Cloudinary URL
    }

    // Coffee-specific fields
    if (productType === 'Coffee') {
      productData.origin = req.body.origin;
      productData.roastLevel = req.body.roastLevel || 'Medium';
      productData.stock = parseInt(req.body.stock) || 0;
      
      // Handle categories
      if (req.body.categories) {
        productData.categories = typeof req.body.categories === 'string' 
          ? JSON.parse(req.body.categories) 
          : req.body.categories;
      }

      // Handle variants
      if (req.body.variants) {
        productData.variants = typeof req.body.variants === 'string'
          ? JSON.parse(req.body.variants)
          : req.body.variants;
      }

      // Handle other optional fields
      if (req.body.flavorProfile) {
        productData.flavorProfile = typeof req.body.flavorProfile === 'string'
          ? JSON.parse(req.body.flavorProfile)
          : req.body.flavorProfile;
      }
      if (req.body.brewingMethods) {
        productData.brewingMethods = typeof req.body.brewingMethods === 'string'
          ? JSON.parse(req.body.brewingMethods)
          : req.body.brewingMethods;
      }
      if (req.body.certifications) {
        productData.certifications = typeof req.body.certifications === 'string'
          ? JSON.parse(req.body.certifications)
          : req.body.certifications;
      }
      if (req.body.tags) {
        productData.tags = typeof req.body.tags === 'string'
          ? JSON.parse(req.body.tags)
          : req.body.tags;
      }
    }

    // Accessory-specific fields
    if (productType === 'Accessory') {
      productData.category = req.body.category;
      productData.material = req.body.material;
      productData.brand = req.body.brand;
      productData.stock = parseInt(req.body.stock) || 0;
      
      if (req.body.dimensions) {
        productData.dimensions = typeof req.body.dimensions === 'string'
          ? JSON.parse(req.body.dimensions)
          : req.body.dimensions;
      }
      if (req.body.colors) {
        productData.colors = typeof req.body.colors === 'string'
          ? JSON.parse(req.body.colors)
          : req.body.colors;
      }
    }

    // GiftSet-specific fields
    if (productType === 'GiftSet') {
      if (req.body.items) {
        productData.items = typeof req.body.items === 'string'
          ? JSON.parse(req.body.items)
          : req.body.items;
      }
      if (req.body.packaging) {
        productData.packaging = typeof req.body.packaging === 'string'
          ? JSON.parse(req.body.packaging)
          : req.body.packaging;
      }
      productData.stock = parseInt(req.body.stock) || 0;
    }

    const product = await Model.create(productData);

    console.log(`✅ Staff ${req.staff.name} created ${productType}:`, product._id);

    res.status(201).json({
      success: true,
      data: product,
      message: `${productType} created successfully`
    });
  } catch (error) {
    console.error('Create product error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// @desc    Update product
// @route   PUT /api/staff/products/:id
// @access  Private (Staff Admin)
router.put('/:id', protectStaffAdmin, upload.single('image'), productValidation, async (req, res) => {
  try {
    console.log('=== STAFF UPDATE PRODUCT ===');
    console.log('Staff:', req.staff.name);
    console.log('Product ID:', req.params.id);
    console.log('Product type:', req.body.productType);
    console.log('Has new image:', !!req.file);
    console.log('============================');

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const { productType = 'Coffee' } = req.body;
    const Model = getModelByType(productType);

    // Check if product exists
    const existingProduct = await Model.findById(req.params.id);
    if (!existingProduct) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    let updateData = {};

    // Handle bilingual name and description
    if (req.body.nameEn || req.body.nameAr) {
      updateData.name = {
        en: req.body.nameEn || existingProduct.name?.en || req.body.name,
        ar: req.body.nameAr || existingProduct.name?.ar || req.body.name
      };
    }

    if (req.body.descriptionEn || req.body.descriptionAr) {
      updateData.description = {
        en: req.body.descriptionEn || existingProduct.description?.en || req.body.description,
        ar: req.body.descriptionAr || existingProduct.description?.ar || req.body.description
      };
    }

    // Handle image upload
    if (req.file) {
      updateData.image = req.file.path; // Cloudinary URL
    }

    // Common fields
    if (req.body.price !== undefined) updateData.price = parseFloat(req.body.price);
    if (req.body.isActive !== undefined) updateData.isActive = req.body.isActive === 'true';
    if (req.body.isFeatured !== undefined) updateData.isFeatured = req.body.isFeatured === 'true';
    if (req.body.stock !== undefined) updateData.stock = parseInt(req.body.stock);

    // Coffee-specific fields
    if (productType === 'Coffee') {
      if (req.body.origin) updateData.origin = req.body.origin;
      if (req.body.roastLevel) updateData.roastLevel = req.body.roastLevel;
      if (req.body.categories) {
        updateData.categories = typeof req.body.categories === 'string'
          ? JSON.parse(req.body.categories)
          : req.body.categories;
      }
      if (req.body.variants) {
        updateData.variants = typeof req.body.variants === 'string'
          ? JSON.parse(req.body.variants)
          : req.body.variants;
      }
      if (req.body.flavorProfile) {
        updateData.flavorProfile = typeof req.body.flavorProfile === 'string'
          ? JSON.parse(req.body.flavorProfile)
          : req.body.flavorProfile;
      }
      if (req.body.brewingMethods) {
        updateData.brewingMethods = typeof req.body.brewingMethods === 'string'
          ? JSON.parse(req.body.brewingMethods)
          : req.body.brewingMethods;
      }
      if (req.body.certifications) {
        updateData.certifications = typeof req.body.certifications === 'string'
          ? JSON.parse(req.body.certifications)
          : req.body.certifications;
      }
      if (req.body.tags) {
        updateData.tags = typeof req.body.tags === 'string'
          ? JSON.parse(req.body.tags)
          : req.body.tags;
      }
    }

    // Accessory-specific fields
    if (productType === 'Accessory') {
      if (req.body.category) updateData.category = req.body.category;
      if (req.body.material) updateData.material = req.body.material;
      if (req.body.brand) updateData.brand = req.body.brand;
      if (req.body.dimensions) {
        updateData.dimensions = typeof req.body.dimensions === 'string'
          ? JSON.parse(req.body.dimensions)
          : req.body.dimensions;
      }
      if (req.body.colors) {
        updateData.colors = typeof req.body.colors === 'string'
          ? JSON.parse(req.body.colors)
          : req.body.colors;
      }
    }

    // GiftSet-specific fields
    if (productType === 'GiftSet') {
      if (req.body.items) {
        updateData.items = typeof req.body.items === 'string'
          ? JSON.parse(req.body.items)
          : req.body.items;
      }
      if (req.body.packaging) {
        updateData.packaging = typeof req.body.packaging === 'string'
          ? JSON.parse(req.body.packaging)
          : req.body.packaging;
      }
    }

    const product = await Model.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    ).lean();

    console.log(`✅ Staff ${req.staff.name} updated ${productType}:`, product._id);

    res.json({
      success: true,
      data: product,
      message: `${productType} updated successfully`
    });
  } catch (error) {
    console.error('Update product error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// @desc    Delete product
// @route   DELETE /api/staff/products/:id
// @access  Private (Staff Admin)
router.delete('/:id', protectStaffAdmin, async (req, res) => {
  try {
    const { type } = req.query;

    if (!type) {
      return res.status(400).json({
        success: false,
        message: 'Product type is required (Coffee, Accessory, or GiftSet)'
      });
    }

    const Model = getModelByType(type);
    const product = await Model.findById(req.params.id);

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    await Model.findByIdAndDelete(req.params.id);

    console.log(`✅ Staff ${req.staff.name} deleted ${type}:`, req.params.id);

    res.json({
      success: true,
      message: `${type} deleted successfully`
    });
  } catch (error) {
    console.error('Delete product error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// @desc    Toggle product visibility (isActive)
// @route   PATCH /api/staff/products/:id/visibility
// @access  Private (Staff Admin)
router.patch('/:id/visibility', protectStaffAdmin, async (req, res) => {
  try {
    const { type, isActive } = req.body;

    if (!type) {
      return res.status(400).json({
        success: false,
        message: 'Product type is required (Coffee, Accessory, or GiftSet)'
      });
    }

    if (isActive === undefined) {
      return res.status(400).json({
        success: false,
        message: 'isActive field is required'
      });
    }

    const Model = getModelByType(type);
    const product = await Model.findByIdAndUpdate(
      req.params.id,
      { isActive: isActive === 'true' || isActive === true },
      { new: true, runValidators: true }
    ).lean();

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    console.log(`✅ Staff ${req.staff.name} toggled visibility for ${type}:`, req.params.id, '→', product.isActive);

    res.json({
      success: true,
      data: product,
      message: `Product ${product.isActive ? 'shown' : 'hidden'} successfully`
    });
  } catch (error) {
    console.error('Toggle visibility error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// @desc    Get product statistics
// @route   GET /api/staff/products/stats
// @access  Private (Staff Admin)
router.get('/analytics/stats', protectStaffAdmin, async (req, res) => {
  try {
    const [coffeeCount, accessoryCount, giftSetCount] = await Promise.all([
      Coffee.countDocuments(),
      Accessory.countDocuments(),
      GiftSet.countDocuments()
    ]);

    const [coffeeActive, accessoryActive, giftSetActive] = await Promise.all([
      Coffee.countDocuments({ isActive: true }),
      Accessory.countDocuments({ isActive: true }),
      GiftSet.countDocuments({ isActive: true })
    ]);

    res.json({
      success: true,
      data: {
        totalProducts: coffeeCount + accessoryCount + giftSetCount,
        activeProducts: coffeeActive + accessoryActive + giftSetActive,
        byType: {
          coffee: { total: coffeeCount, active: coffeeActive },
          accessories: { total: accessoryCount, active: accessoryActive },
          giftSets: { total: giftSetCount, active: giftSetActive }
        }
      }
    });
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

module.exports = router;
