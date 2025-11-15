#!/bin/bash

# Al Marya Rostery - Build All APKs Script
# Builds release APKs for User, Staff, and Driver apps

set -e  # Exit on error

# Set Java 17 for compatibility with Gradle
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH="$JAVA_HOME/bin:$PATH"

echo "🚀 Starting Build Process for All Al Marya Apps"
echo "================================================"
echo ""
echo "☕ Using Java version:"
java -version 2>&1 | head -1
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Base directory
BASE_DIR="/Volumes/PERSONAL/Al Marya Rostery APP"
OUTPUT_DIR="$BASE_DIR/APK files"

# Delete all existing APKs
echo -e "${YELLOW}🗑️  Deleting all existing APK files...${NC}"
find "$BASE_DIR" -name "*.apk" -type f -delete 2>/dev/null || true
if [ -d "$OUTPUT_DIR" ]; then
    rm -rf "$OUTPUT_DIR"/*
fi
echo -e "${GREEN}✅ Old APK files deleted${NC}"
echo ""

# Build function
build_app() {
    local app_name=$1
    local app_dir=$2
    
    echo -e "${BLUE}📱 Building ${app_name}...${NC}"
    echo "----------------------------------------"
    
    cd "$app_dir"
    
    echo "🧹 Cleaning project..."
    flutter clean > /dev/null 2>&1
    
    echo "📦 Getting dependencies..."
    flutter pub get > /dev/null 2>&1
    
    echo "🔨 Building release APKs..."
    flutter build apk --release --split-per-abi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ ${app_name} built successfully!${NC}"
        
        # List generated APKs
        echo "Generated APKs:"
        ls -lh build/app/outputs/flutter-apk/*.apk | awk '{print "  " $9, "-", $5}'
        
        # Copy to output directory
        OUTPUT_DIR="$BASE_DIR/APK files"
        mkdir -p "$OUTPUT_DIR"
        cp build/app/outputs/flutter-apk/*.apk "$OUTPUT_DIR/"
        echo "APKs copied to: $OUTPUT_DIR"
    else
        echo -e "${RED}❌ ${app_name} build failed!${NC}"
        exit 1
    fi
    
    echo ""
}

# Create output directory
mkdir -p "$BASE_DIR/APK files"

# Build each app
build_app "User App" "$BASE_DIR/al_marya_rostery"
build_app "Staff App" "$BASE_DIR/al_marya_staff_app"
build_app "Driver App" "$BASE_DIR/al_marya_driver_app"

echo "================================================"
echo -e "${GREEN}🎉 All apps built successfully!${NC}"
echo ""
echo "Release APKs location:"
echo "  $BASE_DIR/APK files"
echo ""
ls -lh "$BASE_DIR/APK files"/*.apk 2>/dev/null | awk '{print "  " $9, "-", $5}' || echo "  (No APKs found)"
echo ""
echo "✅ Build process complete!"
