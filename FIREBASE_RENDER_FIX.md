# Firebase Service Account Key Fix for Render

## Problem
Your Render deployment is showing this error:
```
❌ Error checking Firebase user: Credential implementation provided to initializeApp() 
via the "credential" property failed to fetch a valid Google OAuth2 access token 
with the following error: "error:1E08010C:DECODER routines::unsupported".
```

**Root Cause**: The `FIREBASE_SERVICE_ACCOUNT_KEY` environment variable on Render contains corrupted or improperly formatted JSON.

---

## Solution: Fix the Firebase Service Account Key

### Step 1: Get Your Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **qahwat-al-emarat**
3. Click the ⚙️ gear icon → **Project Settings**
4. Go to **Service Accounts** tab
5. Click **Generate New Private Key** button
6. Click **Generate Key** to download the JSON file
7. Save it securely (this file contains sensitive credentials!)

### Step 2: Format the Key for Render

We have a script to properly format the key. Run this:

```bash
cd backend/scripts
node format-firebase-key.js /path/to/your/downloaded-serviceAccountKey.json
```

**Example:**
```bash
node format-firebase-key.js ~/Downloads/qahwat-al-emarat-firebase-adminsdk-xxxxx.json
```

The script will:
- ✅ Validate the JSON structure
- ✅ Convert to single-line format
- ✅ Show you what to copy
- ✅ Save it to `firebase-key-formatted.txt`

### Step 3: Update Render Environment Variable

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Open your service: **al-marya-rostary**
3. Click on **Environment** tab in the left sidebar
4. Find the variable: `FIREBASE_SERVICE_ACCOUNT_KEY`
5. Click the **Edit** button (pencil icon)
6. **Delete the old value completely**
7. **Paste the new formatted JSON** (from the script output)
8. Click **Save Changes**

### Step 4: Verify the Fix

After Render redeploys (automatically), check the logs:

✅ **Success** - You should see:
```
✅ Firebase Admin SDK initialized successfully
✅ Firebase User Sync Service using existing Firebase instance
🚀 Starting Auto Firebase Sync Service...
```

❌ **Still failing** - If you still see the decoder error:
1. Make sure you copied the ENTIRE JSON string
2. Ensure there are NO line breaks in the value
3. Verify the JSON starts with `{` and ends with `}`

---

## Alternative: Use Render Secret Files

If environment variables continue to have issues, you can upload the service account key as a secret file:

### Option A: Secret File (More Reliable)

1. In Render Dashboard → Your Service → **Environment** tab
2. Scroll down to **Secret Files** section
3. Click **Add Secret File**
4. Set:
   - **Filename**: `/etc/secrets/firebase-service-account.json`
   - **Contents**: Paste your service account JSON (can be multi-line)
5. Click **Save**

Then update your code to use the file:

```javascript
// In backend/services/firebaseUserSyncService.js
initializeFirebase() {
  try {
    if (admin.apps.length === 0) {
      const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || 
                                 '/etc/secrets/firebase-service-account.json';
      
      let serviceAccount;
      
      // Try to load from secret file first
      if (fs.existsSync(serviceAccountPath)) {
        serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
        console.log('✅ Loaded Firebase credentials from secret file');
      } else {
        // Fallback to environment variable
        const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
        if (serviceAccountKey) {
          serviceAccount = JSON.parse(serviceAccountKey);
          console.log('✅ Loaded Firebase credentials from env var');
        }
      }
      
      if (serviceAccount) {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: serviceAccount.project_id
        });
        this.initialized = true;
        console.log('✅ Firebase User Sync Service initialized');
      }
    }
  } catch (error) {
    console.error('❌ Firebase initialization error:', error.message);
    this.initialized = false;
  }
}
```

---

## Troubleshooting

### Error: "private_key must be a string"
**Cause**: JSON parsing failed, special characters not escaped
**Fix**: Use the format script, don't manually copy-paste

### Error: "ENOENT: no such file or directory"
**Cause**: Using file path on Render without Secret File
**Fix**: Either use environment variable OR set up Secret File

### Error: "Invalid service account"
**Cause**: Wrong project or key deleted/rotated in Firebase
**Fix**: Generate a fresh key from Firebase Console

### Sync still failing after fix
**Cause**: Old instances still running
**Fix**: 
1. Go to Render Dashboard
2. Click **Manual Deploy** → **Clear build cache & deploy**
3. This forces a complete restart

---

## Security Reminder

⚠️ **NEVER commit the service account key to Git!**

Your `.gitignore` already protects:
- `**/firebase-adminsdk*.json`
- `**/serviceAccountKey.json`
- `firebase-key-formatted.txt`

Keep these files LOCAL only. Only add them to Render's environment.

---

## Current Status

- ✅ Server is running
- ✅ MongoDB connected
- ✅ API endpoints working
- ❌ Firebase Admin SDK failing to authenticate
- ❌ User sync not working

Once fixed, you should see:
- ✅ Firebase authentication working
- ✅ User sync operational
- ✅ No more decoder errors

---

## Need Help?

If the issue persists after following these steps:

1. Check Render logs for the exact error message
2. Verify your Firebase project is active
3. Ensure the service account has "Firebase Admin" role
4. Try regenerating a new service account key
5. Consider using Secret Files instead of environment variables
