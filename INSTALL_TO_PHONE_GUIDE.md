# Install Al Marya Rostery App to Your Phone

**Date:** October 16, 2025  
**App:** Al Marya Rostery Coffee Shop App  
**Package:** com.qahwat.app

---

## Quick Start - Choose Your Method

### Method 1: Direct Install via USB (Fastest) ⚡
**Time:** 3-5 minutes  
**Best for:** Quick testing, debugging

### Method 2: Build APK and Install (Recommended) 📦
**Time:** 5-10 minutes  
**Best for:** Sharing with others, production testing

### Method 3: Build App Bundle for Play Store 🏪
**Time:** 10-15 minutes  
**Best for:** Publishing to Google Play Store

---

## Method 1: Direct Install via USB (Fastest) ⚡

### Prerequisites
- ✅ Android phone with USB cable
- ✅ USB debugging enabled on phone
- ✅ Flutter installed on Mac
- ✅ Phone drivers installed (automatic on macOS)

### Step 1: Enable USB Debugging on Your Phone

**On Your Android Phone:**

1. Open **Settings**
2. Scroll to **About Phone**
3. Tap **Build Number** 7 times rapidly
   - You'll see "You are now a developer!"
4. Go back to **Settings**
5. Find **Developer Options** (usually under System or Advanced)
6. Enable **USB Debugging**
7. Tap **OK** when prompted

### Step 2: Connect Phone to Mac

1. Connect your phone via USB cable
2. On your phone, you'll see a prompt:
   ```
   "Allow USB debugging from this computer?"
   [Always allow] [Allow] [Cancel]
   ```
3. Check **"Always allow from this computer"**
4. Tap **Allow**

### Step 3: Verify Connection

```bash
# Check if phone is detected
flutter devices
```

**Expected Output:**
```
Found 2 connected devices:
  iPhone 17 Pro Max (mobile) • 00008130-001234567890123E • ios • iOS 18.0
  SM G981B (mobile) • R58N123456 • android-arm64 • Android 14 (API 34)
```

### Step 4: Install and Run

```bash
# Navigate to project
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"

# Install directly to phone
flutter run --release
```

**What Happens:**
1. ✅ Flutter builds the app (2-3 minutes)
2. ✅ Installs app on your phone automatically
3. ✅ Launches the app
4. ✅ App stays on phone even after disconnecting

**App Location on Phone:**
- App drawer: "ALMARYAH ROSTERY"
- Can be used like any other app
- Stays installed until you uninstall it

---

## Method 2: Build APK and Install (Recommended) 📦

This method creates an APK file you can share with others or install manually.

### Step 1: Build the APK

```bash
# Navigate to project
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"

# Build release APK
flutter build apk --release
```

**Build Progress:**
```
Running Gradle task 'assembleRelease'...
✓ Built build/app/outputs/flutter-apk/app-release.apk (23.4MB).
```

### Step 2: Locate the APK

The APK will be created at:
```
/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery/build/app/outputs/flutter-apk/app-release.apk
```

### Step 3: Transfer APK to Phone

**Option A: USB Transfer**
```bash
# Copy APK to Downloads folder
adb push build/app/outputs/flutter-apk/app-release.apk /sdcard/Download/AlMaryaRostery.apk
```

**Option B: AirDrop/Email/Cloud**
1. Find the APK in Finder:
   ```bash
   open build/app/outputs/flutter-apk/
   ```
2. Right-click `app-release.apk`
3. Choose:
   - **AirDrop** to nearby phone
   - **Share** → Email to yourself
   - Upload to **Google Drive/Dropbox**

**Option C: QR Code (if you have a file sharing service)**
1. Upload APK to cloud storage
2. Get shareable link
3. Create QR code from link
4. Scan with phone

### Step 4: Install APK on Phone

1. On your phone, open **Files** app or **Downloads**
2. Tap the `app-release.apk` or `AlMaryaRostery.apk` file
3. You'll see a warning:
   ```
   "For your security, your phone is not allowed to install
   unknown apps from this source"
   ```
