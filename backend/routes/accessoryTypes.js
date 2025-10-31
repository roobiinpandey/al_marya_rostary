const express = require('express');
const router = express.Router();
const AccessoryType = require('../models/AccessoryType');
const Accessory = require('../models/Accessory');

/**
 * @route   GET /api/accessory-types
 * @desc    Get all accessory types
 * @access  Public
 */
router.get('/', async (req, res) => {
  try {
    const { active } = req.query;
    
    let query = {};
    if (active === 'true') {
      query.isActive = true;
    }
    
    const types = await AccessoryType.find(query)
      .sort({ displayOrder: 1, 'name.en': 1 })
      .lean();
    
    res.json({
      success: true,
      data: types,
      count: types.length
    });
  } catch (error) {
    console.error('Error fetching accessory types:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching accessory types',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/accessory-types/:slug
 * @desc    Get single accessory type by slug
 * @access  Public
 */
router.get('/:slug', async (req, res) => {
  try {
    const type = await AccessoryType.findOne({ slug: req.params.slug }).lean();
    
    if (!type) {
      return res.status(404).json({
        success: false,
        message: 'Accessory type not found'
      });
    }
    
    res.json({
      success: true,
      data: type
    });
  } catch (error) {
    console.error('Error fetching accessory type:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching accessory type',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/accessory-types
 * @desc    Create new accessory type
 * @access  Private/Admin
 */
router.post('/', async (req, res) => {
  try {
    const { slug, name, description, icon, route, displayOrder, showOnMainPage } = req.body;
    
    // Check if slug already exists
    const existingType = await AccessoryType.findOne({ slug });
    if (existingType) {
      return res.status(400).json({
        success: false,
        message: 'Accessory type with this slug already exists'
      });
    }
    
    const newType = new AccessoryType({
      slug,
      name,
      description,
      icon,
      route,
      displayOrder,
      showOnMainPage
    });
    
    await newType.save();
    
    res.status(201).json({
      success: true,
      message: 'Accessory type created successfully',
      data: newType
    });
  } catch (error) {
    console.error('Error creating accessory type:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating accessory type',
      error: error.message
    });
  }
});

/**
 * @route   PUT /api/accessory-types/:slug
 * @desc    Update accessory type
 * @access  Private/Admin
 */
router.put('/:slug', async (req, res) => {
  try {
    const { name, description, icon, route, displayOrder, showOnMainPage, isActive } = req.body;
    
    const type = await AccessoryType.findOne({ slug: req.params.slug });
    
    if (!type) {
      return res.status(404).json({
        success: false,
        message: 'Accessory type not found'
      });
    }
    
    // Update fields
    if (name) type.name = name;
    if (description) type.description = description;
    if (icon) type.icon = icon;
    if (route !== undefined) type.route = route;
    if (displayOrder !== undefined) type.displayOrder = displayOrder;
    if (showOnMainPage !== undefined) type.showOnMainPage = showOnMainPage;
    if (isActive !== undefined) type.isActive = isActive;
    
    await type.save();
    
    res.json({
      success: true,
      message: 'Accessory type updated successfully',
      data: type
    });
  } catch (error) {
    console.error('Error updating accessory type:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating accessory type',
      error: error.message
    });
  }
});

/**
 * @route   DELETE /api/accessory-types/:slug
 * @desc    Delete accessory type
 * @access  Private/Admin
 */
router.delete('/:slug', async (req, res) => {
  try {
    const type = await AccessoryType.findOne({ slug: req.params.slug });
    
    if (!type) {
      return res.status(404).json({
        success: false,
        message: 'Accessory type not found'
      });
    }
    
    // Check if there are accessories using this type
    const accessoryCount = await Accessory.countDocuments({ type: req.params.slug });
    
    if (accessoryCount > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete type. ${accessoryCount} accessories are using this type.`,
        accessoryCount
      });
    }
    
    await AccessoryType.deleteOne({ slug: req.params.slug });
    
    res.json({
      success: true,
      message: 'Accessory type deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting accessory type:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting accessory type',
      error: error.message
    });
  }
});

/**
 * @route   PATCH /api/accessory-types/:slug/toggle
 * @desc    Toggle active status
 * @access  Private/Admin
 */
router.patch('/:slug/toggle', async (req, res) => {
  try {
    const type = await AccessoryType.findOne({ slug: req.params.slug });
    
    if (!type) {
      return res.status(404).json({
        success: false,
        message: 'Accessory type not found'
      });
    }
    
    type.isActive = !type.isActive;
    await type.save();
    
    res.json({
      success: true,
      message: `Accessory type ${type.isActive ? 'activated' : 'deactivated'} successfully`,
      data: type
    });
  } catch (error) {
    console.error('Error toggling accessory type:', error);
    res.status(500).json({
      success: false,
      message: 'Error toggling accessory type',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/accessory-types/:slug/update-count
 * @desc    Update product count for a type
 * @access  Private/Admin
 */
router.post('/:slug/update-count', async (req, res) => {
  try {
    const count = await AccessoryType.updateProductCount(req.params.slug);
    
    res.json({
      success: true,
      message: 'Product count updated successfully',
      productCount: count
    });
  } catch (error) {
    console.error('Error updating product count:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating product count',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/accessory-types/seed
 * @desc    Seed default accessory types
 * @access  Private/Admin
 */
router.post('/seed', async (req, res) => {
  try {
    await AccessoryType.seedDefaultTypes();
    
    const types = await AccessoryType.find().sort({ displayOrder: 1 }).lean();
    
    res.json({
      success: true,
      message: 'Default accessory types seeded successfully',
      data: types
    });
  } catch (error) {
    console.error('Error seeding accessory types:', error);
    res.status(500).json({
      success: false,
      message: 'Error seeding accessory types',
      error: error.message
    });
  }
});

module.exports = router;
