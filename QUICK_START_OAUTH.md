# 🚀 QUICK START: Google & Facebook Login Setup

**This is a SIMPLE, STRAIGHTFORWARD guide. No complicated stuff.**

---

## ✅ What You Already Have

- ✅ MongoDB Atlas connected
- ✅ Backend API running
- ✅ Firebase packages installed (`firebase_auth`, `google_sign_in`)
- ✅ User model ready
- ✅ Backend OAuth controller created
- ✅ Flutter OAuth service created

---

## 🎯 What You Need to Do (3 Simple Steps)

### STEP 1: Firebase Console (5 minutes)

1. **Go to**: https://console.firebase.google.com/
2. **Click your project** (or create new)
3. **Go to Authentication** → Click "Get Started"
4. **Click "Sign-in method" tab**
5. **Enable these:**
   - ✅ Email/Password (toggle ON)
   - ✅ Google (toggle ON)
   - ✅ Facebook (toggle ON if you want)

6. **Download config files:**
   - **For iOS**: Settings → Your apps → iOS app → Download `GoogleService-Info.plist`
     - Put it in: `ios/Runner/GoogleService-Info.plist`
   
   - **For Android**: Settings → Your apps → Android app → Download `google-services.json`
     - Put it in: `android/app/google-services.json`

**That's it for Firebase!** ✅

---

### STEP 2: Google Cloud Console (5 minutes)

1. **Go to**: https://console.cloud.google.com/
2. **Select your Firebase project** from dropdown (top left)
3. **Go to**: APIs & Services → Credentials
4. **Click "Create Credentials" → "OAuth 2.0 Client ID"**

**Create 2 Client IDs:**

#### A) Android Client
```
Application type: Android
Name: Al Marya Android
Package name: com.almaryah.qahwat_al_emarat
```

**Need SHA-1 fingerprint?** Run this:
```bash
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"
cd android
./gradlew signingReport | grep SHA1
```
Copy the SHA-1 hash and paste it.

#### B) iOS Client (optional, for iOS testing)
```
Application type: iOS
Name: Al Marya iOS
Bundle ID: com.almaryah.qahwatalemarat
```

**Done!** ✅

---

### STEP 3: Add Button to Your App (2 minutes)

**Option A: Use the ready-made button widget**

Open your login page file and add:

```dart
import '../../core/widgets/google_signin_button.dart';

// In your build method, add after your email/password login button:

const SizedBox(height: 24),

// Divider
Row(
  children: [
    Expanded(child: Divider(color: Colors.grey.shade400)),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text('OR', style: TextStyle(color: Colors.grey)),
    ),
    Expanded(child: Divider(color: Colors.grey.shade400)),
  ],
),

const SizedBox(height: 24),

// Google button
GoogleSignInButton(
  onSuccess: () {
    print('Google login successful!');
  },
  onError: (error) {
    print('Google login failed: $error');
  },
),
```

**OR Option B: Quick manual button**

```dart
import '../../core/services/oauth_service.dart';

// Add this variable at top of your State class:
final _oauthService = OAuthService();

// Add this button:
OutlinedButton.icon(
  onPressed: () async {
    final result = await _oauthService.signInWithGoogle();
    if (result['success'] == true) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  },
  icon: Icon(Icons.g_mobiledata),
  label: Text('Continue with Google'),
  style: OutlinedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
  ),
),
```

**Done!** ✅

---

## 🧪 Test It Now!

1. **Start backend:**
   ```bash
   cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery/backend"
   npm start
   ```

2. **Run Flutter app:**
   ```bash
   cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"
   flutter run
   ```

3. **Click "Continue with Google"**
4. **Select your Google account**
5. **You should be logged in!** 🎉

---

## 📊 How It Works

```
User clicks "Google" button
    ↓
Google login popup appears
    ↓
User selects account
    ↓
Firebase authenticates user
    ↓
App sends token to your backend
    ↓
Backend creates/updates user in MongoDB
    ↓
Backend returns JWT token
    ↓
App saves token and navigates to home
    ↓
✅ USER LOGGED IN!
```

---

## 🔍 Check If It Worked

### In Flutter Console:
```
🔵 Starting Google Sign In...
✅ Google account selected: user@gmail.com
✅ Firebase authentication successful
📡 Backend response: 200
✅ Google login successful: user@gmail.com
```

### In Backend Console:
```
🔵 Verifying Google ID token...
✅ Token verified for: user@gmail.com
✅ New Google user created: user@gmail.com (ID: 670e...)
```

### In MongoDB:
```javascript
// User document should have:
{
  email: "user@gmail.com",
  name: "User Name",
  authProvider: "google",
  providerId: "google-user-id",
  firebaseUid: "firebase-uid",
  isEmailVerified: true
}
```

---

## 🐛 Common Issues & Quick Fixes

### ❌ "PlatformException: sign_in_failed"
**Fix**: SHA-1 fingerprint is wrong or missing

```bash
# Get correct SHA-1:
cd android
./gradlew signingReport

# Copy SHA-1 and add to Google Cloud Console
```

### ❌ "API not enabled"
**Fix**: Enable Google Sign-In API

1. Go to Google Cloud Console
2. APIs & Services → Library
3. Search "Google Sign-In"
4. Click "Enable"

### ❌ "Backend authentication failed"
**Fix**: Check backend is running

```bash
# Make sure backend is running on port 5001
curl http://localhost:5001/api/health
```

### ❌ "Invalid ID token"
**Fix**: Firebase config files missing

- Check `ios/Runner/GoogleService-Info.plist` exists
- Check `android/app/google-services.json` exists

---

## 📝 Facebook Login (Optional)

If you want Facebook login too:

1. **Add package** to `pubspec.yaml`:
   ```yaml
   flutter_facebook_auth: ^7.1.1
   ```

2. **Run**: `flutter pub get`

3. **Go to**: https://developers.facebook.com/
4. **Create app** → Enable Facebook Login
5. **Follow same pattern** as Google setup

(Facebook setup is more complex, start with Google first!)

---

## ✅ You're Done!

Your app now has:
- ✅ Email/Password login (existing)
- ✅ Google login (NEW!)
- ✅ All users stored in MongoDB Atlas
- ✅ Single authentication system
- ✅ JWT tokens for API access

**No complicated multi-location user storage.**
**Everything in MongoDB Atlas.**
**Simple and straightforward!**

---

## 🎯 Next Steps (Optional)

1. **Add Facebook login** (if needed)
2. **Add Apple Sign In** (for iOS App Store requirement)
3. **Add profile pictures** from Google/Facebook
4. **Sync user preferences** across devices

---

## 📞 Still Having Issues?

Run the setup checker:
```bash
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"
./setup_oauth.sh
```

It will tell you exactly what's missing!

---

**Created**: October 18, 2025  
**Status**: ✅ Ready to Use  
**Time to Setup**: ~15 minutes  

🎉 **Happy Coding!**
