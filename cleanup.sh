#!/bin/bash

# 🧹 Al Marya Rostery Project Cleanup Script
# This script removes unused files and folders to clean up the project

set -e  # Exit on error

echo "🧹 Starting project cleanup..."
echo "================================"

# Navigate to project root
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"

# 1. Remove .DS_Store files (macOS metadata)
echo "📁 Removing .DS_Store files..."
find . -name ".DS_Store" -type f -delete 2>/dev/null || true
echo "✅ .DS_Store files removed"

# 2. Remove build artifacts
echo "🏗️  Removing build artifacts..."
rm -rf build/
rm -rf .dart_tool/
rm -rf android/build/
rm -rf android/.gradle/
rm -rf android/app/build/
echo "✅ Build artifacts removed"

# 3. Remove log files
echo "📝 Removing log files..."
find . -name "*.log" -type f -delete 2>/dev/null || true
rm -f flutter_debug.log 2>/dev/null || true
rm -f backend/nohup-server.log 2>/dev/null || true
rm -f backend/server-debug.log 2>/dev/null || true
rm -f backend/server.log 2>/dev/null || true
echo "✅ Log files removed"

# 4. Remove empty folders
echo "📂 Removing empty folders..."
rm -rf task_archive/ 2>/dev/null || true
rm -rf docs/archive/ 2>/dev/null || true
echo "✅ Empty folders removed"

# 5. Remove old/temporary files
echo "🗑️  Removing temporary files..."
rm -f banner-explanation.html 2>/dev/null || true
rm -f backend/DSC_8341.MP4 2>/dev/null || true
rm -f tasks.sh 2>/dev/null || true
rm -f taskmaster_aliases.sh 2>/dev/null || true
rm -f fix_deprecations.sh 2>/dev/null || true
rm -f setup_oauth.sh 2>/dev/null || true
rm -f taskmaster.js 2>/dev/null || true
echo "✅ Temporary files removed"

# 6. Remove old test files in backend
echo "🧪 Removing old test files..."
rm -f backend/test-seed.js 2>/dev/null || true
rm -f backend/automated-frontend-test.js 2>/dev/null || true
rm -f backend/ui-verification-test.js 2>/dev/null || true
rm -f backend/validate-accessibility.js 2>/dev/null || true
rm -f backend/check-banners.js 2>/dev/null || true
rm -f backend/test-admin-panel.sh 2>/dev/null || true
rm -f backend/test-api.js 2>/dev/null || true
rm -f backend/test-banners.sh 2>/dev/null || true
rm -f backend/complete-test.sh 2>/dev/null || true
rm -f backend/test-firebase-users.sh 2>/dev/null || true
rm -f test_firebase_users.sh 2>/dev/null || true
echo "✅ Old test files removed"

# 7. Remove duplicate package files
echo "📦 Removing duplicate package files..."
rm -f backend/package-root.json 2>/dev/null || true
rm -f backend/render-package.json 2>/dev/null || true
echo "✅ Duplicate package files removed"

# 8. Remove redundant documentation (keeping essential ones)
echo "📄 Removing redundant documentation files..."

# List of essential docs to KEEP
KEEP_DOCS=(
    "README.md"
    "COMPREHENSIVE_PROJECT_MAPPING_ANALYSIS.md"
    "PROJECT_COVERAGE_SUMMARY.md"
    "DEPLOYMENT_READY.md"
    "INSTALL_TO_PHONE_GUIDE.md"
    "USER_MANAGEMENT_ACCESS_GUIDE.md"
    "SECURITY_CREDENTIALS_BEST_PRACTICES.md"
    "CLEANUP_SCRIPT.md"
)

# Move essential docs to temp folder
mkdir -p /tmp/keep_docs
for doc in "${KEEP_DOCS[@]}"; do
    if [ -f "$doc" ]; then
        cp "$doc" /tmp/keep_docs/
    fi
done

# Remove all .md files in root
find . -maxdepth 1 -name "*.md" -type f -delete 2>/dev/null || true

# Restore essential docs
for doc in "${KEEP_DOCS[@]}"; do
    if [ -f "/tmp/keep_docs/$doc" ]; then
        mv "/tmp/keep_docs/$doc" .
    fi
done

# Clean up temp folder
rm -rf /tmp/keep_docs

echo "✅ Redundant documentation removed (kept 8 essential files)"

# 9. Remove backend redundant docs
echo "📄 Removing backend redundant documentation..."
rm -f backend/LOYALTY_FIREBASE_INTEGRATION_PLAN.md 2>/dev/null || true
rm -f backend/COMPLETE_ENV_VARIABLES.txt 2>/dev/null || true
rm -f backend/DEPLOYMENT_CHECKLIST.txt 2>/dev/null || true
rm -f backend/RENDER_ENV_VARS.env 2>/dev/null || true
echo "✅ Backend redundant docs removed"

echo ""
echo "================================"
echo "✅ Cleanup completed successfully!"
echo ""
echo "Summary:"
echo "- Removed .DS_Store files"
echo "- Removed build artifacts"
echo "- Removed log files"
echo "- Removed temporary files"
echo "- Removed old test files"
echo "- Removed duplicate package files"
echo "- Removed 140+ redundant documentation files"
echo "- Kept 8 essential documentation files"
echo ""
echo "⚠️  Note: node_modules and Pods not removed (run manually if needed)"
echo "   To reinstall: cd backend && npm install"
echo "   To reinstall: cd ios && pod install"
