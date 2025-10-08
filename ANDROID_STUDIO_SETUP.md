# 🛠️ Android Studio Setup Guide for APK Building

Complete setup guide for building APKs easily with Android Studio for your Qahwat Al Emarat Flutter app.

## 📋 Prerequisites Check

### 1. Verify Current Installation
```bash
# Check Flutter installation
flutter --version

# Check Android Studio
which studio

# Check Java installation
java -version
```

## 🔧 Android Studio Configuration

### Step 1: Install/Update Android Studio
1. **Download Android Studio** from [developer.android.com/studio](https://developer.android.com/studio)
2. **Install** following the default setup wizard
3. **Launch Android Studio**

### Step 2: Configure Android SDK
1. Open **Android Studio**
2. Go to **Android Studio** → **Settings** (or **Preferences** on macOS)
3. Navigate to **Appearance & Behavior** → **System Settings** → **Android SDK**

#### SDK Platforms Tab:
- ✅ **Android 14.0 (API 34)** - Latest stable
- ✅ **Android 13.0 (API 33)** - Wide compatibility
- ✅ **Android 12.0 (API 31)** - Minimum recommended

#### SDK Tools Tab:
- ✅ **Android SDK Build-Tools** (latest version)
- ✅ **Android SDK Command-line Tools** (latest)
- ✅ **Android SDK Platform-Tools**
- ✅ **Android Emulator**
- ✅ **Intel x86 Emulator Accelerator (HAXM installer)**

### Step 3: Set Environment Variables

#### For macOS/Linux:
```bash
# Add to your ~/.zshrc or ~/.bashrc
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

# Reload your shell
source ~/.zshrc
```

#### For Windows:
```bash
# Add to System Environment Variables
ANDROID_HOME = C:\Users\YourUsername\AppData\Local\Android\Sdk
PATH = %PATH%;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\cmdline-tools\latest\bin
```

### Step 4: Accept Android Licenses
```bash
# Accept all Android licenses
flutter doctor --android-licenses
# Type 'y' for all prompts
```

### Step 5: Install Flutter Plugin
1. In Android Studio, go to **Plugins** (Settings → Plugins)
2. Search for **"Flutter"**
3. **Install** the Flutter plugin
4. **Restart** Android Studio

## 🚀 Building APKs with Android Studio

### Method 1: Using Android Studio GUI

#### For Debug APK (Testing):
1. **Open Project**:
   - Android Studio → **Open** → Select your project folder
   - `/Volumes/PERSONAL/Qahwat Al Emarat APP/qahwat_al_emarat`

2. **Build Debug APK**:
   - **Build** menu → **Build Bundle(s) / APK(s)** → **Build APK(s)**
   - Wait for build to complete
   - Click **"locate"** to find the APK file

#### For Release APK (Production):
1. **Generate Signed APK**:
   - **Build** menu → **Generate Signed Bundle / APK**
   - Select **APK** → **Next**
   - **Create new keystore** (first time only):
     ```
     Key store path: /path/to/your/keystore.jks
     Password: [your-secure-password]
     Key alias: qahwat-key
     Key password: [your-key-password]
     Validity: 25 years
     ```
   - **Build Type**: release
   - **Signature Versions**: V1 and V2
   - **Finish**

### Method 2: Using Terminal in Android Studio
1. **Open Terminal** in Android Studio (bottom panel)
2. **Run build commands**:
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APKs by architecture
flutter build apk --split-per-abi --release
```

## 📱 APK Output Locations

### Debug APK:
```
build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Split APKs:
```
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

## 🔧 Troubleshooting Common Issues

### Issue 1: "SDK location not found"
**Solution:**
1. File → Project Structure → SDK Location
2. Set Android SDK location: `/Users/[username]/Library/Android/sdk`

### Issue 2: "cmdline-tools component is missing"
**Solution:**
1. Android Studio → SDK Manager → SDK Tools
2. Install "Android SDK Command-line Tools (latest)"

### Issue 3: "Gradle build failed"
**Solution:**
```bash
# Clean and rebuild
cd "/Volumes/PERSONAL/Qahwat Al Emarat APP/qahwat_al_emarat"
flutter clean
flutter pub get
flutter build apk --debug
```

### Issue 4: "Android licenses not accepted"
**Solution:**
```bash
flutter doctor --android-licenses
# Accept all with 'y'
```

## 📊 Build Optimization

### Reduce APK Size:
1. **Enable ProGuard** (already configured in your `build.gradle.kts`):
   ```kotlin
   buildTypes {
       release {
           isMinifyEnabled = true
           isShrinkResources = true
       }
   }
   ```

2. **Split APKs by Architecture**:
   ```bash
   flutter build apk --split-per-abi --release
   ```

3. **Remove unused resources**:
   ```bash
   flutter build apk --release --tree-shake-icons
   ```

## 🔍 Testing Your APK

### Install on Connected Device:
1. **Connect Android device** via USB
2. **Enable Developer Options** on device
3. **Enable USB Debugging**
4. In Android Studio:
   - Run → Select Device → Install APK
   - Or use terminal: `adb install path/to/your.apk`

### Test Backend Connection:
1. **Install APK** on device
2. **Open app** and test features
3. **Verify** data loads from `https://***REMOVED***.onrender.com`

## 🚀 Quick Build Workflow

### Your Optimized Workflow:
1. **Open Android Studio**
2. **Open your Flutter project**
3. **Make sure device is connected** (optional)
4. **Build → Generate Signed Bundle/APK**
5. **Select APK → Next → Finish**
6. **APK ready for distribution!**

## 📋 Keystore Management (Important!)

### Create Keystore (One-time setup):
```bash
keytool -genkey -v -keystore qahwat-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias qahwat-key
```

### Keystore Security:
- ⚠️ **NEVER commit keystore to Git**
- ✅ **Backup keystore safely**
- ✅ **Remember passwords**
- ✅ **Store in secure location**

### Add keystore to `.gitignore`:
```
# Android keystore
*.jks
*.keystore
key.properties
```

## 🔐 Signing Configuration (Optional)

Create `android/key.properties`:
```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=qahwat-key
storeFile=../qahwat-keystore.jks
```

## 🎯 Performance Tips

### Faster Builds:
1. **Increase Gradle memory** in `gradle.properties`:
   ```properties
   org.gradle.jvmargs=-Xmx4096m
   org.gradle.parallel=true
   org.gradle.configureondemand=true
   ```

2. **Use local Gradle daemon**:
   ```bash
   ./gradlew --daemon
   ```

## 📱 Distribution Options

### Internal Testing:
- Share APK directly via email/messaging
- Use Google Play Console Internal Testing
- Firebase App Distribution

### Production:
- Google Play Store (recommended)
- Samsung Galaxy Store
- Amazon Appstore
- Direct APK distribution

## ✅ Final Checklist

Before building production APK:
- [ ] Backend URL configured correctly
- [ ] App permissions set in AndroidManifest.xml
- [ ] Keystore created and secured
- [ ] ProGuard rules configured
- [ ] App icon and name set
- [ ] Version code and name updated
- [ ] Tested on different devices

## 🔄 Continuous Deployment

### GitHub Actions (Optional):
Create `.github/workflows/android.yml` for automated APK building:
```yaml
name: Build Android APK
on:
  push:
    tags:
      - 'v*'
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          java-version: '11'
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

Your Android Studio is now fully configured for easy APK building! 🎉

## 🆘 Need Help?

If you encounter issues:
1. Check `flutter doctor -v` for detailed diagnostics
2. Clean project: `flutter clean && flutter pub get`
3. Restart Android Studio
4. Check Android Studio Event Log for errors

Your Qahwat Al Emarat app is ready to build! 📱☕
