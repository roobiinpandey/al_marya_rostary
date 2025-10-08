# Firebase Setup Guide for Push Notifications

This guide will help you configure Firebase Admin SDK for push notifications in your Qahwat Al Emarat application.

## Overview
The warnings you're seeing:
```
⚠️ Firebase service account not configured. Push notifications will be simulated.
```

This happens because the Firebase Admin SDK needs proper credentials to send real push notifications.

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select existing project
3. Enter project name: `qahwat-al-emarat` (or your preferred name)
4. Enable Google Analytics (optional)
5. Create the project

## Step 2: Enable Firebase Cloud Messaging (FCM)

1. In your Firebase project console, click on "Project Settings" (gear icon)
2. Go to the "Cloud Messaging" tab
3. Note down your:
   - **Server Key** (Legacy)
   - **Sender ID**
   - **Project ID**

## Step 3: Generate Service Account Key

1. In Firebase Console, go to "Project Settings" → "Service Accounts"
2. Click "Generate new private key"
3. Download the JSON file (keep it secure!)
4. The JSON file contains your service account credentials

### Sample Service Account JSON Structure:
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxx@your-project.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxx%40your-project.iam.gserviceaccount.com"
}
```

## Step 4: Configure Environment Variables

### Option A: Using Service Account JSON as Environment Variable (Recommended for Render)

Add to your Render environment variables:

```bash
FIREBASE_SERVICE_ACCOUNT_KEY={"type":"service_account","project_id":"your-project-id",...}
FIREBASE_PROJECT_ID=your-project-id
```

### Option B: Using Service Account File Path (Local Development)

```bash
FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/serviceAccountKey.json
FIREBASE_PROJECT_ID=your-project-id
```

## Step 5: Configure FCM in Flutter App (Frontend)

### Android Configuration

1. Download `google-services.json` from Firebase Console:
   - Project Settings → General → Your Apps → Android app
   - Download `google-services.json`

2. Place the file in: `android/app/google-services.json`

3. Update `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

4. Update `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

### iOS Configuration

1. Download `GoogleService-Info.plist` from Firebase Console:
   - Project Settings → General → Your Apps → iOS app
   - Download `GoogleService-Info.plist`

2. Add to Xcode project: `ios/Runner/GoogleService-Info.plist`

### Flutter Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
```

## Step 6: Render Deployment Configuration

### Add to Render Environment Variables:

1. Go to your Render service dashboard
2. Navigate to "Environment" tab
3. Add these variables:

```bash
# Firebase Configuration
FIREBASE_SERVICE_ACCOUNT_KEY={"type":"service_account","project_id":"your-project-id","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"firebase-adminsdk-xxx@your-project.iam.gserviceaccount.com","client_id":"...","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"..."}

FIREBASE_PROJECT_ID=your-project-id
```

**Important**: When copying the JSON to Render, ensure it's a single line without line breaks in the private key section.

## Step 7: Test Firebase Configuration

### Backend Test Script

Create `backend/test-firebase.js`:
```javascript
const admin = require('firebase-admin');

// Test Firebase initialization
const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
const projectId = process.env.FIREBASE_PROJECT_ID;

if (serviceAccountKey) {
  try {
    const serviceAccount = JSON.parse(serviceAccountKey);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: projectId
    });
    console.log('✅ Firebase initialized successfully');
    console.log('📱 Project ID:', projectId);
  } catch (error) {
    console.error('❌ Firebase initialization failed:', error.message);
  }
} else {
  console.warn('⚠️ FIREBASE_SERVICE_ACCOUNT_KEY not found');
}
```

Run test:
```bash
cd backend
node test-firebase.js
```

## Step 8: Verify Push Notifications

### Test Endpoint

Your backend includes a test notification endpoint. After deployment, test it:

```bash
curl -X POST https://your-app.render.com/api/admin/notifications \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -d '{
    "title": "Test Notification",
    "message": "Firebase is working!",
    "type": "info",
    "targetAudience": ["all"]
  }'
```

## Troubleshooting

### Common Issues:

1. **"Invalid service account key"**
   - Verify JSON format is correct
   - Ensure no extra spaces or line breaks
   - Check all required fields are present

2. **"Project not found"**
   - Verify FIREBASE_PROJECT_ID matches your Firebase project
   - Ensure service account belongs to correct project

3. **"Permission denied"**
   - Ensure service account has Cloud Messaging Admin role
   - Regenerate service account key if needed

4. **"Invalid registration token"**
   - Flutter app not properly configured
   - FCM token not being generated/stored correctly

### Debug Logs

Enable debug mode to see detailed Firebase logs:
```javascript
process.env.NODE_ENV = 'development';
```

### Service Account Permissions

Ensure your service account has these roles:
- Firebase Admin SDK Service Agent
- Cloud Messaging Admin (if needed)

## Security Best Practices

1. **Never commit service account keys to Git**
2. **Use environment variables for credentials**
3. **Rotate service account keys regularly**
4. **Limit service account permissions to minimum required**
5. **Monitor Firebase usage and quotas**

## Firebase Console Monitoring

After setup, monitor your notifications in Firebase Console:
- Cloud Messaging → Send your first message
- Analytics → Events (if enabled)
- Usage and billing

## Expected Success Messages

After proper configuration, you should see:
```
✅ Firebase Admin SDK initialized successfully
📱 Push notification sent: X/X successful
```

Instead of:
```
⚠️ Firebase service account not configured. Push notifications will be simulated.
🔄 Simulating push notification send...
```

## Next Steps

1. Configure email service (see EMAIL_SETUP_GUIDE.md)
2. Test both services in production
3. Monitor logs for any issues
4. Set up proper error alerting

## Support

If you encounter issues:
1. Check Firebase Console for project status
2. Verify environment variables in Render dashboard
3. Review server logs for detailed error messages
4. Test locally first before deploying to production
