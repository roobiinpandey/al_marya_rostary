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

// Public admin settings routes (no auth required for local development)
// These routes should be secured in production

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
