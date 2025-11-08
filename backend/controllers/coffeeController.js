const Coffee = require('../models/Coffee');
const { validationResult } = require('express-validator');

// Helper function to create default variants based on base price
const createDefaultVariants = (basePrice) => {
  const price = parseFloat(basePrice) || 50; // Default base price
  
  return [
    {
      size: '250gm',
      weight: 250,
      price: Math.round(price * 0.8), // 20% less for smaller size
      stock: 100,
      description: {
        en: '250gm pack - Perfect for trying new flavors',
        ar: 'عبوة ٢٥٠ جرام - مثالية لتجربة النكهات الجديدة'
      },
      displayName: {
        en: '250gm Pack',
        ar: 'عبوة ٢٥٠ جرام'
      },
      isActive: true
    },
    {
      size: '500gm',
      weight: 500,
      price: price, // Base price for standard size
      stock: 100,
      description: {
        en: '500gm pack - Perfect for regular consumption',
        ar: 'عبوة ٥٠٠ جرام - مثالية للاستهلاك المنتظم'
      },
      displayName: {
        en: '500gm Pack',
        ar: 'عبوة ٥٠٠ جرام'
      },
      isActive: true
    },
    {
      size: '1kg',
      weight: 1000,
      price: Math.round(price * 1.8), // Better value for bulk
      stock: 50,
      description: {
        en: '1kg pack - Perfect for bulk purchase and sharing',
        ar: 'عبوة كيلو جرام - مثالية للشراء بالجملة والمشاركة'
      },
      displayName: {
        en: '1kg Pack',
        ar: 'عبوة كيلو جرام'
      },
      isActive: true
    }
  ];
};

// Helper function to process and validate variants
const processVariants = (variants) => {
  if (!Array.isArray(variants)) return createDefaultVariants(50);
  
  return variants.map(variant => ({
    size: variant.size || '500gm',
    weight: variant.weight || (variant.size === '250gm' ? 250 : variant.size === '1kg' ? 1000 : 500),
    price: parseFloat(variant.price) || 50,
    stock: parseInt(variant.stock) || 0,
    description: {
      en: variant.description?.en || getDefaultDescription(variant.size, 'en'),
      ar: variant.description?.ar || getDefaultDescription(variant.size, 'ar')
    },
    displayName: {
      en: variant.displayName?.en || getDefaultDisplayName(variant.size, 'en'),
      ar: variant.displayName?.ar || getDefaultDisplayName(variant.size, 'ar')
    },
    isActive: variant.isActive !== undefined ? variant.isActive : true
  }));
};

// Helper function to get default descriptions
const getDefaultDescription = (size, lang) => {
  const descriptions = {
    en: {
      '250gm': '250gm pack - Perfect for trying new flavors',
      '500gm': '500gm pack - Perfect for regular consumption',
      '1kg': '1kg pack - Perfect for bulk purchase and sharing'
    },
    ar: {
      '250gm': 'عبوة ٢٥٠ جرام - مثالية لتجربة النكهات الجديدة',
      '500gm': 'عبوة ٥٠٠ جرام - مثالية للاستهلاك المنتظم',
      '1kg': 'عبوة كيلو جرام - مثالية للشراء بالجملة والمشاركة'
    }
  };
  return descriptions[lang][size] || `${size} pack`;
};

// Helper function to get default display names
const getDefaultDisplayName = (size, lang) => {
  const names = {
    en: {
      '250gm': '250gm Pack',
      '500gm': '500gm Pack',
      '1kg': '1kg Pack'
    },
    ar: {
      '250gm': 'عبوة ٢٥٠ جرام',
      '500gm': 'عبوة ٥٠٠ جرام',
      '1kg': 'عبوة كيلو جرام'
    }
  };
  return names[lang][size] || `${size} Pack`;
};

