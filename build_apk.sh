#!/bin/bash

# 📱 Qahwat Al Emarat APK Builder
# Automated script to build and organize APK files

set -e  # Exit on any error

echo "🚀 Starting APK Build Process..."
echo "=================================="

# Navigate to project directory
PROJECT_DIR="/Volumes/PERSONAL/Qahwat Al Emarat APP/qahwat_al_emarat"
cd "$PROJECT_DIR"

echo "📁 Current directory: $(pwd)"
echo ""

# Check Flutter doctor
echo "🔍 Checking Flutter environment..."
flutter doctor
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
echo ""

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get
echo ""

# Build the APK
BUILD_TYPE="${1:-debug}"  # Default to debug, accept parameter
echo "🔨 Building $BUILD_TYPE APK..."

if [ "$BUILD_TYPE" = "release" ]; then
    echo "📱 Running: flutter build apk --release"
    flutter build apk --release || echo "⚠️  Flutter reported error, but APK might still be generated..."
    SOURCE_APK="app-release.apk"
else
    echo "📱 Running: flutter build apk --debug"
    flutter build apk --debug || echo "⚠️  Flutter reported error, but APK might still be generated..."
    SOURCE_APK="app-debug.apk"
fi

# Create expected directory structure
echo "📂 Creating Flutter expected directory structure..."
mkdir -p "$PROJECT_DIR/build/app/outputs/flutter-apk/"

# Check if APK was generated
ANDROID_APK_PATH="$PROJECT_DIR/android/app/build/outputs/flutter-apk/$SOURCE_APK"
if [ ! -f "$ANDROID_APK_PATH" ]; then
    echo "❌ Error: APK not found at $ANDROID_APK_PATH"
    echo "🔍 Checking for any APK files in Android build directory..."
    find "$PROJECT_DIR/android/app/build/outputs" -name "*.apk" -type f 2>/dev/null || echo "No APK files found"
    exit 1
fi

# Copy APK to expected location
echo "📋 Copying APK to expected Flutter location..."
cp "$ANDROID_APK_PATH" "$PROJECT_DIR/build/app/outputs/flutter-apk/"
echo "✅ APK successfully copied!"

# Show APK details
echo ""
echo "🎉 APK Build Complete!"
echo "======================"
echo "📍 APK Location:"
echo "   - Android Build: $PROJECT_DIR/android/app/build/outputs/flutter-apk/$SOURCE_APK"
echo "   - Flutter Build: $PROJECT_DIR/build/app/outputs/flutter-apk/$SOURCE_APK"
echo ""

# Show APK file details
APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/$SOURCE_APK"
if [ -f "$APK_PATH" ]; then
    FILE_SIZE=$(ls -lh "$APK_PATH" | awk '{print $5}')
    echo "📊 APK Details:"
    echo "   - File: $SOURCE_APK"
    echo "   - Size: $FILE_SIZE"
    echo "   - Type: $BUILD_TYPE"
    echo "   - Backend: https://***REMOVED***.onrender.com"
    echo ""
    
    echo "📱 Installation Instructions:"
    echo "   1. Transfer APK to Android device"
    echo "   2. Enable 'Unknown Sources' in Settings"
    echo "   3. Install the APK file"
    echo "   4. App will connect to production backend automatically"
    echo ""
    
    # Optional: Open folder in Finder (macOS)
    echo "📂 Opening APK folder..."
    open "$PROJECT_DIR/build/app/outputs/flutter-apk/"
    
else
    echo "❌ Error: APK file not found at expected location!"
    echo "🔍 Checking Android build directory..."
    ls -la "$PROJECT_DIR/android/app/build/outputs/flutter-apk/" || echo "No APKs found in Android build directory"
    exit 1
fi

echo "🎯 Build process completed successfully!"
