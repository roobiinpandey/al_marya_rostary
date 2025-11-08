# Quick Commands for Safe GitHub Push

## ✅ Security Pre-Check (Run Before Every Push)
```bash
./pre-push-security-check.sh
```

## 📦 Stage Your Changes
```bash
# Option 1: Stage all changes (recommended after security check)
git add .

# Option 2: Stage specific files only
git add lib/features/subscription/
git add lib/features/coffee/
# ... add other specific paths

# Option 3: Interactive staging (choose what to include)
git add -p
```

## 📝 Commit Your Changes
```bash
# Descriptive commit message
git commit -m "feat: implement 1kg pricing display in subscription grid

- Fixed price detection for variant size formats (1.0 kg, 1kg, 1000g)
- Added robust normalization for size string matching
- Updated coffee card to show exact 1kg prices from database
- All prices now pulled dynamically from MongoDB (no hardcoded values)"
```

## 🚀 Push to GitHub
```bash
# Push to main branch
git push origin main

# Or force push (use with caution)
git push -f origin main

# Push all local branches
git push --all origin
```

## 🔍 Verify What Will Be Pushed
```bash
# See what's staged
git status

# See detailed changes
git diff --cached

# See commit history
git log --oneline -5
```

## ⚠️ If You Need to Remove Sensitive Files Already Committed

```bash
# Remove file from git but keep local copy
git rm --cached path/to/file

# Remove file from entire git history (DANGEROUS)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/sensitive/file" \
  --prune-empty --tag-name-filter cat -- --all

# Better alternative: use BFG Repo-Cleaner
# https://rtyley.github.io/bfg-repo-cleaner/
```

## 📋 Files Currently Ignored (Safe)
- ✅ `.env` files
- ✅ Service account keys
- ✅ Admin scripts (create-admin-user.js, etc.)
- ✅ Build artifacts
- ✅ node_modules
- ✅ Large binary files