// @desc    Get all coffees
// @route   GET /api/coffees
// @access  Public
const getCoffees = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;
    const language = req.query.lang || req.headers['accept-language']?.split(',')[0]?.split('-')[0] || 'en';

    const filter = { isActive: true };

    // Add search functionality
    if (req.query.search) {
      filter.$text = { $search: req.query.search };
    }

    // Add category filter
    if (req.query.category) {
      filter.categories = req.query.category;
    }

    // Add price range filter
    if (req.query.minPrice || req.query.maxPrice) {
      filter.price = {};
      if (req.query.minPrice) filter.price.$gte = parseFloat(req.query.minPrice);
      if (req.query.maxPrice) filter.price.$lte = parseFloat(req.query.maxPrice);
    }

    const coffees = await Coffee.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .select('-__v')
      .lean(); // Convert to plain JavaScript objects

    const total = await Coffee.countDocuments(filter);

    // Localize coffee data - manual localization for lean objects
    const lang = ['en', 'ar'].includes(language) ? language : 'en';
    const localizedCoffees = coffees.map(coffee => ({
      ...coffee,
      localizedName: coffee.name?.[lang] || coffee.name?.en,
      localizedDescription: coffee.description?.[lang] || coffee.description?.en
    }));

    res.json({
      success: true,
      data: localizedCoffees,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      },
      language
    });
  } catch (error) {
    console.error('Get coffees error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Get single coffee
// @route   GET /api/coffees/:id
// @access  Public
const getCoffee = async (req, res) => {
  try {
    const language = req.query.lang || req.headers['accept-language']?.split(',')[0]?.split('-')[0] || 'en';
    const coffee = await Coffee.findById(req.params.id).lean(); // Convert to plain object

    if (!coffee) {
      return res.status(404).json({
        success: false,
        message: 'Coffee not found'
      });
    }

    // Manual localization for lean object
    const lang = ['en', 'ar'].includes(language) ? language : 'en';
    const localizedCoffee = {
      ...coffee,
      localizedName: coffee.name?.[lang] || coffee.name?.en,
      localizedDescription: coffee.description?.[lang] || coffee.description?.en
    };

    res.json({
      success: true,
      data: localizedCoffee,
      language
    });
  } catch (error) {
    console.error('Get coffee error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Create new coffee
// @route   POST /api/coffees
// @access  Private/Admin
const createCoffee = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    // Check if image was uploaded
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Image is required'
      });
    }

    // Process variants first to determine if we have custom variants
    const variants = req.body.variants ? processVariants(JSON.parse(req.body.variants)) : createDefaultVariants(req.body.price);
    
    // Calculate price and stock from variants if not provided
    const hasCustomVariants = req.body.variants && JSON.parse(req.body.variants).length > 0;
    const price = req.body.price || (hasCustomVariants ? Math.min(...variants.map(v => v.price)) : 50);
    const stock = req.body.stock !== undefined ? req.body.stock : (hasCustomVariants ? variants.reduce((sum, v) => sum + v.stock, 0) : 0);

    const coffeeData = {
      name: {
        en: req.body.nameEn || req.body.name,
        ar: req.body.nameAr || req.body.name
      },
      description: {
        en: req.body.descriptionEn || req.body.description,
        ar: req.body.descriptionAr || req.body.description
      },
      price: price,
      image: req.file.path, // Cloudinary URL
      origin: req.body.origin,
      roastLevel: req.body.roastLevel,
      stock: stock,
      categories: req.body.categories ? JSON.parse(req.body.categories) : [],
      variants: variants,
      tastingNotes: req.body.tastingNotes ? JSON.parse(req.body.tastingNotes) : [],
      brewingMethods: req.body.brewingMethods ? JSON.parse(req.body.brewingMethods) : [],
      certifications: req.body.certifications ? JSON.parse(req.body.certifications) : [],
      tags: req.body.tags ? JSON.parse(req.body.tags) : [],
      isActive: req.body.isActive !== undefined ? req.body.isActive : true,
      isFeatured: req.body.isFeatured !== undefined ? req.body.isFeatured : false
    };

    const coffee = (await Coffee.create(coffeeData)).toObject(); // Convert to plain object

    res.status(201).json({
      success: true,
      data: coffee,
      message: 'Coffee created successfully'
    });
  } catch (error) {
    console.error('Create coffee error:', error);
    
    // Note: Cloudinary automatically manages file storage
    // No need to manually delete files on error

    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Update coffee
// @route   PUT /api/coffees/:id
// @access  Private/Admin
const updateCoffee = async (req, res) => {
  try {
    console.log('=== UPDATE COFFEE REQUEST ===');
    console.log('Product ID:', req.params.id);
    console.log('Request body:', req.body);
    console.log('Has file:', !!req.file);
    console.log('============================');
    
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.error('Validation errors:', errors.array());
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    let updateData = {};

    // Get existing product to preserve fields if partial update
    const existingCoffee = await Coffee.findById(req.params.id);
    if (!existingCoffee) {
      return res.status(404).json({
        success: false,
        message: 'Coffee not found'
      });
    }

    // Handle bilingual name and description
    if (req.body.nameEn || req.body.nameAr) {
      updateData.name = {
        en: req.body.nameEn || existingCoffee.name?.en || req.body.name || existingCoffee.name,
        ar: req.body.nameAr || existingCoffee.name?.ar || req.body.name || existingCoffee.name
      };
    }
    
    if (req.body.descriptionEn || req.body.descriptionAr) {
      updateData.description = {
        en: req.body.descriptionEn || existingCoffee.description?.en || req.body.description || existingCoffee.description,
        ar: req.body.descriptionAr || existingCoffee.description?.ar || req.body.description || existingCoffee.description
      };
    }

    // Handle other fields
    ['price', 'origin', 'roastLevel', 'stock', 'isActive', 'isFeatured'].forEach(field => {
      if (req.body[field] !== undefined) {
        updateData[field] = req.body[field];
      }
    });

    // Handle file upload if new image provided
    if (req.file) {
      updateData.image = req.file.path; // Cloudinary URL
      // Note: Cloudinary automatically manages old images
      // No need to manually delete old files
    }

    // Parse JSON fields
    if (req.body.categories) updateData.categories = JSON.parse(req.body.categories);
    if (req.body.variants) updateData.variants = processVariants(JSON.parse(req.body.variants));
    if (req.body.tastingNotes) updateData.tastingNotes = JSON.parse(req.body.tastingNotes);
    if (req.body.brewingMethods) updateData.brewingMethods = JSON.parse(req.body.brewingMethods);
    if (req.body.certifications) updateData.certifications = JSON.parse(req.body.certifications);
    if (req.body.tags) updateData.tags = JSON.parse(req.body.tags);

    const coffee = await Coffee.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    ).lean(); // Convert to plain JavaScript object

    if (!coffee) {
      return res.status(404).json({
        success: false,
        message: 'Coffee not found'
      });
    }

    res.json({
      success: true,
      data: coffee,
      message: 'Coffee updated successfully'
    });
  } catch (error) {
    console.error('Update coffee error:', error);
    
    // Note: Cloudinary automatically manages file storage
    // No need to manually delete files on error

    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Delete coffee
// @route   DELETE /api/coffees/:id
// @access  Private/Admin
const deleteCoffee = async (req, res) => {
  try {
    const coffee = await Coffee.findById(req.params.id);

    if (!coffee) {
      return res.status(404).json({
        success: false,
        message: 'Coffee not found'
      });
    }

    // Delete image file
    if (coffee.image) {
      const fs = require('fs');
      const path = require('path');
      const imagePath = path.join(__dirname, '..', coffee.image);
      if (fs.existsSync(imagePath)) {
        fs.unlinkSync(imagePath);
      }
    }

    await Coffee.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Coffee deleted successfully'
    });
  } catch (error) {
    console.error('Delete coffee error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Get coffee statistics
// @route   GET /api/coffees/stats
// @access  Private/Admin
const getCoffeeStats = async (req, res) => {
  try {
    const stats = await Coffee.aggregate([
      {
        $group: {
          _id: null,
          totalCoffees: { $sum: 1 },
          activeCoffees: {
            $sum: { $cond: ['$isActive', 1, 0] }
          },
          featuredCoffees: {
            $sum: { $cond: ['$isFeatured', 1, 0] }
          },
          averagePrice: { $avg: '$price' },
          totalStock: { $sum: '$stock' }
        }
      }
    ]);

    const categoryStats = await Coffee.aggregate([
      { $unwind: '$categories' },
      {
        $group: {
          _id: '$categories',
          count: { $sum: 1 }
        }
      },
      { $sort: { count: -1 } },
      { $limit: 10 }
    ]);

    res.json({
      success: true,
      data: {
        overview: stats[0] || {
          totalCoffees: 0,
          activeCoffees: 0,
          featuredCoffees: 0,
          averagePrice: 0,
          totalStock: 0
        },
        categories: categoryStats
      }
    });
  } catch (error) {
    console.error('Get coffee stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

module.exports = {
  getCoffees,
  getCoffee,
  createCoffee,
  updateCoffee,
  deleteCoffee,
  getCoffeeStats
};
