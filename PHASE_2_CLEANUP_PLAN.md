# Phase 2 Cleanup Plan - Al Marya Rostery

## ✅ Phase 1 Complete (November 2, 2025)

Successfully cleaned up:
- ✅ Deleted `lib/screens/` folder (6 files)
- ✅ Deleted demo and test files
- ✅ Removed 13 backend email setup scripts
- ✅ Organized documentation into `docs/` folder
- ✅ Enhanced `.gitignore`
- ✅ Removed `.DS_Store` files
- ✅ Moved APK out of repository
- ✅ **250 MB space saved**
- ✅ **20,000+ files removed from tracking**

---

## 🎯 Phase 2: Code Migration (Requires Manual Review)

### Priority: MEDIUM

These require careful migration and testing:

### 1. **Migrate lib/models/ → lib/data/models/**

Current duplicates to consolidate:

```bash
# Old location (lib/models/)
lib/models/cart.dart
lib/models/coffee.dart
lib/models/order.dart
lib/models/saved_address.dart
lib/models/user.dart

# New location (already exists)
lib/data/models/coffee_product_model.dart
lib/domain/models/auth_models.dart  # Contains User
```

**Action Required:**
1. Search for all imports of `../models/` or `models/`
2. Update imports to use `data/models/` or `domain/models/`
3. Remove unused old model files
4. Test thoroughly

**Estimated Time:** 2-3 hours

---

### 2. **Migrate lib/providers/ → feature providers**

```bash
# Current providers (lib/providers/)
lib/providers/address_provider.dart    → features/account/presentation/providers/
lib/providers/gift_set_provider.dart   → features/gifts/presentation/providers/
lib/providers/location_provider.dart   → core/services/location_service.dart

# Files using these providers
lib/main.dart (line 29)
lib/widgets/location_selection_sheet.dart
lib/widgets/add_address_sheet.dart
```

**Action Required:**
1. Move `address_provider.dart` to `features/account/presentation/providers/`
2. Move `gift_set_provider.dart` to `features/gifts/presentation/providers/`
3. Refactor `location_provider.dart` as a service in `core/services/`
4. Update all imports in:
   - `main.dart`
   - `widgets/location_selection_sheet.dart`
   - `widgets/add_address_sheet.dart`
5. Test address and location features

**Estimated Time:** 2-3 hours

---

### 3. **Migrate lib/pages/ → feature pages**

```bash
# Remaining old pages
lib/pages/coffee_detail_page.dart    → Already replaced by features/coffee/presentation/pages/product_detail_page.dart
lib/pages/login_page.dart            → Already replaced by features/auth/presentation/pages/login_page.dart
lib/pages/profile_page.dart          → Used in router (lib/utils/app_router.dart line 5)
lib/pages/settings_page.dart         → Used in router (lib/utils/app_router.dart line 2)
lib/pages/orders_page.dart           → Used in router (lib/utils/app_router.dart line 4)
```

**Status Check:**
```bash
# Check which files are actually used
grep -r "import.*pages/profile_page" lib/
grep -r "import.*pages/settings_page" lib/
grep -r "import.*pages/orders_page" lib/
grep -r "import.*pages/coffee_detail_page" lib/
grep -r "import.*pages/login_page" lib/
```

**Action Required:**
1. Verify which pages are still in use
2. Migrate active pages to appropriate feature folders
3. Update router imports
4. Delete unused old pages

**Estimated Time:** 1-2 hours

---

### 4. **Consolidate lib/widgets/**

```bash
lib/widgets/add_address_sheet.dart        → features/account/presentation/widgets/
lib/widgets/location_selection_sheet.dart → features/checkout/presentation/widgets/
lib/widgets/language_toggle_widget.dart   → core/widgets/
lib/widgets/common/                       → Keep in lib/widgets/common/
```

**Action Required:**
1. Move feature-specific widgets to their feature folders
2. Keep common widgets in `lib/widgets/common/`
3. Update imports
4. Test UI components

**Estimated Time:** 1-2 hours

---

## 🔍 Phase 3: Optional Cleanup (Low Priority)

### 1. **Review Firebase Functions**

```bash
functions/
  index.js
  package.json
```

**Question:** Is this folder being used? 
- If backend/ handles everything, this might be obsolete
- Check Firebase console for deployed functions
- If unused, delete the folder

**Action:** Manual investigation required

---

### 2. **Review Firebase DataConnect**

```bash
dataconnect/
  dataconnect.yaml
  seed_data.gql
  example/
  schema/
```

**Question:** Is DataConnect actually in use?
- DataConnect is a newer Firebase feature
- Check if configured in Firebase console
- If not used, delete the folder

**Action:** Manual investigation required

---

### 3. **Review GitHub Actions**

```bash
.github/
```

**Question:** Do you have CI/CD workflows set up?
- If not, this folder can be deleted
- If yes, review and update workflows

**Action:** Manual investigation required

---

## 📋 Migration Checklist

### Before Each Migration:
- [ ] Create a new git branch
- [ ] Run tests to ensure current functionality
- [ ] Document what you're migrating

### During Migration:
- [ ] Update one file type at a time
- [ ] Search for all imports before deleting
- [ ] Test after each change
- [ ] Commit incrementally

### After Migration:
- [ ] Run full test suite: `flutter test`
- [ ] Build app: `flutter build apk --release`
- [ ] Test on device/simulator
- [ ] Code review
- [ ] Merge to main

---

## 🎯 Recommended Migration Order

1. **Start with lib/widgets/** (easiest, low risk)
2. **Then lib/providers/** (medium risk, well-defined)
3. **Then lib/pages/** (requires router updates)
4. **Finally lib/models/** (highest risk, many dependencies)

---

## 🛠️ Helper Commands

### Find all imports of a file:
```bash
grep -r "import.*YOUR_FILE_NAME" lib/
```

### Find all usages of a class:
```bash
grep -r "YourClassName" lib/
```

### Check if a file is actually used:
```bash
# If this returns nothing, the file is likely unused
grep -r "$(basename YOUR_FILE .dart)" lib/ --exclude="YOUR_FILE.dart"
```

### Run quick health check:
```bash
flutter analyze
flutter test
```

---

## 📊 Expected Final Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── services/
│   ├── utils/
│   └── widgets/ (only truly common widgets)
├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
├── domain/
│   ├── models/
│   └── repositories/
└── features/
    ├── auth/
    ├── home/
    ├── cart/
    ├── checkout/
    ├── account/
    ├── rewards/
    ├── coffee/
    ├── gifts/
    └── ... (each feature self-contained)
```

---

## ⚠️ Important Reminders

1. **Never delete without backup** - Backup is in `cleanup_backup_20251102_033121/`
2. **Test after each migration** - Don't batch all changes
3. **Commit incrementally** - Easier to revert if issues arise
4. **Update imports carefully** - One wrong import can break the build
5. **Keep production deadline in mind** - Don't rush Phase 2 if deadline is close

---

## 🎉 When You Complete Phase 2

Run this command to see improvement:
```bash
find lib/ -type f -name "*.dart" | wc -l
git ls-files | wc -l
du -sh lib/
```

Compare with before cleanup!

---

## 📞 Need Help?

If you encounter issues during Phase 2:
1. Check backup: `cleanup_backup_20251102_033121/`
2. Review git history: `git log --oneline`
3. Restore if needed: `git reset --hard <commit-hash>`
4. Ask for help with specific error messages

---

**Status:** Ready for Phase 2  
**Risk Level:** Medium  
**Recommended Timeline:** 1-2 days (with testing)  
**Best Time:** After current production release
