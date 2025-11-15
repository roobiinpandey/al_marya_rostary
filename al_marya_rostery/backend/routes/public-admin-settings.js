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
} = require('../controllers/publicAdminSettingsController');
const { protect } = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth');

// Apply authentication to all admin settings routes
router.use(protect);
router.use(adminAuth);

// Special routes first (before /:key which would catch everything)
router.put('/bulk', bulkUpdateSettings);
router.post('/initialize', initializeDefaults);
router.post('/reset', resetToDefaults);

// General routes
router.get('/', getSettings);
router.post('/', createSetting);

// Specific key routes last
router.get('/:key', getSetting);
router.put('/:key', updateSetting);
router.delete('/:key', deleteSetting);

module.exports = router;
