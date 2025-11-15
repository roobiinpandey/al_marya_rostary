const firebaseUserSyncService = require('./firebaseUserSyncService');
const { LoyaltyAccount } = require('../models/Loyalty');

/**
 * Auto Sync Service
 * Automatically syncs new users to Firebase and creates loyalty accounts
 * This service is called when users register or are created
 */
class AutoSyncService {
  /**
   * Sync newly created user to Firebase and create loyalty account
   * @param {Object} user - MongoDB user document
   * @returns {Promise<Object>} Sync result
   */
  async syncNewUser(user) {
    const result = {
      success: false,
      firebaseSync: null,
      loyaltyAccount: null,
      errors: []
    };

    try {
      // 1. Sync to Firebase
      if (firebaseUserSyncService.initialized) {
        try {
          const firebaseSync = await firebaseUserSyncService.syncUserToFirebase(user);
          result.firebaseSync = {
            success: true,
            firebaseUid: firebaseSync.firebaseUid,
            message: 'User synced to Firebase successfully'
          };
          
          // Update user with Firebase UID if not already set
          if (!user.firebaseUid && firebaseSync.firebaseUid) {
            user.firebaseUid = firebaseSync.firebaseUid;
            await user.save();
            console.log(`✅ Updated user ${user.email} with Firebase UID: ${firebaseSync.firebaseUid}`);
          }
        } catch (firebaseError) {
          console.error(`❌ Firebase sync failed for ${user.email}:`, firebaseError.message);
          result.errors.push({
            service: 'firebase',
            error: firebaseError.message
          });
          result.firebaseSync = {
            success: false,
            message: firebaseError.message
          };
        }
      } else {
        console.warn('⚠️ Firebase not initialized - skipping Firebase sync');
        result.firebaseSync = {
          success: false,
          message: 'Firebase not initialized'
        };
      }

      // 2. Create Loyalty Account (only if we have Firebase UID)
      if (user.firebaseUid) {
        try {
          // Check if loyalty account already exists
          let loyaltyAccount = await LoyaltyAccount.findOne({ userId: user.firebaseUid });
          
          if (!loyaltyAccount) {
            // Create new loyalty account
            loyaltyAccount = await LoyaltyAccount.create({
              userId: user.firebaseUid,
              userEmail: user.email,
              userName: user.name || user.displayName || 'Customer',
              currentBalance: 0,
              totalPointsEarned: 0,
              totalPointsSpent: 0,
              currentTier: 'Bronze'
            });
            
            console.log(`✅ Created loyalty account for ${user.email} (${user.firebaseUid})`);
            result.loyaltyAccount = {
              success: true,
              accountId: loyaltyAccount._id,
              message: 'Loyalty account created successfully'
            };
          } else {
            console.log(`ℹ️ Loyalty account already exists for ${user.email}`);
            result.loyaltyAccount = {
              success: true,
              accountId: loyaltyAccount._id,
              message: 'Loyalty account already exists'
            };
          }
        } catch (loyaltyError) {
          console.error(`❌ Loyalty account creation failed for ${user.email}:`, loyaltyError.message);
          result.errors.push({
            service: 'loyalty',
            error: loyaltyError.message
          });
          result.loyaltyAccount = {
            success: false,
            message: loyaltyError.message
          };
        }
      } else {
        console.warn(`⚠️ No Firebase UID for ${user.email} - skipping loyalty account creation`);
        result.loyaltyAccount = {
          success: false,
          message: 'No Firebase UID available'
        };
      }

      // Determine overall success
      result.success = result.firebaseSync?.success && result.loyaltyAccount?.success;
      
      return result;
    } catch (error) {
      console.error('❌ Auto sync failed:', error);
      result.errors.push({
        service: 'autoSync',
        error: error.message
      });
      return result;
    }
  }

  /**
   * Update Firebase user when MongoDB user is updated
   * @param {Object} user - MongoDB user document
   * @returns {Promise<Object>} Update result
   */
  async updateFirebaseUser(user) {
    try {
      if (!firebaseUserSyncService.initialized) {
        return {
          success: false,
          message: 'Firebase not initialized'
        };
      }

      if (!user.firebaseUid) {
        return {
          success: false,
          message: 'User does not have Firebase UID'
        };
      }

      const syncResult = await firebaseUserSyncService.syncUserToFirebase(user);
      return {
        success: true,
        message: 'Firebase user updated successfully',
        data: syncResult
      };
    } catch (error) {
      console.error('❌ Firebase update failed:', error);
      return {
        success: false,
        message: error.message
      };
    }
  }

  /**
   * Sync all existing users (for migration purposes)
   * @returns {Promise<Object>} Migration result
   */
  async syncAllExistingUsers() {
    const User = require('../models/User');
    
    try {
      const users = await User.find({});
      const results = {
        total: users.length,
        synced: 0,
        failed: 0,
        errors: []
      };

      for (const user of users) {
        try {
          const syncResult = await this.syncNewUser(user);
          if (syncResult.success) {
            results.synced++;
          } else {
            results.failed++;
            results.errors.push({
              email: user.email,
              errors: syncResult.errors
            });
          }
        } catch (error) {
          results.failed++;
          results.errors.push({
            email: user.email,
            error: error.message
          });
        }
      }

      console.log(`\n📊 Migration Summary:`);
      console.log(`   Total users: ${results.total}`);
      console.log(`   Successfully synced: ${results.synced}`);
      console.log(`   Failed: ${results.failed}`);
      
      return results;
    } catch (error) {
      console.error('❌ Migration failed:', error);
      throw error;
    }
  }
}

module.exports = new AutoSyncService();
