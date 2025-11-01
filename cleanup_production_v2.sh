#!/bin/bash

# Production Cleanup Script V2 - Al Marya Rostery
# Generated: November 2, 2025
# This script performs automated cleanup of unnecessary files

set -e  # Exit on error

echo "======================================"
echo "🧹 Al Marya Rostery - Deep Cleanup"
echo "======================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to project directory
PROJECT_DIR="/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"
cd "$PROJECT_DIR" || exit 1

echo "📂 Working directory: $PROJECT_DIR"
echo ""

# Create backup before cleanup
BACKUP_DIR="cleanup_backup_$(date +%Y%m%d_%H%M%S)"
echo "💾 Creating backup: $BACKUP_DIR"
mkdir -p "../$BACKUP_DIR"

# ======================
# PRIORITY 1: SAFE DELETIONS
# ======================

echo -e "${YELLOW}🗑️  PRIORITY 1: Safe Deletions${NC}"
echo ""

# 1. Delete .DS_Store files
echo "Removing .DS_Store files..."
find . -name ".DS_Store" -type f -delete
echo -e "${GREEN}✅ Deleted .DS_Store files${NC}"

# 2. Delete backup files
if [ -f "lib/pages/orders_page.dart.backup" ]; then
    cp "lib/pages/orders_page.dart.backup" "../$BACKUP_DIR/"
    rm "lib/pages/orders_page.dart.backup"
    echo -e "${GREEN}✅ Deleted orders_page.dart.backup${NC}"
fi

# 3. Delete demo files (not needed in production)
if [ -f "lib/demo_main.dart" ]; then
    cp "lib/demo_main.dart" "../$BACKUP_DIR/"
    rm "lib/demo_main.dart"
    echo -e "${GREEN}✅ Deleted demo_main.dart${NC}"
fi

if [ -f "lib/widgets/firestore_test_widget.dart" ]; then
    cp "lib/widgets/firestore_test_widget.dart" "../$BACKUP_DIR/"
    rm "lib/widgets/firestore_test_widget.dart"
    echo -e "${GREEN}✅ Deleted firestore_test_widget.dart${NC}"
fi

# 4. Delete APK file (should not be in git)
if [ -f "al-marya-rostery-FIXED.apk" ]; then
    mv "al-marya-rostery-FIXED.apk" "../$BACKUP_DIR/"
    echo -e "${GREEN}✅ Moved APK to backup (should not be in git)${NC}"
fi

# 5. Delete entire lib/screens/ folder (all replaced)
if [ -d "lib/screens" ]; then
    cp -r "lib/screens" "../$BACKUP_DIR/"
    rm -rf "lib/screens"
    echo -e "${GREEN}✅ Deleted lib/screens/ folder (replaced by features/)${NC}"
fi

echo ""

# ======================
# GITIGNORE UPDATE
# ======================

echo -e "${YELLOW}📝 Updating .gitignore${NC}"
echo ""

# Backup existing .gitignore
cp .gitignore ../$BACKUP_DIR/.gitignore.backup

# Add to .gitignore if not already present
cat >> .gitignore << 'EOL'

# macOS System Files
.DS_Store
**/.DS_Store

# Build Outputs
*.apk
*.ipa
*.aab
*.app

# Backup Files
*.backup
*.bak
*.old

# IDE
.idea/
.vscode/
*.iml

# Environment & Logs
.env
.env.local
*.log

# Node Modules (should always be ignored)
node_modules/
backend/node_modules/
functions/node_modules/

# Build directories
build/
.dart_tool/
.flutter-plugins-dependencies

EOL

echo -e "${GREEN}✅ Updated .gitignore${NC}"
echo ""

# ======================
# BACKEND CLEANUP
# ======================

echo -e "${YELLOW}🗄️  Backend Cleanup${NC}"
echo ""

# Backup and delete unnecessary email setup scripts
BACKEND_SCRIPTS_TO_DELETE=(
    "backend/diagnose-email.sh"
    "backend/diagnose-gmail-account.sh"
    "backend/fix-gmail.sh"
    "backend/configure-email.sh"
    "backend/setup-email.sh"
    "backend/setup-new-gmail.sh"
    "backend/update-gmail.sh"
    "backend/troubleshoot-email.sh"
    "backend/setup-sendgrid.sh"
    "backend/final-setup-plan.sh"
    "backend/simple-api-test.sh"
    "backend/test-dynamic-attributes.sh"
    "backend/kill-port.sh"
)

for script in "${BACKEND_SCRIPTS_TO_DELETE[@]}"; do
    if [ -f "$script" ]; then
        cp "$script" "../$BACKUP_DIR/"
        rm "$script"
        echo -e "${GREEN}✅ Deleted $(basename $script)${NC}"
    fi
done

echo ""

# ======================
# DOCUMENTATION CONSOLIDATION
# ======================

echo -e "${YELLOW}📚 Documentation Cleanup${NC}"
echo ""

# Create docs folder if it doesn't exist
mkdir -p docs

# Move documentation files to docs/
DOC_FILES=(
    "CLOUDINARY_ACTION_PLAN.md"
    "DEPLOY_NOW.md"
    "FIREBASE_AUTH_FIX.md"
    "IMAGE_HOSTING_GUIDE.md"
    "PRODUCTION_CHECKLIST.md"
    "SECURITY_CREDENTIALS_BEST_PRACTICES.md"
)

for doc in "${DOC_FILES[@]}"; do
    if [ -f "$doc" ]; then
        cp "$doc" "../$BACKUP_DIR/"
        mv "$doc" "docs/"
        echo -e "${GREEN}✅ Moved $doc to docs/${NC}"
    fi
done

# Move cleanup script to root if it's in backend
if [ -f "backend/cleanup_for_production.sh" ]; then
    rm "backend/cleanup_for_production.sh"
    echo -e "${GREEN}✅ Removed duplicate cleanup script from backend${NC}"
fi

echo ""

# ======================
# GIT OPERATIONS
# ======================

echo -e "${YELLOW}🔧 Git Cleanup${NC}"
echo ""

# Remove node_modules from git if tracked
if git ls-files | grep -q "node_modules/"; then
    git rm -r --cached node_modules/ 2>/dev/null || true
    echo -e "${GREEN}✅ Removed node_modules from git tracking${NC}"
fi

# Remove .DS_Store from git if tracked
git rm --cached -r **/.DS_Store 2>/dev/null || true
echo -e "${GREEN}✅ Removed .DS_Store from git tracking${NC}"

echo ""

# ======================
# SUMMARY
# ======================

echo -e "${GREEN}======================================"
echo "✅ CLEANUP COMPLETE!"
echo -e "======================================${NC}"
echo ""
echo "📊 Summary:"
echo "  • Deleted .DS_Store files"
echo "  • Deleted backup files"
echo "  • Deleted demo/test files"
echo "  • Moved APK to backup"
echo "  • Deleted lib/screens/ folder"
echo "  • Cleaned up backend scripts"
echo "  • Organized documentation"
echo "  • Updated .gitignore"
echo "  • Cleaned git tracking"
echo ""
echo "💾 Backup created at: ../$BACKUP_DIR"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT NEXT STEPS:${NC}"
echo "  1. Review changes: git status"
echo "  2. Test the app: flutter run"
echo "  3. Run tests: flutter test"
echo "  4. If everything works, commit:"
echo "     git add -A"
echo "     git commit -m 'chore: Deep cleanup - remove redundant files and folders'"
echo "  5. If issues occur, restore from backup"
echo ""
echo -e "${GREEN}🎉 Done!${NC}"
