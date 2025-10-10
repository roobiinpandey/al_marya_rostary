# 🔐 Security Configuration Guide

## ⚠️ Critical Security Notice

**ALL CREDENTIALS AND API KEYS MUST BE CONFIGURED LOCALLY - NEVER COMMIT TO GIT**

This repository contains **NO REAL CREDENTIALS**. All examples use placeholder formats to prevent accidental exposure.

## 🚨 What You Need to Set Up Locally

### 1. Environment Variables (.env)

**Copy `backend/.env.example` to `backend/.env` and replace ALL placeholders:**

```bash
# Copy template
cp backend/.env.example backend/.env

# Edit with your real values
nano backend/.env
```

**Replace these placeholders with real values:**

```properties
# Database - Get from MongoDB Atlas
MONGODB_URI=***REMOVED***[USERNAME]:[PASSWORD]@[CLUSTER].mongodb.net/[DATABASE]?retryWrites=true&w=majority&appName=[APP_NAME]

# JWT Secrets - Generate strong random strings
JWT_SECRET=[RANDOM_32_CHAR_STRING]
JWT_REFRESH_SECRET=[ANOTHER_RANDOM_32_CHAR_STRING]

# Firebase - Download from Firebase Console
FIREBASE_SERVICE_ACCOUNT_KEY=[FIREBASE_SERVICE_ACCOUNT_JSON]
FIREBASE_PROJECT_ID=[YOUR_FIREBASE_PROJECT_ID]

# Admin Credentials - Create strong passwords
ADMIN_USERNAME=[YOUR_ADMIN_USERNAME]
ADMIN_PASSWORD=[STRONG_ADMIN_PASSWORD]
```

### 2. Firebase Configuration Files

**Generate these files using Firebase Console:**

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist` 
- `lib/firebase_options.dart`

**See `FIREBASE_SETUP_GUIDE.md` for detailed instructions.**

### 3. MongoDB Atlas Setup

**Follow `MONGODB_ATLAS_SETUP.md` to:**
- Create MongoDB Atlas cluster
- Set up database user
- Configure IP whitelist
- Get connection string

## 🛡️ Security Checklist

### ✅ Required Actions:

- [ ] Copy `.env.example` to `.env` with real values
- [ ] Generate Firebase configuration files locally
- [ ] Set up MongoDB Atlas with proper security
- [ ] Use strong passwords and secrets (min 32 characters)
- [ ] Enable 2FA on all cloud services
- [ ] Restrict API keys to specific domains/IPs

### ❌ Never Do:

- [ ] ~~Commit `.env` files to Git~~
- [ ] ~~Share API keys in code or documentation~~
- [ ] ~~Use weak passwords or default credentials~~
- [ ] ~~Expose database credentials publicly~~
- [ ] ~~Use production credentials in development~~

## 🔒 Files Excluded from Git

These files are automatically excluded via `.gitignore`:

```
# Environment variables
.env
.env.local
.env.production
.env.development
backend/.env
backend/.env.local

# Firebase configuration files (contain API keys)
ios/Runner/GoogleService-Info.plist
android/app/google-services.json
lib/firebase_options.dart
```

## 🚀 Quick Setup Commands

```bash
# 1. Install dependencies
cd backend && npm install
cd ../
flutter pub get

# 2. Set up environment
cp backend/.env.example backend/.env
# Edit backend/.env with your credentials

# 3. Generate Firebase config
npm install -g firebase-tools
dart pub global activate flutterfire_cli
flutterfire configure --project=[YOUR_FIREBASE_PROJECT_ID]

# 4. Test setup
cd backend && npm start
# In another terminal:
flutter run
```

## 📞 Getting Help

If you need help with:

- **MongoDB Setup**: See `MONGODB_ATLAS_SETUP.md`
- **Firebase Setup**: See `FIREBASE_SETUP_GUIDE.md`  
- **Deployment**: See `DEPLOYMENT_GUIDE.md`
- **General Questions**: Check GitHub Issues or create new issue

## 🔐 Security Best Practices

### Production Deployment:
- Use separate credentials for development/staging/production
- Enable monitoring and alerts
- Regularly rotate API keys and passwords
- Use environment-specific Firebase projects
- Enable database audit logging

### Development:
- Never commit real credentials
- Use different credentials than production
- Test with non-sensitive data
- Enable Git hooks to prevent credential commits

---

**Remember: This repository is public. Keep all credentials local and secure!** 🔒
