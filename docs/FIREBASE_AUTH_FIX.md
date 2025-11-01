# Firebase Authentication Troubleshooting Guide

## Issue: Cannot login & "Account already exists" error when registering

## Root Causes & Solutions

### 1. Enable Email/Password Authentication in Firebase Console ⭐ MOST LIKELY ISSUE

**Check Firebase Console:**
1. Go to: https://console.firebase.google.com/project/qahwatapp/authentication/providers
2. Click on "Email/Password" provider
3. Make sure **"Email/Password"** is **ENABLED**
4. Also check if **"Email link (passwordless sign-in)"** is enabled (optional)

**If it's disabled:**
- Click "Enable"
- Save changes
- Try creating a new account in your app

---

### 2. Check for Existing Accounts

**View registered users:**
1. Go to: https://console.firebase.google.com/project/qahwatapp/authentication/users
2. Check if your email is already registered
3. If yes, try logging in with that account instead of registering

**Reset a user's password:**
- In the Users tab, click the 3 dots menu next to the user
- Select "Send password reset email"
- Check your email and reset password
- Try logging in again

---

### 3. Account Exists with Different Provider

**Error:** "The account already exists for that email"

**This means:**
- You previously signed in with Google/Apple using that email
- Now you're trying to create an email/password account with the same email
- Firebase considers these as different authentication methods for the SAME account

**Solution:**
1. Sign in using the original method (Google/Apple)
2. OR delete the existing account from Firebase Console
3. Then create new email/password account

---

### 4. Firebase Rules Check

**Check Firestore Security Rules:**
1. Go to: https://console.firebase.google.com/project/qahwatapp/firestore/rules
2. Make sure rules allow authenticated users to read/write

**Example rules:**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

### 5. Test with Debug Tool

Run this test from your app to see detailed error messages:

1. Open the app
2. Try to register with a new email
3. Check the console/logs for detailed Firebase error codes

**Common error codes:**
- `email-already-in-use` - Account exists, try logging in
- `weak-password` - Password too short (min 6 characters)
- `invalid-email` - Email format is wrong
- `operation-not-allowed` - Email/password auth is disabled in Firebase Console

---

### 6. Clear App Data & Try Again

**For iOS Simulator:**
```bash
# Stop the app
# Then reset it:
xcrun simctl uninstall booted qahwatalemarat
```

**Then reinstall:**
```bash
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"
flutter run
```

---

## Quick Test Steps

1. **First, check Firebase Console:**
   - Authentication > Sign-in method
   - Verify "Email/Password" is ENABLED ✅

2. **Check existing users:**
   - Authentication > Users
   - See if your test email is already there

3. **Try this test account:**
   - Email: `test@almaryarostery.com`
   - Password: `test123456`
   - Try registering this new account

4. **Watch console logs:**
   - Look for Firebase error codes
   - Share the exact error with me

---

## Your Firebase Project Details

- **Project ID:** qahwatapp
- **Console URL:** https://console.firebase.google.com/project/qahwatapp
- **Auth URL:** https://console.firebase.google.com/project/qahwatapp/authentication

---

## If Still Not Working

**Share these details:**
1. Exact error message you see in the app
2. Console logs (any Firebase error codes)
3. Screenshot of Firebase Console > Authentication > Sign-in method
4. Screenshot of Firebase Console > Authentication > Users

Then I can provide a more specific fix!
