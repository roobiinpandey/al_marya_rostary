const QuickCategory = require('../models/QuickCategory');
const { validationResult } = require('express-validator');
const fs = require('fs');
const path = require('path');

// @desc    Get all quick categories
// @route   GET /api/quick-categories
// @access  Private (Admin)
const getQuickCategories = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const filter = {};

    // Add active filter
    if (req.query.active !== undefined) {
      filter.isActive = req.query.active === 'true';
    }

    // Add search functionality
    if (req.query.search) {
      filter.$or = [
        { title: { $regex: req.query.search, $options: 'i' } },
        { subtitle: { $regex: req.query.search, $options: 'i' } },
        { tags: { $in: [new RegExp(req.query.search, 'i')] } }
      ];
    }

    // Add tag filter
    if (req.query.tag) {
      filter.tags = { $in: [req.query.tag.toLowerCase()] };
    }

    const quickCategories = await QuickCategory.find(filter)
      .sort({ displayOrder: 1, createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .select('-__v')
      .lean();

    const total = await QuickCategory.countDocuments(filter);

    res.json({
      success: true,
      data: quickCategories,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get quick categories error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Get active quick categories for frontend
// @route   GET /api/quick-categories/active
// @access  Public
const getActiveQuickCategories = async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;

    const quickCategories = await QuickCategory.findActive(limit);

    res.json({
      success: true,
      data: quickCategories
    });
  } catch (error) {
    console.error('Get active quick categories error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Get single quick category
// @route   GET /api/quick-categories/:id
// @access  Private (Admin)
const getQuickCategory = async (req, res) => {
  try {
    const quickCategory = await QuickCategory.findById(req.params.id).lean();

    if (!quickCategory) {
      return res.status(404).json({
        success: false,
        message: 'Quick category not found'
      });
    }

    res.json({
      success: true,
      data: quickCategory
    });
  } catch (error) {
    console.error('Get quick category error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Create new quick category
// @route   POST /api/quick-categories
// @access  Private (Admin)
const createQuickCategory = async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { title, subtitle, color, displayOrder, isActive, linkTo, linkValue, description, tags } = req.body;

    // Handle image upload
    let imageUrl = req.body.imageUrl; // Allow URL input
    if (req.file) {
      imageUrl = `/uploads/${req.file.filename}`;
    }

    if (!imageUrl) {
      return res.status(400).json({
        success: false,
        message: 'Image is required (either upload or provide URL)'
      });
    }

    // Get the highest display order and increment
    const maxOrderCategory = await QuickCategory.findOne().sort({ displayOrder: -1 });
    const newDisplayOrder = displayOrder !== undefined ? displayOrder : (maxOrderCategory ? maxOrderCategory.displayOrder + 1 : 0);

    const quickCategoryData = {
      title,
      subtitle,
      imageUrl,
      color,
      displayOrder: newDisplayOrder,
      isActive: isActive !== undefined ? isActive : true,
      linkTo: linkTo || 'none',
      linkValue: linkValue || '',
      description: description || '',
      tags: Array.isArray(tags) ? tags : (tags ? [tags] : [])
    };

    const quickCategory = new QuickCategory(quickCategoryData);
    await quickCategory.save();

    res.status(201).json({
      success: true,
      message: 'Quick category created successfully',
      data: quickCategory
    });
  } catch (error) {
    console.error('Create quick category error:', error);
    
    // Clean up uploaded file if there's an error
    if (req.file) {
      const filePath = path.join(__dirname, '../uploads', req.file.filename);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    }

    res.status(500).json({
      success: false,
      message: error.message || 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Update quick category
// @route   PUT /api/quick-categories/:id
// @access  Private (Admin)
const updateQuickCategory = async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const quickCategory = await QuickCategory.findById(req.params.id);
    if (!quickCategory) {
      return res.status(404).json({
        success: false,
        message: 'Quick category not found'
      });
    }

    const { title, subtitle, color, displayOrder, isActive, linkTo, linkValue, description, tags } = req.body;
    const oldImagePath = quickCategory.imageUrl;

    // Handle image upload
    let imageUrl = req.body.imageUrl || quickCategory.imageUrl;
    if (req.file) {
      imageUrl = `/uploads/${req.file.filename}`;
      
      // Delete old image file if it exists and was uploaded (not external URL)
      if (oldImagePath && oldImagePath.startsWith('/uploads/')) {
        const oldFilePath = path.join(__dirname, '..', oldImagePath);
        if (fs.existsSync(oldFilePath)) {
          fs.unlinkSync(oldFilePath);
        }
      }
    }

    // Update fields
    quickCategory.title = title || quickCategory.title;
    quickCategory.subtitle = subtitle || quickCategory.subtitle;
    quickCategory.imageUrl = imageUrl;
    quickCategory.color = color || quickCategory.color;
    quickCategory.displayOrder = displayOrder !== undefined ? displayOrder : quickCategory.displayOrder;
    quickCategory.isActive = isActive !== undefined ? isActive : quickCategory.isActive;
    quickCategory.linkTo = linkTo || quickCategory.linkTo;
    quickCategory.linkValue = linkValue !== undefined ? linkValue : quickCategory.linkValue;
    quickCategory.description = description !== undefined ? description : quickCategory.description;
    quickCategory.tags = Array.isArray(tags) ? tags : (tags ? [tags] : quickCategory.tags);

    await quickCategory.save();

    res.json({
      success: true,
      message: 'Quick category updated successfully',
      data: quickCategory
    });
  } catch (error) {
    console.error('Update quick category error:', error);
    
    // Clean up uploaded file if there's an error
    if (req.file) {
      const filePath = path.join(__dirname, '../uploads', req.file.filename);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    }

    res.status(500).json({
      success: false,
      message: error.message || 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Delete quick category
// @route   DELETE /api/quick-categories/:id
// @access  Private (Admin)
const deleteQuickCategory = async (req, res) => {
  try {
    const quickCategory = await QuickCategory.findById(req.params.id);
    if (!quickCategory) {
      return res.status(404).json({
        success: false,
        message: 'Quick category not found'
      });
    }

    // Delete associated image file if it was uploaded
    if (quickCategory.imageUrl && quickCategory.imageUrl.startsWith('/uploads/')) {
      const filePath = path.join(__dirname, '..', quickCategory.imageUrl);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    }

    await QuickCategory.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Quick category deleted successfully'
    });
  } catch (error) {
    console.error('Delete quick category error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Toggle quick category status
// @route   PUT /api/quick-categories/:id/toggle-status
// @access  Private (Admin)
const toggleQuickCategoryStatus = async (req, res) => {
  try {
    const quickCategory = await QuickCategory.findById(req.params.id);
    if (!quickCategory) {
      return res.status(404).json({
        success: false,
        message: 'Quick category not found'
      });
    }

    await quickCategory.toggleActive();

    res.json({
      success: true,
      message: `Quick category ${quickCategory.isActive ? 'activated' : 'deactivated'} successfully`,
      data: quickCategory
    });
  } catch (error) {
    console.error('Toggle quick category status error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Reorder quick categories
// @route   PUT /api/quick-categories/reorder
// @access  Private (Admin)
const reorderQuickCategories = async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { orderedIds } = req.body;

    // Verify all IDs exist
    const existingCategories = await QuickCategory.find({ _id: { $in: orderedIds } });
    if (existingCategories.length !== orderedIds.length) {
      return res.status(400).json({
        success: false,
        message: 'One or more quick category IDs are invalid'
      });
    }

    await QuickCategory.reorderCategories(orderedIds);

    res.json({
      success: true,
      message: 'Quick categories reordered successfully'
    });
  } catch (error) {
    console.error('Reorder quick categories error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Get quick category statistics
// @route   GET /api/quick-categories/stats
// @access  Private (Admin)
const getQuickCategoryStats = async (req, res) => {
  try {
    const totalCategories = await QuickCategory.countDocuments();
    const activeCategories = await QuickCategory.countDocuments({ isActive: true });
    const inactiveCategories = totalCategories - activeCategories;

    // Get analytics summary
    const analyticsResult = await QuickCategory.getAnalyticsSummary();
    const analytics = analyticsResult[0] || {
      totalCategories: 0,
      totalClicks: 0,
      totalViews: 0,
      avgClickThroughRate: 0
    };

    // Get most popular categories
    const popularCategories = await QuickCategory.find({ isActive: true })
      .sort({ clickCount: -1 })
      .limit(5)
      .select('title clickCount viewCount')
      .lean();

    const stats = {
      totalCategories,
      activeCategories,
      inactiveCategories,
      totalClicks: analytics.totalClicks,
      totalViews: analytics.totalViews,
      avgClickThroughRate: parseFloat(analytics.avgClickThroughRate?.toFixed(2) || '0'),
      popularCategories
    };

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Get quick category stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Track quick category click
// @route   POST /api/quick-categories/:id/click
// @access  Public
const trackQuickCategoryClick = async (req, res) => {
  try {
    const quickCategory = await QuickCategory.findById(req.params.id);
    if (!quickCategory) {
      return res.status(404).json({
        success: false,
        message: 'Quick category not found'
      });
    }

    await quickCategory.incrementClicks();

    res.json({
      success: true,
      message: 'Click tracked successfully'
    });
  } catch (error) {
    console.error('Track quick category click error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Track quick category view
// @route   POST /api/quick-categories/:id/view
// @access  Public
const trackQuickCategoryView = async (req, res) => {
  try {
    const quickCategory = await QuickCategory.findById(req.params.id);
    if (!quickCategory) {
      return res.status(404).json({
        success: false,
        message: 'Quick category not found'
      });
    }

    await quickCategory.incrementViews();

    res.json({
      success: true,
      message: 'View tracked successfully'
    });
  } catch (error) {
    console.error('Track quick category view error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

module.exports = {
  getQuickCategories,
  getActiveQuickCategories,
  getQuickCategory,
  createQuickCategory,
  updateQuickCategory,
  deleteQuickCategory,
  toggleQuickCategoryStatus,
  reorderQuickCategories,
  getQuickCategoryStats,
  trackQuickCategoryClick,
  trackQuickCategoryView
};
