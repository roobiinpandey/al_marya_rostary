#!/bin/bash

# ============================================================================
# SECURITY CHECK - Verify no sensitive data in Git
# ============================================================================

set -e

echo "🔐 SECURITY VERIFICATION"
echo "========================"
echo ""

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ISSUES_FOUND=0

# Check for .env files
echo "🔍 Checking for .env files in Git..."
ENV_FILES=$(git ls-files | grep -E '\.env$' || true)
if [ -n "$ENV_FILES" ]; then
    echo "${RED}❌ FOUND .env files:${NC}"
    echo "$ENV_FILES"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo "${GREEN}✅ No .env files in Git${NC}"
fi
echo ""

# Check for Firebase credentials
echo "🔍 Checking for Firebase credentials..."
FIREBASE_FILES=$(git ls-files | grep -E 'google-services\.json|GoogleService-Info\.plist|firebase.*\.json' || true)
if [ -n "$FIREBASE_FILES" ]; then
    echo "${RED}❌ FOUND Firebase files:${NC}"
    echo "$FIREBASE_FILES"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo "${GREEN}✅ No Firebase credentials in Git${NC}"
fi
echo ""

# Check for API keys in code
echo "🔍 Checking for hardcoded API keys..."
API_KEYS=$(git grep -i -E 'api[_-]?key|secret[_-]?key|password.*=.*["\x27][^"\x27]{20,}' -- '*.dart' '*.js' '*.ts' || true)
if [ -n "$API_KEYS" ]; then
    echo "${YELLOW}⚠️  Potential API keys found in code:${NC}"
    echo "$API_KEYS" | head -5
    echo ""
    echo "Please review these and move to .env files"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo "${GREEN}✅ No hardcoded API keys detected${NC}"
fi
echo ""

# Check for private keys
echo "🔍 Checking for private keys..."
PRIVATE_KEYS=$(git ls-files | grep -E '\.key$|\.pem$|\.p12$|\.pfx$|\.jks$|\.keystore$' || true)
if [ -n "$PRIVATE_KEYS" ]; then
    echo "${RED}❌ FOUND private keys:${NC}"
    echo "$PRIVATE_KEYS"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo "${GREEN}✅ No private keys in Git${NC}"
fi
echo ""

# Check for large files
echo "🔍 Checking for large files (>10MB)..."
LARGE_FILES=$(git ls-files | xargs -I {} du -sh {} 2>/dev/null | awk '$1 ~ /M$/ {sub(/M$/, "", $1); if ($1 > 10) print}' || true)
if [ -n "$LARGE_FILES" ]; then
    echo "${YELLOW}⚠️  Large files found:${NC}"
    echo "$LARGE_FILES" | head -5
    echo ""
fi
echo ""

# Summary
echo "════════════════════════════════════════════════════════════"
if [ $ISSUES_FOUND -eq 0 ]; then
    echo "${GREEN}✅ SECURITY CHECK PASSED!${NC}"
    echo "No sensitive data detected in Git repository"
else
    echo "${RED}❌ SECURITY ISSUES FOUND: $ISSUES_FOUND${NC}"
    echo "Please fix the issues above before pushing to GitHub"
    exit 1
fi
echo "════════════════════════════════════════════════════════════"
