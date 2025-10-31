const Accessory = require('../models/Accessory');
const { validationResult } = require('express-validator');

// Get all accessories with filtering and pagination
exports.getAllAccessories = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      type,
      category,
      brand,
      minPrice,
      maxPrice,
      inStock,
      featured,
      search,
      sortBy = 'displayOrder',
      sortOrder = 'asc'
    } = req.query;

    // Build filter object
    const filter = { isActive: true };
    
    if (type) filter.type = type;
    if (category) filter.category = new RegExp(category, 'i');
    if (brand) filter.brand = new RegExp(brand, 'i');
    if (inStock === 'true') filter['stock.isInStock'] = true;
    if (featured === 'true') filter.isFeatured = true;
    
    if (minPrice || maxPrice) {
      filter['price.regular'] = {};
      if (minPrice) filter['price.regular'].$gte = parseFloat(minPrice);
      if (maxPrice) filter['price.regular'].$lte = parseFloat(maxPrice);
    }

    // Handle search
    if (search) {
      filter.$text = { $search: search };
    }

    // Build sort object
    const sort = {};
    if (search) {
      sort.score = { $meta: 'textScore' };
    } else {
      sort[sortBy] = sortOrder === 'desc' ? -1 : 1;
    }

    const options = {
      page: parseInt(page),
      limit: parseInt(limit),
      sort
    };

    const accessories = await Accessory.find(filter)
      .sort(sort)
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .lean();

    const total = await Accessory.countDocuments(filter);

    res.json({
      success: true,
      data: accessories,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching accessories:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching accessories',
      error: error.message
    });
  }
};

// Get accessory by ID
exports.getAccessoryById = async (req, res) => {
  try {
    const accessory = await Accessory.findById(req.params.id);
    
    if (!accessory) {
      return res.status(404).json({
        success: false,
        message: 'Accessory not found'
      });
    }

    // Increment view count
    await accessory.incrementViews();

    // Return as lean object
    const accessoryData = accessory.toObject();

    res.json({
      success: true,
      data: accessoryData
    });
  } catch (error) {
    console.error('Error fetching accessory:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching accessory',
      error: error.message
    });
  }
};

// Create new accessory (Admin only)
exports.createAccessory = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const accessory = new Accessory(req.body);
    await accessory.save();

    res.status(201).json({
      success: true,
      message: 'Accessory created successfully',
      data: accessory
    });
  } catch (error) {
    console.error('Error creating accessory:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating accessory',
      error: error.message
    });
  }
};

// Update accessory (Admin only)
exports.updateAccessory = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const accessory = await Accessory.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!accessory) {
      return res.status(404).json({
        success: false,
        message: 'Accessory not found'
      });
    }

    res.json({
      success: true,
      message: 'Accessory updated successfully',
      data: accessory
    });
  } catch (error) {
    console.error('Error updating accessory:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating accessory',
      error: error.message
    });
  }
};

// Delete accessory (Admin only)
exports.deleteAccessory = async (req, res) => {
  try {
    const accessory = await Accessory.findByIdAndDelete(req.params.id);

    if (!accessory) {
      return res.status(404).json({
        success: false,
        message: 'Accessory not found'
      });
    }

    res.json({
      success: true,
      message: 'Accessory deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting accessory:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting accessory',
      error: error.message
    });
  }
};

// Toggle accessory active status
exports.toggleAccessoryStatus = async (req, res) => {
  try {
    const accessory = await Accessory.findById(req.params.id);

    if (!accessory) {
      return res.status(404).json({
        success: false,
        message: 'Accessory not found'
      });
    }

    accessory.isActive = !accessory.isActive;
    await accessory.save();

    res.json({
      success: true,
      message: `Accessory ${accessory.isActive ? 'activated' : 'deactivated'} successfully`,
      data: accessory
    });
  } catch (error) {
    console.error('Error toggling accessory status:', error);
    res.status(500).json({
      success: false,
      message: 'Error toggling accessory status',
      error: error.message
    });
  }
};

// Update stock
exports.updateStock = async (req, res) => {
  try {
    const { quantity } = req.body;
    const accessory = await Accessory.findById(req.params.id);

    if (!accessory) {
      return res.status(404).json({
        success: false,
        message: 'Accessory not found'
      });
    }

    await accessory.updateStock(quantity);

    res.json({
      success: true,
      message: 'Stock updated successfully',
      data: accessory
    });
  } catch (error) {
    console.error('Error updating stock:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating stock',
      error: error.message
    });
  }
};

// Get accessories by type
exports.getAccessoriesByType = async (req, res) => {
  try {
    const { type } = req.params;
    const { limit = 20 } = req.query;
    
    const accessories = await Accessory.findByType(type, parseInt(limit));

    res.json({
      success: true,
      data: accessories
    });
  } catch (error) {
    console.error('Error fetching accessories by type:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching accessories by type',
      error: error.message
    });
  }
};

// Get featured accessories
exports.getFeaturedAccessories = async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    const accessories = await Accessory.findFeatured(parseInt(limit));

    res.json({
      success: true,
      data: accessories
    });
  } catch (error) {
    console.error('Error fetching featured accessories:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching featured accessories',
      error: error.message
    });
  }
};

// Get accessories in stock
exports.getInStockAccessories = async (req, res) => {
  try {
    const accessories = await Accessory.findInStock();

    res.json({
      success: true,
      data: accessories
    });
  } catch (error) {
    console.error('Error fetching in-stock accessories:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching in-stock accessories',
      error: error.message
    });
  }
};

// Add rating to accessory
exports.addRating = async (req, res) => {
  try {
    const { rating } = req.body;
    
    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5'
      });
    }

    const accessory = await Accessory.findById(req.params.id);

    if (!accessory) {
      return res.status(404).json({
        success: false,
        message: 'Accessory not found'
      });
    }

    await accessory.addRating(rating);

    res.json({
      success: true,
      message: 'Rating added successfully',
      data: accessory
    });
  } catch (error) {
    console.error('Error adding rating:', error);
    res.status(500).json({
      success: false,
      message: 'Error adding rating',
      error: error.message
    });
  }
};

// Get accessory analytics (Admin only)
exports.getAccessoryAnalytics = async (req, res) => {
  try {
    const analytics = await Accessory.aggregate([
      {
        $match: { isActive: true }
      },
      {
        $group: {
          _id: null,
          totalAccessories: { $sum: 1 },
          totalViews: { $sum: '$analytics.viewCount' },
          totalPurchases: { $sum: '$analytics.purchaseCount' },
          avgRating: { $avg: '$analytics.avgRating' },
          totalValue: { $sum: '$price.regular' },
          typeDistribution: {
            $push: '$type'
          },
          stockStatus: {
            $push: {
              inStock: '$stock.isInStock',
              quantity: '$stock.quantity'
            }
          }
        }
      }
    ]);

    res.json({
      success: true,
      data: analytics[0] || {}
    });
  } catch (error) {
    console.error('Error fetching accessory analytics:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching accessory analytics',
      error: error.message
    });
  }
};
