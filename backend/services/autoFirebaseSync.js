const admin = require('firebase-admin');
const User = require('../models/User');
const firebaseUserSyncService = require('./firebaseUserSyncService');

/**
 * Automatic Firebase Sync Service
 * Provides real-time synchronization between Firebase Auth and local database
 */
class AutoFirebaseSyncService {
  constructor() {
    this.isRunning = false;
    this.syncInterval = null;
    this.lastSyncTime = null;
    this.pollIntervalMs = parseInt(process.env.FIREBASE_SYNC_INTERVAL_MS) || 60000; // 1 minute default
    this.maxRetries = 3;
    this.syncStats = {
      totalSyncs: 0,
      successfulSyncs: 0,
      failedSyncs: 0,
      lastSyncDuration: 0
    };
  }

  /**
   * Start automatic sync service
   */
  start() {
    if (this.isRunning) {
      console.log('⚠️ Auto Firebase sync is already running');
      return;
    }

    console.log('🚀 Starting Auto Firebase Sync Service...');
    console.log(`📅 Sync interval: ${this.pollIntervalMs / 1000} seconds`);
    
    this.isRunning = true;
    
    // Initial sync
    this.performSync();
    
    // Set up periodic sync
    this.syncInterval = setInterval(() => {
      this.performSync();
    }, this.pollIntervalMs);
    
    console.log('✅ Auto Firebase Sync Service started');
  }

  /**
   * Stop automatic sync service
   */
  stop() {
    if (!this.isRunning) {
      console.log('⚠️ Auto Firebase sync is not running');
      return;
    }

    console.log('🛑 Stopping Auto Firebase Sync Service...');
    
    this.isRunning = false;
    
    if (this.syncInterval) {
      clearInterval(this.syncInterval);
      this.syncInterval = null;
    }
    
    console.log('✅ Auto Firebase Sync Service stopped');
  }

  /**
   * Perform automatic sync operation
   */
  async performSync() {
    if (!firebaseUserSyncService.initialized) {
      console.log('⚠️ Firebase not initialized, skipping auto sync');
      return;
    }

    const startTime = Date.now();
    console.log('🔄 Starting automatic Firebase sync...');

    try {
      this.syncStats.totalSyncs++;

      // Check for new Firebase users
      const newUsers = await this.checkForNewFirebaseUsers();
      
      if (newUsers.length > 0) {
        console.log(`📱 Found ${newUsers.length} new Firebase users to sync`);
        
        for (const firebaseUser of newUsers) {
          try {
            const result = await firebaseUserSyncService.syncUserFromFirebase(firebaseUser);
            
            if (result.success) {
              console.log(`✅ Auto-synced new user: ${firebaseUser.email}`);
            } else {
              console.error(`❌ Failed to auto-sync user ${firebaseUser.email}:`, result.error);
            }
          } catch (error) {
            console.error(`❌ Error auto-syncing user ${firebaseUser.email}:`, error.message);
          }
        }
      } else {
        console.log('📱 No new Firebase users found');
      }

      // Check for updated Firebase users
      const updatedUsers = await this.checkForUpdatedFirebaseUsers();
      
      if (updatedUsers.length > 0) {
        console.log(`📝 Found ${updatedUsers.length} updated Firebase users to sync`);
        
        for (const firebaseUser of updatedUsers) {
          try {
            const result = await firebaseUserSyncService.syncUserFromFirebase(firebaseUser);
            
            if (result.success) {
              console.log(`✅ Auto-updated user: ${firebaseUser.email}`);
            } else {
              console.error(`❌ Failed to auto-update user ${firebaseUser.email}:`, result.error);
            }
          } catch (error) {
            console.error(`❌ Error auto-updating user ${firebaseUser.email}:`, error.message);
          }
        }
      } else {
        console.log('📝 No updated Firebase users found');
      }

      // Update sync stats
      this.syncStats.successfulSyncs++;
      this.lastSyncTime = new Date();
      this.syncStats.lastSyncDuration = Date.now() - startTime;
      
      console.log(`✅ Automatic sync completed in ${this.syncStats.lastSyncDuration}ms`);
      console.log(`📊 Sync stats: ${this.syncStats.successfulSyncs}/${this.syncStats.totalSyncs} successful`);

    } catch (error) {
      this.syncStats.failedSyncs++;
      console.error('❌ Automatic Firebase sync error:', error.message);
    }
  }

  /**
   * Check for new Firebase users that haven't been synced to local database
   */
  async checkForNewFirebaseUsers() {
    try {
      const auth = admin.auth();
      const newUsers = [];
      
      // Get all Firebase users created since last sync
      let pageToken;
      do {
        const listUsersResult = await auth.listUsers(1000, pageToken);
        
        for (const firebaseUser of listUsersResult.users) {
          // Check if user exists in local database
          const localUser = await User.findOne({
            $or: [
              { firebaseUid: firebaseUser.uid },
              { email: firebaseUser.email }
            ]
          });

          if (!localUser) {
            // New user not in local database
            newUsers.push(firebaseUser);
          }
        }

        pageToken = listUsersResult.pageToken;
      } while (pageToken);

      return newUsers;

    } catch (error) {
      console.error('❌ Error checking for new Firebase users:', error.message);
      return [];
    }
  }

