const express = require('express');
const multer = require('multer');
const path = require('path');
const { body } = require('express-validator');
const {
  getSupportTickets,
  getSupportTicket,
  createSupportTicket,
  updateSupportTicket,
  addTicketMessage,
  assignSupportTicket,
  resolveSupportTicket,
  getSupportTicketStats
} = require('../controllers/supportController');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '../uploads/support'));
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'support-' + uniqueSuffix + path.extname(file.originalname));
  }
});

// File filter to allow common file types
const fileFilter = (req, file, cb) => {
  const allowedTypes = [
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
    'application/pdf', 'text/plain', 'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ];
  
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Unsupported file type. Allowed: images, PDF, DOC, DOCX, TXT'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
    files: 5 // Maximum 5 files
  }
});

// Validation rules
const ticketValidation = [
  body('title')
    .trim()
    .isLength({ min: 5, max: 150 })
    .withMessage('Title must be between 5 and 150 characters'),
  body('description')
    .trim()
    .isLength({ min: 10, max: 1000 })
    .withMessage('Description must be between 10 and 1000 characters'),
  body('category')
    .optional()
    .isIn(['general', 'order-issue', 'payment-problem', 'delivery-issue', 'product-quality', 'account-problem', 'feature-request', 'bug-report', 'other'])
    .withMessage('Invalid category'),
  body('priority')
    .optional()
    .isIn(['low', 'normal', 'high', 'urgent'])
    .withMessage('Invalid priority'),
  body('guestEmail')
    .if(body('guestName').exists())
    .isEmail()
    .withMessage('Valid email is required for guest tickets'),
  body('guestName')
    .if(body('guestEmail').exists())
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Guest name must be between 2 and 100 characters')
];

const messageValidation = [
  body('message')
    .trim()
    .isLength({ min: 1, max: 2000 })
    .withMessage('Message must be between 1 and 2000 characters'),
  body('isInternal')
    .optional()
    .isBoolean()
    .withMessage('isInternal must be a boolean')
];

const updateValidation = [
  body('title')
    .optional()
    .trim()
    .isLength({ min: 5, max: 150 })
    .withMessage('Title must be between 5 and 150 characters'),
  body('category')
    .optional()
    .isIn(['general', 'order-issue', 'payment-problem', 'delivery-issue', 'product-quality', 'account-problem', 'feature-request', 'bug-report', 'other'])
    .withMessage('Invalid category'),
  body('priority')
    .optional()
    .isIn(['low', 'normal', 'high', 'urgent'])
    .withMessage('Invalid priority'),
  body('status')
    .optional()
    .isIn(['open', 'in-progress', 'waiting-customer', 'resolved', 'closed'])
    .withMessage('Invalid status')
];

const assignValidation = [
  body('assignedTo')
    .isMongoId()
    .withMessage('Valid admin ID is required')
];

const resolveValidation = [
  body('summary')
    .trim()
    .isLength({ min: 10, max: 500 })
    .withMessage('Resolution summary must be between 10 and 500 characters'),
  body('feedback')
    .optional()
    .trim()
    .isLength({ max: 1000 })
    .withMessage('Feedback cannot exceed 1000 characters')
];

// Ensure support uploads directory exists
const fs = require('fs');
const supportUploadsDir = path.join(__dirname, '../uploads/support');
if (!fs.existsSync(supportUploadsDir)) {
  fs.mkdirSync(supportUploadsDir, { recursive: true });
}

// Routes
router.get('/stats', getSupportTicketStats);
router.get('/', getSupportTickets);
router.get('/:id', getSupportTicket);
router.post('/', upload.array('attachments', 5), ticketValidation, createSupportTicket);
router.put('/:id', updateValidation, updateSupportTicket);
router.post('/:id/messages', upload.array('attachments', 3), messageValidation, addTicketMessage);
router.post('/:id/assign', assignValidation, assignSupportTicket);
router.post('/:id/resolve', resolveValidation, resolveSupportTicket);

module.exports = router;
