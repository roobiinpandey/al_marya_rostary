#!/usr/bin/env node

/**
 * Firebase Sync Debug Script
 * Test Firebase synchronization functionality step by step
 */

require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const firebaseUserSyncService = require('./services/firebaseUserSyncService');
const admin = require('firebase-admin');

async function debugFirebaseSync() {
    try {
        console.log('🔍 Firebase Sync Debug Script');
        console.log('=============================\n');

        // Connect to MongoDB
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected to MongoDB\n');

        // Test 1: Check Firebase initialization
        console.log('🧪 Test 1: Firebase Initialization');
        console.log('-----------------------------------');
        try {
            console.log('Firebase apps count:', admin.apps.length);
            if (admin.apps.length > 0) {
                console.log('✅ Firebase Admin SDK is initialized');
                const auth = admin.auth();
                console.log('✅ Firebase Auth service available');
            } else {
                console.log('❌ Firebase Admin SDK not initialized');
                return;
            }
        } catch (error) {
            console.error('❌ Firebase initialization error:', error.message);
            return;
        }

        // Test 2: Check sync status
        console.log('\n🧪 Test 2: Firebase Sync Status');
        console.log('--------------------------------');
        try {
            const syncStatus = await firebaseUserSyncService.getSyncStatus();
            console.log('Sync Status:', JSON.stringify(syncStatus, null, 2));
        } catch (error) {
            console.error('❌ Sync status error:', error.message);
            return;
        }

        // Test 3: List Firebase users (first 5)
        console.log('\n🧪 Test 3: List Firebase Users');
        console.log('-------------------------------');
        try {
            const auth = admin.auth();
            const listUsersResult = await auth.listUsers(5);
            console.log(`Found ${listUsersResult.users.length} Firebase users (showing first 5):`);
            
            listUsersResult.users.forEach((user, index) => {
                console.log(`${index + 1}. ${user.email} (UID: ${user.uid})`);
                console.log(`   - Display Name: ${user.displayName || 'None'}`);
                console.log(`   - Email Verified: ${user.emailVerified}`);
                console.log(`   - Disabled: ${user.disabled}`);
                console.log(`   - Created: ${user.metadata.creationTime}`);
                console.log('');
            });
        } catch (error) {
            console.error('❌ List Firebase users error:', error.message);
            if (error.code === 'auth/insufficient-permission') {
                console.log('💡 This might be a Firebase permissions issue. Check your service account permissions.');
            }
            return;
        }

        // Test 4: Check local users
        console.log('\n🧪 Test 4: Local Users');
        console.log('-----------------------');
        const localUsers = await User.find({}).limit(5);
        console.log(`Found ${localUsers.length} local users (showing first 5):`);
        
        localUsers.forEach((user, index) => {
            console.log(`${index + 1}. ${user.email}`);
            console.log(`   - Name: ${user.name}`);
            console.log(`   - Firebase UID: ${user.firebaseUid || 'None'}`);
            console.log(`   - Sync Status: ${user.firebaseSyncStatus}`);
            console.log(`   - Last Sync: ${user.lastFirebaseSync || 'Never'}`);
            console.log('');
        });

        // Test 5: Try syncing one Firebase user to local
        console.log('\n🧪 Test 5: Test Single Firebase User Sync');
        console.log('------------------------------------------');
        try {
            const auth = admin.auth();
            const listUsersResult = await auth.listUsers(1);
            
            if (listUsersResult.users.length > 0) {
                const firebaseUser = listUsersResult.users[0];
                console.log(`Testing sync for Firebase user: ${firebaseUser.email}`);
                
                const syncResult = await firebaseUserSyncService.syncUserFromFirebase(firebaseUser);
                console.log('Sync Result:', JSON.stringify(syncResult, null, 2));
                
                if (syncResult.success) {
                    console.log('✅ Single user sync test successful');
                } else {
                    console.log('❌ Single user sync test failed');
                }
            } else {
                console.log('ℹ️ No Firebase users found to test with');
            }
        } catch (error) {
            console.error('❌ Single user sync test error:', error.message);
        }

        // Test 6: Test bulk sync (first 3 users only)
        console.log('\n🧪 Test 6: Test Small Batch Sync');
        console.log('---------------------------------');
        try {
            console.log('Testing bulk sync with first 3 Firebase users...');
            
            // Create a test progress callback
            const progressCallback = (progress) => {
                console.log(`Progress: ${progress.processed}/${progress.total} (${progress.progressPercent}%) - Synced: ${progress.synced}, Errors: ${progress.errors}`);
            };
            
            const auth = admin.auth();
            const listUsersResult = await auth.listUsers(3);
            
            if (listUsersResult.users.length > 0) {
                console.log(`Found ${listUsersResult.users.length} Firebase users for test`);
                
                // Test the sync function with a small batch
                let testResults = {
                    total: listUsersResult.users.length,
                    synced: 0,
                    errors: 0,
                    processed: 0,
                    details: []
                };
                
                for (const firebaseUser of listUsersResult.users) {
                    try {
                        const result = await firebaseUserSyncService.syncUserFromFirebase(firebaseUser);
                        testResults.processed++;
                        
                        if (result.success) {
                            testResults.synced++;
                        } else {
                            testResults.errors++;
                        }
                        
                        testResults.details.push({
                            email: firebaseUser.email,
                            result
                        });
                        
                        // Call progress callback
                        const progressPercent = (testResults.processed / testResults.total) * 100;
                        progressCallback({
                            processed: testResults.processed,
                            total: testResults.total,
                            synced: testResults.synced,
                            errors: testResults.errors,
                            progressPercent: progressPercent.toFixed(1)
                        });
                        
                    } catch (error) {
                        console.error(`Error syncing ${firebaseUser.email}:`, error.message);
                        testResults.processed++;
                        testResults.errors++;
                    }
                }
                
                console.log('\nTest Results:', JSON.stringify(testResults, null, 2));
                
                if (testResults.synced > 0) {
                    console.log('✅ Small batch sync test successful');
                } else {
                    console.log('❌ Small batch sync test failed - no users synced');
                }
            } else {
                console.log('ℹ️ No Firebase users found for batch test');
            }
            
        } catch (error) {
            console.error('❌ Small batch sync test error:', error.message);
        }

        console.log('\n🏁 Debug Complete');
        console.log('==================');
        console.log('If all tests passed, the sync should work. If not, check the errors above.');

    } catch (error) {
        console.error('❌ Debug script failed:', error.message);
        console.error('Stack trace:', error.stack);
    } finally {
        await mongoose.disconnect();
        console.log('\n✅ Disconnected from MongoDB');
        process.exit(0);
    }
}

// Run the debug script
debugFirebaseSync();
