# Firebase and Email Configuration Guide

This guide will help you configure Firebase (for push notifications) and Email services (for user communications) to eliminate the startup warnings.

## Current Status

You'll see these warnings when starting the backend:
- ⚠️ Firebase service account not configured. Push notifications will be simulated.
- ⚠️ Email configuration not complete. Email features will be simulated.

## 🔥 Firebase Configuration (Push Notifications)

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or use existing project
3. Enter project name: `qahwat-al-emarat` (or your preferred name)
4. Enable/disable Google Analytics (optional)
5. Create project

### Step 2: Enable Cloud Messaging

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Go to **Cloud Messaging** tab
3. Note down your **Server Key** (you'll need this later)

### Step 3: Generate Service Account Key

1. In Firebase Console, go to **Project Settings** > **Service Accounts**
2. Click **Generate new private key**
3. Download the JSON file (keep it secure!)

### Step 4: Configure Environment Variables

Add to your `.env` file:

```bash
# Firebase Configuration
FIREBASE_SERVICE_ACCOUNT_KEY={"type":"service_account","project_id":"your-project-id","private_key_id":"..."}
FIREBASE_PROJECT_ID=your-firebase-project-id
```

**Option A: JSON String (Recommended for production)**
Copy the entire content of your service account JSON file and paste it as a single line:

```bash
FIREBASE_SERVICE_ACCOUNT_KEY={"type":"service_account","project_id":"qahwat-al-emarat","private_key_id":"abc123","private_key":"-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n","client_email":"firebase-adminsdk-xyz@qahwat-al-emarat.iam.gserviceaccount.com","client_id":"123456789","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token"}
```

**Option B: File Path (For development)**
```bash
FIREBASE_SERVICE_ACCOUNT_PATH=./config/firebase-service-account.json
```

### Step 5: Test Firebase

Run the test command:
```bash
cd backend
node test-firebase-simple.js
```

## 📧 Email Configuration (SMTP)

### Option 1: Gmail SMTP (Recommended)

#### Step 1: Enable App Passwords
1. Go to your Gmail account settings
2. Enable 2-Factor Authentication
3. Go to **App Passwords**
4. Generate password for "Mail" application
5. Copy the 16-character password

#### Step 2: Configure Environment Variables
Add to your `.env` file:

```bash
# Gmail SMTP Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-16-char-app-password

# Email Sender Information
EMAIL_FROM_NAME=Qahwat Al Emarat
EMAIL_FROM_ADDRESS=your-email@gmail.com
```

### Option 2: Maileroo SMTP (Alternative)

If you prefer Maileroo service:

```bash
# Maileroo SMTP Configuration
SMTP_HOST=smtp.maileroo.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-maileroo-username
SMTP_PASS=your-maileroo-password

# Email Sender Information
EMAIL_FROM_NAME=Qahwat Al Emarat
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
```

### Step 3: Test Email

Run the test command:
```bash
cd backend
node test-maileroo.js
```

## 🚀 Complete Configuration Example

Here's a complete `.env` example with all services configured:

```bash
# Environment Configuration
NODE_ENV=production
PORT=5001

# MongoDB Configuration
MONGODB_URI=***REMOVED******REMOVED***:Nepal1590@***REMOVED***.ph5cazq.mongodb.net/qahwat_al_emarat?retryWrites=true&w=majority&appName=***REMOVED***

# JWT Configuration
JWT_SECRET=qahwat_al_emarat_jwt_secret_key_2025
JWT_EXPIRE=7d
JWT_REFRESH_SECRET=qahwat_al_emarat_refresh_secret_key_2025
JWT_REFRESH_EXPIRE=30d

# CORS Configuration
FRONTEND_URL=http://localhost:3000
BASE_URL=http://localhost:5001

# Admin Configuration
ADMIN_USERNAME=admin
ADMIN_PASSWORD=qahwat2024

# Firebase Configuration
FIREBASE_SERVICE_ACCOUNT_KEY={"type":"service_account","project_id":"qahwat-al-emarat","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"firebase-adminsdk-...@qahwat-al-emarat.iam.gserviceaccount.com","client_id":"...","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token"}
FIREBASE_PROJECT_ID=qahwat-al-emarat

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
EMAIL_FROM_NAME=Qahwat Al Emarat
EMAIL_FROM_ADDRESS=your-email@gmail.com
```

## ✅ Verification

After configuring, restart your backend server:

```bash
cd backend
npm start
```

You should see:
- ✅ Firebase Admin SDK initialized successfully
- ✅ Email service configured successfully

Instead of the warnings!

## 🔧 Troubleshooting

### Firebase Issues:
- Make sure JSON is properly formatted (no line breaks in .env)
- Check project ID matches your Firebase project
- Verify service account has proper permissions

### Email Issues:
- For Gmail: Ensure 2FA is enabled and app password is correct
- Check SMTP settings match your provider
- Verify firewall doesn't block SMTP ports

### Test Commands:
```bash
# Test Firebase
node test-firebase-simple.js

# Test Email
node test-maileroo.js

# Test all services
node test-services.sh
```

## 📱 Mobile App Integration

Once Firebase is configured, you'll need to:

1. Add Firebase SDK to your Flutter app
2. Update `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
3. Implement FCM token registration in the mobile app
4. Test push notifications end-to-end

## 🔐 Security Notes

- Keep service account keys secure
- Use environment variables, never commit keys to code
- Use app passwords for email (not your main password)
- Consider using cloud secret management for production
