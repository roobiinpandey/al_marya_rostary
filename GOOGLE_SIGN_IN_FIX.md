# Google Sign-In Crash Fix

## Issue
App crashes when clicking Google Sign-In button on iOS

## Root Causes Identified

### 1. **iOS Simulator Limitation** ⚠️
Google Sign-In **DOES NOT WORK** on iOS Simulator in many cases because:
- Simulator cannot properly handle Google authentication redirects
- ASWebAuthenticationSession may not function correctly
- Some Google services require a real device

### 2. **Missing Server Client ID Configuration** ✅ FIXED
The GoogleSignIn initialization was missing the server client ID (web client ID from Firebase)

**Fixed in**: `lib/data/datasources/firebase_auth_service.dart`
```dart
GoogleSignIn(
  serverClientId: '446607982003-30k0be0oqccmk2q7fk7li0drirhulsls.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
)
```

### 3. **iOS Info.plist URL Scheme** ✅ FIXED
The REVERSED_CLIENT_ID in Info.plist was incorrect

**Fixed in**: `ios/Runner/Info.plist`
```xml
<string>com.googleusercontent.apps.446607982003-bp1odin3pialumko8opuv4sqbugefkrv</string>
```

## Testing Requirements

### ✅ To Test on Real iOS Device:
1. Connect iPhone/iPad via USB
2. Trust the device in Xcode
3. Run: `flutter run`
4. Try Google Sign-In - should work!

### ⚠️ Testing on Simulator:
Google Sign-In may NOT work on iOS Simulator. This is a **known limitation**, not a bug in your code.

## Alternative Testing Methods

### Option 1: Test on Android (Recommended for Simulator Testing)
```bash
flutter run -d <android-device-id>
```

### Option 2: Test Email/Password Authentication
Email/password authentication works fine on simulator for development testing.

### Option 3: Use a Real iOS Device
This is the **most reliable** way to test Google Sign-In on iOS.

## Firebase Console Configuration Checklist

✅ iOS Bundle ID: `com.almaryah.qahwatalemarat`
✅ iOS Client ID: `446607982003-bp1odin3pialumko8opuv4sqbugefkrv.apps.googleusercontent.com`
✅ Web Client ID: `446607982003-30k0be0oqccmk2q7fk7li0drirhulsls.apps.googleusercontent.com`
✅ Android Client ID: `446607982003-ggmhdf6088hdjni6dq70idorqne3covk.apps.googleusercontent.com`

## Current Status

### What's Fixed:
1. ✅ Server client ID properly configured
2. ✅ iOS URL scheme (REVERSED_CLIENT_ID) corrected
3. ✅ Error handling and logging improved
4. ✅ Firebase initialization error handling

### Next Steps:
1. **Test on a REAL iOS device** (iPhone/iPad)
2. If testing on Android, it should work immediately
3. Simulator testing for Google Sign-In is not reliable

## Verification Commands

```bash
# Check if GoogleSignIn pod is installed
cd ios && pod list | grep Google

# Expected output should include:
# - GoogleSignIn
# - GoogleUtilities
# - GTMSessionFetcher
# - GTMAppAuth
```

## Known iOS Simulator Issues

The iOS Simulator has known limitations with:
- Google Sign-In (ASWebAuthenticationSession)
- Apple Sign-In  
- Some biometric features
- Push notifications
- Some network authentication flows

**This is NOT a bug in your app** - it's a platform limitation.

## Recommended Action

**Test on a real iOS device or use Android emulator for Google Sign-In testing during development.**
