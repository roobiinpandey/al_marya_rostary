const admin = require('firebase-admin');
const User = require('../models/User');

/**
 * Firebase User Sync Service
 * Manages bidirectional synchronization between Firebase Auth and local User database
 */
class FirebaseUserSyncService {
  constructor() {
    this.initialized = false;
    this.initializeFirebase();
  }

  /**
   * Initialize Firebase Admin SDK
   */
  initializeFirebase() {
    try {
      if (admin.apps.length === 0) {
        const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
        const projectId = process.env.FIREBASE_PROJECT_ID;

        if (serviceAccountKey) {
          const serviceAccount = JSON.parse(serviceAccountKey);
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            projectId: serviceAccount.project_id || projectId
          });
          this.initialized = true;
          console.log('✅ Firebase User Sync Service initialized');
        } else {
          console.warn('⚠️ Firebase not configured for User Sync Service');
          this.initialized = false;
        }
      } else {
        this.initialized = true;
        console.log('✅ Firebase User Sync Service using existing Firebase instance');
      }
    } catch (error) {
      console.error('❌ Firebase User Sync Service initialization error:', error.message);
      this.initialized = false;
    }
  }

  /**
   * Sync user from local database to Firebase Auth
   * @param {Object} localUser - MongoDB user document
   * @returns {Promise<Object>} Sync result
   */
  async syncUserToFirebase(localUser) {
    if (!this.initialized) {
      throw new Error('Firebase not initialized');
    }

    try {
      const auth = admin.auth();
      let firebaseUser;

      // Check if Firebase user already exists
      if (localUser.firebaseUid) {
        try {
          firebaseUser = await auth.getUser(localUser.firebaseUid);
        } catch (error) {
          if (error.code === 'auth/user-not-found') {
            // Firebase user was deleted, need to recreate
            firebaseUser = null;
            localUser.firebaseUid = null;
          } else {
            throw error;
          }
        }
      }

      if (!firebaseUser) {
        // Create new Firebase user
        const createRequest = {
          email: localUser.email,
          displayName: localUser.name,
          emailVerified: localUser.isEmailVerified,
          disabled: !localUser.isActive
        };

        // Add phone number if available
        if (localUser.phone) {
          createRequest.phoneNumber = localUser.phone;
        }

        firebaseUser = await auth.createUser(createRequest);
        console.log(`✅ Created Firebase user for: ${localUser.email}`);
      } else {
        // Update existing Firebase user
        const updateRequest = {
          email: localUser.email,
          displayName: localUser.name,
          emailVerified: localUser.isEmailVerified,
          disabled: !localUser.isActive
        };

        // Add phone number if available
        if (localUser.phone) {
          updateRequest.phoneNumber = localUser.phone;
        }

        firebaseUser = await auth.updateUser(localUser.firebaseUid, updateRequest);
        console.log(`✅ Updated Firebase user for: ${localUser.email}`);
      }

      // Set custom claims for roles and user ID
      await auth.setCustomUserClaims(firebaseUser.uid, {
        roles: localUser.roles,
        userId: localUser._id.toString(),
        lastSync: Date.now()
      });

      // Update local user with Firebase UID and sync status
      await localUser.linkFirebaseUser(firebaseUser.uid);

      return {
        success: true,
        firebaseUid: firebaseUser.uid,
        action: localUser.firebaseUid ? 'updated' : 'created',
        message: `User ${localUser.email} synced to Firebase successfully`
      };

    } catch (error) {
      console.error(`❌ Error syncing user ${localUser.email} to Firebase:`, error.message);
      
      // Update local user with error status
      await localUser.updateFirebaseSync('error', error.message);

      return {
        success: false,
        error: error.message,
        action: 'error'
      };
    }
  }

  /**
   * Sync user from Firebase Auth to local database
   * @param {Object} firebaseUser - Firebase user record
   * @returns {Promise<Object>} Sync result
   */
  async syncUserFromFirebase(firebaseUser) {
    try {
      // Find existing local user by Firebase UID or email
      let localUser = await User.findByFirebaseUid(firebaseUser.uid);
      
      if (!localUser) {
        localUser = await User.findByEmail(firebaseUser.email);
      }

      const userData = {
        name: firebaseUser.displayName || firebaseUser.email.split('@')[0],
        email: firebaseUser.email,
        phone: firebaseUser.phoneNumber || null,
        isEmailVerified: firebaseUser.emailVerified,
        isActive: !firebaseUser.disabled,
        firebaseUid: firebaseUser.uid,
        firebaseSyncStatus: 'synced',
        lastFirebaseSync: new Date()
      };

      if (localUser) {
        // Update existing local user
        Object.assign(localUser, userData);
        await localUser.save();
        console.log(`✅ Updated local user from Firebase: ${firebaseUser.email}`);
        
        return {
          success: true,
          userId: localUser._id,
          action: 'updated',
          message: `Local user ${firebaseUser.email} updated from Firebase`
        };
      } else {
        // Create new local user
        localUser = new User({
          ...userData,
          // Set default password (will be hashed by pre-save middleware)
          password: 'firebase-auth-' + Math.random().toString(36).substring(7),
          roles: ['customer'] // Default role for Firebase users
        });

        await localUser.save();
        console.log(`✅ Created local user from Firebase: ${firebaseUser.email}`);

        return {
          success: true,
          userId: localUser._id,
          action: 'created',
          message: `Local user ${firebaseUser.email} created from Firebase`
        };
      }

    } catch (error) {
      console.error(`❌ Error syncing user ${firebaseUser.email} from Firebase:`, error.message);
      
      return {
        success: false,
        error: error.message,
        action: 'error'
      };
    }
  }

  /**
   * Delete user from Firebase Auth
   * @param {string} firebaseUid - Firebase user UID
   * @returns {Promise<Object>} Deletion result
   */
  async deleteFirebaseUser(firebaseUid) {
    if (!this.initialized) {
      throw new Error('Firebase not initialized');
    }

    try {
      const auth = admin.auth();
      await auth.deleteUser(firebaseUid);
      
      console.log(`✅ Deleted Firebase user: ${firebaseUid}`);
      
      return {
        success: true,
        message: `Firebase user ${firebaseUid} deleted successfully`
      };

    } catch (error) {
      console.error(`❌ Error deleting Firebase user ${firebaseUid}:`, error.message);
      
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Sync all local users to Firebase
   * @returns {Promise<Object>} Bulk sync results
   */
  async syncAllUsersToFirebase() {
    if (!this.initialized) {
      throw new Error('Firebase not initialized');
    }

    try {
      const users = await User.find({});
      const results = {
        total: users.length,
        synced: 0,
        errors: 0,
        details: []
      };

      for (const user of users) {
        const result = await this.syncUserToFirebase(user);
        results.details.push({
          email: user.email,
          result
        });

        if (result.success) {
          results.synced++;
        } else {
          results.errors++;
        }

        // Add small delay to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 100));
      }

      console.log(`✅ Bulk sync completed: ${results.synced} synced, ${results.errors} errors`);
      
      return results;

    } catch (error) {
      console.error('❌ Error in bulk sync:', error.message);
      throw error;
    }
  }

  /**
   * Sync all Firebase users to local database
   * @returns {Promise<Object>} Bulk sync results
   */
  async syncAllUsersFromFirebase() {
    if (!this.initialized) {
      throw new Error('Firebase not initialized');
    }

    try {
      const auth = admin.auth();
      const results = {
        total: 0,
        synced: 0,
        errors: 0,
        details: []
      };

      // List all Firebase users
      let pageToken;
      do {
        const listUsersResult = await auth.listUsers(1000, pageToken);
        
        for (const firebaseUser of listUsersResult.users) {
          results.total++;
          
          const result = await this.syncUserFromFirebase(firebaseUser);
          results.details.push({
            email: firebaseUser.email,
            result
          });

          if (result.success) {
            results.synced++;
          } else {
            results.errors++;
          }

          // Add small delay to avoid overwhelming the database
          await new Promise(resolve => setTimeout(resolve, 50));
        }

        pageToken = listUsersResult.pageToken;
      } while (pageToken);

      console.log(`✅ Firebase to local sync completed: ${results.synced} synced, ${results.errors} errors`);
      
      return results;

    } catch (error) {
      console.error('❌ Error in Firebase to local sync:', error.message);
      throw error;
    }
  }

  /**
   * Get sync status for all users
   * @returns {Promise<Object>} Sync status overview
   */
  async getSyncStatus() {
    try {
      const totalUsers = await User.countDocuments();
      const syncedUsers = await User.countDocuments({ firebaseSyncStatus: 'synced' });
      const pendingUsers = await User.countDocuments({ firebaseSyncStatus: 'pending' });
      const errorUsers = await User.countDocuments({ firebaseSyncStatus: 'error' });
      const manualUsers = await User.countDocuments({ firebaseSyncStatus: 'manual' });
      const withFirebaseUid = await User.countDocuments({ firebaseUid: { $exists: true, $ne: null } });

      return {
        totalUsers,
        syncedUsers,
        pendingUsers,
        errorUsers,
        manualUsers,
        withFirebaseUid,
        syncPercentage: totalUsers > 0 ? ((syncedUsers / totalUsers) * 100).toFixed(1) : 0,
        firebaseEnabled: this.initialized
      };

    } catch (error) {
      console.error('❌ Error getting sync status:', error.message);
      throw error;
    }
  }

  /**
   * Handle Firebase Auth webhook events
   * @param {Object} eventData - Firebase Auth event data
   * @returns {Promise<Object>} Event handling result
   */
  async handleFirebaseAuthEvent(eventData) {
    try {
      const { eventType, uid, email } = eventData;

      switch (eventType) {
        case 'user.create':
          // Firebase user was created (e.g., via mobile app)
          const firebaseUser = await admin.auth().getUser(uid);
          return await this.syncUserFromFirebase(firebaseUser);

        case 'user.delete':
          // Firebase user was deleted
          const localUser = await User.findByFirebaseUid(uid);
          if (localUser) {
            localUser.firebaseUid = null;
            localUser.firebaseSyncStatus = 'manual';
            await localUser.save();
          }
          return {
            success: true,
            action: 'unlinked',
            message: `Local user unlinked from deleted Firebase user ${uid}`
          };

        case 'user.update':
          // Firebase user was updated
          const updatedFirebaseUser = await admin.auth().getUser(uid);
          return await this.syncUserFromFirebase(updatedFirebaseUser);

        default:
          console.warn(`⚠️ Unhandled Firebase Auth event type: ${eventType}`);
          return {
            success: false,
            error: `Unhandled event type: ${eventType}`
          };
      }

    } catch (error) {
      console.error(`❌ Error handling Firebase Auth event:`, error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }
}

// Export singleton instance
module.exports = new FirebaseUserSyncService();
