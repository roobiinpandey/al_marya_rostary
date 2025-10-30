# Known Issues & Bug Tracker 🐛

**Date:** October 19, 2025  
**Status:** Active Tracking  
**Last Updated:** October 19, 2025

---

## 🚨 **CRITICAL ISSUES**

### **None Currently** ✅
- All critical checkout and cart issues have been resolved
- Multiple address saving functionality implemented and ready for testing

---

## 🟡 **MODERATE ISSUES**

### **1. Unused Google Sign-In Method Warning**
- **File:** `lib/core/widgets/google_signin_button.dart`
- **Issue:** `_handleGoogleSignIn` method declared but not referenced
- **Impact:** Compiler warning only, no functionality impact
- **Priority:** Low
- **Fix:** Remove unused method or implement Google sign-in feature
- **Status:** Non-blocking

### **2. Flutter Packages Updates Available**
- **Issue:** 45 packages have newer versions available
- **Impact:** Missing latest features and security updates
- **Priority:** Medium
- **Fix:** Run `flutter pub upgrade` (planned for sprint)
- **Status:** Scheduled for next sprint

---

## 🟢 **MINOR ISSUES**

### **1. iOS AppDelegate Swift Module Warning**
- **File:** `ios/Runner/AppDelegate.swift`
- **Issue:** "No such module 'Flutter'" compiler warning
- **Impact:** Warning only, app builds and runs correctly
- **Priority:** Very Low
- **Fix:** iOS project configuration cleanup
- **Status:** Cosmetic issue only

### **2. Android Gradle Build Warning**
- **File:** `android/build.gradle.kts`
- **Issue:** Gradle task creation warnings
- **Impact:** Build warnings, no runtime impact
- **Priority:** Very Low
- **Fix:** Update Gradle configuration
- **Status:** Non-critical

---

## 📋 **RESOLVED ISSUES** ✅

### **1. Checkout "Coming Soon" Dialog**
- **Date Resolved:** October 19, 2025
- **Issue:** Cart showed "coming soon" message instead of checkout
- **Root Cause:** App using old cart page instead of new features implementation
- **Fix:** Updated navigation to use correct cart page from features folder
- **Status:** ✅ RESOLVED

### **2. Multiple Address Saving Prevention**
- **Date Resolved:** October 19, 2025  
- **Issue:** Could not save multiple delivery locations
- **Root Cause:** Overly strict duplicate prevention (50m radius)
- **Fix:** Reduced duplicate threshold to 10m and added name-based checking
- **Status:** ✅ RESOLVED

### **3. Old Cart Page Conflicts**
- **Date Resolved:** October 19, 2025
- **Issue:** Two cart page implementations causing confusion
- **Root Cause:** Legacy code not removed
- **Fix:** Deleted old cart page, updated imports
- **Status:** ✅ RESOLVED

---

## 🔍 **TESTING GAPS**

### **Areas Needing Testing:**
1. **Multiple Address Saving** - Ready for testing
2. **Complete Checkout Flow** - Needs verification
3. **Guest vs Authenticated Checkout** - Needs testing
4. **Real Product Cart Functionality** - Needs testing
5. **Performance on Various Devices** - Not yet tested

---

## 📊 **ISSUE STATISTICS**

- **Total Issues Tracked:** 7
- **Critical:** 0 🟢
- **Moderate:** 2 🟡  
- **Minor:** 2 🟢
- **Resolved:** 3 ✅
- **Resolution Rate:** 43%

---

## 🎯 **NEXT ACTIONS**

### **Immediate (This Week):**
1. **Test multiple address saving** - Verify recent fix works
2. **Complete checkout flow testing** - End-to-end verification
3. **Performance testing** - Check on different devices

### **Short Term (Next Sprint):**
1. **Update Flutter packages** - Address version warnings
2. **Clean up unused code** - Remove warnings
3. **Optimize performance** - Address any findings

### **Long Term (Future Sprints):**
1. **Implement Google Sign-In** - Complete social login
2. **iOS/Android build optimization** - Clean warnings
3. **Add comprehensive error handling** - Prevent future issues

---

## 🐛 **ISSUE REPORTING TEMPLATE**

When reporting new issues, include:

```markdown
## Issue Title

**Priority:** Critical/Moderate/Minor
**Component:** Area affected
**Device:** iOS/Android/Both
**Steps to Reproduce:**
1. Step 1
2. Step 2
3. Step 3

**Expected Behavior:** What should happen
**Actual Behavior:** What actually happens
**Screenshots:** If applicable
**Workaround:** Temporary fix if available
```

---

## ✅ **QUALITY ASSURANCE STATUS**

### **Code Quality:** 🟢 Good
- No critical warnings
- Clean architecture implemented
- Proper separation of concerns

### **Functionality:** 🟡 Mostly Working
- Core features implemented
- Recent fixes applied
- Testing in progress

### **Performance:** 🟡 Unknown
- Not yet tested comprehensively
- Initial performance seems good
- Device testing needed

### **User Experience:** 🟢 Good
- Intuitive navigation
- Professional UI
- Clear error messages

---

**Issue Tracker Maintained By:** Development Team  
**Review Frequency:** Daily during active development  
**Escalation:** Critical issues reported immediately
