const express = require('express');
const router = express.Router();
const {
  generateSalesReport,
  generateUserReport,
  generateProductReport
} = require('../controllers/reportsController');
const { protect } = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth');

// Apply auth middleware to all routes
router.use(protect);
router.use(adminAuth);

// Report generation routes
router.get('/sales', generateSalesReport);
router.get('/users', generateUserReport);
router.get('/products', generateProductReport);

module.exports = router;