  /**
   * Check for updated Firebase users that need to be re-synced
   */
  async checkForUpdatedFirebaseUsers() {
    try {
      const auth = admin.auth();
      const updatedUsers = [];
      
      // Get local users with Firebase UIDs
      const localUsersWithFirebase = await User.find({
        firebaseUid: { $exists: true, $ne: null }
      }).select('firebaseUid email lastFirebaseSync');

      console.log(`🔍 Checking ${localUsersWithFirebase.length} local users for Firebase updates`);

      for (const localUser of localUsersWithFirebase) {
        try {
          // Get current Firebase user data
          const firebaseUser = await auth.getUser(localUser.firebaseUid);
          
          // Check if Firebase user was updated since last sync
          const firebaseLastActivity = new Date(firebaseUser.metadata.lastRefreshTime || firebaseUser.metadata.lastSignInTime);
          const lastSync = localUser.lastFirebaseSync || new Date(0);
          
          if (firebaseLastActivity > lastSync) {
            updatedUsers.push(firebaseUser);
          }

        } catch (error) {
          if (error.code === 'auth/user-not-found') {
            console.log(`⚠️ Firebase user not found for local user ${localUser.email}, will unlink`);
            // Unlink deleted Firebase user
            await User.findByIdAndUpdate(localUser._id, {
              firebaseUid: null,
              firebaseSyncStatus: 'manual',
              firebaseSyncError: 'Firebase user deleted'
            });
          } else {
            console.error(`❌ Error checking Firebase user ${localUser.firebaseUid}:`, error.message);
          }
        }
      }

      return updatedUsers;

    } catch (error) {
      console.error('❌ Error checking for updated Firebase users:', error.message);
      return [];
    }
  }

  /**
   * Force immediate sync
   */
  async forceSyncNow() {
    console.log('⚡ Forcing immediate Firebase sync...');
    await this.performSync();
  }

  /**
   * Get sync service status
   */
  getStatus() {
    return {
      isRunning: this.isRunning,
      lastSyncTime: this.lastSyncTime,
      pollIntervalMs: this.pollIntervalMs,
      stats: this.syncStats,
      nextSyncIn: this.isRunning && this.lastSyncTime 
        ? Math.max(0, this.pollIntervalMs - (Date.now() - this.lastSyncTime.getTime()))
        : null
    };
  }

  /**
   * Update sync interval
   */
  updateInterval(intervalMs) {
    console.log(`🔧 Updating sync interval from ${this.pollIntervalMs}ms to ${intervalMs}ms`);
    
    this.pollIntervalMs = intervalMs;
    
    if (this.isRunning) {
      // Restart with new interval
      this.stop();
      this.start();
    }
  }

  /**
   * Sync specific Firebase user immediately (for webhook use)
   */
  async syncFirebaseUserImmediately(firebaseUid) {
    try {
      console.log(`⚡ Immediate sync for Firebase user: ${firebaseUid}`);
      
      const auth = admin.auth();
      const firebaseUser = await auth.getUser(firebaseUid);
      
      const result = await firebaseUserSyncService.syncUserFromFirebase(firebaseUser);
      
      if (result.success) {
        console.log(`✅ Immediate sync successful for: ${firebaseUser.email}`);
      } else {
        console.error(`❌ Immediate sync failed for: ${firebaseUser.email}`, result.error);
      }
      
      return result;

    } catch (error) {
      console.error(`❌ Error in immediate sync for ${firebaseUid}:`, error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Handle Firebase user deletion immediately
   */
  async handleFirebaseUserDeletion(firebaseUid) {
    try {
      console.log(`🗑️ Handling Firebase user deletion: ${firebaseUid}`);
      
      // Find and update local user
      const localUser = await User.findOne({ firebaseUid });
      
      if (localUser) {
        localUser.firebaseUid = null;
        localUser.firebaseSyncStatus = 'manual';
        localUser.firebaseSyncError = 'Firebase user was deleted';
        localUser.lastFirebaseSync = new Date();
        await localUser.save();
        
        console.log(`✅ Unlinked local user ${localUser.email} from deleted Firebase user`);
        
        return {
          success: true,
          action: 'unlinked',
          message: `Local user ${localUser.email} unlinked from deleted Firebase user`
        };
      } else {
        console.log(`⚠️ No local user found for deleted Firebase UID: ${firebaseUid}`);
        return {
          success: true,
          action: 'ignored',
          message: 'No local user found for deleted Firebase user'
        };
      }

    } catch (error) {
      console.error(`❌ Error handling Firebase user deletion ${firebaseUid}:`, error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }
}

// Export singleton instance
module.exports = new AutoFirebaseSyncService();
