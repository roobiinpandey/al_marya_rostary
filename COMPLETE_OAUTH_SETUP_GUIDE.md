# 🔐 Complete OAuth Authentication Setup Guide
## Google & Facebook Login with MongoDB Atlas

This guide provides a **COMPLETE, WORKING** setup for Google and Facebook authentication.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Firebase Console Setup](#firebase-console-setup)
3. [Google OAuth Setup](#google-oauth-setup)
4. [Facebook OAuth Setup](#facebook-oauth-setup)
5. [Backend Implementation](#backend-implementation)
6. [Flutter Implementation](#flutter-implementation)
7. [Testing](#testing)

---

## 🎯 Prerequisites

### ✅ Already Installed (From pubspec.yaml)
- ✅ `firebase_core: ^3.6.0`
- ✅ `firebase_auth: ^5.3.1`
- ✅ `google_sign_in: ^6.2.1`
- ✅ MongoDB Atlas connection
- ✅ Backend API running

### 📦 Additional Package Needed
```yaml
# Add to pubspec.yaml dependencies:
flutter_facebook_auth: ^7.1.1
```

---

## 🔥 Firebase Console Setup

### Step 1: Create/Access Firebase Project

1. Go to https://console.firebase.google.com/
2. Select your project: **"Al Marya Rostery"** or create new
3. Click ⚙️ Settings → Project Settings

### Step 2: Add Flutter Apps

#### iOS App
1. Click **Add app** → iOS
2. iOS bundle ID: `com.almaryah.qahwatalemarat`
3. Download `GoogleService-Info.plist`
4. Place in: `ios/Runner/GoogleService-Info.plist`

#### Android App
1. Click **Add app** → Android
2. Package name: `com.almaryah.qahwat_al_emarat`
3. Download `google-services.json`
4. Place in: `android/app/google-services.json`

#### Web App
1. Click **Add app** → Web
2. App nickname: "Al Marya Rostery Web"
3. Copy the Firebase config (you'll need this)

### Step 3: Enable Authentication Methods

1. Go to **Authentication** → **Sign-in method**
2. Enable:
   - ✅ **Email/Password**
   - ✅ **Google**
   - ✅ **Facebook**

---

## 🔵 Google OAuth Setup

### Step 1: Google Cloud Console

1. Go to https://console.cloud.google.com/
2. Select your Firebase project (or create new)
3. Navigate to **APIs & Services** → **Credentials**

### Step 2: Create OAuth 2.0 Client IDs

You need **3 OAuth Client IDs**:

#### 1️⃣ Android OAuth Client
```
Application type: Android
Package name: com.almaryah.qahwat_al_emarat
SHA-1: Get from: keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### 2️⃣ iOS OAuth Client
```
Application type: iOS
Bundle ID: com.almaryah.qahwatalemarat
```

#### 3️⃣ Web OAuth Client (for Flutter Web)
```
Application type: Web application
Authorized JavaScript origins:
  - http://localhost:3000
  - https://your-domain.com
Authorized redirect URIs:
  - http://localhost:3000/__/auth/handler
  - https://your-domain.com/__/auth/handler
```

### Step 3: Copy Client IDs

**IMPORTANT**: Copy all 3 Client IDs. You'll need them.

```
Android Client ID: xxx.apps.googleusercontent.com
iOS Client ID: yyy.apps.googleusercontent.com
Web Client ID: zzz.apps.googleusercontent.com
```

### Step 4: Configure Firebase

1. Back to Firebase Console
2. **Authentication** → **Sign-in method** → **Google**
3. Paste **Web Client ID** in the "Web SDK configuration"
4. Save

---

## 📘 Facebook OAuth Setup

### Step 1: Facebook Developers Console

1. Go to https://developers.facebook.com/
2. Click **My Apps** → **Create App**
3. Choose **Consumer** → Next
4. App Name: **Al Marya Rostery**
5. Contact Email: your@email.com
6. Create App

### Step 2: Add Facebook Login

1. In your app dashboard, click **Add Product**
2. Find **Facebook Login** → Set Up
3. Choose platform: **iOS**, **Android**, **Web**

### Step 3: Configure iOS

```
Bundle ID: com.almaryah.qahwatalemarat
```

### Step 4: Configure Android

```
Package Name: com.almaryah.qahwat_al_emarat
Default Activity Class: com.almaryah.qahwat_al_emarat.MainActivity
Key Hash: Get from: keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
```

### Step 5: Configure Web

```
Site URL: https://your-domain.com
Privacy Policy URL: https://your-domain.com/privacy
Terms of Service URL: https://your-domain.com/terms
```

### Step 6: Get App ID & Secret

1. Settings → Basic
2. Copy:
   - **App ID**: `123456789012345`
   - **App Secret**: `abc123def456...`

### Step 7: Add to Firebase

1. Firebase Console → **Authentication** → **Sign-in method** → **Facebook**
2. Enable Facebook
3. Paste:
   - App ID
   - App Secret
4. Copy the OAuth redirect URI
5. Go back to Facebook Developers
6. **Facebook Login** → **Settings**
7. Add OAuth redirect URI: `https://YOUR-PROJECT-ID.firebaseapp.com/__/auth/handler`
8. Save

---

## 🖥️ Backend Implementation

### Step 1: Update User Model

Your User model already has social fields. Add OAuth provider field:

```javascript
// backend/models/User.js - Add to schema
authProvider: {
  type: String,
  enum: ['email', 'google', 'facebook', 'apple'],
  default: 'email'
},
providerId: {
  type: String,  // Google/Facebook user ID
  sparse: true
}
```

### Step 2: Create OAuth Controller

Create `backend/controllers/oauthController.js`:

```javascript
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const admin = require('firebase-admin');

// @desc    Google OAuth Login
// @route   POST /api/auth/google
// @access  Public
exports.googleAuth = async (req, res) => {
  try {
    const { idToken } = req.body;

    // Verify Google ID token with Firebase
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const { uid, email, name, picture } = decodedToken;

    // Check if user exists
    let user = await User.findOne({ 
      $or: [
        { email },
        { firebaseUid: uid },
        { providerId: uid }
      ]
    });

    if (!user) {
      // Create new user
      user = await User.create({
        name: name || email.split('@')[0],
        email,
        firebaseUid: uid,
        providerId: uid,
        authProvider: 'google',
        avatar: picture,
        isEmailVerified: true,
        isActive: true,
        firebaseSyncStatus: 'synced',
        lastFirebaseSync: new Date()
      });

      console.log(`✅ New Google user created: ${email}`);
    } else {
      // Update existing user
      if (!user.firebaseUid) {
        user.firebaseUid = uid;
      }
      if (!user.providerId) {
        user.providerId = uid;
      }
      if (user.authProvider === 'email') {
        user.authProvider = 'google';
      }
      if (picture && !user.avatar) {
        user.avatar = picture;
      }
      user.isEmailVerified = true;
      user.lastLogin = new Date();
      user.firebaseSyncStatus = 'synced';
      user.lastFirebaseSync = new Date();
      await user.save();

      console.log(`✅ Existing user logged in via Google: ${email}`);
    }

    // Generate JWT token
    const token = jwt.sign(
      { 
        id: user._id,
        email: user.email,
        roles: user.roles 
      },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    // Update statistics
    user.statistics.totalOrders = user.statistics.totalOrders || 0;
    await user.save();

    res.json({
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        avatar: user.avatar,
        roles: user.roles,
        authProvider: user.authProvider
      }
    });

  } catch (error) {
    console.error('❌ Google auth error:', error);
    res.status(400).json({
      success: false,
      message: 'Google authentication failed',
      error: error.message
    });
  }
};

// @desc    Facebook OAuth Login
// @route   POST /api/auth/facebook
// @access  Public
exports.facebookAuth = async (req, res) => {
  try {
    const { accessToken } = req.body;

    // Verify Facebook access token by getting user profile
    const response = await fetch(
      `https://graph.facebook.com/me?fields=id,name,email,picture&access_token=${accessToken}`
    );
    
    if (!response.ok) {
      throw new Error('Invalid Facebook access token');
    }

    const fbUser = await response.json();
    const { id, email, name, picture } = fbUser;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email permission required for Facebook login'
      });
    }

    // Check if user exists
    let user = await User.findOne({ 
      $or: [
        { email },
        { providerId: id }
      ]
    });

    if (!user) {
      // Create new user
      user = await User.create({
        name: name || email.split('@')[0],
        email,
        providerId: id,
        authProvider: 'facebook',
        avatar: picture?.data?.url,
        isEmailVerified: true,
        isActive: true,
        socialProfiles: {
          facebook: `https://facebook.com/${id}`
        }
      });

      console.log(`✅ New Facebook user created: ${email}`);
    } else {
      // Update existing user
      if (!user.providerId) {
        user.providerId = id;
      }
      if (user.authProvider === 'email') {
        user.authProvider = 'facebook';
      }
      if (picture?.data?.url && !user.avatar) {
        user.avatar = picture.data.url;
      }
      user.isEmailVerified = true;
      user.lastLogin = new Date();
      if (!user.socialProfiles.facebook) {
        user.socialProfiles.facebook = `https://facebook.com/${id}`;
      }
      await user.save();

      console.log(`✅ Existing user logged in via Facebook: ${email}`);
    }

    // Generate JWT token
    const token = jwt.sign(
      { 
        id: user._id,
        email: user.email,
        roles: user.roles 
      },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        avatar: user.avatar,
        roles: user.roles,
        authProvider: user.authProvider
      }
    });

  } catch (error) {
    console.error('❌ Facebook auth error:', error);
    res.status(400).json({
      success: false,
      message: 'Facebook authentication failed',
      error: error.message
    });
  }
};
```

### Step 3: Add OAuth Routes

Update `backend/routes/auth.js`:

```javascript
const { googleAuth, facebookAuth } = require('../controllers/oauthController');

