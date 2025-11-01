# 🔐 ROTATE CREDENTIALS - STEP BY STEP GUIDE

**CRITICAL**: Follow these steps IN ORDER to rotate your exposed credentials.

---

## 📋 EXPOSED CREDENTIALS THAT NEED ROTATION

### 1. MongoDB Password
- **User**: `roobiinpandey_db_user`
- **Exposed Password**: `***REMOVED***`
- **Cluster**: `almaryarostery.2yel8zi.mongodb.net`
- **Database**: `al_marya_rostery`

### 2. Google API Key
- **Key**: `AIzaSyA9PHzkR6CykfVk3yNqY5SDuCP2F6pN3Oc`
- **Used in**: 
  - `android/app/google-services.json`
  - `android/app/src/main/AndroidManifest.xml`

### 3. MongoDB Atlas API Keys
- **Public Key**: `xgjybvct`
- **Private Key**: `ae520a49-2587-4b0b-9c84-329ddbdab1b1`

---

## 🎯 STEP 1: ROTATE MONGODB PASSWORD (15 minutes)

### A. Generate New Password

1. Open Terminal and run:
```bash
# Generate a secure random password
openssl rand -base64 32
```

2. **COPY THE OUTPUT** - This is your new password. Example:
```
dK8mP2vX9qL4nR7wT5yB3hJ6cF1gA0sN8eU4iO2pM=
```

### B. Update MongoDB Atlas

1. Go to: https://cloud.mongodb.com/
2. Login to your account
3. Select your organization
4. Click on your project (almaryarostery)
5. In left sidebar, click **"Database Access"**
6. Find user: `roobiinpandey_db_user`
7. Click **"Edit"** button (pencil icon)
8. Click **"Edit Password"**
9. Paste your new password from Step A
10. Click **"Update User"**
11. Wait 2-3 minutes for changes to propagate

### C. Update Local .env File

Run this command (replace NEW_PASSWORD with your actual password):
```bash
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery/backend"

# Backup current .env
cp .env .env.backup

# Replace password in .env (use your actual new password)
sed -i '' 's/***REMOVED***/YOUR_NEW_PASSWORD_HERE/g' .env
```

### D. Update Render.com Environment Variables

1. Go to: https://dashboard.render.com/
2. Login to your account
3. Find your service: **almaryarostary** (or similar name)
4. Click on the service name
5. Go to **"Environment"** tab
6. Find the variable: `MONGODB_URI`
7. Click **"Edit"** (pencil icon)
8. Replace the old password in the URI:
   ```
   OLD: mongodb+srv://roobiinpandey_db_user:***REMOVED***@almaryarostery...
   NEW: mongodb+srv://roobiinpandey_db_user:YOUR_NEW_PASSWORD@almaryarostery...
   ```
9. Click **"Save Changes"**
10. Render will automatically redeploy (takes ~2-3 minutes)

### E. Test the Connection

Wait 3-4 minutes, then test:
```bash
# Test your API
curl https://almaryarostary.onrender.com/api/health
```

Should return: `{"status":"ok"}` or similar

---

## 🎯 STEP 2: ROTATE MONGODB ATLAS API KEYS (10 minutes)

### A. Create New API Key

1. Go to: https://cloud.mongodb.com/
2. Click your **profile icon** (top right)
3. Select **"Organization Access Manager"**
4. Go to **"API Keys"** tab
5. Click **"Create API Key"**
6. Name: `Al Marya App - $(date +%Y-%m)`
7. Permissions: **"Organization Project Creator"** or **"Organization Read Only"** (depending on needs)
8. Click **"Next"**
9. **COPY** both Public Key and Private Key
10. Add your current IP to API Access List if prompted
11. Click **"Done"**

### B. Delete Old API Key

1. In the same API Keys page
2. Find the old key with public key: `xgjybvct`
3. Click **"..."** (three dots)
4. Click **"Delete"**
5. Confirm deletion

### C. Update Local .env

```bash
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery/backend"

# Edit .env file manually or use sed
# Replace with your new keys:
nano .env

# Update these lines:
MONGODB_ATLAS_PUBLIC_KEY=your_new_public_key
MONGODB_ATLAS_PRIVATE_KEY=your_new_private_key
```

### D. Update Render.com (if these keys are used there)

1. Go to Render dashboard
2. Environment tab
3. Update `MONGODB_ATLAS_PUBLIC_KEY` and `MONGODB_ATLAS_PRIVATE_KEY`
4. Save changes

---

## 🎯 STEP 3: RESTRICT GOOGLE API KEY (10 minutes)

**Note**: Google API keys in `google-services.json` are generally safe for client apps, but we should restrict them.

### Option A: Add Restrictions (Recommended - Faster)

1. Go to: https://console.cloud.google.com/
2. Login with your Google account
3. Select your project (should auto-select Al Marya project)
4. Click **"APIs & Services"** → **"Credentials"**
5. Find API key: `AIzaSyA9PHzkR6CykfVk3yNqY5SDuCP2F6pN3Oc`
6. Click the key name to edit
7. Under **"Application restrictions"**:
   - Select **"Android apps"**
   - Click **"Add an item"**
   - Package name: `com.almaryarostery.app` (check your AndroidManifest.xml)
   - Get SHA-1 fingerprint:
     ```bash
     cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery/android"
     ./gradlew signingReport
     # Copy the SHA-1 from the output
     ```
   - Paste SHA-1 fingerprint
