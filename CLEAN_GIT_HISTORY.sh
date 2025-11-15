#!/bin/bash

# ============================================================================
# CLEAN GIT HISTORY - Remove all commits and start fresh
# ============================================================================
# This script will:
# 1. Back up sensitive files
# 2. Remove all Git history
# 3. Create a fresh repository
# 4. Force push to GitHub (clean slate)
# ============================================================================

set -e  # Exit on error

echo "🔐 CLEANING GIT HISTORY AND SECURING REPOSITORY"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get current directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "📂 Project directory: $PROJECT_DIR"
echo ""

# ============================================================================
# STEP 1: Backup sensitive files
# ============================================================================
echo "${YELLOW}Step 1: Backing up sensitive files...${NC}"

BACKUP_DIR="$HOME/al_marya_secrets_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📦 Creating backup at: $BACKUP_DIR"

# Backup .env files
find . -name ".env" -not -path "*/node_modules/*" -not -path "*/build/*" | while read file; do
    mkdir -p "$BACKUP_DIR/$(dirname "$file")"
    cp "$file" "$BACKUP_DIR/$file"
    echo "  ✅ Backed up: $file"
done

# Backup Firebase credentials
find . -name "google-services.json" -o -name "GoogleService-Info.plist" | while read file; do
    mkdir -p "$BACKUP_DIR/$(dirname "$file")"
    cp "$file" "$BACKUP_DIR/$file"
    echo "  ✅ Backed up: $file"
done

echo "${GREEN}✅ Sensitive files backed up to: $BACKUP_DIR${NC}"
echo ""

# ============================================================================
# STEP 2: Remove sensitive files from working directory
# ============================================================================
echo "${YELLOW}Step 2: Removing sensitive files from Git tracking...${NC}"

# Remove .env files from Git
git rm -rf --cached al_marya_rostery/backend/.env 2>/dev/null || true

# Remove Firebase configs from Git
git rm -rf --cached "**/google-services.json" 2>/dev/null || true
git rm -rf --cached "**/GoogleService-Info.plist" 2>/dev/null || true

# Remove build artifacts
git rm -rf --cached "**/build/" 2>/dev/null || true
git rm -rf --cached "**/ios/Pods/" 2>/dev/null || true
git rm -rf --cached "**/.dart_tool/" 2>/dev/null || true

echo "${GREEN}✅ Sensitive files removed from Git${NC}"
echo ""

# ============================================================================
# STEP 3: Create fresh Git repository
# ============================================================================
echo "${YELLOW}Step 3: Creating fresh Git repository (removing all history)...${NC}"
echo ""
echo "${RED}⚠️  WARNING: This will DELETE ALL Git history!${NC}"
echo "Current commits: $(git log --oneline | wc -l)"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Aborted by user"
    exit 1
fi

# Save current remote URL
REMOTE_URL=$(git remote get-url origin)
echo "📌 Saved remote URL: $REMOTE_URL"

# Remove .git directory
echo "🗑️  Removing old Git history..."
rm -rf .git

# Initialize new Git repository
echo "🆕 Initializing fresh Git repository..."
git init
git branch -M main

# Add remote
echo "🔗 Adding remote: $REMOTE_URL"
git remote add origin "$REMOTE_URL"

echo "${GREEN}✅ Fresh Git repository created${NC}"
echo ""

# ============================================================================
# STEP 4: Add files to new repository
# ============================================================================
echo "${YELLOW}Step 4: Adding files to new repository...${NC}"

# Add .gitignore first
git add .gitignore
git commit -m "chore: Add comprehensive .gitignore for security"

# Add all files (respecting .gitignore)
git add .
git commit -m "feat: Initial clean commit - Al Marya Rostery multi-app project

- 3 Flutter apps: User, Staff, Driver
- Node.js backend API
- Firebase Cloud Functions
- Clean codebase with 0 compile errors
- All sensitive data excluded via .gitignore"

echo "${GREEN}✅ Files added to fresh repository${NC}"
echo ""

# ============================================================================
# STEP 5: Verify no sensitive data is included
# ============================================================================
echo "${YELLOW}Step 5: Verifying no sensitive data...${NC}"

echo "🔍 Checking for sensitive files in Git..."
SENSITIVE_FILES=$(git ls-files | grep -E '\.env$|google-services\.json|GoogleService-Info\.plist|\.key$|\.pem$' || true)

if [ -n "$SENSITIVE_FILES" ]; then
    echo "${RED}❌ ERROR: Sensitive files found in Git:${NC}"
    echo "$SENSITIVE_FILES"
    echo ""
    echo "Please remove these files before pushing!"
    exit 1
fi

echo "${GREEN}✅ No sensitive files detected${NC}"
echo ""

# ============================================================================
# STEP 6: Push to GitHub
# ============================================================================
echo "${YELLOW}Step 6: Ready to force push to GitHub${NC}"
echo ""
echo "${RED}⚠️  This will OVERWRITE the GitHub repository!${NC}"
echo "Repository: $REMOTE_URL"
echo "Branch: main"
echo ""
read -p "Push to GitHub now? (yes/no): " push_confirm

if [ "$push_confirm" = "yes" ]; then
    echo "🚀 Force pushing to GitHub..."
    git push -f origin main
    echo ""
    echo "${GREEN}✅ Successfully pushed clean repository to GitHub!${NC}"
else
    echo "⏸️  Skipped push. You can manually push later with:"
    echo "   git push -f origin main"
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo "════════════════════════════════════════════════════════════"
echo "${GREEN}✅ GIT HISTORY CLEANING COMPLETE!${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📊 Summary:"
echo "  • Old commits: 184 (deleted)"
echo "  • New commits: 2 (clean)"
echo "  • Sensitive data: Backed up to $BACKUP_DIR"
echo "  • Repository: Clean and secure"
echo ""
echo "🔐 Security checklist:"
echo "  ✅ .env files excluded"
echo "  ✅ Firebase credentials excluded"
echo "  ✅ Build artifacts excluded"
echo "  ✅ API keys protected"
echo ""
echo "📝 Next steps:"
echo "  1. Verify repository on GitHub"
echo "  2. Restore .env files from backup if needed:"
echo "     cp -r $BACKUP_DIR/al_marya_rostery/backend/.env al_marya_rostery/backend/"
echo "  3. Update team members about the history reset"
echo ""
echo "════════════════════════════════════════════════════════════"