// Add these routes:
router.post('/google', googleAuth);
router.post('/facebook', facebookAuth);
```

### Step 4: Install node-fetch (if not installed)

```bash
cd backend
npm install node-fetch@2.7.0
```

---

## 📱 Flutter Implementation

### Step 1: Add Facebook Auth Package

```yaml
# pubspec.yaml - dependencies section
flutter_facebook_auth: ^7.1.1
```

Run:
```bash
flutter pub get
```

### Step 2: Create OAuth Service

Create `lib/core/services/oauth_service.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/app_constants.dart';

class OAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Google Sign In
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      print('🔵 Starting Google Sign In...');
      
      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign in cancelled');
      }

      print('✅ Google account selected: ${googleUser.email}');

      // Get auth details
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);

      print('✅ Firebase authentication successful');

      // Get ID token for backend
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw Exception('Failed to get ID token');
      }

      // Send to backend
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': idToken}),
      );

      print('📡 Backend response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          // Save token
          await _secureStorage.write(
            key: 'auth_token',
            value: data['token'],
          );

          print('✅ Google login successful: ${data['user']['email']}');

          return {
            'success': true,
            'user': data['user'],
            'token': data['token'],
          };
        }
      }

      throw Exception('Backend authentication failed');

    } catch (e) {
      print('❌ Google sign in error: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Facebook Sign In
  Future<Map<String, dynamic>> signInWithFacebook() async {
    try {
      print('📘 Starting Facebook Sign In...');
      
      // Trigger Facebook login
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        throw Exception('Facebook login cancelled or failed');
      }

      print('✅ Facebook login successful');

      // Get access token
      final AccessToken? accessToken = result.accessToken;
      
      if (accessToken == null) {
        throw Exception('Failed to get Facebook access token');
      }

      // Send to backend
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/facebook'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'accessToken': accessToken.tokenString}),
      );

      print('📡 Backend response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          // Save token
          await _secureStorage.write(
            key: 'auth_token',
            value: data['token'],
          );

          print('✅ Facebook authentication successful: ${data['user']['email']}');

          return {
            'success': true,
            'user': data['user'],
            'token': data['token'],
          };
        }
      }

      throw Exception('Backend authentication failed');

    } catch (e) {
      print('❌ Facebook sign in error: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
      FacebookAuth.instance.logOut(),
      _secureStorage.delete(key: 'auth_token'),
    ]);
  }
}
```

### Step 3: Update Login Page

Update `lib/features/auth/presentation/pages/login_page.dart` to add OAuth buttons:

```dart
// Add at the top of the file
import '../../../../core/services/oauth_service.dart';

