const admin = require('firebase-admin');
const User = require('../models/User');
const firebaseUserSyncService = require('../services/firebaseUserSyncService');
const { logAdminAction } = require('../utils/auditLogger');
// ⚡ NEW: Import cache manager
const { 
  cacheFirebaseUser, 
  getCachedFirebaseUser,
  CACHE_TTL 
} = require('../utils/cacheManager');

/**
 * Firebase Admin Controller
 * Provides comprehensive Firebase Authentication user management for admin panel
 */

/**
 * @desc    Get all Firebase Auth users with local sync status
 * @route   GET /api/admin/firebase-users
 * @access  Private/Admin
 */
exports.getAllFirebaseUsers = async (req, res) => {
  try {
    const { limit = 100, search = '' } = req.query;
    const auth = admin.auth();
    
    // Optimized: Fetch only the requested limit of users
    const maxLimit = Math.min(parseInt(limit), 1000); // Cap at 1000
    
    console.log(`📥 Fetching Firebase users (limit: ${maxLimit})${search ? ` with search: "${search}"` : ''}`);
    
    // Fetch users from Firebase
    const listUsersResult = await auth.listUsers(maxLimit);
    let firebaseUsers = listUsersResult.users;
    
    // Apply search filter if provided
    if (search) {
      const searchLower = search.toLowerCase();
      firebaseUsers = firebaseUsers.filter(user => {
        return (user.email && user.email.toLowerCase().includes(searchLower)) ||
               (user.displayName && user.displayName.toLowerCase().includes(searchLower)) ||
               (user.phoneNumber && user.phoneNumber.includes(search));
      });
      console.log(`🔍 Search filtered: ${firebaseUsers.length} users match "${search}"`);
    }

    console.log(`👥 Processing ${firebaseUsers.length} Firebase users...`);

    // ⚡ OPTIMIZED: Batch fetch local users for better performance
    const firebaseEmails = firebaseUsers.map(u => u.email).filter(Boolean);
    const firebaseUids = firebaseUsers.map(u => u.uid);
    
    const localUsers = await User.find({
      $or: [
        { firebaseUid: { $in: firebaseUids } },
        { email: { $in: firebaseEmails } }
      ]
    })
    .select('_id firebaseUid email firebaseSyncStatus lastFirebaseSync firebaseSyncError roles isActive')
    .lean(); // ⚡ Returns plain JS objects for 10-20% performance gain

    // Create a lookup map for faster matching
    const localUserMap = new Map();
    localUsers.forEach(user => {
      if (user.firebaseUid) {
        localUserMap.set(user.firebaseUid, user);
      }
      if (user.email) {
        localUserMap.set(user.email, user);
      }
    });

    // Enrich Firebase users with local data
    const enrichedUsers = firebaseUsers.map((firebaseUser) => {
      const localUser = localUserMap.get(firebaseUser.uid) || localUserMap.get(firebaseUser.email);

      return {
        // Firebase data
        uid: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        phoneNumber: firebaseUser.phoneNumber,
        photoURL: firebaseUser.photoURL,
        emailVerified: firebaseUser.emailVerified,
        disabled: firebaseUser.disabled,
        metadata: {
          creationTime: firebaseUser.metadata.creationTime,
          lastSignInTime: firebaseUser.metadata.lastSignInTime,
          lastRefreshTime: firebaseUser.metadata.lastRefreshTime
        },
        providerData: firebaseUser.providerData.map(p => ({
          providerId: p.providerId,
          uid: p.uid,
          displayName: p.displayName,
          email: p.email
        })),
        customClaims: firebaseUser.customClaims || {},
        
        // Local database sync status
        syncStatus: {
          isLinked: !!localUser,
          localUserId: localUser?._id || null,
          syncStatus: localUser?.firebaseSyncStatus || 'not-synced',
          lastSync: localUser?.lastFirebaseSync || null,
          syncError: localUser?.firebaseSyncError || null,
          localRoles: localUser?.roles || [],
          localIsActive: localUser?.isActive || false
        }
      };
    });

    console.log(`✅ Returning ${enrichedUsers.length} Firebase users (${localUsers.length} linked to local DB)`);

    res.json({
      success: true,
      message: 'Firebase users retrieved successfully',
      data: {
        users: enrichedUsers,
        pagination: {
          total: enrichedUsers.length,
          limit: maxLimit,
          hasMore: listUsersResult.pageToken ? true : false
        },
        stats: {
          totalFetched: enrichedUsers.length,
          linkedToLocal: localUsers.length,
          notLinked: enrichedUsers.length - localUsers.length
        }
      }
    });

  } catch (error) {
    console.error('❌ Get all Firebase users error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch Firebase users',
      error: error.message
    });
  }
};

