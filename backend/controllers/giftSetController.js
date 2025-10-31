const GiftSet = require('../models/GiftSet');
const { validationResult } = require('express-validator');
const { serialize } = require('../middleware/jsonSerializer');

// Get all gift sets with filtering and pagination
exports.getAllGiftSets = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      occasion,
      targetAudience,
      minPrice,
      maxPrice,
      featured,
      popular,
      available,
      search,
      sortBy = 'displayOrder',
      sortOrder = 'asc'
    } = req.query;

    // Build filter object
    const filter = { isActive: true };
    
    if (occasion) filter.occasion = occasion;
    if (targetAudience) filter.targetAudience = targetAudience;
    if (featured === 'true') filter.isFeatured = true;
    if (popular === 'true') filter.isPopular = true;
    if (available === 'true') filter['availability.isAvailable'] = true;
    
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

    const giftSets = await GiftSet.find(filter)
      .sort(sort)
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .lean(); // Add .lean() for better performance

    // Add virtual properties manually since we're using .lean()
    const processedGiftSets = giftSets.map(giftSet => {
      // Calculate discount percentage
      const salePrice = giftSet.price?.sale;
      const regularPrice = giftSet.price?.regular;
      let discountPercentage = 0;
      if (salePrice && salePrice < regularPrice) {
        discountPercentage = Math.round(((regularPrice - salePrice) / regularPrice) * 100);
      }

      // Calculate availability status
      let availabilityStatus = 'Available';
      if (!giftSet.availability?.isAvailable) {
        availabilityStatus = 'Unavailable';
      } else {
        const now = new Date();
        const seasonal = giftSet.availability?.seasonalAvailability;
        
        if (seasonal && seasonal.startDate && seasonal.endDate) {
          if (now < seasonal.startDate || now > seasonal.endDate) {
            availabilityStatus = 'Seasonal - Not Available';
          }
        }
        
        const limited = giftSet.availability?.limitedQuantity;
        if (limited && limited.remaining <= 0) {
          availabilityStatus = 'Sold Out';
        } else if (limited && limited.remaining <= 5) {
          availabilityStatus = `Limited - ${limited.remaining} left`;
        }
      }

      // Calculate total items
      const totalItems = giftSet.contents?.reduce((total, item) => total + (item.quantity || 1), 0) || 0;

      return {
        ...giftSet,
        discountPercentage,
        availabilityStatus,
        totalItems
      };
    });

    const total = await GiftSet.countDocuments(filter);

    res.json({
      success: true,
      data: serialize(processedGiftSets), // Serialize the data to handle ObjectIds
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching gift sets:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching gift sets',
      error: error.message
    });
  }
};

// Get gift set by ID
exports.getGiftSetById = async (req, res) => {
  try {
    const giftSet = await GiftSet.findById(req.params.id)
      .populate('reviews.userId', 'name email')
      .lean();
    
    if (!giftSet) {
      return res.status(404).json({
        success: false,
        message: 'Gift set not found'
      });
    }

    // Increment view count (need to do this separately since we used .lean())
    await GiftSet.findByIdAndUpdate(req.params.id, { $inc: { 'analytics.viewCount': 1 } });

    res.json({
      success: true,
      data: serialize(giftSet)
    });
  } catch (error) {
    console.error('Error fetching gift set:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching gift set',
      error: error.message
    });
  }
};

// Create new gift set (Admin only)
exports.createGiftSet = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const giftSet = new GiftSet(req.body);
    await giftSet.save();

    res.status(201).json({
      success: true,
      message: 'Gift set created successfully',
      data: giftSet
    });
  } catch (error) {
    console.error('Error creating gift set:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating gift set',
      error: error.message
    });
  }
};

// Update gift set (Admin only)
exports.updateGiftSet = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const giftSet = await GiftSet.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!giftSet) {
      return res.status(404).json({
        success: false,
        message: 'Gift set not found'
      });
    }

    res.json({
      success: true,
      message: 'Gift set updated successfully',
      data: giftSet
    });
  } catch (error) {
    console.error('Error updating gift set:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating gift set',
      error: error.message
    });
  }
};

// Delete gift set (Admin only)
exports.deleteGiftSet = async (req, res) => {
  try {
    const giftSet = await GiftSet.findByIdAndDelete(req.params.id);

    if (!giftSet) {
      return res.status(404).json({
        success: false,
        message: 'Gift set not found'
      });
    }

    res.json({
      success: true,
      message: 'Gift set deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting gift set:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting gift set',
      error: error.message
    });
  }
};

// Toggle gift set active status
exports.toggleGiftSetStatus = async (req, res) => {
  try {
    const giftSet = await GiftSet.findById(req.params.id);

    if (!giftSet) {
      return res.status(404).json({
        success: false,
        message: 'Gift set not found'
      });
    }

    giftSet.isActive = !giftSet.isActive;
    await giftSet.save();

    res.json({
      success: true,
      message: `Gift set ${giftSet.isActive ? 'activated' : 'deactivated'} successfully`,
      data: giftSet
    });
  } catch (error) {
    console.error('Error toggling gift set status:', error);
    res.status(500).json({
      success: false,
      message: 'Error toggling gift set status',
      error: error.message
    });
  }
};

