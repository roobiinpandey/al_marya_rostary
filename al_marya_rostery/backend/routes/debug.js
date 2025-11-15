const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const User = require('../models/User');

/**
 * Debug endpoint to compare Firebase vs Local user counts
 * GET /api/debug/user-counts
 */
router.get('/user-counts', async (req, res) => {
  try {
    // Get Firebase user count
    const auth = admin.auth();
    let totalFirebaseUsers = 0;
    const firebaseUsers = [];
    
    let pageToken;
    do {
      const listUsersResult = await auth.listUsers(1000, pageToken);
      for (const user of listUsersResult.users) {
        totalFirebaseUsers++;
        firebaseUsers.push({
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          disabled: user.disabled,
          emailVerified: user.emailVerified
        });
      }
      pageToken = listUsersResult.pageToken;
    } while (pageToken);

    // Get local MongoDB user count
    const totalLocalUsers = await User.countDocuments();
    const localUsers = await User.find({}, 'email name firebaseUid isActive').limit(20);

    // Get sync status
    const linkedUsers = await User.countDocuments({ firebaseUid: { $exists: true, $ne: null } });
    const syncedUsers = await User.countDocuments({ firebaseSyncStatus: 'synced' });

    res.json({
      success: true,
      data: {
        counts: {
          firebase: totalFirebaseUsers,
          local: totalLocalUsers,
          linked: linkedUsers,
          synced: syncedUsers
        },
        samples: {
          firebaseUsers: firebaseUsers.slice(0, 10), // First 10 Firebase users
          localUsers: localUsers.slice(0, 10) // First 10 local users
        },
        analysis: {
          difference: totalFirebaseUsers - totalLocalUsers,
          syncPercentage: totalLocalUsers > 0 ? ((linkedUsers / totalLocalUsers) * 100).toFixed(1) : 0
        }
      }
    });

  } catch (error) {
    console.error('❌ Debug user counts error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Debug endpoint to fix duplicate firebaseUid: null issue
 * POST /api/debug/fix-duplicate-firebase-uid
 */
router.post('/fix-duplicate-firebase-uid', async (req, res) => {
  try {
    console.log('🔧 Starting duplicate firebaseUid fix...');
    
    // Find all users with firebaseUid: null
    const usersWithNullFirebaseUid = await User.find({ 
      $or: [
        { firebaseUid: null },
        { firebaseUid: { $exists: false } }
      ]
    });
    
    console.log(`📊 Found ${usersWithNullFirebaseUid.length} users with null/missing firebaseUid`);
    
    // Remove the firebaseUid field entirely from these users (instead of setting to null)
    let fixedCount = 0;
    for (const user of usersWithNullFirebaseUid) {
      await User.updateOne(
        { _id: user._id },
        { $unset: { firebaseUid: "" } }
      );
      fixedCount++;
    }
    
    console.log(`✅ Fixed ${fixedCount} users by removing null firebaseUid fields`);
    
    res.json({
      success: true,
      message: 'Fixed duplicate firebaseUid issue',
      data: {
        usersFound: usersWithNullFirebaseUid.length,
        usersFixed: fixedCount,
        details: usersWithNullFirebaseUid.map(u => ({
          id: u._id,
          email: u.email,
          name: u.name
        }))
      }
    });

  } catch (error) {
    console.error('❌ Fix duplicate firebaseUid error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Debug endpoint to check for problematic users
 * GET /api/debug/problematic-users
 */
router.get('/problematic-users', async (req, res) => {
  try {
    // Check for users with issues
    const duplicateFirebaseUids = await User.aggregate([
      { $match: { firebaseUid: { $ne: null } } },
      { $group: { _id: "$firebaseUid", count: { $sum: 1 }, users: { $push: "$$ROOT" } } },
      { $match: { count: { $gt: 1 } } }
    ]);
    
    const nullFirebaseUids = await User.find({ 
      $or: [
        { firebaseUid: null },
        { firebaseUid: { $exists: false } }
      ]
    }, 'email name firebaseUid').limit(10);
    
    const guestUsers = await User.find({ 
      email: { $regex: /guest_.*@temp\.com/ }
    }, 'email name firebaseUid createdAt').limit(10);

    res.json({
      success: true,
      data: {
        duplicateFirebaseUids: duplicateFirebaseUids,
        nullFirebaseUids: nullFirebaseUids,
        guestUsers: guestUsers,
        summary: {
          duplicatesCount: duplicateFirebaseUids.length,
          nullCount: nullFirebaseUids.length,
          guestCount: guestUsers.length
        }
      }
    });

  } catch (error) {
    console.error('❌ Check problematic users error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;
