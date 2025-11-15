const Wishlist = require('../models/Wishlist');
const Coffee = require('../models/Coffee');
const Accessory = require('../models/Accessory');
const GiftSet = require('../models/GiftSet');

/**
 * Get user's wishlist with populated product details
 */
exports.getWishlist = async (req, res) => {
  try {
    const userId = req.user._id;

    const wishlist = await Wishlist.getOrCreate(userId);

    // Populate products based on type
    const populatedItems = [];

    for (const item of wishlist.items) {
      let product = null;

      switch (item.productType) {
        case 'Coffee':
          product = await Coffee.findById(item.productId)
            .select('name description price images roastLevel origin isActive')
            .lean();
          break;
        case 'Accessory':
          product = await Accessory.findById(item.productId)
            .select('name description price primaryImageUrl category type isActive stock')
            .lean();
          break;
        case 'GiftSet':
          product = await GiftSet.findById(item.productId)
            .select('name description price images contents isActive')
            .lean();
          break;
      }

      if (product && product.isActive) {
        populatedItems.push({
          ...product,
          _id: item.productId,
          productType: item.productType,
          addedAt: item.addedAt,
        });
      }
    }

    res.json({
      success: true,
      data: populatedItems,
      count: populatedItems.length,
    });
  } catch (error) {
    console.error('❌ Error getting wishlist:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get wishlist',
      error: error.message,
    });
  }
};

/**
 * Add product to wishlist
 */
exports.addToWishlist = async (req, res) => {
  try {
    const userId = req.user._id;
    const { productId, productType } = req.body;

    if (!productId || !productType) {
      return res.status(400).json({
        success: false,
        message: 'Product ID and type are required',
      });
    }

    // Validate product type
    if (!['Coffee', 'Accessory', 'GiftSet'].includes(productType)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid product type',
      });
    }

    // Verify product exists
    let productExists = false;
    switch (productType) {
      case 'Coffee':
        productExists = await Coffee.exists({ _id: productId, isActive: true });
        break;
      case 'Accessory':
        productExists = await Accessory.exists({ _id: productId, isActive: true });
        break;
      case 'GiftSet':
        productExists = await GiftSet.exists({ _id: productId, isActive: true });
        break;
    }

    if (!productExists) {
      return res.status(404).json({
        success: false,
        message: 'Product not found',
      });
    }

    const wishlist = await Wishlist.getOrCreate(userId);
    await wishlist.addItem(productId, productType);

    res.status(201).json({
      success: true,
      message: 'Added to wishlist',
      data: {
        count: wishlist.getCount(),
      },
    });
  } catch (error) {
    console.error('❌ Error adding to wishlist:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add to wishlist',
      error: error.message,
    });
  }
};

/**
 * Remove product from wishlist
 */
exports.removeFromWishlist = async (req, res) => {
  try {
    const userId = req.user._id;
    const { productId } = req.params;

    if (!productId) {
      return res.status(400).json({
        success: false,
        message: 'Product ID is required',
      });
    }

    const wishlist = await Wishlist.getOrCreate(userId);
    await wishlist.removeItem(productId);

    res.json({
      success: true,
      message: 'Removed from wishlist',
      data: {
        count: wishlist.getCount(),
      },
    });
  } catch (error) {
    console.error('❌ Error removing from wishlist:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to remove from wishlist',
      error: error.message,
    });
  }
};

/**
 * Check if product is in wishlist
 */
exports.checkWishlist = async (req, res) => {
  try {
    const userId = req.user._id;
    const { productId } = req.params;

    const wishlist = await Wishlist.getOrCreate(userId);
    const inWishlist = wishlist.hasItem(productId);

    res.json({
      success: true,
      data: {
        inWishlist,
        productId,
      },
    });
  } catch (error) {
    console.error('❌ Error checking wishlist:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to check wishlist',
      error: error.message,
    });
  }
};

/**
 * Get wishlist count
 */
exports.getWishlistCount = async (req, res) => {
  try {
    const userId = req.user._id;

    const wishlist = await Wishlist.getOrCreate(userId);

    res.json({
      success: true,
      data: {
        count: wishlist.getCount(),
      },
    });
  } catch (error) {
    console.error('❌ Error getting wishlist count:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get wishlist count',
      error: error.message,
    });
  }
};

/**
 * Clear wishlist
 */
exports.clearWishlist = async (req, res) => {
  try {
    const userId = req.user._id;

    const wishlist = await Wishlist.getOrCreate(userId);
    await wishlist.clearAll();

    res.json({
      success: true,
      message: 'Wishlist cleared',
      data: {
        count: 0,
      },
    });
  } catch (error) {
    console.error('❌ Error clearing wishlist:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to clear wishlist',
      error: error.message,
    });
  }
};
