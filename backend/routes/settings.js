const express = require('express');
const router = express.Router();
const {
  getSettings,
  getSetting,
  updateSetting,
  createSetting,
  deleteSetting,
  bulkUpdateSettings,
  initializeDefaults,
  resetToDefaults
} = require('../controllers/settingsController');
const { protect } = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth');

// Apply auth middleware to all routes
router.use(protect);
router.use(adminAuth);

// Settings management routes
router.get('/', getSettings);
router.post('/', createSetting);
router.post('/initialize', initializeDefaults);
router.post('/reset', resetToDefaults);
router.put('/bulk', bulkUpdateSettings);

router.get('/:key', getSetting);
router.put('/:key', updateSetting);
router.delete('/:key', deleteSetting);

module.exports = router;
