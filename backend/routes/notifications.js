const express = require('express');
const multer = require('multer');
const path = require('path');
const { body } = require('express-validator');
const {
  getNotifications,
  getNotification,
  createNotification,
  updateNotification,
  deleteNotification,
  sendNotification,
  sendTestNotification,
  getNotificationStats,
  getReadyToSend
} = require('../controllers/notificationController');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '../uploads'));
  },
  filename: (req, file, cb) => {
    // Generate unique filename with timestamp
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'notification-' + uniqueSuffix + path.extname(file.originalname));
  }
});

// File filter to allow only images
const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed!'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  }
});

// Validation rules
const notificationValidation = [
  body('title')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Title must be between 2 and 100 characters'),
  body('message')
    .trim()
    .isLength({ min: 2, max: 500 })
    .withMessage('Message must be between 2 and 500 characters'),
  body('type')
    .optional()
    .isIn(['info', 'success', 'warning', 'error', 'promotion', 'update', 'reminder'])
    .withMessage('Invalid notification type'),
  body('priority')
    .optional()
    .isIn(['low', 'normal', 'high', 'urgent'])
    .withMessage('Invalid priority level'),
  body('scheduledDate')
    .optional()
    .isISO8601()
    .withMessage('Scheduled date must be a valid date'),
  body('actionButton.text')
    .optional()
    .isLength({ max: 50 })
    .withMessage('Button text cannot be more than 50 characters'),
  body('actionButton.link')
    .optional()
    .isURL()
    .withMessage('Button link must be a valid URL')
];

// Routes
router.get('/stats', getNotificationStats);
router.get('/ready-to-send', getReadyToSend);
router.post('/test', sendTestNotification);
router.get('/', getNotifications);
router.get('/:id', getNotification);
router.post('/', upload.single('image'), notificationValidation, createNotification);
router.put('/:id', upload.single('image'), notificationValidation, updateNotification);
router.delete('/:id', deleteNotification);
router.post('/:id/send', sendNotification);

module.exports = router;
