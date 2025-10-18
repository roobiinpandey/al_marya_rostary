#!/bin/bash
# Quick Install Script for Al Marya Rostery App
# This script will build and install the app on your connected Android phone

echo "🚀 Al Marya Rostery - Quick Install to Phone"
echo "=============================================="
echo ""

# Navigate to project directory
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"

# Check for connected devices
echo "📱 Checking for connected devices..."
flutter devices

# Ask user which method to use
echo ""
echo "Choose installation method:"
echo "1) Direct install to connected phone (fastest)"
echo "2) Build APK file for manual installation"
echo "3) Build split APKs (smallest size)"
echo ""
read -p "Enter choice (1-3): " choice

case $choice in
  1)
    echo ""
    echo "🚀 Installing directly to phone..."
    echo "This will take 2-3 minutes..."
    flutter run --release
    ;;
  2)
    echo ""
    echo "📦 Building release APK..."
    echo "This will take 3-5 minutes..."
    flutter build apk --release
    
    if [ $? -eq 0 ]; then
      echo ""
      echo "✅ APK built successfully!"
      echo "📍 Location: build/app/outputs/flutter-apk/app-release.apk"
      echo ""
      read -p "Open folder in Finder? (y/n): " open_finder
      if [ "$open_finder" = "y" ]; then
        open build/app/outputs/flutter-apk/
      fi
      
      # Check if phone is connected
      if adb devices | grep -q "device$"; then
        echo ""
        read -p "Phone detected! Install now? (y/n): " install_now
        if [ "$install_now" = "y" ]; then
          echo "Installing..."
          adb install -r build/app/outputs/flutter-apk/app-release.apk
          if [ $? -eq 0 ]; then
            echo "✅ App installed successfully!"
            echo "Opening app..."
            adb shell am start -n com.qahwat.app/.MainActivity
          fi
        fi
      else
        echo ""
        echo "ℹ️  No phone detected via USB"
        echo "Transfer the APK to your phone and install manually:"
        echo "1. Copy app-release.apk to your phone"
        echo "2. Enable 'Unknown sources' in Settings"
        echo "3. Tap the APK file to install"
      fi
    fi
    ;;
  3)
    echo ""
    echo "📦 Building split APKs (smallest size)..."
    echo "This will take 3-5 minutes..."
    flutter build apk --split-per-abi --release
    
    if [ $? -eq 0 ]; then
      echo ""
      echo "✅ Split APKs built successfully!"
      echo "📍 Location: build/app/outputs/flutter-apk/"
      echo ""
      echo "Three APKs created:"
      echo "  - app-armeabi-v7a-release.apk (32-bit phones)"
      echo "  - app-arm64-v8a-release.apk (64-bit phones) ← Most common"
      echo "  - app-x86_64-release.apk (emulators)"
      echo ""
      open build/app/outputs/flutter-apk/
    fi
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

echo ""
echo "✅ Done!"
