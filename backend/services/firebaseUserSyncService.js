const admin = require('firebase-admin');
const User = require('../models/User');
const fs = require('fs');
const path = require('path');

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
   * Initialize Firebase Admin SDK with multiple fallback methods
   */
  initializeFirebase() {
    try {
      if (admin.apps.length === 0) {
        let serviceAccount = null;
        let loadMethod = '';

        // Method 1: Try loading from secret file (Render Secret Files)
        const secretFilePath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || 
                              '/etc/secrets/firebase-service-account.json';
        
        if (fs.existsSync(secretFilePath)) {
          try {
            const fileContent = fs.readFileSync(secretFilePath, 'utf8');
            serviceAccount = JSON.parse(fileContent);
            loadMethod = 'secret file';
            console.log('✅ Loaded Firebase credentials from secret file');
          } catch (fileError) {
            console.warn('⚠️ Failed to parse secret file:', fileError.message);
          }
        }

        // Method 2: Try loading from environment variable
        if (!serviceAccount) {
          const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
          if (serviceAccountKey) {
            try {
              // Trim whitespace and validate
              const trimmedKey = serviceAccountKey.trim();
              if (trimmedKey.startsWith('{') && trimmedKey.endsWith('}')) {
                serviceAccount = JSON.parse(trimmedKey);
                loadMethod = 'environment variable';
                console.log('✅ Loaded Firebase credentials from environment variable');
              } else {
                console.error('❌ FIREBASE_SERVICE_ACCOUNT_KEY is not valid JSON (missing braces)');
              }
            } catch (parseError) {
              console.error('❌ Failed to parse FIREBASE_SERVICE_ACCOUNT_KEY:', parseError.message);
              console.error('   First 50 chars:', serviceAccountKey.substring(0, 50));
              console.error('   Last 50 chars:', serviceAccountKey.substring(serviceAccountKey.length - 50));
            }
          }
        }

        // Initialize Firebase if we have valid credentials
        if (serviceAccount) {
          // Validate required fields
          const requiredFields = ['project_id', 'private_key', 'client_email'];
          const missingFields = requiredFields.filter(field => !serviceAccount[field]);
          
          if (missingFields.length > 0) {
            console.error('❌ Service account missing required fields:', missingFields.join(', '));
            this.initialized = false;
            return;
          }

          const projectId = process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id;
          
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            projectId: projectId
          });
          
          this.initialized = true;
          console.log(`✅ Firebase User Sync Service initialized via ${loadMethod}`);
          console.log(`   Project ID: ${projectId}`);
        } else {
          console.warn('⚠️ Firebase not configured for User Sync Service');
          console.warn('   - No secret file found at:', secretFilePath);
          console.warn('   - FIREBASE_SERVICE_ACCOUNT_KEY not set or invalid');
          this.initialized = false;
        }
      } else {
        this.initialized = true;
        console.log('✅ Firebase User Sync Service using existing Firebase instance');
      }
    } catch (error) {
      console.error('❌ Firebase User Sync Service initialization error:', error.message);
      console.error('   Error details:', error);
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
        // Create new local user with strong password
        const randomPassword = 'Firebase@' + Math.random().toString(36).substring(2, 8) + Math.floor(Math.random() * 999);
        
        localUser = new User({
          ...userData,
          // Set secure default password that meets validation requirements
          password: randomPassword,
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
   * Sync all local users to Firebase (simplified version)
   * @param {Function} progressCallback - Optional callback for progress updates
   * @param {number} batchSize - Number of users to process in parallel (default: 10)
   * @returns {Promise<Object>} Bulk sync results
   */
  async syncAllUsersToFirebase(progressCallback = null, batchSize = 10) {
    if (!this.initialized) {
      throw new Error('Firebase not initialized');
    }

    try {
      const users = await User.find({});
      console.log(`🔄 Starting bulk sync for ${users.length} users`);

      const results = {
        total: users.length,
        synced: 0,
        errors: 0,
        processed: 0,
        details: [],
        startTime: new Date()
      };

      // Process users sequentially to avoid issues
      for (const user of users) {
        try {
          console.log(`Syncing local user: ${user.email}`);
          const result = await this.syncUserToFirebase(user);
          
          results.processed++;
          
          if (result.success) {
            results.synced++;
          } else {
            results.errors++;
          }

          results.details.push({
            email: user.email,
            result
          });

          // Call progress callback if provided
          if (progressCallback && results.processed % 5 === 0) {
            const progressPercent = (results.processed / results.total) * 100;
            progressCallback({
              processed: results.processed,
              total: results.total,
              synced: results.synced,
              errors: results.errors,
              progressPercent: progressPercent.toFixed(1)
            });
          }

        } catch (error) {
          console.error(`❌ Error syncing user ${user.email}:`, error.message);
          results.processed++;
          results.errors++;
          
          results.details.push({
            email: user.email,
            result: { success: false, error: error.message }
          });
        }

        // Small delay between users
        await new Promise(resolve => setTimeout(resolve, 100));
      }

      const duration = (new Date() - results.startTime) / 1000;
      console.log(`✅ Bulk sync completed in ${duration.toFixed(1)}s: ${results.synced} synced, ${results.errors} errors`);
      
      return results;

    } catch (error) {
      console.error('❌ Error in bulk sync:', error.message);
      throw error;
    }
  }

  /**
   * Sync all Firebase users to local database (simplified version)
   * @param {Function} progressCallback - Optional callback for progress updates
   * @param {number} batchSize - Number of users to process in parallel (default: 15)
   * @returns {Promise<Object>} Bulk sync results
   */
  async syncAllUsersFromFirebase(progressCallback = null, batchSize = 15) {
    if (!this.initialized) {
      throw new Error('Firebase not initialized');
    }

    try {
      const auth = admin.auth();
      const results = {
        total: 0,
        synced: 0,
        errors: 0,
        processed: 0,
        details: [],
        startTime: new Date()
      };

      console.log(`🔄 Starting Firebase to local sync`);

      // Get all Firebase users (simplified approach)
      const allFirebaseUsers = [];
      let pageToken;
      
      do {
        const listUsersResult = await auth.listUsers(1000, pageToken);
        allFirebaseUsers.push(...listUsersResult.users);
        pageToken = listUsersResult.pageToken;
      } while (pageToken);

      results.total = allFirebaseUsers.length;
      console.log(`📊 Found ${allFirebaseUsers.length} Firebase users to sync`);

      // Process users sequentially to avoid issues
      for (const firebaseUser of allFirebaseUsers) {
        try {
          console.log(`Syncing Firebase user: ${firebaseUser.email}`);
          
          // Find existing local user by Firebase UID or email
          let localUser = await User.findOne({ 
            $or: [
              { firebaseUid: firebaseUser.uid },
              { email: firebaseUser.email }
            ]
          });

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
            // Update existing user
            Object.assign(localUser, userData);
            await localUser.save();
            console.log(`   ✅ Updated: ${firebaseUser.email}`);
          } else {
            // Create new user
            // Generate secure password that meets validation requirements  
            const randomPassword = 'Firebase@' + Math.random().toString(36).substring(2, 8) + Math.floor(Math.random() * 999);
            
            localUser = new User({
              ...userData,
              password: randomPassword,
              roles: ['customer']
            });
            await localUser.save();
            console.log(`   ✅ Created: ${firebaseUser.email}`);
          }

          results.processed++;
          results.synced++;
          
          results.details.push({
            email: firebaseUser.email,
            result: {
              success: true,
              userId: localUser._id,
              action: localUser.firebaseUid ? 'updated' : 'created',
              message: `Local user ${firebaseUser.email} ${localUser.firebaseUid ? 'updated' : 'created'} from Firebase`
            }
          });

          // Call progress callback if provided
          if (progressCallback && results.processed % 5 === 0) {
            const progressPercent = (results.processed / results.total) * 100;
            progressCallback({
              processed: results.processed,
              total: results.total,
              synced: results.synced,
              errors: results.errors,
              progressPercent: progressPercent.toFixed(1)
            });
          }

        } catch (error) {
          console.error(`❌ Error syncing Firebase user ${firebaseUser.email}:`, error.message);
          results.processed++;
          results.errors++;
          
          results.details.push({
            email: firebaseUser.email,
            result: { success: false, error: error.message }
          });
        }

        // Small delay between users
        await new Promise(resolve => setTimeout(resolve, 50));
      }

      const duration = (new Date() - results.startTime) / 1000;
      console.log(`✅ Firebase to local sync completed in ${duration.toFixed(1)}s: ${results.synced} synced, ${results.errors} errors`);
      
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
