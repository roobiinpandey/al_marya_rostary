# 🔥 Firebase Setup Guide

## 🚨 Important Security Notice

Firebase configuration files contain API keys and should **NEVER** be committed to public repositories. This guide helps you set up Firebase properly while keeping your credentials secure.

## 📋 Required Firebase Configuration Files

Your project needs these files (they are now excluded from Git):

1. `android/app/google-services.json` (Android)
2. `ios/Runner/GoogleService-Info.plist` (iOS) 
3. `lib/firebase_options.dart` (Flutter)

## 🔧 Setup Instructions

### Step 1: Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing `***REMOVED***`
3. Enable Authentication, Firestore, and Cloud Messaging

### Step 2: Generate Configuration Files

#### For Android:
1. In Firebase Console → Project Settings → General
2. Click "Add app" → Android
3. Enter package name: `com.qahwat.app`
4. Download `google-services.json`
5. Place in `android/app/google-services.json`

#### For iOS:
1. In Firebase Console → Project Settings → General  
2. Click "Add app" → iOS
3. Enter bundle ID: `qahwatalemarat`
4. Download `GoogleService-Info.plist`
5. Place in `ios/Runner/GoogleService-Info.plist`

#### For Flutter:
```bash
# Install FlutterFire CLI
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# Generate firebase_options.dart
flutterfire configure --project=your-firebase-project-id
```

This will create `lib/firebase_options.dart`

### Step 3: Verify Firebase Setup

After adding the configuration files:

1. **Check file placement:**
   ```
   android/app/google-services.json ✅
   ios/Runner/GoogleService-Info.plist ✅  
   lib/firebase_options.dart ✅
   ```

2. **Test Firebase initialization:**
   ```bash
   flutter run
   # Check logs for "Firebase initialized successfully"
   ```

### Step 4: Environment Variables

Add to your `backend/.env`:

```properties
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_SERVICE_ACCOUNT_KEY={"type":"service_account","project_id":"your-project-id",...}
```

**⚠️ Never commit the `.env` file to Git!**

## 🔐 Security Best Practices

### ✅ Do:
- Keep Firebase config files local only
- Use different Firebase projects for dev/staging/production
- Enable App Check in Firebase Console
- Restrict API keys to specific platforms

### ❌ Don't:
- Commit Firebase config files to Git
- Share API keys publicly
- Use production Firebase in development
- Hardcode secrets in source code

## 🛠️ Project-Specific Configuration

### Authentication Setup:
1. Firebase Console → Authentication → Sign-in method
2. Enable Google Sign-in
3. Add your app's SHA-1 fingerprint (Android)
4. Configure authorized domains

### Push Notifications:
1. Firebase Console → Cloud Messaging
2. Upload APNs certificate (iOS)
3. Test notification delivery

### Firestore Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only authenticated users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public read for coffee products
    match /coffees/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## 🧪 Testing Configuration

### Test Authentication:
```dart
// In your Flutter app
try {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Firebase initialized successfully');
} catch (e) {
  print('Firebase initialization error: $e');
}
```

### Test Backend Connection:
```bash
# Test Firebase Admin SDK
cd backend
node -e "
const admin = require('firebase-admin');
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: process.env.FIREBASE_PROJECT_ID
});
console.log('Firebase Admin SDK initialized successfully');
"
```

## 📞 Troubleshooting

### Common Issues:

1. **"Default FirebaseApp is not initialized"**
   - Check `lib/firebase_options.dart` exists
   - Verify `Firebase.initializeApp()` is called in `main()`

2. **Google Sign-in not working**
   - Verify SHA-1 fingerprint is added to Firebase Console
   - Check `google-services.json` is in correct location

3. **iOS build fails**
   - Ensure `GoogleService-Info.plist` is added to Xcode project
   - Check bundle ID matches Firebase configuration

4. **Push notifications not received**
   - Verify FCM token generation
   - Check notification permissions
   - Test with Firebase Console → Cloud Messaging

## 📱 Platform-Specific Setup

### Android:
- Add SHA-1 fingerprint to Firebase Console
- Enable Google Play Services
- Test on real device (emulator may have issues)

### iOS:
- Add APNs certificate to Firebase Console
- Enable Push Notifications capability in Xcode
- Test on real device (simulator can't receive notifications)

## 🚀 Production Deployment

### Before deploying:
1. Use separate Firebase projects for staging/production
2. Update configuration files for production environment
3. Enable Firebase App Check for additional security
4. Set up monitoring and alerts

### Production checklist:
- [ ] Production Firebase project configured
- [ ] API keys restricted to production domains/apps
- [ ] Security rules properly configured
- [ ] Monitoring enabled
- [ ] Backup strategy in place

## 📚 Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Security Best Practices](https://firebase.google.com/docs/rules/security)
- [Firebase App Check](https://firebase.google.com/docs/app-check)
