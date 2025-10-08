const Coffee = require('../models/Coffee');
const { validationResult } = require('express-validator');

// @desc    Get all coffees
// @route   GET /api/coffees
// @access  Public
const getCoffees = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

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
      .select('-__v');

    const total = await Coffee.countDocuments(filter);

    res.json({
      success: true,
      data: coffees,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
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
    const coffee = await Coffee.findById(req.params.id);

    if (!coffee) {
      return res.status(404).json({
        success: false,
        message: 'Coffee not found'
      });
    }

    res.json({
      success: true,
      data: coffee
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

    const coffeeData = {
      ...req.body,
      image: `/uploads/${req.file.filename}`,
      categories: req.body.categories ? JSON.parse(req.body.categories) : [],
      variants: req.body.variants ? JSON.parse(req.body.variants) : [],
      tastingNotes: req.body.tastingNotes ? JSON.parse(req.body.tastingNotes) : [],
      brewingMethods: req.body.brewingMethods ? JSON.parse(req.body.brewingMethods) : [],
      certifications: req.body.certifications ? JSON.parse(req.body.certifications) : [],
      tags: req.body.tags ? JSON.parse(req.body.tags) : []
    };

    const coffee = await Coffee.create(coffeeData);

    res.status(201).json({
      success: true,
      data: coffee,
      message: 'Coffee created successfully'
    });
  } catch (error) {
    console.error('Create coffee error:', error);

    // Delete uploaded file if coffee creation fails
    if (req.file) {
      const fs = require('fs');
      const path = require('path');
      fs.unlinkSync(path.join(__dirname, '../uploads', req.file.filename));
    }

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
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    let updateData = { ...req.body };

    // Handle file upload if new image provided
    if (req.file) {
      updateData.image = `/uploads/${req.file.filename}`;

      // Delete old image file
      const oldCoffee = await Coffee.findById(req.params.id);
      if (oldCoffee && oldCoffee.image) {
        const fs = require('fs');
        const path = require('path');
        const oldImagePath = path.join(__dirname, '..', oldCoffee.image);
        if (fs.existsSync(oldImagePath)) {
          fs.unlinkSync(oldImagePath);
        }
      }
    }

    // Parse JSON fields
    if (updateData.categories) updateData.categories = JSON.parse(updateData.categories);
    if (updateData.variants) updateData.variants = JSON.parse(updateData.variants);
    if (updateData.tastingNotes) updateData.tastingNotes = JSON.parse(updateData.tastingNotes);
    if (updateData.brewingMethods) updateData.brewingMethods = JSON.parse(updateData.brewingMethods);
    if (updateData.certifications) updateData.certifications = JSON.parse(updateData.certifications);
    if (updateData.tags) updateData.tags = JSON.parse(updateData.tags);

    const coffee = await Coffee.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );

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

    // Delete uploaded file if update fails
    if (req.file) {
      const fs = require('fs');
      const path = require('path');
      fs.unlinkSync(path.join(__dirname, '../uploads', req.file.filename));
    }

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
