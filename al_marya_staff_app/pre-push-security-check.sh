#!/bin/bash

# Pre-Push Security Check Script
# Run this before pushing to GitHub to ensure no sensitive data is exposed

echo "🔒 Al Marya Rostery - Security Pre-Push Check"
echo "=============================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track if any issues found
ISSUES_FOUND=0

echo "📋 Checking for sensitive files..."
echo ""

# 1. Check for .env files
echo "1️⃣  Checking for .env files..."
ENV_FILES=$(find . -name ".env" -o -name ".env.local" -o -name ".env.production" 2>/dev/null | grep -v node_modules)
if [ -n "$ENV_FILES" ]; then
    echo -e "${YELLOW}   ⚠️  Found .env files (should be gitignored):${NC}"
    echo "$ENV_FILES"
    
    # Check if they're actually ignored
    for file in $ENV_FILES; do
        if git check-ignore -q "$file"; then
            echo -e "${GREEN}   ✅ $file is gitignored${NC}"
        else
            echo -e "${RED}   ❌ WARNING: $file is NOT gitignored!${NC}"
            ISSUES_FOUND=1
        fi
    done
else
    echo -e "${GREEN}   ✅ No .env files found in tracked locations${NC}"
fi
echo ""

# 2. Check for service account keys
echo "2️⃣  Checking for service account keys..."
SERVICE_ACCOUNT_FILES=$(find . -name "*service-account*.json" -o -name "*serviceAccount*.json" -o -name "firebase-adminsdk*.json" 2>/dev/null | grep -v node_modules)
if [ -n "$SERVICE_ACCOUNT_FILES" ]; then
    echo -e "${YELLOW}   ⚠️  Found service account files:${NC}"
    for file in $SERVICE_ACCOUNT_FILES; do
        if git check-ignore -q "$file"; then
            echo -e "${GREEN}   ✅ $file is gitignored${NC}"
        else
            echo -e "${RED}   ❌ CRITICAL: $file is NOT gitignored!${NC}"
            ISSUES_FOUND=1
        fi
    done
else
    echo -e "${GREEN}   ✅ No service account files found${NC}"
fi
echo ""

# 3. Check for credential files
echo "3️⃣  Checking for credential files..."
CRED_FILES=$(find . -name "*credentials*" -o -name "*secrets*" -o -name "*private-key*" 2>/dev/null | grep -v node_modules | grep -v .git)
if [ -n "$CRED_FILES" ]; then
    echo -e "${YELLOW}   ⚠️  Found credential-related files:${NC}"
    for file in $CRED_FILES; do
        if git check-ignore -q "$file"; then
            echo -e "${GREEN}   ✅ $file is gitignored${NC}"
        else
            echo -e "${RED}   ❌ WARNING: $file might not be gitignored!${NC}"
            ISSUES_FOUND=1
        fi
    done
else
    echo -e "${GREEN}   ✅ No credential files found${NC}"
fi
echo ""

# 4. Check for hardcoded secrets in staged files
echo "4️⃣  Checking staged files for hardcoded secrets..."
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)
if [ -n "$STAGED_FILES" ]; then
    # Check for common secret patterns
    FOUND_SECRETS=$(git diff --cached | grep -iE "(password|secret|api_key|private_key|token|credential).*[:=].*['\"][^'\"]{8,}" || true)
    if [ -n "$FOUND_SECRETS" ]; then
        echo -e "${RED}   ❌ POTENTIAL SECRETS FOUND in staged changes:${NC}"
        echo "$FOUND_SECRETS"
        ISSUES_FOUND=1
    else
        echo -e "${GREEN}   ✅ No obvious secrets in staged changes${NC}"
    fi
else
    echo -e "${YELLOW}   ⚠️  No files staged for commit${NC}"
fi
echo ""

# 5. Check for admin scripts
echo "5️⃣  Checking for admin/test scripts..."
ADMIN_SCRIPTS=$(find backend -name "create-*.js" -o -name "test-*.js" -o -name "check-*.js" 2>/dev/null | grep -v node_modules)
if [ -n "$ADMIN_SCRIPTS" ]; then
    echo -e "${YELLOW}   ⚠️  Found admin/test scripts:${NC}"
    for file in $ADMIN_SCRIPTS; do
        if git check-ignore -q "$file"; then
            echo -e "${GREEN}   ✅ $file is gitignored${NC}"
        else
            echo -e "${YELLOW}   ⚠️  $file is tracked (verify no secrets inside)${NC}"
        fi
    done
else
    echo -e "${GREEN}   ✅ No admin scripts found${NC}"
fi
echo ""

# 6. Check Firebase config files (should be safe but verify)
echo "6️⃣  Checking Firebase config files..."
FIREBASE_CONFIG="lib/firebase_options.dart"
if [ -f "$FIREBASE_CONFIG" ]; then
    # Check if it contains service account keys (shouldn't)
    if grep -q "private_key" "$FIREBASE_CONFIG"; then
        echo -e "${RED}   ❌ CRITICAL: $FIREBASE_CONFIG contains private keys!${NC}"
        ISSUES_FOUND=1
    else
        echo -e "${GREEN}   ✅ $FIREBASE_CONFIG looks safe (client-side only)${NC}"
    fi
else
    echo -e "${GREEN}   ✅ No firebase_options.dart in tracked files${NC}"
fi
echo ""

# 7. Check for large files (APKs, builds, etc.)
echo "7️⃣  Checking for large files..."
LARGE_FILES=$(find . -type f -size +10M 2>/dev/null | grep -v node_modules | grep -v .git | grep -v build)
if [ -n "$LARGE_FILES" ]; then
    echo -e "${YELLOW}   ⚠️  Found large files (should be gitignored):${NC}"
    echo "$LARGE_FILES"
    for file in $LARGE_FILES; do
        if git check-ignore -q "$file"; then
            echo -e "${GREEN}   ✅ $file is gitignored${NC}"
        else
            echo -e "${RED}   ❌ WARNING: $file is NOT gitignored!${NC}"
            ISSUES_FOUND=1
        fi
    done
else
    echo -e "${GREEN}   ✅ No large files found in tracked locations${NC}"
fi
echo ""

# 8. Check what will actually be committed
echo "8️⃣  Files that will be committed:"
git diff --cached --name-only --diff-filter=ACM
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}   ⚠️  No files staged for commit${NC}"
fi
echo ""

# Final Summary
echo "=============================================="
if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ All security checks passed!${NC}"
    echo ""
    echo "Safe to push to GitHub with:"
    echo "  git push origin main"
    echo ""
    echo "Or push all branches:"
    echo "  git push --all origin"
    exit 0
else
    echo -e "${RED}❌ Security issues found! Please fix before pushing.${NC}"
    echo ""
    echo "Recommended actions:"
    echo "  1. Review flagged files above"
    echo "  2. Add sensitive files to .gitignore"
    echo "  3. Remove sensitive data from tracked files"
    echo "  4. Run: git rm --cached <filename> (to untrack without deleting)"
    echo "  5. Re-run this script"
    exit 1
fi