8. Under **"API restrictions"**:
   - Select **"Restrict key"**
   - Check:
     - ✅ Maps SDK for Android
     - ✅ Places API
     - ✅ Geocoding API
     - ✅ Firebase (if listed)
9. Click **"Save"**

### Option B: Create New Key (Most Secure - but requires APK rebuild)

1. In Google Cloud Console → Credentials
2. Click **"Create Credentials"** → **"API Key"**
3. Copy the new key immediately
4. Click **"Restrict Key"**
5. Add restrictions as in Option A
6. Update your files:
   ```bash
   cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"
   
   # Update AndroidManifest.xml
   sed -i '' 's/AIzaSyA9PHzkR6CykfVk3yNqY5SDuCP2F6pN3Oc/YOUR_NEW_KEY/g' android/app/src/main/AndroidManifest.xml
   ```
7. Download new `google-services.json` from Firebase Console
8. Replace `android/app/google-services.json`
9. Rebuild APK

---

## 🎯 STEP 4: VERIFY NO UNAUTHORIZED ACCESS (10 minutes)

### A. Check MongoDB Access Logs

1. MongoDB Atlas dashboard
2. Click your cluster
3. Go to **"Metrics"** tab
4. Look at **"Operations"** and **"Connections"** graphs
5. Check for unusual spikes in last 18 days
6. Go to **"Activity Feed"** (left sidebar)
7. Look for:
   - Unknown IP addresses
   - Unexpected user operations
   - Failed authentication attempts from unknown sources

### B. Check Google Cloud Usage

1. Google Cloud Console
2. Go to **"APIs & Services"** → **"Dashboard"**
3. Check API usage graphs for:
   - Maps API
   - Places API
   - Geocoding API
4. Look for unusual spikes or patterns
5. Go to **"Billing"** → Check for unexpected charges

### C. Check Render Logs

```bash
# Or check via Render dashboard → Logs tab
# Look for unusual activity or errors
```

---

## 🎯 STEP 5: CLEAN UP LOCAL FILES (5 minutes)

```bash
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"

# Verify .env files are NOT tracked
git status | grep ".env"

# If you see any .env files listed, remove them:
git rm --cached backend/.env
git rm --cached .env

# Commit the security updates
git add .gitignore
git commit -m "Security: Update .gitignore to prevent credential leaks"
git push origin main
```

---

## 🎯 STEP 6: TEST EVERYTHING (10 minutes)

### A. Test Backend API
```bash
# Health check
curl https://almaryarostary.onrender.com/api/health

# Test authentication (should fail without token)
curl https://almaryarostary.onrender.com/api/coffees

# Test public endpoint
curl https://almaryarostary.onrender.com/api/sliders
```

### B. Test Flutter App
```bash
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"

# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Test in app:
# - Login/Register
# - View products
# - View profile
# - Place order
```

---

## 📊 COMPLETION CHECKLIST

Mark each item when completed:

### MongoDB
- [ ] Generated new secure password
- [ ] Updated password in MongoDB Atlas
- [ ] Updated `backend/.env` file
- [ ] Updated Render.com environment variables
- [ ] Tested backend connection
- [ ] Created new MongoDB Atlas API keys
- [ ] Deleted old API keys
- [ ] Verified no unauthorized access in logs

### Google API
- [ ] Added restrictions to existing key OR created new key
- [ ] Updated Android app restrictions (SHA-1)
- [ ] Restricted to specific APIs only
- [ ] Updated files if new key created
- [ ] Verified no unusual usage in Cloud Console

### Cleanup
- [ ] Verified `.env` files not in git
- [ ] Committed security updates
- [ ] Tested all app functionality
- [ ] Documented new credentials securely (NOT in git)

### Monitoring
- [ ] Set calendar reminder to rotate credentials in 3 months
- [ ] Bookmarked MongoDB Atlas dashboard
- [ ] Bookmarked Google Cloud Console
- [ ] Subscribed to GitHub security alerts

---

## ⚠️ IMPORTANT REMINDERS

1. **NEVER commit the new credentials to git**
2. **Store new credentials in a password manager** (1Password, LastPass, etc.)
3. **The old credentials in git history are still exposed** - they're just useless now
4. **Test thoroughly** after rotation to ensure nothing breaks
5. **Keep this document LOCAL ONLY** - it contains sensitive info

---

## 🆘 IF SOMETHING BREAKS

### Backend not connecting after password change:
1. Check Render logs for connection errors
2. Verify password was updated correctly (no typos)
3. Wait 5 minutes - sometimes takes time to propagate
4. Check MongoDB Atlas → Database Access → User is still active

### App crashing after Google API key change:
1. Verify SHA-1 fingerprint matches your app
2. Check API restrictions allow all needed APIs
3. May need to regenerate `google-services.json` from Firebase Console
4. Rebuild app: `flutter clean && flutter build apk --release`

### Can't login to MongoDB Atlas:
1. Use password reset
2. Contact MongoDB support if locked out
3. Have backup admin access ready

---

## 📞 NEXT STEPS AFTER COMPLETION

1. **Delete this file** (contains sensitive info):
   ```bash
   rm ROTATE_CREDENTIALS_NOW.md
   ```

2. **Monitor for 1 week**:
   - Check MongoDB logs daily
   - Check Google Cloud usage daily
   - Check Render logs for errors

3. **Set up long-term security**:
   - Install `git-secrets` (prevents future leaks)
   - Set up MongoDB Atlas alerts
   - Enable 2FA on all accounts

---

**START TIME**: ___________
**END TIME**: ___________
**TOTAL TIME**: Should take ~60 minutes total

Good luck! 🔐
