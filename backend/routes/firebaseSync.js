const express = require('express');
const router = express.Router();
const firebaseUserSyncService = require('../services/firebaseUserSyncService');
const User = require('../models/User');
const admin = require('firebase-admin');

/**
 * Firebase Auth Webhook Controller
 * Handles Firebase Authentication events and user sync operations
 */

/**
 * Firebase Auth Event Webhook
 * POST /api/firebase-sync/webhook
 * Receives Firebase Auth events for real-time synchronization
 */
router.post('/webhook', async (req, res) => {
  try {
    console.log('📱 Received Firebase Auth webhook:', req.body);

    const eventData = req.body;
    const result = await firebaseUserSyncService.handleFirebaseAuthEvent(eventData);

    res.json({
      success: true,
      message: 'Firebase Auth event processed',
      result
    });

  } catch (error) {
    console.error('❌ Firebase Auth webhook error:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to process Firebase Auth event',
      error: error.message
    });
  }
});

/**
 * Sync Single User to Firebase
 * POST /api/firebase-sync/sync-to-firebase/:userId
 */
router.post('/sync-to-firebase/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const result = await firebaseUserSyncService.syncUserToFirebase(user);

    res.json({
      success: result.success,
      message: result.message || result.error,
      data: result
    });

  } catch (error) {
    console.error('❌ Sync to Firebase error:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to sync user to Firebase',
      error: error.message
    });
  }
});

/**
 * Sync Single User from Firebase
 * POST /api/firebase-sync/sync-from-firebase/:firebaseUid
 */
router.post('/sync-from-firebase/:firebaseUid', async (req, res) => {
  try {
    const firebaseUid = req.params.firebaseUid;
    
    // Get Firebase user
    const firebaseUser = await admin.auth().getUser(firebaseUid);
    
    const result = await firebaseUserSyncService.syncUserFromFirebase(firebaseUser);

    res.json({
      success: result.success,
      message: result.message || result.error,
      data: result
    });

  } catch (error) {
    console.error('❌ Sync from Firebase error:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to sync user from Firebase',
      error: error.message
    });
  }
});

/**
 * Bulk Sync All Users to Firebase
 * POST /api/firebase-sync/bulk-sync-to-firebase
 */
router.post('/bulk-sync-to-firebase', async (req, res) => {
  try {
    console.log('🔄 Starting bulk sync to Firebase...');
    const { batchSize = 10 } = req.body;
    
    const result = await firebaseUserSyncService.syncAllUsersToFirebase(null, batchSize);

    res.json({
      success: true,
      message: 'Bulk sync to Firebase completed',
      data: result
    });

  } catch (error) {
    console.error('❌ Bulk sync to Firebase error:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to sync users to Firebase',
      error: error.message
    });
  }
});

/**
 * Bulk Sync All Users to Firebase with Progress Stream
 * GET /api/firebase-sync/bulk-sync-to-firebase/stream
 */
router.get('/bulk-sync-to-firebase/stream', async (req, res) => {
  try {
    // Set up Server-Sent Events
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Cache-Control'
    });

    const { batchSize = 10 } = req.query;

    // Progress callback function
    const progressCallback = (progress) => {
      const data = JSON.stringify({
        type: 'progress',
        data: progress
      });
      res.write(`data: ${data}\n\n`);
    };

    // Send start event
    res.write(`data: ${JSON.stringify({ type: 'start', message: 'Starting bulk sync to Firebase...' })}\n\n`);

    console.log('🔄 Starting streaming bulk sync to Firebase...');
    const result = await firebaseUserSyncService.syncAllUsersToFirebase(progressCallback, parseInt(batchSize));

    // Send completion event
    const completionData = JSON.stringify({
      type: 'complete',
      data: result,
      message: 'Bulk sync to Firebase completed'
    });
    res.write(`data: ${completionData}\n\n`);
    res.end();

  } catch (error) {
    console.error('❌ Streaming bulk sync to Firebase error:', error.message);
    const errorData = JSON.stringify({
      type: 'error',
      error: error.message,
      message: 'Failed to sync users to Firebase'
    });
    res.write(`data: ${errorData}\n\n`);
    res.end();
  }
});

/**
 * Bulk Sync All Users from Firebase
 * POST /api/firebase-sync/bulk-sync-from-firebase
 */
router.post('/bulk-sync-from-firebase', async (req, res) => {
  try {
    console.log('🔄 Starting bulk sync from Firebase...');
    const { batchSize = 15 } = req.body;
    
    const result = await firebaseUserSyncService.syncAllUsersFromFirebase(null, batchSize);

    res.json({
      success: true,
      message: 'Bulk sync from Firebase completed',
      data: result
    });

  } catch (error) {
    console.error('❌ Bulk sync from Firebase error:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to sync users from Firebase',
      error: error.message
    });
  }
});

/**
 * Bulk Sync All Users from Firebase with Progress Stream
 * GET /api/firebase-sync/bulk-sync-from-firebase/stream
 */
