const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { body, validationResult } = require('express-validator');
const BrewingMethod = require('../models/BrewingMethod');
const { protect } = require('../middleware/auth');
const requireAdmin = require('../middleware/adminAuth');
const { serialize } = require('../middleware/jsonSerializer');

// Multer configuration for image uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/brewing-methods/');
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'brewing-method-' + uniqueSuffix + path.extname(file.originalname));
  }
});

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

// Validation rules for creating brewing methods
const brewingMethodValidation = [
  body('name.en')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('English name must be between 2 and 100 characters'),
  body('name.ar')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Arabic name must be between 2 and 100 characters'),
  body('description.en')
    .trim()
    .isLength({ min: 10, max: 500 })
    .withMessage('English description must be between 10 and 500 characters'),
  body('description.ar')
    .trim()
    .isLength({ min: 10, max: 500 })
    .withMessage('Arabic description must be between 10 and 500 characters'),
  body('instructions.en')
    .trim()
    .isLength({ min: 50, max: 2000 })
    .withMessage('English instructions must be between 50 and 2000 characters'),
  body('instructions.ar')
    .trim()
    .isLength({ min: 50, max: 2000 })
    .withMessage('Arabic instructions must be between 50 and 2000 characters'),
  body('parameters.grindSize')
    .isIn(['Extra Fine', 'Fine', 'Medium-Fine', 'Medium', 'Medium-Coarse', 'Coarse', 'Extra Coarse'])
    .withMessage('Invalid grind size'),
  body('parameters.coffeeToWaterRatio')
    .trim()
    .isLength({ min: 1, max: 50 })
    .withMessage('Coffee to water ratio is required'),
  body('difficulty')
    .isIn(['Beginner', 'Intermediate', 'Advanced', 'Expert'])
    .withMessage('Invalid difficulty level'),
  body('totalTime')
    .isInt({ min: 1 })
    .withMessage('Total time must be at least 1 minute'),
  body('servings')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Servings must be at least 1'),
  body('displayOrder')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Display order must be a non-negative integer')
];

// Relaxed validation rules for updating brewing methods (allows partial updates)
const brewingMethodUpdateValidation = [
  body('name.en')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('English name must be between 2 and 100 characters'),
  body('name.ar')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Arabic name must be between 2 and 100 characters'),
  body('description.en')
    .optional()
    .trim()
    .isLength({ min: 10, max: 500 })
    .withMessage('English description must be between 10 and 500 characters'),
  body('description.ar')
    .optional()
    .trim()
    .isLength({ min: 10, max: 500 })
    .withMessage('Arabic description must be between 10 and 500 characters'),
  body('instructions.en')
    .optional()
    .trim()
    .isLength({ min: 50, max: 2000 })
    .withMessage('English instructions must be between 50 and 2000 characters'),
  body('instructions.ar')
    .optional()
    .trim()
    .isLength({ min: 50, max: 2000 })
    .withMessage('Arabic instructions must be between 50 and 2000 characters'),
  body('parameters.grindSize')
    .optional()
    .isIn(['Extra Fine', 'Fine', 'Medium-Fine', 'Medium', 'Medium-Coarse', 'Coarse', 'Extra Coarse'])
    .withMessage('Invalid grind size'),
  body('parameters.coffeeToWaterRatio')
    .optional()
    .trim()
    .isLength({ min: 1, max: 50 })
    .withMessage('Coffee to water ratio is required'),
  body('difficulty')
    .optional()
    .isIn(['Beginner', 'Intermediate', 'Advanced', 'Expert'])
    .withMessage('Invalid difficulty level'),
  body('totalTime')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Total time must be at least 1 minute'),
  body('servings')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Servings must be at least 1'),
  body('displayOrder')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Display order must be a non-negative integer')
];

