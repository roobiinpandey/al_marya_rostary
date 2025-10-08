const Category = require('../models/Category');
const { validationResult } = require('express-validator');

// @desc    Get all categories
// @route   GET /api/categories
// @access  Public
const getCategories = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const skip = (page - 1) * limit;

    const filter = {};

    // Add active filter
    if (req.query.active !== undefined) {
      filter.isActive = req.query.active === 'true';
    }

    // Add search functionality
    if (req.query.search) {
      filter.name = { $regex: req.query.search, $options: 'i' };
    }

    const categories = await Category.find(filter)
      .sort({ displayOrder: 1, name: 1 })
      .skip(skip)
      .limit(limit)
      .select('-__v');

    const total = await Category.countDocuments(filter);

    res.json({
      success: true,
      data: categories,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Get single category
// @route   GET /api/categories/:id
// @access  Public
const getCategory = async (req, res) => {
  try {
    const category = await Category.findById(req.params.id);

    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    res.json({
      success: true,
      data: category
    });
  } catch (error) {
    console.error('Get category error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Create new category
// @route   POST /api/categories
// @access  Private/Admin
const createCategory = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const categoryData = { ...req.body };

    // Handle parent category
    if (categoryData.parentCategory && categoryData.parentCategory === '') {
      categoryData.parentCategory = null;
    }

    const category = await Category.create(categoryData);

    res.status(201).json({
      success: true,
      data: category,
      message: 'Category created successfully'
    });
  } catch (error) {
    console.error('Create category error:', error);

    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Category name already exists'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Update category
// @route   PUT /api/categories/:id
// @access  Private/Admin
const updateCategory = async (req, res) => {
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

    // Handle parent category
    if (updateData.parentCategory && updateData.parentCategory === '') {
      updateData.parentCategory = null;
    }

    const category = await Category.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    res.json({
      success: true,
      data: category,
      message: 'Category updated successfully'
    });
  } catch (error) {
    console.error('Update category error:', error);

    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Category name already exists'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Delete category
// @route   DELETE /api/categories/:id
// @access  Private/Admin
const deleteCategory = async (req, res) => {
  try {
    const category = await Category.findById(req.params.id);

    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    // Check if category has products
    const productCount = await category.getProductCount();
    if (productCount > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete category. It contains ${productCount} product(s). Please reassign or remove products first.`
      });
    }

    // Check if category has subcategories
    const subcategories = await Category.countDocuments({ parentCategory: req.params.id });
    if (subcategories > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete category. It has ${subcategories} subcategory(ies). Please delete subcategories first.`
      });
    }

    await Category.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Category deleted successfully'
    });
  } catch (error) {
    console.error('Delete category error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Get category statistics
// @route   GET /api/categories/stats
// @access  Private/Admin
const getCategoryStats = async (req, res) => {
  try {
    const Coffee = require('../models/Coffee');

    const stats = await Category.aggregate([
      { $match: { isActive: true } },
      {
        $lookup: {
          from: 'coffees',
          let: { categoryName: '$name' },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $in: ['$$categoryName', '$categories'] },
                    { $eq: ['$isActive', true] }
                  ]
                }
              }
            }
          ],
          as: 'products'
        }
      },
      {
        $addFields: {
          productCount: { $size: '$products' }
        }
      },
      {
        $group: {
          _id: null,
          totalCategories: { $sum: 1 },
          categoriesWithProducts: {
            $sum: { $cond: [{ $gt: ['$productCount', 0] }, 1, 0] }
          },
          totalProducts: { $sum: '$productCount' }
        }
      }
    ]);

    const topCategories = await Category.aggregate([
      { $match: { isActive: true } },
      {
        $lookup: {
          from: 'coffees',
          let: { categoryName: '$name' },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $in: ['$$categoryName', '$categories'] },
                    { $eq: ['$isActive', true] }
                  ]
                }
              }
            }
          ],
          as: 'products'
        }
      },
      {
        $addFields: {
          productCount: { $size: '$products' }
        }
      },
      { $sort: { productCount: -1 } },
      { $limit: 10 },
      {
        $project: {
          name: 1,
          productCount: 1
        }
      }
    ]);

    res.json({
      success: true,
      data: {
        overview: stats[0] || {
          totalCategories: 0,
          categoriesWithProducts: 0,
          totalProducts: 0
        },
        topCategories
      }
    });
  } catch (error) {
    console.error('Get category stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

module.exports = {
  getCategories,
  getCategory,
  createCategory,
  updateCategory,
  deleteCategory,
  getCategoryStats
};
