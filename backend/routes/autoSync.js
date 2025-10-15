const express = require('express');
const router = express.Router();
const autoFirebaseSync = require('../services/autoFirebaseSync');

/**
 * Auto Firebase Sync Management Routes
 */

/**
 * Start automatic sync service
 * POST /api/auto-sync/start
 */
router.post('/start', async (req, res) => {
  try {
    autoFirebaseSync.start();
    
    res.json({
      success: true,
      message: 'Automatic Firebase sync started',
      status: autoFirebaseSync.getStatus()
    });
  } catch (error) {
    console.error('❌ Error starting auto sync:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to start automatic sync',
      error: error.message
    });
  }
});

/**
 * Stop automatic sync service
 * POST /api/auto-sync/stop
 */
router.post('/stop', async (req, res) => {
  try {
    autoFirebaseSync.stop();
    
    res.json({
      success: true,
      message: 'Automatic Firebase sync stopped',
      status: autoFirebaseSync.getStatus()
    });
  } catch (error) {
    console.error('❌ Error stopping auto sync:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to stop automatic sync',
      error: error.message
    });
  }
});

/**
 * Get auto sync status
 * GET /api/auto-sync/status
 */
router.get('/status', (req, res) => {
  try {
    const status = autoFirebaseSync.getStatus();
    
    res.json({
      success: true,
      message: 'Auto sync status retrieved',
      data: status
    });
  } catch (error) {
    console.error('❌ Error getting auto sync status:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to get auto sync status',
      error: error.message
    });
  }
});

/**
 * Force immediate sync
 * POST /api/auto-sync/force-sync
 */
router.post('/force-sync', async (req, res) => {
  try {
    await autoFirebaseSync.forceSyncNow();
    
    res.json({
      success: true,
      message: 'Immediate sync completed',
      status: autoFirebaseSync.getStatus()
    });
  } catch (error) {
    console.error('❌ Error forcing sync:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to force immediate sync',
      error: error.message
    });
  }
});

/**
 * Update sync interval
 * PUT /api/auto-sync/interval
 */
router.put('/interval', (req, res) => {
  try {
    const { intervalMs } = req.body;
    
    if (!intervalMs || intervalMs < 10000) { // Minimum 10 seconds
      return res.status(400).json({
        success: false,
        message: 'Interval must be at least 10000ms (10 seconds)'
      });
    }
    
    autoFirebaseSync.updateInterval(intervalMs);
    
    res.json({
      success: true,
      message: 'Sync interval updated',
      status: autoFirebaseSync.getStatus()
    });
  } catch (error) {
    console.error('❌ Error updating sync interval:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to update sync interval',
      error: error.message
    });
  }
});

/**
 * Firebase Auth webhook for real-time sync
 * POST /api/auto-sync/webhook
 */
router.post('/webhook', async (req, res) => {
  try {
    const { eventType, uid, email } = req.body;
    
    console.log(`📱 Firebase Auth webhook: ${eventType} for ${email || uid}`);
    
    let result;
    
    switch (eventType) {
      case 'user.create':
        result = await autoFirebaseSync.syncFirebaseUserImmediately(uid);
        break;
        
      case 'user.update':
        result = await autoFirebaseSync.syncFirebaseUserImmediately(uid);
        break;
        
      case 'user.delete':
        result = await autoFirebaseSync.handleFirebaseUserDeletion(uid);
        break;
        
      default:
        console.warn(`⚠️ Unhandled webhook event type: ${eventType}`);
        result = {
          success: false,
          error: `Unhandled event type: ${eventType}`
        };
    }
    
    res.json({
      success: result.success,
      message: result.message || result.error,
      eventType,
      result
    });
    
  } catch (error) {
    console.error('❌ Webhook error:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to process webhook',
      error: error.message
    });
  }
});

module.exports = router;