4. Tap **Settings**
5. Enable **"Allow from this source"**
6. Go back and tap the APK again
7. Tap **Install**
8. Wait for installation (10-30 seconds)
9. Tap **Open** to launch

### Step 5: Launch App

- Find "ALMARYAH ROSTERY" in your app drawer
- Tap to open
- Grant permissions when prompted (location, storage, etc.)

---

## Method 3: Build App Bundle for Play Store 🏪

This creates an optimized `.aab` file for Google Play Store submission.

### Step 1: Build App Bundle

```bash
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"

# Build release app bundle
flutter build appbundle --release
```

**Output:**
```
✓ Built build/app/outputs/bundle/release/app-release.aab (18.2MB).
```

### Step 2: Upload to Play Store

1. Go to [Google Play Console](https://play.google.com/console)
2. Create new app or select existing
3. Navigate to **Production** → **Create new release**
4. Upload `build/app/outputs/bundle/release/app-release.aab`
5. Fill in release notes
6. Submit for review

**Note:** You need a Google Play Developer account ($25 one-time fee)

---

## Build Options Explained

### Debug Build
```bash
flutter build apk --debug
```
- ✅ Faster build time
- ✅ Includes debugging symbols
- ❌ Larger file size (~45MB)
- ❌ Slower performance
- **Use for:** Development, testing

### Release Build (Recommended)
```bash
flutter build apk --release
```
- ✅ Optimized performance
- ✅ Smaller file size (~23MB)
- ✅ Production-ready
- ❌ No debugging
- **Use for:** Production, sharing

### Profile Build
```bash
flutter build apk --profile
```
- ✅ Performance profiling enabled
- ✅ Medium file size (~35MB)
- **Use for:** Performance testing

### Split APKs by Architecture (Smallest Size)
```bash
flutter build apk --split-per-abi --release
```

**Creates 3 separate APKs:**
- `app-armeabi-v7a-release.apk` (~15MB) - Older 32-bit phones
- `app-arm64-v8a-release.apk` (~18MB) - Modern 64-bit phones
- `app-x86_64-release.apk` (~20MB) - Emulators/Intel phones

**Choose the right APK:**
- Most modern phones: `app-arm64-v8a-release.apk`
- Older phones (pre-2018): `app-armeabi-v7a-release.apk`
- Emulators: `app-x86_64-release.apk`

---

## Troubleshooting

### Issue 1: "App not installed" Error

**Cause:** Conflicting package name or previous installation

**Solution:**
```bash
# Uninstall old version first
adb uninstall com.qahwat.app

# Then reinstall
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Issue 2: Phone Not Detected

**Check Connection:**
```bash
flutter devices
adb devices
```

**If empty:**
1. Unplug and replug USB cable
2. Try different USB port
3. Check USB cable (use data cable, not charge-only)
4. Restart ADB: `adb kill-server && adb start-server`
5. Check USB debugging is still enabled on phone

### Issue 3: Build Failed

**Common Fixes:**
```bash
# Clean build cache
flutter clean

# Get dependencies
flutter pub get

# Try building again
flutter build apk --release
```

### Issue 4: "Gradle Build Failed"

**Solution:**
```bash
# Navigate to android folder
cd android

# Clean Gradle
./gradlew clean

# Go back to root
cd ..

# Build again
flutter build apk --release
```

### Issue 5: APK Too Large

**Optimize Size:**
```bash
# Build with split APKs
flutter build apk --split-per-abi --release

# Or build app bundle (smaller)
flutter build appbundle --release
```

### Issue 6: "Unknown Sources" Not Showing

**For Android 8.0+:**
1. Settings → Apps & notifications
2. Advanced → Special app access
3. Install unknown apps
4. Choose your browser/file manager
5. Allow from this source

---

## Quick Commands Reference

### Build Commands
```bash
# Debug APK (faster build, larger size)
flutter build apk --debug

# Release APK (recommended)
flutter build apk --release

# Split APKs (smallest size)
flutter build apk --split-per-abi --release

# App Bundle for Play Store
flutter build appbundle --release

# Install directly to phone
flutter run --release
```

### ADB Commands
```bash
# List connected devices
adb devices

# Install APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Uninstall app
adb uninstall com.qahwat.app

# Copy APK to phone
adb push app-release.apk /sdcard/Download/

# Open app on phone
adb shell am start -n com.qahwat.app/.MainActivity
```

### Flutter Commands
```bash
# Check connected devices
flutter devices

# Install and run on phone
flutter run --release

# Clean build cache
flutter clean

# Get dependencies
flutter pub get
```

---

## Installation Checklist

### Before Building
- [ ] Phone connected via USB (if using Method 1)
- [ ] USB debugging enabled on phone
- [ ] Phone authorized on Mac
- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] No compilation errors (`flutter analyze`)

### Building APK
- [ ] Navigate to project directory
- [ ] Run `flutter build apk --release`
- [ ] Build completes successfully
- [ ] APK created in `build/app/outputs/flutter-apk/`

### Installing on Phone
- [ ] APK transferred to phone
- [ ] "Unknown sources" enabled
- [ ] APK tapped and installed
- [ ] App appears in app drawer
- [ ] App launches successfully

### First Launch
- [ ] Location permission granted (if prompted)
- [ ] Storage permission granted (if needed)
- [ ] App connects to backend
- [ ] Products load from MongoDB
- [ ] App is functional

---

## Recommended: One-Command Install Script

Create a simple script for future installations:

```bash
#!/bin/bash
# install.sh - Quick install script

echo "🚀 Building Al Marya Rostery App..."
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"

# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Check if phone is connected
if adb devices | grep -q "device$"; then
    echo "📱 Phone detected! Installing..."
    adb install -r build/app/outputs/flutter-apk/app-release.apk
    echo "✅ App installed! Opening..."
    adb shell am start -n com.qahwat.app/.MainActivity
else
    echo "📦 APK built successfully!"
    echo "📍 Location: build/app/outputs/flutter-apk/app-release.apk"
    open build/app/outputs/flutter-apk/
fi
```

**Make executable and run:**
```bash
chmod +x install.sh
./install.sh
```

---

## App Information

**Package Name:** `com.qahwat.app`  
**App Name:** ALMARYAH ROSTERY  
**Version:** 1.0.0  
**Min Android:** API 21 (Android 5.0)  
**Target Android:** API 34 (Android 14)  

**Size:**
- Release APK: ~23MB
- Split APK (arm64): ~18MB
- App Bundle: ~18MB

**Permissions Required:**
- 📍 Location (for delivery address)
- 📷 Camera (for profile picture)
- 💾 Storage (for caching)
- 🌐 Internet (for API calls)

---

## Next Steps After Installation

1. **Launch App**
   - Tap "ALMARYAH ROSTERY" icon
   - App opens to login/home screen

2. **Grant Permissions**
   - Allow location access
   - Allow storage access
   - Allow notifications (optional)

3. **Test Features**
   - Browse coffee products
   - Add items to cart
   - Test user registration
   - Test checkout flow

4. **Share with Others**
   - Send APK file via email/cloud
   - They can install same way
   - No developer account needed

---

## Summary - Fastest Method

**For Quick Testing (1 command):**
```bash
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery" && flutter run --release
```

**For Sharing/Distribution:**
```bash
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery" && flutter build apk --release
# Then find APK in: build/app/outputs/flutter-apk/app-release.apk
```

---

**Choose Method 1 if:** You just want to test quickly on your phone  
**Choose Method 2 if:** You want to share with others or keep the APK  
**Choose Method 3 if:** You're publishing to Google Play Store

**All methods result in a fully functional app on your phone!** 🚀
