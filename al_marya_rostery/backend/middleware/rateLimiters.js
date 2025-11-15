/**
 * Rate Limiting Middleware
 * Provides specialized rate limiters for different endpoint types
 * 
 * Usage:
 * const { orderLimiter, subscriptionLimiter } = require('../middleware/rateLimiters');
 * router.post('/orders', protect, orderLimiter, createOrder);
 */

const rateLimit = require('express-rate-limit');
const logger = require('../utils/logger');

/**
 * Create a custom rate limiter with logging
 */
const createRateLimiter = (options) => {
  const {
    windowMs,
    max,
    message,
    keyGenerator,
    handler
  } = options;

  return rateLimit({
    windowMs,
    max,
    standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
    legacyHeaders: false, // Disable the `X-RateLimit-*` headers
    
    // Custom key generator (default: IP address)
    keyGenerator: keyGenerator || ((req) => {
      // Use user ID if authenticated, otherwise IP
      return req.user?.userId || req.ip;
    }),
    
    // Custom handler when rate limit is exceeded
    handler: handler || ((req, res) => {
      const identifier = req.user?.userId || req.ip;
      
      logger.security('Rate limit exceeded', {
        identifier,
        endpoint: req.originalUrl,
        method: req.method,
        userAgent: req.get('User-Agent')
      });
      
      res.status(429).json({
        success: false,
        message: message || 'Too many requests. Please try again later.',
        retryAfter: Math.ceil(windowMs / 1000) // seconds
      });
    }),
    
    // Skip successful requests (only count failures)
    skip: (req) => {
      // Skip rate limiting for admin users
      return req.user?.roles?.includes('admin');
    }
  });
};

/**
 * Order creation rate limiter
 * Prevents abuse of order creation endpoint
 */
const orderLimiter = createRateLimiter({
  windowMs: 60 * 1000, // 1 minute
  max: 10, // 10 orders per minute per user/IP
  message: 'Too many orders created. Please wait before placing another order.'
});

/**
 * Subscription rate limiter
 * Prevents abuse of subscription creation/modification
 */
const subscriptionLimiter = createRateLimiter({
  windowMs: 60 * 1000, // 1 minute
  max: 5, // 5 subscription operations per minute
  message: 'Too many subscription requests. Please wait before trying again.'
});

/**
 * Payment rate limiter
 * Stricter limits for payment operations
 */
const paymentLimiter = createRateLimiter({
  windowMs: 60 * 1000, // 1 minute
  max: 3, // 3 payment attempts per minute
  message: 'Too many payment attempts. Please wait before trying again.'
});

/**
 * Review rate limiter
 * Prevents review spam
 */
const reviewLimiter = createRateLimiter({
  windowMs: 60 * 1000, // 1 minute
  max: 5, // 5 reviews per minute
  message: 'Too many reviews submitted. Please wait before submitting another review.'
});

/**
 * File upload rate limiter
 * Prevents excessive file uploads
 */
const uploadLimiter = createRateLimiter({
  windowMs: 60 * 1000, // 1 minute
  max: 10, // 10 uploads per minute
  message: 'Too many file uploads. Please wait before uploading more files.'
});

/**
 * Search rate limiter
 * Prevents search API abuse
 */
const searchLimiter = createRateLimiter({
  windowMs: 60 * 1000, // 1 minute
  max: 30, // 30 searches per minute
  message: 'Too many search requests. Please wait before searching again.'
});

/**
 * Email rate limiter
 * Prevents email spam (contact forms, etc.)
 */
const emailLimiter = createRateLimiter({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5, // 5 emails per hour per IP
  message: 'Too many emails sent. Please try again later.'
});

/**
 * Generic API rate limiter
 * Default limiter for general API endpoints
 */
const apiLimiter = createRateLimiter({
  windowMs: 60 * 1000, // 1 minute
  max: 100, // 100 requests per minute
  message: 'Too many API requests. Please slow down.'
});

/**
 * Strict rate limiter for sensitive operations
 * Used for password reset, account deletion, etc.
 */
const strictLimiter = createRateLimiter({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 3, // Only 3 attempts per hour
  message: 'Too many attempts. For security, please try again later.'
});

/**
 * Rate limiter for webhook endpoints
 * Higher limits for trusted external services
 */
const webhookLimiter = createRateLimiter({
  windowMs: 60 * 1000, // 1 minute
  max: 1000, // 1000 webhooks per minute (very high for Stripe/payment providers)
  message: 'Webhook rate limit exceeded.'
});

/**
 * Export middleware function to apply all rate limiters at once
 */
const applyRateLimiters = (app) => {
  // General API rate limiting
  app.use('/api/', apiLimiter);
  
  logger.info('Rate limiters initialized', {
    limiters: [
      'orderLimiter',
      'subscriptionLimiter',
      'paymentLimiter',
      'reviewLimiter',
      'uploadLimiter',
      'searchLimiter',
      'emailLimiter',
      'strictLimiter',
      'webhookLimiter'
    ]
  });
};

module.exports = {
  orderLimiter,
  subscriptionLimiter,
  paymentLimiter,
  reviewLimiter,
  uploadLimiter,
  searchLimiter,
  emailLimiter,
  apiLimiter,
  strictLimiter,
  webhookLimiter,
  applyRateLimiters,
  createRateLimiter // Export for custom rate limiters
};
