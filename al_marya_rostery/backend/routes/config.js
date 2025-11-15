/**
 * Configuration Routes
 * Provides public configuration values to the frontend
 */

const express = require('express');
const router = express.Router();

/**
 * @route   GET /api/config/stripe
 * @desc    Get Stripe publishable key
 * @access  Public
 */
router.get('/stripe', (req, res) => {
  try {
    // Only send the publishable key (safe to expose)
    // NEVER send the secret key to the frontend
    const publishableKey = process.env.STRIPE_PUBLISHABLE_KEY;

    if (!publishableKey) {
      return res.status(500).json({
        success: false,
        message: 'Stripe configuration not found'
      });
    }

    res.json({
      success: true,
      data: {
        publishableKey
      }
    });
  } catch (error) {
    console.error('Error fetching Stripe config:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch Stripe configuration'
    });
  }
});

module.exports = router;
