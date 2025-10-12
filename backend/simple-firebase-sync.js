#!/usr/bin/env node

/**
 * Simple Firebase Sync Test
 * Test Firebase sync without complex batching to isolate the issue
 */

require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const firebaseUserSyncService = require('./services/firebaseUserSyncService');
const admin = require('firebase-admin');

async function simpleFirebaseSync() {
    try {
        console.log('🔥 Simple Firebase Sync Test');
        console.log('============================\n');

        // Connect to MongoDB
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected to MongoDB\n');

        // Get Firebase users (limit to 5 for test)
        const auth = admin.auth();
        const listUsersResult = await auth.listUsers(5);
        console.log(`📱 Found ${listUsersResult.users.length} Firebase users\n`);

        let synced = 0;
        let errors = 0;

        for (const firebaseUser of listUsersResult.users) {
            try {
                console.log(`Syncing: ${firebaseUser.email}`);
                
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
                    synced++;
                } else {
                    // Create new user
                    localUser = new User({
                        ...userData,
                        password: 'firebase-auth-' + Math.random().toString(36).substring(7),
                        roles: ['customer']
                    });
                    await localUser.save();
                    console.log(`   ✅ Created: ${firebaseUser.email}`);
                    synced++;
                }

            } catch (error) {
                console.error(`   ❌ Error syncing ${firebaseUser.email}:`, error.message);
                errors++;
            }
        }

        console.log(`\n🎉 Sync Complete: ${synced} synced, ${errors} errors`);

        // Check results
        const totalLocalUsers = await User.countDocuments();
        const syncedUsers = await User.countDocuments({ firebaseSyncStatus: 'synced' });
        
        console.log(`📊 Local Database:`);
        console.log(`   - Total users: ${totalLocalUsers}`);
        console.log(`   - Synced users: ${syncedUsers}`);

    } catch (error) {
        console.error('❌ Sync failed:', error.message);
    } finally {
        await mongoose.disconnect();
        console.log('\n✅ Disconnected from MongoDB');
        process.exit(0);
    }
}

// Run the simple sync test
simpleFirebaseSync();
