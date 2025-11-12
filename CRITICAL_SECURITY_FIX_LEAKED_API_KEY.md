# 🚨 CRITICAL: Leaked Google API Key - IMMEDIATE ACTION REQUIRED

**Alert Date**: November 10, 2025  
**Severity**: 🔴 CRITICAL - PUBLIC LEAK  
**Leaked Key**: `AIzaSyDpDdjerkO5z8naLmcfgdQ76k-V8mmsmuU`  
**Location**: `android/app/google-services.json`  
**Detected by**: GitHub Secret Scanning (2 minutes ago)

---

## ⚠️ WHAT HAPPENED

GitHub detected that your Google API Key was exposed in the pushed commit:
- **Commit**: b5f0c08 (release: v1.0.0)
- **Branch**: release/v1.0.0
- **File**: android/app/google-services.json
- **Status**: 🔴 PUBLIC - Anyone can see it on GitHub

This is a **critical security issue** that must be fixed IMMEDIATELY.

---

## 🔧 IMMEDIATE REMEDIATION STEPS

### Step 1: Revoke the Leaked Google API Key (5 minutes)

1. Go to: https://console.cloud.google.com/apis/credentials
2. Log in with your Google Cloud account
3. Select project: **almaryah-rostery**
4. Find the API key: `AIzaSyDpDdjerkO5z8naLmcfgdQ76k-V8mmsmuU`
5. Click the key to open details
6. Click **REGENERATE KEY** or **DELETE**
7. Confirm the revocation

**Important**: This will break any services using this key until you add the new key.

### Step 2: Generate New Google API Key (2 minutes)

1. In Google Cloud Console, go to **APIs & Services > Credentials**
2. Click **+ Create Credentials > API Key**
3. Choose: **Restrict key** (recommended)
4. Application restrictions: Select **Android apps**
5. Add your package name: `com.almaryahrostery`
6. Add certificate SHA-1: `51abd25676af00fe0be6da8f009954ef59925fde`
7. Save the new key