router.get('/bulk-sync-from-firebase/stream', async (req, res) => {
  try {
    // Set up Server-Sent Events
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Cache-Control'
    });

    const { batchSize = 15 } = req.query;

    // Progress callback function
    const progressCallback = (progress) => {
      const data = JSON.stringify({
        type: 'progress',
        data: progress
      });
      res.write(`data: ${data}\n\n`);
    };

    // Send start event
    res.write(`data: ${JSON.stringify({ type: 'start', message: 'Starting bulk sync from Firebase...' })}\n\n`);

    console.log('🔄 Starting streaming bulk sync from Firebase...');
    const result = await firebaseUserSyncService.syncAllUsersFromFirebase(progressCallback, parseInt(batchSize));

    // Send completion event
    const completionData = JSON.stringify({
      type: 'complete',
      data: result,
      message: 'Bulk sync from Firebase completed'
    });
    res.write(`data: ${completionData}\n\n`);
    res.end();

  } catch (error) {
    console.error('❌ Streaming bulk sync from Firebase error:', error.message);
    const errorData = JSON.stringify({
      type: 'error',
      error: error.message,
      message: 'Failed to sync users from Firebase'
    });
    res.write(`data: ${errorData}\n\n`);
    res.end();
  }
});

/**
 * Get Sync Status
 * GET /api/firebase-sync/status
 */
router.get('/status', async (req, res) => {
  try {
    const status = await firebaseUserSyncService.getSyncStatus();

    res.json({
      success: true,
      message: 'Sync status retrieved',
      data: status
    });

  } catch (error) {
    console.error('❌ Get sync status error:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to get sync status',
      error: error.message
    });
  }
});

/**
 * Get Users Needing Sync
 * GET /api/firebase-sync/pending-sync
 */
router.get('/pending-sync', async (req, res) => {
  try {
    const users = await User.getNeedingFirebaseSync();

    res.json({
      success: true,
      message: 'Users needing sync retrieved',
      data: users.map(user => ({
        _id: user._id,
        name: user.name,
        email: user.email,
        firebaseUid: user.firebaseUid,
        firebaseSyncStatus: user.firebaseSyncStatus,
        lastFirebaseSync: user.lastFirebaseSync,
        firebaseSyncError: user.firebaseSyncError
      }))
    });

  } catch (error) {
    console.error('❌ Get pending sync error:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to get users needing sync',
      error: error.message
    });
  }
});

/**
 * Delete Firebase User
 * DELETE /api/firebase-sync/firebase-user/:firebaseUid
 */
router.delete('/firebase-user/:firebaseUid', async (req, res) => {
  try {
    const firebaseUid = req.params.firebaseUid;
    
    // Delete from Firebase
    const result = await firebaseUserSyncService.deleteFirebaseUser(firebaseUid);

    if (result.success) {
      // Update local user to remove Firebase connection
      const localUser = await User.findByFirebaseUid(firebaseUid);
      if (localUser) {
        localUser.firebaseUid = null;
        localUser.firebaseSyncStatus = 'manual';
        localUser.firebaseSyncError = null;
        await localUser.save();
      }
    }

    res.json({
      success: result.success,
      message: result.message || result.error,
      data: result
    });

  } catch (error) {
    console.error('❌ Delete Firebase user error:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to delete Firebase user',
      error: error.message
    });
  }
});

/**
 * Manual User Sync Test
 * POST /api/firebase-sync/test-sync
 */
router.post('/test-sync', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required for test sync'
      });
    }

    // Find user by email
    const user = await User.findByEmail(email);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Test sync to Firebase
    const syncResult = await firebaseUserSyncService.syncUserToFirebase(user);

    res.json({
      success: true,
      message: 'Test sync completed',
      data: {
        user: {
          _id: user._id,
          name: user.name,
          email: user.email,
          firebaseUid: user.firebaseUid,
          firebaseSyncStatus: user.firebaseSyncStatus
        },
        syncResult
      }
    });

  } catch (error) {
    console.error('❌ Test sync error:', error.message);
    res.status(500).json({
      success: false,
      message: 'Test sync failed',
      error: error.message
    });
  }
});

/**
 * Get Firebase Users List
 * GET /api/firebase-sync/firebase-users
 */
router.get('/firebase-users', async (req, res) => {
  try {
    const auth = admin.auth();
    const firebaseUsers = [];
    
    // List all Firebase users
    let pageToken;
    do {
      const listUsersResult = await auth.listUsers(100, pageToken); // Limit to 100 per page
      
      for (const user of listUsersResult.users) {
        firebaseUsers.push({
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          phoneNumber: user.phoneNumber,
          emailVerified: user.emailVerified,
          disabled: user.disabled,
          creationTime: user.metadata.creationTime,
          lastSignInTime: user.metadata.lastSignInTime
        });
      }

      pageToken = listUsersResult.pageToken;
    } while (pageToken && firebaseUsers.length < 1000); // Limit total results

    res.json({
      success: true,
      message: 'Firebase users retrieved',
      data: {
        users: firebaseUsers,
        count: firebaseUsers.length
      }
    });

  } catch (error) {
    console.error('❌ Get Firebase users error:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to get Firebase users',
      error: error.message
    });
  }
});

module.exports = router;
