# 📱 APK Build Guide - Qahwat Al Emarat

This guide will help you build APK files that are connected to your backend and automatically reflect any changes you make.

## 🔧 Pre-Build Configuration

### 1. Backend URL Configuration
Your app is now configured to connect to: `https://***REMOVED***.onrender.com`

### 2. Network Permissions
✅ Already configured in `android/app/src/main/AndroidManifest.xml`:
- Internet permission
- Network state access
- Storage permissions

## 🏗️ Building APK Files

### 🚀 **EASIEST METHOD: Use Our Automated Script**
```bash
# Navigate to your Flutter project
cd "/Volumes/PERSONAL/Qahwat Al Emarat APP/qahwat_al_emarat"

# Build debug APK (for testing)
./build_apk.sh debug

# Build release APK (for distribution)
./build_apk.sh release
```

This script handles everything automatically:
- ✅ Cleans previous builds
- ✅ Gets dependencies  
- ✅ Builds APK
- ✅ Fixes Flutter's APK location issue
- ✅ Opens APK folder when done

### Method 1: Debug APK (Manual Build)
```bash
# Navigate to your Flutter project
cd "/Volumes/PERSONAL/Qahwat Al Emarat APP/qahwat_al_emarat"

# Clean and get dependencies
flutter clean && flutter pub get

# Build debug APK
flutter build apk --debug

# Fix APK location (required step!)
mkdir -p build/app/outputs/flutter-apk/
cp android/app/build/outputs/flutter-apk/app-debug.apk build/app/outputs/flutter-apk/

# APK location: build/app/outputs/flutter-apk/app-debug.apk
```

### Method 2: Release APK (Manual Build)
```bash
# Navigate to your Flutter project
cd "/Volumes/PERSONAL/Qahwat Al Emarat APP/qahwat_al_emarat"

# Clean and get dependencies
flutter clean && flutter pub get

# Build release APK
flutter build apk --release

# Fix APK location (required step!)
mkdir -p build/app/outputs/flutter-apk/
cp android/app/build/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/

# APK location: build/app/outputs/flutter-apk/app-release.apk
```

### Method 3: Split APKs by Architecture (Smaller Files)
```bash
# Build separate APKs for different architectures
flutter build apk --split-per-abi --release

# Output files (after copying from android/app/build/outputs/flutter-apk/):
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (64-bit ARM)
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk (32-bit ARM)
# build/app/outputs/flutter-apk/app-x86_64-release.apk (64-bit Intel)
```

## 🔄 Automatic Backend Changes Reflection

### How It Works:
1. **API Calls**: Your Flutter app makes HTTP requests to your backend
2. **Real-time Updates**: When you update your backend, the API responses change
3. **App Reflects Changes**: Your app automatically shows new data without rebuilding

### Backend Changes That Reflect Automatically:
- ✅ **Menu items** (coffee products, prices, descriptions)
- ✅ **User authentication** (login/register behavior)
- ✅ **Orders and cart** (order processing, status updates)
- ✅ **Push notifications** (Firebase notifications)
- ✅ **Email notifications** (Maileroo email service)
- ✅ **Admin settings** (app configuration, features)

### Changes That Require APK Rebuild:
- ❌ **App UI/UX changes** (colors, layouts, new screens)
- ❌ **New features** (additional functionality)
- ❌ **Firebase configuration** (if you change Firebase project)
- ❌ **App permissions** (new Android permissions)

## 📦 APK Installation Commands

### Install on Connected Device:
```bash
# Install debug APK
adb install build/app/outputs/flutter-apk/app-debug.apk

# Install release APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Force reinstall (if already installed)
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Share APK File:
The APK files are located in:
- **Debug**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Release**: `build/app/outputs/flutter-apk/app-release.apk`

## 🚀 Production Deployment Workflow

### 1. Deploy Backend Changes
```bash
# Make changes to backend code
# Commit and push to GitHub
git add .
git commit -m "Backend updates"
git push origin main

# Render automatically deploys from GitHub
# Changes are live at: https://***REMOVED***.onrender.com
```

### 2. Test Changes
- Open your existing APK on device
- The app will automatically fetch new data from updated backend
- No need to rebuild APK for backend-only changes

### 3. When to Rebuild APK
Only rebuild when you change:
- Flutter/Dart code
- App configuration
- UI/UX elements
- Add new features

## 🔍 Testing Backend Connection

### Check API Connection:
```bash
# Test if your backend is accessible
curl https://***REMOVED***.onrender.com/health

# Expected response:
# {"status":"ok","timestamp":"..."}
```

### Test Specific Endpoints:
```bash
# Test authentication endpoint
curl -X POST https://***REMOVED***.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","password":"test123"}'

# Test products endpoint
curl https://***REMOVED***.onrender.com/api/products
```

## 📱 APK Build Optimization

### Reduce APK Size:
```bash
# Build with tree-shaking (removes unused code)
flutter build apk --release --tree-shake-icons

# Build with split architectures
flutter build apk --release --split-per-abi --tree-shake-icons
```

### Build for Specific Architecture:
```bash
# For most modern phones (recommended)
flutter build apk --release --target-platform android-arm64

# For older phones
flutter build apk --release --target-platform android-arm
```

## 🐛 Troubleshooting

### Common Issues:

1. **Network Connection Errors**
   - Check internet permission in AndroidManifest.xml
   - Verify backend URL is accessible
   - Test API endpoints manually

2. **APK Installation Failed**
   ```bash
   # Uninstall existing app first
   adb uninstall com.qahwat.alemarat
   
   # Then install new APK
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

3. **App Not Reflecting Backend Changes**
   - Check if backend is deployed and accessible
   - Verify API URLs in app configuration
   - Clear app cache/data and restart

4. **Build Errors**
   ```bash
   # Clean build files
   flutter clean
   
   # Get dependencies
   flutter pub get
   
   # Rebuild
   flutter build apk --release
   ```

## 📊 File Sizes (Approximate)

- **Debug APK**: ~50-80 MB (includes debugging symbols)
- **Release APK**: ~20-40 MB (optimized, no debug info)
- **Split APKs**: ~15-25 MB each (architecture-specific)

## 🔄 Continuous Updates

### Your Workflow:
1. **Make backend changes** → Push to GitHub → Render auto-deploys
2. **Users see changes immediately** in existing APKs
3. **Only rebuild APK** when changing Flutter code
4. **Distribute new APK** only for major app updates

This setup gives you the best of both worlds: rapid backend updates without needing to rebuild and redistribute APKs constantly!

## 📲 Distribution Options

### Internal Testing:
- Share APK files directly
- Use Google Play Console Internal Testing
- Firebase App Distribution

### Production Release:
- Google Play Store (recommended)
- Direct APK distribution
- Alternative app stores

Your app is now configured to automatically reflect backend changes! 🚀