**New Key**: (You'll generate this and add below)

### Step 3: Remove Leaked Key from Git History (10 minutes)

**WARNING**: This will rewrite git history. All developers need to re-clone.

**Option A: Using git-filter-repo (Recommended)**

```bash
# Install git-filter-repo if not already installed
brew install git-filter-repo

# Navigate to repo
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"

# Create a file with the string to remove
echo 'AIzaSyDpDdjerkO5z8naLmcfgdQ76k-V8mmsmuU' > /tmp/secrets.txt

# Remove from all history
git filter-repo --replace-text /tmp/secrets.txt

# Force push to GitHub (THIS WILL OVERWRITE HISTORY)
git push --force --all
git push --force --tags
```

**Option B: Manual Fix (Safer)**

If you want to keep the current release/v1.0.0 and just fix it:

```bash
# 1. Checkout the branch
git checkout release/v1.0.0

# 2. Edit the file (see below)
# 3. Commit the change
git commit --amend -m "security: Rotate Google API Key"

# 4. Force push
git push --force origin release/v1.0.0
git push --force origin v1.0.0
```

### Step 4: Update android/app/google-services.json

Replace the old key with your new generated key:

**OLD** (REVOKED):
```json
"current_key": "AIzaSyDpDdjerkO5z8naLmcfgdQ76k-V8mmsmuU"
```

**NEW** (Get this from Google Cloud Console):
```json
"current_key": "[YOUR_NEW_API_KEY_HERE]"
```

### Step 5: Add google-services.json to .gitignore (Prevents Future Leaks)

Add to `/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery/android/.gitignore`:

```gitignore
# Firebase configuration - Never commit API keys
google-services.json
```

Then remove from git tracking:
```bash
git rm --cached android/app/google-services.json
```

### Step 6: Create Local-Only Template

Create `android/app/google-services.json.example` (safe template):

```json
{
  "project_info": {
    "project_number": "506062617127",
    "project_id": "almaryah-rostery",
    "storage_bucket": "almaryah-rostery.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:506062617127:android:388c9d9cc29f6bd1046c02",
        "android_client_info": {
          "package_name": "com.almaryahrostery"
        }
      },
      "oauth_client": [
        {
          "client_id": "506062617127-sh9vpt84p4fg7a85tdl2lnfjhcep6ng3.apps.googleusercontent.com",
          "client_type": 1,
          "android_info": {
            "package_name": "com.almaryahrostery",
            "certificate_hash": "51abd25676af00fe0be6da8f009954ef59925fde"
          }
        },
        {
          "client_id": "506062617127-q2mkkkuj97tpka3uc3n11qemkevabs83.apps.googleusercontent.com",
          "client_type": 3
        }
      ],
      "api_key": [
        {
          "current_key": "[REPLACE_WITH_YOUR_NEW_API_KEY]"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": [
            {
              "client_id": "506062617127-q2mkkkuj97tpka3uc3n11qemkevabs83.apps.googleusercontent.com",
              "client_type": 3
            }
          ]
        }
      }
    }
  ],
  "configuration_version": "1"
}
```

Then add instructions to README.

### Step 7: Update Release Branch

```bash
# 1. Commit the security fix
git add android/app/google-services.json
git commit -m "security: Rotate leaked Google API Key - revoke old key"

# 2. Update the tag
git tag -d v1.0.0  # Delete old tag
git tag -a v1.0.0 -m "Release v1.0.0 - Fixed: Leaked Google API Key rotated"

# 3. Force push with new changes
git push --force origin release/v1.0.0
git push --force origin v1.0.0
```

---

## 📋 CHECKLIST - DO THIS NOW

- [ ] **1. Revoke leaked key** at: https://console.cloud.google.com/apis/credentials
- [ ] **2. Generate new Google API Key**
- [ ] **3. Note the new key for later**
- [ ] **4. Remove from git history** (git-filter-repo or manual amendment)
- [ ] **5. Update google-services.json** with new key
- [ ] **6. Add google-services.json to .gitignore**
- [ ] **7. Create google-services.json.example** template
- [ ] **8. Commit and force push** to GitHub
- [ ] **9. Verify** key is removed from GitHub
- [ ] **10. Close alert** on GitHub as "Revoked"

---

## ⏱️ TIME ESTIMATE

- Revoke old key: 5 min
- Generate new key: 2 min
- Fix git history: 10 min
- Update file & .gitignore: 5 min
- Push changes: 3 min

**Total**: ~25 minutes to complete security fix

---

## 🔒 ADDITIONAL SECURITY

After fixing this:

1. **Rotate all credentials** (as originally planned)
2. **Check git history** for other exposed keys
3. **Update Render** with new Google API Key (if needed for backend)
4. **Update backend .env** with any Google-related configs
5. **Monitor Google Cloud Console** for any unauthorized usage

---

## 🚨 WHAT NOT TO DO

❌ **DON'T** ignore this alert  
❌ **DON'T** just delete the branch  
❌ **DON'T** publish to Play Store with leaked key  
❌ **DON'T** skip revoking the old key  
❌ **DON'T** commit google-services.json in future  

---

## ✅ AFTER FIXING

Your app will be:
- ✅ Secure again
- ✅ Ready for Play Store submission
- ✅ Protected from future key leaks
- ✅ Using best practices

---

## 📞 REFERENCE LINKS

- Google Cloud Console: https://console.cloud.google.com
- GitHub Secret Scanning: https://github.com/roobiinpandey/al_marya_rostary/security/secret-scanning
- Firebase Security: https://firebase.google.com/docs/auth/android/google-play-app-signing

---

## ⚡ NEXT ACTIONS

**Immediate** (RIGHT NOW):
1. ✅ Revoke the leaked key in Google Cloud Console
2. ✅ Generate a new API key
3. ✅ Remove from git history
4. ✅ Update android/app/google-services.json
5. ✅ Force push to GitHub

**Then**:
- Update Render environment (Step 3)
- Build APKs (Step 4)
- Submit to Play Store (Step 5)

**This is critical for security and must be done before publishing!**