/**
 * @desc    Get single Firebase user with full details
 * @route   GET /api/admin/firebase-users/:uid
 * @access  Private/Admin
 */
exports.getFirebaseUser = async (req, res) => {
  try {
    const { uid } = req.params;
    
    // ⚡ NEW: Try to get from cache first
    const cached = getCachedFirebaseUser(uid);
    if (cached) {
      console.log(`💾 Cache HIT: Firebase user ${uid}`);
      return res.json({
        success: true,
        message: 'Firebase user retrieved from cache',
        data: cached,
        cached: true
      });
    }
    
    const auth = admin.auth();
    
    // Get Firebase user
    const firebaseUser = await auth.getUser(uid);
    
    // ⚡ OPTIMIZED: Get linked local user with .lean() and specific fields
    const localUser = await User.findOne({
      $or: [
        { firebaseUid: uid },
        { email: firebaseUser.email }
      ]
    })
    .select('-password -__v')
    .lean();

    const responseData = {
      firebase: {
        uid: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        phoneNumber: firebaseUser.phoneNumber,
        photoURL: firebaseUser.photoURL,
        emailVerified: firebaseUser.emailVerified,
        disabled: firebaseUser.disabled,
        metadata: firebaseUser.metadata,
        providerData: firebaseUser.providerData,
        customClaims: firebaseUser.customClaims || {},
        tokensValidAfterTime: firebaseUser.tokensValidAfterTime
      },
      local: localUser || null,
      isLinked: !!localUser
    };
    
    // ⚡ NEW: Cache the result for 2 minutes
    cacheFirebaseUser(uid, responseData);
    console.log(`💾 Cache SET: Firebase user ${uid}`);
    
    res.json({
      success: true,
      message: 'Firebase user retrieved successfully',
      data: responseData,
      cached: false
    });

  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      return res.status(404).json({
        success: false,
        message: 'Firebase user not found'
      });
    }

    console.error('❌ Get Firebase user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch Firebase user',
      error: error.message
    });
  }
};

/**
 * @desc    Update Firebase user
 * @route   PUT /api/admin/firebase-users/:uid
 * @access  Private/Admin
 */
exports.updateFirebaseUser = async (req, res) => {
  try {
    const { uid } = req.params;
    const { displayName, phoneNumber, email, emailVerified, disabled, photoURL } = req.body;
    
    const auth = admin.auth();
    
    // Build update request
    const updateRequest = {};
    if (displayName !== undefined) updateRequest.displayName = displayName;
    if (phoneNumber !== undefined) updateRequest.phoneNumber = phoneNumber;
    if (email !== undefined) updateRequest.email = email;
    if (emailVerified !== undefined) updateRequest.emailVerified = emailVerified;
    if (disabled !== undefined) updateRequest.disabled = disabled;
    if (photoURL !== undefined) updateRequest.photoURL = photoURL;

    // Update Firebase user
    const updatedUser = await auth.updateUser(uid, updateRequest);

    // Sync to local database if linked
    const localUser = await User.findOne({ firebaseUid: uid });
    if (localUser) {
      if (displayName) localUser.name = displayName;
      if (email) localUser.email = email;
      if (phoneNumber) localUser.phone = phoneNumber;
      if (emailVerified !== undefined) localUser.isEmailVerified = emailVerified;
      if (disabled !== undefined) localUser.isActive = !disabled;
      
      localUser.lastFirebaseSync = new Date();
      await localUser.save();
    }

    // Log admin action
    await logAdminAction(
      req.user.id,
      'FIREBASE_USER_UPDATED',
      { firebaseUid: uid, changes: updateRequest },
      req,
      uid
    );

    res.json({
      success: true,
      message: 'Firebase user updated successfully',
      data: {
        uid: updatedUser.uid,
        email: updatedUser.email,
        displayName: updatedUser.displayName,
        phoneNumber: updatedUser.phoneNumber,
        emailVerified: updatedUser.emailVerified,
        disabled: updatedUser.disabled
      }
    });

  } catch (error) {
    console.error('❌ Update Firebase user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update Firebase user',
      error: error.message
    });
  }
};

/**
 * @desc    Set custom claims for Firebase user (role management)
 * @route   POST /api/admin/firebase-users/:uid/custom-claims
 * @access  Private/Admin
 */