// Get all brewing methods (public)
router.get('/', async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      difficulty,
      category,
      search,
      maxTime,
      sortBy = 'displayOrder',
      sortOrder = 'asc'
    } = req.query;

    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    let query = { isActive: true };

    // Apply filters
    if (difficulty) {
      query.difficulty = difficulty;
    }

    if (category) {
      query.categories = { $in: [category] };
    }

    if (maxTime) {
      query.totalTime = { $lte: parseInt(maxTime) };
    }

    if (search) {
      query.$text = { $search: search };
    }

    // Build sort object
    const sortObj = {};
    if (search) {
      sortObj.score = { $meta: 'textScore' };
    } else {
      const order = sortOrder === 'desc' ? -1 : 1;
      sortObj[sortBy] = order;
    }

    const brewingMethods = await BrewingMethod.find(query)
      .sort(sortObj)
      .skip(skip)
      .limit(limitNum)
      .lean();

    const total = await BrewingMethod.countDocuments(query);

    // Serialize the data and add virtual properties
    const serializedMethods = brewingMethods.map(method => {
      const serialized = serialize(method);
      
      // Add virtual properties manually since .lean() doesn't include them
      serialized.formattedTotalTime = method.totalTime < 60 
        ? `${method.totalTime} min` 
        : `${Math.floor(method.totalTime / 60)}h ${method.totalTime % 60 > 0 ? method.totalTime % 60 + 'min' : ''}`;
      
      serialized.status = method.isActive ? 'Active' : 'Inactive';
      serialized.formattedRating = (method.analytics?.avgRating || 0).toFixed(1);
      
      return serialized;
    });

    res.json({
      success: true,
      data: serializedMethods,
      pagination: {
        current: pageNum,
        pages: Math.ceil(total / limitNum),
        total,
        limit: limitNum
      }
    });
  } catch (error) {
    console.error('Get brewing methods error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Get single brewing method by ID or slug (public)
router.get('/:identifier', async (req, res) => {
  try {
    const { identifier } = req.params;
    
    let brewingMethod;
    
    // Try to find by ID first, then by slug
    if (identifier.match(/^[0-9a-fA-F]{24}$/)) {
      brewingMethod = await BrewingMethod.findById(identifier).lean();
    } else {
      brewingMethod = await BrewingMethod.findOne({ 'seo.slug': identifier }).lean();
    }

    if (!brewingMethod) {
      return res.status(404).json({
        success: false,
        message: 'Brewing method not found'
      });
    }

    // Increment view count (need to update separately since we used .lean())
    await BrewingMethod.findByIdAndUpdate(brewingMethod._id, { 
      $inc: { 'analytics.viewCount': 1 } 
    });

    // Serialize the data and add virtual properties
    const serialized = serialize(brewingMethod);
    serialized.formattedTotalTime = brewingMethod.totalTime < 60 
      ? `${brewingMethod.totalTime} min` 
      : `${Math.floor(brewingMethod.totalTime / 60)}h ${brewingMethod.totalTime % 60 > 0 ? brewingMethod.totalTime % 60 + 'min' : ''}`;
    
    serialized.status = brewingMethod.isActive ? 'Active' : 'Inactive';
    serialized.formattedRating = (brewingMethod.analytics?.avgRating || 0).toFixed(1);

    res.json({
      success: true,
      data: serialized
    });
  } catch (error) {
    console.error('Get brewing method error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Get popular brewing methods (public)
router.get('/featured/popular', async (req, res) => {
  try {
    const { limit = 6 } = req.query;
    
    const popularMethods = await BrewingMethod.findPopular(parseInt(limit));

    res.json({
      success: true,
      data: popularMethods
    });
  } catch (error) {
    console.error('Get popular brewing methods error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Get brewing methods by difficulty (public)
router.get('/difficulty/:level', async (req, res) => {
  try {
    const { level } = req.params;
    
    if (!['Beginner', 'Intermediate', 'Advanced', 'Expert'].includes(level)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid difficulty level'
      });
    }

    const methods = await BrewingMethod.findByDifficulty(level);

    res.json({
      success: true,
      data: methods
    });
  } catch (error) {
    console.error('Get brewing methods by difficulty error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Create new brewing method (admin only)
router.post('/', protect, requireAdmin, upload.single('image'), brewingMethodValidation, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const brewingMethodData = {
      name: {
        en: req.body['name.en'],
        ar: req.body['name.ar']
      },
      description: {
        en: req.body['description.en'],
        ar: req.body['description.ar']
      },
      instructions: {
        en: req.body['instructions.en'],
        ar: req.body['instructions.ar']
      },
      equipment: req.body.equipment ? JSON.parse(req.body.equipment) : [],
      parameters: {
        grindSize: req.body['parameters.grindSize'],
        coffeeToWaterRatio: req.body['parameters.coffeeToWaterRatio'],
        waterTemperature: {
          celsius: req.body['parameters.waterTemperature.celsius'] ? parseInt(req.body['parameters.waterTemperature.celsius']) : undefined,
          fahrenheit: req.body['parameters.waterTemperature.fahrenheit'] ? parseInt(req.body['parameters.waterTemperature.fahrenheit']) : undefined
        },
        brewTime: {
          minutes: req.body['parameters.brewTime.minutes'] ? parseInt(req.body['parameters.brewTime.minutes']) : undefined,
          description: {
            en: req.body['parameters.brewTime.description.en'] || '',
            ar: req.body['parameters.brewTime.description.ar'] || ''
          }
        }
      },
      difficulty: req.body.difficulty,
      totalTime: parseInt(req.body.totalTime),
      servings: req.body.servings ? parseInt(req.body.servings) : 1,
      categories: req.body.categories ? req.body.categories.split(',').map(cat => cat.trim()) : [],
      tags: req.body.tags ? req.body.tags.split(',').map(tag => tag.trim()) : [],
      icon: req.body.icon,
      color: req.body.color || '#A89A6A',
      isActive: req.body.isActive !== undefined ? req.body.isActive === 'true' : true,
      displayOrder: req.body.displayOrder ? parseInt(req.body.displayOrder) : 0,
      isPopular: req.body.isPopular === 'true',
      tips: req.body.tips ? JSON.parse(req.body.tips) : [],
      variations: req.body.variations ? JSON.parse(req.body.variations) : []
    };

    // Add image path if uploaded
    if (req.file) {
      brewingMethodData.image = `/uploads/brewing-methods/${req.file.filename}`;
    }

    const brewingMethod = await BrewingMethod.create(brewingMethodData);

    res.status(201).json({
      success: true,
      data: brewingMethod,
      message: 'Brewing method created successfully'
    });
  } catch (error) {
    console.error('Create brewing method error:', error);

    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Brewing method with this slug already exists'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Update brewing method (admin only)
router.put('/:id', protect, requireAdmin, upload.single('image'), brewingMethodUpdateValidation, async (req, res) => {
  try {
    console.log('🍵 UPDATE Brewing Method Request:', {
      methodId: req.params.id,
      hasImage: !!req.file,
      imagePath: req.file ? req.file.filename : 'none',
      bodyKeys: Object.keys(req.body)
    });

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.error('❌ Validation errors:', errors.array());
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const brewingMethod = await BrewingMethod.findById(req.params.id);
    if (!brewingMethod) {
      console.error('❌ Brewing method not found:', req.params.id);
      return res.status(404).json({
        success: false,
        message: 'Brewing method not found'
      });
    }

    const updateData = {
      name: {
        en: req.body['name.en'],
        ar: req.body['name.ar']
      },
      description: {
        en: req.body['description.en'],
        ar: req.body['description.ar']
      },
      instructions: {
        en: req.body['instructions.en'],
        ar: req.body['instructions.ar']
      },
      equipment: req.body.equipment ? JSON.parse(req.body.equipment) : brewingMethod.equipment,
      parameters: {
        grindSize: req.body['parameters.grindSize'],
        coffeeToWaterRatio: req.body['parameters.coffeeToWaterRatio'],
        waterTemperature: {
          celsius: req.body['parameters.waterTemperature.celsius'] ? parseInt(req.body['parameters.waterTemperature.celsius']) : brewingMethod.parameters.waterTemperature.celsius,
          fahrenheit: req.body['parameters.waterTemperature.fahrenheit'] ? parseInt(req.body['parameters.waterTemperature.fahrenheit']) : brewingMethod.parameters.waterTemperature.fahrenheit
        },
        brewTime: {
          minutes: req.body['parameters.brewTime.minutes'] ? parseInt(req.body['parameters.brewTime.minutes']) : brewingMethod.parameters.brewTime.minutes,
          description: {
            en: req.body['parameters.brewTime.description.en'] || brewingMethod.parameters.brewTime.description.en,
            ar: req.body['parameters.brewTime.description.ar'] || brewingMethod.parameters.brewTime.description.ar
          }
        }
      },
      difficulty: req.body.difficulty,
      totalTime: parseInt(req.body.totalTime),
      servings: req.body.servings ? parseInt(req.body.servings) : brewingMethod.servings,
      categories: req.body.categories ? req.body.categories.split(',').map(cat => cat.trim()) : brewingMethod.categories,
      tags: req.body.tags ? req.body.tags.split(',').map(tag => tag.trim()) : brewingMethod.tags,
      icon: req.body.icon || brewingMethod.icon,
      color: req.body.color || brewingMethod.color,
      isActive: req.body.isActive !== undefined ? req.body.isActive === 'true' : brewingMethod.isActive,
      displayOrder: req.body.displayOrder ? parseInt(req.body.displayOrder) : brewingMethod.displayOrder,
      isPopular: req.body.isPopular !== undefined ? req.body.isPopular === 'true' : brewingMethod.isPopular,
      tips: req.body.tips ? JSON.parse(req.body.tips) : brewingMethod.tips,
      variations: req.body.variations ? JSON.parse(req.body.variations) : brewingMethod.variations
    };

    // Update image path if new image uploaded
    if (req.file) {
      updateData.image = `/uploads/brewing-methods/${req.file.filename}`;
      console.log('✅ New image uploaded:', updateData.image);
    }

    const updatedBrewingMethod = await BrewingMethod.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );

    console.log('✅ Brewing method updated successfully:', {
      id: updatedBrewingMethod._id,
      name: updatedBrewingMethod.name.en,
      image: updatedBrewingMethod.image
    });

    res.json({
      success: true,
      data: updatedBrewingMethod,
      message: 'Brewing method updated successfully'
    });
  } catch (error) {
    console.error('Update brewing method error:', error);

    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Brewing method with this slug already exists'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Delete brewing method (admin only)
router.delete('/:id', protect, requireAdmin, async (req, res) => {
  try {
    const brewingMethod = await BrewingMethod.findById(req.params.id);
    if (!brewingMethod) {
      return res.status(404).json({
        success: false,
        message: 'Brewing method not found'
      });
    }

    await BrewingMethod.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Brewing method deleted successfully'
    });
  } catch (error) {
    console.error('Delete brewing method error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Toggle brewing method active status (admin only)
router.patch('/:id/toggle-active', protect, requireAdmin, async (req, res) => {
  try {
    const brewingMethod = await BrewingMethod.findById(req.params.id);
    if (!brewingMethod) {
      return res.status(404).json({
        success: false,
        message: 'Brewing method not found'
      });
    }

    await brewingMethod.toggleActive();

    res.json({
      success: true,
      data: brewingMethod,
      message: `Brewing method ${brewingMethod.isActive ? 'activated' : 'deactivated'} successfully`
    });
  } catch (error) {
    console.error('Toggle brewing method status error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Add rating to brewing method (authenticated users)
router.post('/:id/rate', protect, async (req, res) => {
  try {
    const { rating } = req.body;
    
    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5'
      });
    }

    const brewingMethod = await BrewingMethod.findById(req.params.id);
    if (!brewingMethod) {
      return res.status(404).json({
        success: false,
        message: 'Brewing method not found'
      });
    }

    await brewingMethod.addRating(rating);

    res.json({
      success: true,
      data: {
        avgRating: brewingMethod.analytics.avgRating,
        totalRatings: brewingMethod.analytics.totalRatings
      },
      message: 'Rating added successfully'
    });
  } catch (error) {
    console.error('Add rating error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Get brewing methods statistics (admin only)
router.get('/admin/stats', protect, requireAdmin, async (req, res) => {
  try {
    const stats = await BrewingMethod.aggregate([
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          active: { $sum: { $cond: ['$isActive', 1, 0] } },
          inactive: { $sum: { $cond: ['$isActive', 0, 1] } },
          popular: { $sum: { $cond: ['$isPopular', 1, 0] } },
          totalViews: { $sum: '$analytics.viewCount' },
          totalRatings: { $sum: '$analytics.totalRatings' },
          avgRating: { $avg: '$analytics.avgRating' }
        }
      }
    ]);

    const difficultyStats = await BrewingMethod.aggregate([
      {
        $group: {
          _id: '$difficulty',
          count: { $sum: 1 }
        }
      }
    ]);

    res.json({
      success: true,
      data: {
        overview: stats[0] || {
          total: 0,
          active: 0,
          inactive: 0,
          popular: 0,
          totalViews: 0,
          totalRatings: 0,
          avgRating: 0
        },
        byDifficulty: difficultyStats
      }
    });
  } catch (error) {
    console.error('Get brewing method stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

module.exports = router;
