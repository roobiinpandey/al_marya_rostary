# Security Guidelines

## ⚠️ Important Security Information

This repository contains a Flutter mobile application with a Node.js backend. Please follow these security guidelines carefully.

## 🔐 Sensitive Files (Already Protected)

The following files contain sensitive credentials and are already in `.gitignore`:

### Backend Environment Variables
- `backend/.env`
- `backend/.env.local`
- `backend/FIREBASE_SECRET_KEY.md`
- `backend/service-account-key.json`
- `backend/COMPLETE_ENV_VARIABLES.txt`
- All files matching `**/service-account*.json`

### Never Commit These
- MongoDB connection strings with credentials
- JWT secrets
- Firebase admin SDK keys
- Cloudinary API secrets
- Any file containing real passwords or tokens

## ✅ Safe to Commit (Client-Side Credentials)

These files contain **client-side** API keys that are safe to expose:

### Firebase Client Configuration (Public by Design)
- `lib/firebase_options.dart` - Flutter Firebase config
- `android/app/google-services.json` - Android Firebase config
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase config

**Note:** Firebase client API keys (like `AIzaSy...`) are designed to be public. They are protected by Firebase Security Rules on the backend.

## 🛡️ Security Best Practices

### 1. Environment Variables
Always use environment variables for sensitive data:

```javascript
// ✅ CORRECT
const MONGODB_URI = process.env.MONGODB_URI;

// ❌ WRONG - Never hardcode credentials
const MONGODB_URI = 'mongodb+srv://user:password@cluster...';
```

### 2. Backend Scripts
All backend scripts now require environment variables:
- `backend/scripts/check-subscriptions.js`
- `backend/scripts/seed-subscription-plans.js`

Run them with:
```bash
cd backend
MONGODB_URI="your_connection_string" node scripts/script-name.js
```

### 3. Firebase Admin SDK
- Service account keys must stay in `.env` or secure storage
- Never commit `service-account-key.json` or similar files
- Use environment variables: `FIREBASE_SERVICE_ACCOUNT_KEY`

### 4. API Keys & Secrets
Store in environment variables:
- `JWT_SECRET` - At least 32 characters
- `MONGODB_URI` - Database connection string
- `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`
- `FIREBASE_SERVICE_ACCOUNT_KEY`

## 🚀 Deployment Security

### For Render.com (Backend)
Set environment variables in the Render dashboard:
1. Go to your service settings
2. Navigate to "Environment" tab
3. Add all required variables from `backend/.env`

### For Firebase Hosting (Frontend)
1. Use Firebase environment config
2. Never expose backend API keys in Flutter code
3. Use Firebase Security Rules to protect data

## 📋 Pre-Push Checklist

Before pushing to GitHub, verify:

- [ ] No `.env` files committed
- [ ] No hardcoded passwords or secrets
- [ ] All scripts use environment variables
- [ ] No `service-account-key.json` files
- [ ] `.gitignore` is up to date
- [ ] Backend runs with environment variables only

## 🔍 Security Audit Commands

Check for potential security issues:

```bash
# Search for hardcoded credentials
grep -r "mongodb+srv://" --exclude-dir=node_modules --exclude-dir=.git

# Search for API keys
grep -r "api_key\s*=\s*['\"]" --exclude-dir=node_modules --exclude-dir=.git

# Search for passwords
grep -r "password\s*=\s*['\"]" --exclude-dir=node_modules --exclude-dir=.git
```

## 📞 Security Contact

If you discover a security vulnerability, please:
1. Do NOT create a public GitHub issue
2. Contact the repository owner directly
3. Provide details of the vulnerability
4. Allow time for the issue to be fixed before disclosure

## ✅ Security Status

**Last Security Audit:** November 3, 2025
- Hardcoded MongoDB credentials removed
- All backend scripts updated to require environment variables
- `.gitignore` properly configured
- Client-side Firebase configs are intentionally public (safe)

---

**Remember:** When in doubt, use environment variables! Never commit credentials.
