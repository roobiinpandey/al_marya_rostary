const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const wishlistController = require('../controllers/wishlistController');

/**
 * Wishlist Routes
 * All routes require authentication
 * IMPORTANT: Specific routes must come before parameterized routes
 */

// Get wishlist count (before /:productId)
router.get('/count', protect, wishlistController.getWishlistCount);

// Check if product is in wishlist (before /:productId)
router.get('/check/:productId', protect, wishlistController.checkWishlist);

// Clear entire wishlist (before /:productId)
router.delete('/clear', protect, wishlistController.clearWishlist);

// Get user's wishlist
router.get('/', protect, wishlistController.getWishlist);

// Add product to wishlist
router.post('/', protect, wishlistController.addToWishlist);

// Remove product from wishlist
router.delete('/:productId', protect, wishlistController.removeFromWishlist);

module.exports = router;
