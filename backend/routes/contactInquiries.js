const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const contactInquiryController = require('../controllers/contactInquiryController');
const { protect, authorize } = require('../middleware/auth');

// Validation middleware
const validateContactInquiry = [
  body('contactInfo.name').notEmpty().withMessage('Name is required').isLength({ max: 100 }).withMessage('Name cannot exceed 100 characters'),
  body('contactInfo.email').isEmail().withMessage('Valid email is required'),
  body('contactInfo.phone').optional().matches(/^[\+]?[1-9][\d]{0,15}$/).withMessage('Invalid phone number format'),
  body('inquiry.type').isIn([
    'general', 'product-inquiry', 'bulk-order', 'partnership', 'complaint', 
    'feedback', 'technical-support', 'wholesale', 'franchise', 'catering',
    'corporate-gifts', 'return-refund', 'other'
  ]).withMessage('Invalid inquiry type'),
  body('inquiry.subject').notEmpty().withMessage('Subject is required').isLength({ max: 200 }).withMessage('Subject cannot exceed 200 characters'),
  body('inquiry.message').notEmpty().withMessage('Message is required').isLength({ max: 2000 }).withMessage('Message cannot exceed 2000 characters'),
  body('inquiry.priority').optional().isIn(['low', 'medium', 'high', 'urgent']).withMessage('Invalid priority level')
];

const validateResponse = [
  body('message').notEmpty().withMessage('Response message is required').isLength({ max: 2000 }).withMessage('Message cannot exceed 2000 characters'),
  body('isInternal').optional().isBoolean().withMessage('isInternal must be boolean')
];

const validateStatusUpdate = [
  body('status').isIn(['new', 'in-progress', 'pending-info', 'resolved', 'closed', 'escalated']).withMessage('Invalid status'),
  body('note').optional().isLength({ max: 500 }).withMessage('Note cannot exceed 500 characters')
];

const validateAssignment = [
  body('assignedTo').notEmpty().withMessage('Assigned user ID is required'),
  body('department').optional().isIn(['customer-service', 'sales', 'technical', 'management', 'warehouse']).withMessage('Invalid department')
];

const validateSatisfactionRating = [
  body('rating').isInt({ min: 1, max: 5 }).withMessage('Rating must be between 1 and 5'),
  body('feedback').optional().isLength({ max: 500 }).withMessage('Feedback cannot exceed 500 characters')
];

// Public routes
router.post('/', validateContactInquiry, contactInquiryController.createContactInquiry);
router.put('/:id/satisfaction', validateSatisfactionRating, contactInquiryController.setSatisfactionRating);

// User routes (require authentication)
router.get('/my-inquiries', protect, contactInquiryController.getMyInquiries);

// Admin routes (require authentication and admin role)
router.get('/', protect, authorize('admin'), contactInquiryController.getAllContactInquiries);
router.get('/status/:status', protect, authorize('admin'), contactInquiryController.getInquiriesByStatus);
router.get('/department/:department', protect, authorize('admin'), contactInquiryController.getInquiriesByDepartment);
router.get('/priority/:priority', protect, authorize('admin'), contactInquiryController.getInquiriesByPriority);
router.get('/overdue', protect, authorize('admin'), contactInquiryController.getOverdueInquiries);
router.get('/analytics', protect, authorize('admin'), contactInquiryController.getContactAnalytics);
router.get('/:id', protect, authorize('admin'), contactInquiryController.getContactInquiryById);

router.put('/:id/status', protect, authorize('admin'), validateStatusUpdate, contactInquiryController.updateInquiryStatus);
router.put('/:id/assign', protect, authorize('admin'), validateAssignment, contactInquiryController.assignInquiry);
router.post('/:id/response', protect, authorize('admin'), validateResponse, contactInquiryController.addResponse);
router.post('/:id/internal-note', protect, authorize('admin'), [
  body('note').notEmpty().withMessage('Note is required').isLength({ max: 1000 }).withMessage('Note cannot exceed 1000 characters')
], contactInquiryController.addInternalNote);

router.delete('/:id', protect, authorize('admin'), contactInquiryController.deleteContactInquiry);

module.exports = router;
