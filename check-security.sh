#!/bin/bash

# Security Check Script for Git Push
# Run this before pushing to GitHub

echo "🔒 Al Marya Rostery - Git Security Check"
echo "========================================"
echo ""

cd "$(dirname "$0")"

# Check if git repo
if [ ! -d ".git" ]; then
  echo "❌ Not a git repository"
  exit 1
fi

echo "✅ Git repository found"
echo ""

# Check for staged sensitive files
echo "🔍 Checking staged files for sensitive data..."
SENSITIVE_FOUND=0

git diff --cached --name-only | while read file; do
  # Check file name
  if echo "$file" | grep -qiE "\.env$|service-account|credentials|secrets|private.*key"; then
    echo "⚠️  WARNING: Sensitive filename: $file"
    SENSITIVE_FOUND=1
  fi
  
  # Check file content (if file exists)
  if [ -f "$file" ]; then
    if git diff --cached "$file" | grep -qE "mongodb\+srv://|password.*[:=].*[^x]{5}|secret.*[:=].*[^x]{5}|private_key.*BEGIN"; then
      echo "⚠️  WARNING: Possible secret content in: $file"
      SENSITIVE_FOUND=1
    fi
  fi
done

echo ""

# Check for large files
echo "📊 Checking for large files (>10MB)..."
LARGE_FOUND=0

git diff --cached --name-only | while read file; do
  if [ -f "$file" ]; then
    SIZE=$(du -m "$file" | cut -f1)
    if [ "$SIZE" -gt 10 ]; then
      echo "⚠️  WARNING: Large file ($SIZE MB): $file"
      LARGE_FOUND=1
    fi
  fi
done

echo ""

# Check .gitignore is staged if modified
if git diff --name-only | grep -q "^\.gitignore$"; then
  if ! git diff --cached --name-only | grep -q "^\.gitignore$"; then
    echo "⚠️  WARNING: .gitignore is modified but not staged"
    echo "   Run: git add .gitignore"
  fi
fi

echo ""
echo "📋 Current staged files:"
git diff --cached --name-only | head -20
TOTAL=$(git diff --cached --name-only | wc -l)
if [ "$TOTAL" -gt 20 ]; then
  echo "... and $((TOTAL - 20)) more files"
fi

echo ""
echo "✅ Security check complete!"
echo ""
echo "If no warnings above, you can safely:"
echo "  git commit -m \"Your message\""
echo "  git push origin main"
