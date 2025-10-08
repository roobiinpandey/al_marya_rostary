const express = require('express');
const { body } = require('express-validator');
const {
  getNewsletters,
  getNewsletter,
  createNewsletter,
  updateNewsletter,
  deleteNewsletter,
  sendNewsletter,
  sendTestNewsletter,
  getNewsletterStats,
  getReadyToSend
} = require('../controllers/newsletterController');

const router = express.Router();

// Validation rules
const newsletterValidation = [
  body('title')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Title must be between 2 and 100 characters'),
  body('subject')
    .trim()
    .isLength({ min: 2, max: 150 })
    .withMessage('Subject must be between 2 and 150 characters'),
  body('htmlContent')
    .trim()
    .isLength({ min: 10 })
    .withMessage('HTML content must be at least 10 characters'),
  body('scheduledDate')
    .optional()
    .isISO8601()
    .withMessage('Scheduled date must be a valid date'),
  body('campaignType')
    .optional()
    .isIn(['newsletter', 'promotional', 'transactional', 'announcement'])
    .withMessage('Invalid campaign type'),
  body('priority')
    .optional()
    .isIn(['low', 'normal', 'high'])
    .withMessage('Invalid priority level')
];

const testEmailValidation = [
  body('testEmails')
    .isArray({ min: 1 })
    .withMessage('At least one test email is required'),
  body('testEmails.*')
    .isEmail()
    .withMessage('All test emails must be valid email addresses')
];

// Routes
router.get('/stats', getNewsletterStats);
router.get('/ready-to-send', getReadyToSend);
router.get('/', getNewsletters);
router.get('/:id', getNewsletter);
router.post('/', newsletterValidation, createNewsletter);
router.put('/:id', newsletterValidation, updateNewsletter);
router.delete('/:id', deleteNewsletter);
router.post('/:id/send', sendNewsletter);
router.post('/:id/test', testEmailValidation, sendTestNewsletter);

module.exports = router;
