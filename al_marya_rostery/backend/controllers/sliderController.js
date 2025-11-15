const Slider = require('../models/Slider');
const { validationResult } = require('express-validator');
const fs = require('fs');
const path = require('path');

// @desc    Get all sliders
// @route   GET /api/sliders
// @access  Public
const getSliders = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const filter = {};

    // Add active filter
    if (req.query.active !== undefined) {
      filter.isActive = req.query.active === 'true';
    }

    // Add status filter
    if (req.query.status) {
      const now = new Date();
      switch (req.query.status) {
        case 'active':
          filter.isActive = true;
          filter.$or = [
            { startDate: { $lte: now } },
            { startDate: null }
          ];
          filter.$or = [
            { endDate: { $gte: now } },
            { endDate: null }
          ];
          break;
        case 'scheduled':
          filter.isActive = true;
          filter.startDate = { $gt: now };
          break;
        case 'expired':
          filter.isActive = true;
          filter.endDate = { $lt: now };
          break;
        case 'inactive':
          filter.isActive = false;
          break;
      }
    }

    // Add search functionality
    if (req.query.search) {
      filter.title = { $regex: req.query.search, $options: 'i' };
    }

    const sliders = await Slider.find(filter)
      .sort({ displayOrder: 1, createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .select('-__v')
      .lean(); // Convert Mongoose documents to plain JavaScript objects

    const total = await Slider.countDocuments(filter);

    res.json({
      success: true,
      data: sliders,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get sliders error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Get single slider
// @route   GET /api/sliders/:id
// @access  Public
const getSlider = async (req, res) => {
  try {
    const slider = await Slider.findById(req.params.id).lean();

    if (!slider) {
      return res.status(404).json({
        success: false,
        message: 'Slider not found'
      });
    }

    res.json({
      success: true,
      data: slider
    });
  } catch (error) {
    console.error('Get slider error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Create new slider
// @route   POST /api/sliders
// @access  Private/Admin
const createSlider = async (req, res) => {
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
    if (!req.files || !req.files.image || !req.files.image[0]) {
      return res.status(400).json({
        success: false,
        message: 'Image is required'
      });
    }

    // ✨ NEW: Use Cloudinary URLs instead of local paths
    const sliderData = {
      ...req.body,
      image: req.files.image[0].path, // Cloudinary returns full URL in 'path'
      categories: req.body.categories ? JSON.parse(req.body.categories) : [],
      targetAudience: req.body.targetAudience ? JSON.parse(req.body.targetAudience) : ['all'],
      tags: req.body.tags ? JSON.parse(req.body.tags) : []
    };

    // Handle optional mobile image
    if (req.files && req.files.mobileImage) {
      sliderData.mobileImage = req.files.mobileImage[0].path; // Cloudinary URL
    }

    const slider = (await Slider.create(sliderData)).toObject(); // Convert to plain object

    console.log('✅ Slider created with Cloudinary images:', {
      image: slider.image,
      mobileImage: slider.mobileImage
    });

    res.status(201).json({
      success: true,
      data: slider,
      message: 'Slider created successfully'
    });
  } catch (error) {
    console.error('Create slider error:', error);

    // ✨ NEW: Cloudinary handles cleanup automatically on error
    // No need to manually delete files

    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Update slider
// @route   PUT /api/sliders/:id
// @access  Private/Admin
const updateSlider = async (req, res) => {
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

    // ✨ NEW: Handle image update with Cloudinary
    if (req.files && req.files.image && req.files.image[0]) {
      updateData.image = req.files.image[0].path; // Cloudinary URL
      
      // Delete old image from Cloudinary
      const oldSlider = await Slider.findById(req.params.id);
      if (oldSlider && oldSlider.image && oldSlider.image.includes('cloudinary')) {
        const { deleteImage } = require('../config/cloudinary');
        try {
          await deleteImage(oldSlider.image);
          console.log('✅ Old slider image deleted from Cloudinary');
        } catch (err) {
          console.error('⚠️ Error deleting old image from Cloudinary:', err);
        }
      }
    }

    // Handle optional mobile image
    if (req.files && req.files.mobileImage) {
      updateData.mobileImage = req.files.mobileImage[0].path; // Cloudinary URL

      // Delete old mobile image from Cloudinary
      const oldSlider = await Slider.findById(req.params.id);
      if (oldSlider && oldSlider.mobileImage && oldSlider.mobileImage.includes('cloudinary')) {
        const { deleteImage } = require('../config/cloudinary');
        try {
          await deleteImage(oldSlider.mobileImage);
          console.log('✅ Old mobile slider image deleted from Cloudinary');
        } catch (err) {
          console.error('⚠️ Error deleting old mobile image from Cloudinary:', err);
        }
      }
    }

    // Parse JSON fields
    if (updateData.categories) updateData.categories = JSON.parse(updateData.categories);
    if (updateData.targetAudience) updateData.targetAudience = JSON.parse(updateData.targetAudience);
    if (updateData.tags) updateData.tags = JSON.parse(updateData.tags);

    const slider = await Slider.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    ).lean(); // Convert Mongoose document to plain JavaScript object

    if (!slider) {
      return res.status(404).json({
        success: false,
        message: 'Slider not found'
      });
    }

    res.json({
      success: true,
      data: slider,
      message: 'Slider updated successfully'
    });
  } catch (error) {
    console.error('Update slider error:', error);

    // Delete uploaded files if update fails
    if (req.files) {
      
      if (req.files.image && req.files.image[0]) {
        try {
          fs.unlinkSync(path.join(__dirname, '../uploads', req.files.image[0].filename));
        } catch (err) {
          console.error('Error deleting image file:', err);
        }
      }
      
      if (req.files.mobileImage && req.files.mobileImage[0]) {
        try {
          fs.unlinkSync(path.join(__dirname, '../uploads', req.files.mobileImage[0].filename));
        } catch (err) {
          console.error('Error deleting mobile image file:', err);
        }
      }
    }

    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Delete slider
// @route   DELETE /api/sliders/:id
// @access  Private/Admin
const deleteSlider = async (req, res) => {
  try {
    const slider = await Slider.findById(req.params.id);

    if (!slider) {
      return res.status(404).json({
        success: false,
        message: 'Slider not found'
      });
    }

    // Delete image files
    if (slider.image) {
      const imagePath = path.join(__dirname, '..', slider.image);
      if (fs.existsSync(imagePath)) {
        fs.unlinkSync(imagePath);
      }
    }

    if (slider.mobileImage) {
      const mobileImagePath = path.join(__dirname, '..', slider.mobileImage);
      if (fs.existsSync(mobileImagePath)) {
        fs.unlinkSync(mobileImagePath);
      }
    }

    await Slider.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Slider deleted successfully'
    });
  } catch (error) {
    console.error('Delete slider error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Get slider statistics
// @route   GET /api/sliders/stats
// @access  Private/Admin
const getSliderStats = async (req, res) => {
  try {
    const stats = await Slider.aggregate([
      {
        $group: {
          _id: null,
          totalSliders: { $sum: 1 },
          activeSliders: {
            $sum: { $cond: ['$isActive', 1, 0] }
          },
          totalClicks: { $sum: '$clickCount' },
          totalViews: { $sum: '$viewCount' },
          averageClicks: { $avg: '$clickCount' },
          averageViews: { $avg: '$viewCount' }
        }
      }
    ]);

    const topPerforming = await Slider.find({ isActive: true })
      .sort({ clickCount: -1 })
      .limit(5)
      .select('title clickCount viewCount')
      .lean(); // Convert to plain JavaScript objects

    res.json({
      success: true,
      data: {
        overview: stats[0] || {
          totalSliders: 0,
          activeSliders: 0,
          totalClicks: 0,
          totalViews: 0,
          averageClicks: 0,
          averageViews: 0
        },
        topPerforming
      }
    });
  } catch (error) {
    console.error('Get slider stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Track slider click
// @route   POST /api/sliders/:id/click
// @access  Public
const trackSliderClick = async (req, res) => {
  try {
    const slider = await Slider.findById(req.params.id);

    if (!slider) {
      return res.status(404).json({
        success: false,
        message: 'Slider not found'
      });
    }

    await slider.incrementClicks();

    res.json({
      success: true,
      message: 'Click tracked successfully'
    });
  } catch (error) {
    console.error('Track slider click error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Track slider view
// @route   POST /api/sliders/:id/view
// @access  Public
const trackSliderView = async (req, res) => {
  try {
    const slider = await Slider.findById(req.params.id);

    if (!slider) {
      return res.status(404).json({
        success: false,
        message: 'Slider not found'
      });
    }

    await slider.incrementViews();

    res.json({
      success: true,
      message: 'View tracked successfully'
    });
  } catch (error) {
    console.error('Track slider view error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

module.exports = {
  getSliders,
  getSlider,
  createSlider,
  updateSlider,
  deleteSlider,
  getSliderStats,
  trackSliderClick,
  trackSliderView
};
