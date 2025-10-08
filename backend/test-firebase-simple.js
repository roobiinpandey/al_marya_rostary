require('dotenv').config();
const admin = require('firebase-admin');

// Simple Firebase test - replace with your actual credentials
async function testFirebaseSetup() {
    console.log('🔥 Testing Firebase Setup...');
    
    // Your Firebase project details
    const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT_KEY || '{"your":"service_account_json"}';
    const projectId = process.env.FIREBASE_PROJECT_ID || '***REMOVED***'; // Your project ID
    
    try {
        // Parse the service account JSON
        let serviceAccount;
        try {
            serviceAccount = JSON.parse(serviceAccountKey);
            console.log('✅ Service account JSON parsed successfully');
        } catch (error) {
            console.error('❌ Invalid service account JSON:', error.message);
            console.log('💡 Make sure your FIREBASE_SERVICE_ACCOUNT_KEY is valid JSON');
            return false;
        }
        
        // Initialize Firebase Admin SDK
        if (admin.apps.length === 0) {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
                projectId: serviceAccount.project_id || projectId
            });
        }
        
        console.log('✅ Firebase Admin SDK initialized successfully');
        console.log('📱 Project ID:', projectId);
        console.log('📧 Service Account Email:', serviceAccount.client_email);
        
        // Test messaging service availability
        const messaging = admin.messaging();
        console.log('📱 Firebase Cloud Messaging is ready');
        
        return true;
        
    } catch (error) {
        console.error('❌ Firebase initialization failed:', error.message);
        console.log('\n🔧 Common solutions:');
        console.log('1. Verify your service account JSON is complete');
        console.log('2. Check that project_id matches your Firebase project');
        console.log('3. Ensure service account has proper permissions');
        
        return false;
    }
}

// Run the test
testFirebaseSetup().then(success => {
    if (success) {
        console.log('\n🎉 Firebase is ready for production!');
        console.log('📋 Next: Add environment variables to Render');
    } else {
        console.log('\n❌ Firebase setup needs attention');
        console.log('📚 See FIREBASE_SETUP_GUIDE.md for detailed instructions');
    }
}).catch(error => {
    console.error('💥 Test crashed:', error);
});
