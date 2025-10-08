require('dotenv').config();
const admin = require('firebase-admin');

async function debugFirebaseSetup() {
    console.log('🔍 Debugging Firebase Setup...');
    
    const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
    const projectId = process.env.FIREBASE_PROJECT_ID;
    
    console.log('Environment variables check:');
    console.log('- FIREBASE_PROJECT_ID:', projectId);
    console.log('- FIREBASE_SERVICE_ACCOUNT_KEY length:', serviceAccountKey?.length || 0);
    
    if (!serviceAccountKey) {
        console.error('❌ FIREBASE_SERVICE_ACCOUNT_KEY not found');
        return;
    }
    
    try {
        // Parse and inspect the service account
        const serviceAccount = JSON.parse(serviceAccountKey);
        
        console.log('\n📋 Service Account Properties:');
        console.log('- type:', serviceAccount.type);
        console.log('- project_id:', serviceAccount.project_id);
        console.log('- private_key_id:', serviceAccount.private_key_id?.substring(0, 10) + '...');
        console.log('- client_email:', serviceAccount.client_email);
        console.log('- client_id:', serviceAccount.client_id);
        
        // Check if project_id exists and is a string
        if (typeof serviceAccount.project_id !== 'string') {
            console.error('❌ project_id is not a string:', typeof serviceAccount.project_id, serviceAccount.project_id);
            return;
        }
        
        console.log('✅ Service account structure looks good');
        
        // Try to initialize Firebase
        if (admin.apps.length === 0) {
            console.log('\n🔥 Initializing Firebase Admin SDK...');
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
        }
        
        console.log('✅ Firebase Admin SDK initialized successfully!');
        console.log('🎉 Firebase configuration is working properly');
        
    } catch (error) {
        console.error('❌ Error:', error.message);
        console.error('Stack:', error.stack);
    }
}

debugFirebaseSetup();
