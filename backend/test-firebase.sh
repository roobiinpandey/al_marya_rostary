#!/bin/bash

# Test Firebase Configuration
echo "🔥 Testing Firebase Configuration..."

if [ -z "$FIREBASE_SERVICE_ACCOUNT_KEY" ]; then
    echo "❌ FIREBASE_SERVICE_ACCOUNT_KEY not set"
    exit 1
fi

if [ -z "$FIREBASE_PROJECT_ID" ]; then
    echo "❌ FIREBASE_PROJECT_ID not set"  
    exit 1
fi

# Create temporary test file
cat > test-firebase.js << 'EOF'
const admin = require('firebase-admin');

async function testFirebase() {
    try {
        console.log('🔥 Testing Firebase initialization...');
        
        const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
        const projectId = process.env.FIREBASE_PROJECT_ID;
        
        if (!serviceAccountKey) {
            console.error('❌ FIREBASE_SERVICE_ACCOUNT_KEY not found');
            process.exit(1);
        }
        
        if (!projectId) {
            console.error('❌ FIREBASE_PROJECT_ID not found');
            process.exit(1);
        }
        
        // Parse service account
        let serviceAccount;
        try {
            serviceAccount = JSON.parse(serviceAccountKey);
        } catch (error) {
            console.error('❌ Invalid JSON in FIREBASE_SERVICE_ACCOUNT_KEY:', error.message);
            process.exit(1);
        }
        
        // Initialize Firebase Admin
        if (admin.apps.length === 0) {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
                projectId: projectId
            });
        }
        
        console.log('✅ Firebase Admin SDK initialized successfully');
        console.log('📱 Project ID:', projectId);
        console.log('📧 Service Account Email:', serviceAccount.client_email);
        
        // Test messaging service (optional - requires valid device token)
        const messaging = admin.messaging();
        console.log('📱 Firebase Messaging service ready');
        
        console.log('🎉 Firebase configuration test PASSED');
        
    } catch (error) {
        console.error('❌ Firebase test failed:', error.message);
        process.exit(1);
    }
}

testFirebase();
EOF

# Run Firebase test
node test-firebase.js

# Cleanup
rm test-firebase.js

echo "✅ Firebase configuration test completed"