exports.setCustomClaims = async (req, res) => {
  try {
    const { uid } = req.params;
    const { claims } = req.body;

    if (!claims || typeof claims !== 'object') {
      return res.status(400).json({
        success: false,
        message: 'Claims must be an object'
      });
    }

    const auth = admin.auth();
    
    // Set custom claims
    await auth.setCustomUserClaims(uid, {
      ...claims,
      lastUpdated: Date.now()
    });

    // Update local user if linked
    const localUser = await User.findOne({ firebaseUid: uid });
    if (localUser && claims.roles) {
      localUser.roles = Array.isArray(claims.roles) ? claims.roles : [claims.roles];
      await localUser.save();
    }

    // Log admin action
    await logAdminAction(
      req.user.id,
      'FIREBASE_CUSTOM_CLAIMS_SET',
      { firebaseUid: uid, claims },
      req,
      uid
    );

    res.json({
      success: true,
      message: 'Custom claims set successfully',
      data: { uid, claims }
    });

  } catch (error) {
    console.error('❌ Set custom claims error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to set custom claims',
      error: error.message
    });
  }
};

/**
 * @desc    Delete Firebase user
 * @route   DELETE /api/admin/firebase-users/:uid
 * @access  Private/Admin
 */
exports.deleteFirebaseUser = async (req, res) => {
  try {
    const { uid } = req.params;
    const auth = admin.auth();
    
    // Get user email before deletion
    const firebaseUser = await auth.getUser(uid);
    const userEmail = firebaseUser.email;

    // Delete from Firebase
    await auth.deleteUser(uid);

    // Unlink from local database
    const localUser = await User.findOne({ firebaseUid: uid });
    if (localUser) {
      localUser.firebaseUid = null;
      localUser.firebaseSyncStatus = 'manual';
      localUser.firebaseSyncError = 'Firebase user was deleted';
      await localUser.save();
    }

    // Log admin action
    await logAdminAction(
      req.user.id,
      'FIREBASE_USER_DELETED',
      { firebaseUid: uid, email: userEmail },
      req,
      uid
    );

    res.json({
      success: true,
      message: 'Firebase user deleted successfully',
      data: { uid, email: userEmail, localUserUnlinked: !!localUser }
    });

  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      return res.status(404).json({
        success: false,
        message: 'Firebase user not found'
      });
    }

    console.error('❌ Delete Firebase user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete Firebase user',
      error: error.message
    });
  }
};

/**
 * @desc    Toggle Firebase user disabled status
 * @route   POST /api/admin/firebase-users/:uid/toggle-active
 * @access  Private/Admin
 */
exports.toggleFirebaseUserStatus = async (req, res) => {
  try {
    const { uid } = req.params;
    const auth = admin.auth();
    
    // Get current user
    const firebaseUser = await auth.getUser(uid);
    const newDisabledStatus = !firebaseUser.disabled;

    // Update Firebase user
    const updatedUser = await auth.updateUser(uid, {
      disabled: newDisabledStatus
    });

    // Update local user if linked
    const localUser = await User.findOne({ firebaseUid: uid });
    if (localUser) {
      localUser.isActive = !newDisabledStatus;
      await localUser.save();
    }

    // Log admin action
    await logAdminAction(
      req.user.id,
      'FIREBASE_USER_STATUS_TOGGLED',
      { firebaseUid: uid, disabled: newDisabledStatus },
      req,
      uid
    );

    res.json({
      success: true,
      message: `Firebase user ${newDisabledStatus ? 'disabled' : 'enabled'} successfully`,
      data: {
        uid: updatedUser.uid,
        email: updatedUser.email,
        disabled: updatedUser.disabled
      }
    });

  } catch (error) {
    console.error('❌ Toggle Firebase user status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle Firebase user status',
      error: error.message
    });
  }
};

/**
 * @desc    Create Firebase user from admin panel
 * @route   POST /api/admin/firebase-users
 * @access  Private/Admin
 */
exports.createFirebaseUser = async (req, res) => {
  try {
    const { email, password, displayName, phoneNumber, emailVerified = false } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    const auth = admin.auth();
    
    // Create Firebase user
    const createRequest = {
      email,
      password,
      displayName: displayName || email.split('@')[0],
      emailVerified,
      disabled: false
    };

    if (phoneNumber) {
      createRequest.phoneNumber = phoneNumber;
    }

    const newFirebaseUser = await auth.createUser(createRequest);

    // Sync to local database
    const syncResult = await firebaseUserSyncService.syncUserFromFirebase(newFirebaseUser);

    // Log admin action
    await logAdminAction(
      req.user.id,
      'FIREBASE_USER_CREATED',
      { firebaseUid: newFirebaseUser.uid, email: newFirebaseUser.email },
      req,
      newFirebaseUser.uid
    );

    res.status(201).json({
      success: true,
      message: 'Firebase user created successfully',
      data: {
        firebase: {
          uid: newFirebaseUser.uid,
          email: newFirebaseUser.email,
          displayName: newFirebaseUser.displayName
        },
        localSync: syncResult
      }
    });

  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      return res.status(400).json({
        success: false,
        message: 'Email already exists in Firebase'
      });
    }

    console.error('❌ Create Firebase user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create Firebase user',
      error: error.message
    });
  }
};