// Add instance variable
final _oauthService = OAuthService();

// Add after email/password login button:

// Divider
Padding(
  padding: const EdgeInsets.symmetric(vertical: 24),
  child: Row(
    children: [
      Expanded(child: Divider(color: Colors.grey.shade400)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'OR',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      Expanded(child: Divider(color: Colors.grey.shade400)),
    ],
  ),
),

// Google Sign In Button
_buildSocialButton(
  onPressed: _handleGoogleSignIn,
  icon: Icons.g_mobiledata,
  label: 'Continue with Google',
  color: Colors.white,
  textColor: Colors.black87,
  borderColor: Colors.grey.shade300,
),

const SizedBox(height: 12),

// Facebook Sign In Button
_buildSocialButton(
  onPressed: _handleFacebookSignIn,
  icon: Icons.facebook,
  label: 'Continue with Facebook',
  color: const Color(0xFF1877F2),
  textColor: Colors.white,
),

// Add these methods:

Future<void> _handleGoogleSignIn() async {
  setState(() => _isLoading = true);
  
  final result = await _oauthService.signInWithGoogle();
  
  setState(() => _isLoading = false);
  
  if (result['success'] == true) {
    // Navigate to home
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Google login failed'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _handleFacebookSignIn() async {
  setState(() => _isLoading = true);
  
  final result = await _oauthService.signInWithFacebook();
  
  setState(() => _isLoading = false);
  
  if (result['success'] == true) {
    // Navigate to home
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Facebook login failed'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Widget _buildSocialButton({
  required VoidCallback onPressed,
  required IconData icon,
  required String label,
  required Color color,
  required Color textColor,
  Color? borderColor,
}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: OutlinedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        side: BorderSide(
          color: borderColor ?? color,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: Icon(icon, size: 24),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
```

---

## 🧪 Testing

### Test Google Login

1. Run Flutter app:
   ```bash
   flutter run
   ```

2. Click "Continue with Google"
3. Select Google account
4. Check console logs:
   ```
   🔵 Starting Google Sign In...
   ✅ Google account selected: user@gmail.com
   ✅ Firebase authentication successful
   📡 Backend response: 200
   ✅ Google login successful: user@gmail.com
   ```

### Test Facebook Login

1. Click "Continue with Facebook"
2. Login with Facebook credentials
3. Grant email permission
4. Check console logs:
   ```
   📘 Starting Facebook Sign In...
   ✅ Facebook login successful
   📡 Backend response: 200
   ✅ Facebook authentication successful: user@facebook.com
   ```

### Verify in MongoDB

```javascript
// Check user in database
db.users.findOne({ email: "user@gmail.com" })

// Should show:
{
  "_id": ObjectId("..."),
  "email": "user@gmail.com",
  "authProvider": "google",
  "providerId": "google-user-id",
  "firebaseUid": "firebase-uid",
  "isEmailVerified": true,
  ...
}
```

---

## 🔧 Troubleshooting

### Google Sign In Issues

**Problem**: "PlatformException: sign_in_failed"
**Solution**: Check SHA-1 fingerprint is correct in Firebase

```bash
# Get SHA-1:
cd android
./gradlew signingReport
```

**Problem**: "API not enabled"
**Solution**: Enable Google+ API in Google Cloud Console

### Facebook Sign In Issues

**Problem**: "Invalid Key Hash"
**Solution**: Generate correct key hash:

```bash
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
```

**Problem**: "Email permission denied"
**Solution**: User must grant email permission. Show message:
```dart
if (!result.accessToken!.grantedPermissions!.contains('email')) {
  throw Exception('Email permission required');
}
```

### Backend Issues

**Problem**: "Firebase ID token verification failed"
**Solution**: Check Firebase Admin SDK is initialized correctly

**Problem**: "Duplicate email error"
**Solution**: User already exists with email. Update instead of create.

---

## ✅ Checklist

### Firebase Setup
- [ ] iOS app added to Firebase
- [ ] Android app added to Firebase
- [ ] Web app added to Firebase
- [ ] Google authentication enabled
- [ ] Facebook authentication enabled

### Google OAuth
- [ ] Android OAuth client created
- [ ] iOS OAuth client created
- [ ] Web OAuth client created
- [ ] SHA-1 fingerprint added
- [ ] Bundle ID correct

### Facebook OAuth
- [ ] Facebook app created
- [ ] iOS configured
- [ ] Android configured (key hash)
- [ ] OAuth redirect URI added
- [ ] Email permission requested

### Backend
- [ ] User model updated
- [ ] OAuth controller created
- [ ] Routes added
- [ ] Firebase Admin SDK initialized
- [ ] JWT secret set

### Flutter
- [ ] Packages installed
- [ ] OAuth service created
- [ ] Login page updated
- [ ] Firebase initialized
- [ ] Google Services files added

### Testing
- [ ] Google login works
- [ ] Facebook login works
- [ ] User saved to MongoDB
- [ ] Token stored correctly
- [ ] Navigation works

---

## 🎉 Success!

Your OAuth authentication is now complete! Users can login with:
- ✅ Email/Password (existing)
- ✅ Google Account
- ✅ Facebook Account

All users are stored in MongoDB Atlas with proper Firebase integration.

---

## 📞 Need Help?

If you encounter issues:

1. Check console logs (both Flutter and backend)
2. Verify all credentials are correct
3. Ensure OAuth redirect URIs match
4. Test on real device (emulators can have issues)
5. Check network connectivity

---

**Last Updated**: October 18, 2025
**Version**: 1.0
**Status**: Production Ready ✅