// Get gift sets by occasion
exports.getGiftSetsByOccasion = async (req, res) => {
  try {
    const { occasion } = req.params;
    const { limit = 20 } = req.query;
    
    const giftSets = await GiftSet.findByOccasion(occasion, parseInt(limit)).lean();

    res.json({
      success: true,
      data: serialize(giftSets)
    });
  } catch (error) {
    console.error('Error fetching gift sets by occasion:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching gift sets by occasion',
      error: error.message
    });
  }
};

// Get gift sets by target audience
exports.getGiftSetsByAudience = async (req, res) => {
  try {
    const { audience } = req.params;
    const { limit = 20 } = req.query;
    
    const giftSets = await GiftSet.findByTargetAudience(audience, parseInt(limit)).lean();

    res.json({
      success: true,
      data: serialize(giftSets)
    });
  } catch (error) {
    console.error('Error fetching gift sets by audience:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching gift sets by audience',
      error: error.message
    });
  }
};

// Get featured gift sets
exports.getFeaturedGiftSets = async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    const giftSets = await GiftSet.findFeatured(parseInt(limit)).lean();

    res.json({
      success: true,
      data: serialize(giftSets)
    });
  } catch (error) {
    console.error('Error fetching featured gift sets:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching featured gift sets',
      error: error.message
    });
  }
};

// Get popular gift sets
exports.getPopularGiftSets = async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    const giftSets = await GiftSet.findPopular(parseInt(limit)).lean();

    res.json({
      success: true,
      data: serialize(giftSets)
    });
  } catch (error) {
    console.error('Error fetching popular gift sets:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching popular gift sets',
      error: error.message
    });
  }
};

// Get gift sets by price range
exports.getGiftSetsByPriceRange = async (req, res) => {
  try {
    const { minPrice, maxPrice } = req.query;
    
    if (!minPrice || !maxPrice) {
      return res.status(400).json({
        success: false,
        message: 'Both minPrice and maxPrice are required'
      });
    }

    const giftSets = await GiftSet.findByPriceRange(
      parseFloat(minPrice), 
      parseFloat(maxPrice)
    );

    res.json({
      success: true,
      data: giftSets
    });
  } catch (error) {
    console.error('Error fetching gift sets by price range:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching gift sets by price range',
      error: error.message
    });
  }
};

// Add review to gift set
exports.addReview = async (req, res) => {
  try {
    const { rating, comment, occasion, recipientType, wouldRecommend } = req.body;
    
    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5'
      });
    }

    const giftSet = await GiftSet.findById(req.params.id);

    if (!giftSet) {
      return res.status(404).json({
        success: false,
        message: 'Gift set not found'
      });
    }

    const reviewData = {
      userId: req.user?.id,
      rating,
      comment,
      occasion,
      recipientType,
      wouldRecommend
    };

    await giftSet.addReview(reviewData);

    res.json({
      success: true,
      message: 'Review added successfully',
      data: giftSet
    });
  } catch (error) {
    console.error('Error adding review:', error);
    res.status(500).json({
      success: false,
      message: 'Error adding review',
      error: error.message
    });
  }
};

// Update limited quantity
exports.updateLimitedQuantity = async (req, res) => {
  try {
    const { quantity } = req.body;
    const giftSet = await GiftSet.findById(req.params.id);

    if (!giftSet) {
      return res.status(404).json({
        success: false,
        message: 'Gift set not found'
      });
    }

    await giftSet.updateLimitedQuantity(quantity);

    res.json({
      success: true,
      message: 'Limited quantity updated successfully',
      data: giftSet
    });
  } catch (error) {
    console.error('Error updating limited quantity:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating limited quantity',
      error: error.message
    });
  }
};

// Get gift set analytics (Admin only)
exports.getGiftSetAnalytics = async (req, res) => {
  try {
    const analytics = await GiftSet.aggregate([
      {
        $match: { isActive: true }
      },
      {
        $group: {
          _id: null,
          totalGiftSets: { $sum: 1 },
          totalViews: { $sum: '$analytics.viewCount' },
          totalPurchases: { $sum: '$analytics.purchaseCount' },
          avgRating: { $avg: '$analytics.avgRating' },
          avgConversionRate: { $avg: '$analytics.conversionRate' },
          totalValue: { $sum: '$price.regular' },
          occasionDistribution: {
            $push: '$occasion'
          },
          audienceDistribution: {
            $push: '$targetAudience'
          }
        }
      }
    ]);

    res.json({
      success: true,
      data: analytics[0] || {}
    });
  } catch (error) {
    console.error('Error fetching gift set analytics:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching gift set analytics',
      error: error.message
    });
  }
};