/**
 * @desc    Revoke refresh tokens for Firebase user (force logout)
 * @route   POST /api/admin/firebase-users/:uid/revoke-tokens
 * @access  Private/Admin
 */
exports.revokeRefreshTokens = async (req, res) => {
  try {
    const { uid } = req.params;
    const auth = admin.auth();
    
    await auth.revokeRefreshTokens(uid);
    
    // Get user to get the new tokensValidAfterTime
    const user = await auth.getUser(uid);

    // Log admin action
    await logAdminAction(
      req.user.id,
      'FIREBASE_TOKENS_REVOKED',
      { firebaseUid: uid },
      req,
      uid
    );

    res.json({
      success: true,
      message: 'Refresh tokens revoked successfully (user will be logged out)',
      data: {
        uid,
        tokensValidAfterTime: user.tokensValidAfterTime
      }
    });

  } catch (error) {
    console.error('❌ Revoke tokens error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to revoke refresh tokens',
      error: error.message
    });
  }
};

/**
 * @desc    Sync Firebase user to local database
 * @route   POST /api/admin/firebase-users/:uid/sync-to-local
 * @access  Private/Admin
 */
exports.syncFirebaseUserToLocal = async (req, res) => {
  try {
    const { uid } = req.params;
    const auth = admin.auth();
    
    // Get Firebase user
    const firebaseUser = await auth.getUser(uid);
    
    // Sync to local database
    const result = await firebaseUserSyncService.syncUserFromFirebase(firebaseUser);

    res.json({
      success: true,
      message: result.message,
      data: result
    });

  } catch (error) {
    console.error('❌ Sync Firebase user to local error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to sync Firebase user to local database',
      error: error.message
    });
  }
};

/**
 * @desc    Get Firebase user statistics
 * @route   GET /api/admin/firebase-users/stats
 * @access  Private/Admin
 */
exports.getFirebaseUserStats = async (req, res) => {
  try {
    const auth = admin.auth();
    
    // Get all Firebase users for statistics
    let totalFirebaseUsers = 0;
    let emailVerifiedCount = 0;
    let disabledCount = 0;
    let phoneVerifiedCount = 0;
    
    let pageToken;
    do {
      const listUsersResult = await auth.listUsers(1000, pageToken);
      
      for (const user of listUsersResult.users) {
        totalFirebaseUsers++;
        if (user.emailVerified) emailVerifiedCount++;
        if (user.disabled) disabledCount++;
        if (user.phoneNumber) phoneVerifiedCount++;
      }
      
      pageToken = listUsersResult.pageToken;
    } while (pageToken);

    // Get local database statistics
    const totalLocalUsers = await User.countDocuments();
    const linkedUsers = await User.countDocuments({ firebaseUid: { $exists: true, $ne: null } });
    const syncedUsers = await User.countDocuments({ firebaseSyncStatus: 'synced' });
    const pendingSync = await User.countDocuments({ firebaseSyncStatus: 'pending' });
    const errorSync = await User.countDocuments({ firebaseSyncStatus: 'error' });

    res.json({
      success: true,
      message: 'Firebase user statistics retrieved',
      data: {
        firebase: {
          totalUsers: totalFirebaseUsers,
          emailVerified: emailVerifiedCount,
          disabled: disabledCount,
          withPhone: phoneVerifiedCount,
          active: totalFirebaseUsers - disabledCount
        },
        local: {
          totalUsers: totalLocalUsers,
          linkedToFirebase: linkedUsers,
          syncedWithFirebase: syncedUsers,
          pendingSync,
          errorSync,
          notLinked: totalLocalUsers - linkedUsers
        },
        sync: {
          syncPercentage: totalLocalUsers > 0 ? ((linkedUsers / totalLocalUsers) * 100).toFixed(1) : 0,
          unlinkedFirebaseUsers: totalFirebaseUsers - linkedUsers,
          needsAttention: pendingSync + errorSync
        }
      }
    });

  } catch (error) {
    console.error('❌ Get Firebase stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get Firebase user statistics',
      error: error.message
    });
  }
};
