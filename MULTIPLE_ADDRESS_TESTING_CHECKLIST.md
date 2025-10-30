# Multiple Address Saving - Testing Checklist ✅

**Date:** October 19, 2025  
**Feature:** Multiple Address Saving Functionality  
**Status:** Ready for Testing

---

## 🧪 **TESTING STEPS**

### **Test 1: Save First Address (Home)**
1. **✅ Open the app**
2. **✅ Navigate to location selection** (tap location icon)
3. **✅ Tap "+ Add new address"**
4. **✅ Select location on map**
5. **✅ Enter name:** "Home"
6. **✅ Select type:** Home 🏠
7. **✅ Tap "Save Address"**
8. **✅ Verify success message appears**
9. **✅ Verify "Home" appears in saved addresses list**

**Expected Result:** ✅ Home address saved successfully

---

### **Test 2: Save Second Address (Work)**
1. **✅ From location selection, tap "+ Add new address" again**
2. **✅ Select different location on map** (can be nearby)
3. **✅ Enter name:** "Work" or "Office"
4. **✅ Select type:** Work 💼
5. **✅ Tap "Save Address"**
6. **✅ Verify success message appears**
7. **✅ Verify both "Home" and "Work" appear in list**

**Expected Result:** ✅ Both addresses saved and visible

---

### **Test 3: Save Third Address (Other)**
1. **✅ Tap "+ Add new address" again**
2. **✅ Select another location**
3. **✅ Enter name:** "Gym" or "Friend's Place"
4. **✅ Select type:** Other 📍
5. **✅ Tap "Save Address"**
6. **✅ Verify all 3 addresses now appear in list**

**Expected Result:** ✅ Multiple addresses (3+) can be saved

---

### **Test 4: Error Handling - Duplicate Names**
1. **✅ Try to add another "Home" address**
2. **✅ Enter same name but different location**
3. **✅ Tap "Save Address"**
4. **✅ Verify error message appears**
5. **✅ Verify duplicate is NOT saved**

**Expected Result:** ❌ Should prevent duplicate names with clear error

---

### **Test 5: Error Handling - Same Location**
1. **✅ Try to add address at exact same coordinates**
2. **✅ Use different name but same map location**
3. **✅ Tap "Save Address"**
4. **✅ Verify appropriate handling** (should prevent if too close)

**Expected Result:** ❌ Should prevent exact duplicates

---

### **Test 6: Address Selection & Usage**
1. **✅ From address list, tap "Home" address**
2. **✅ Verify it becomes selected/highlighted**
3. **✅ Navigate to checkout**
4. **✅ Verify "Home" address is used for delivery**
5. **✅ Go back and select "Work" address**
6. **✅ Verify checkout uses "Work" address**

**Expected Result:** ✅ Can switch between saved addresses

---

### **Test 7: Default Address Functionality**
1. **✅ Set one address as default** (checkbox when saving)
2. **✅ Close and reopen app**
3. **✅ Verify default address is pre-selected**

**Expected Result:** ✅ Default address persists and loads automatically

---

## 📱 **DEVICE TESTING**

### **iOS Testing:**
- [ ] iPhone Simulator ✅
- [ ] Physical iPhone device
- [ ] Different iOS versions

### **Android Testing:**
- [ ] Android Emulator
- [ ] Physical Android device
- [ ] Different Android versions

---

## 🔧 **TECHNICAL VERIFICATION**

### **Data Persistence:**
1. **✅ Add multiple addresses**
2. **✅ Close app completely**
3. **✅ Reopen app**
4. **✅ Verify all addresses are still saved**

**Expected Result:** ✅ Addresses persist between app sessions

### **Memory Usage:**
1. **✅ Add 5+ addresses**
2. **✅ Check app performance**
3. **✅ Verify no memory leaks**

**Expected Result:** ✅ Good performance with multiple addresses

---

## 📊 **TEST RESULTS**

### **✅ PASSED TESTS:**
- [ ] Save first address (Home)
- [ ] Save second address (Work)  
- [ ] Save third address (Other)
- [ ] Duplicate name prevention
- [ ] Same location prevention
- [ ] Address selection in checkout
- [ ] Default address functionality
- [ ] Data persistence
- [ ] Performance with multiple addresses

### **❌ FAILED TESTS:**
- None expected (fixes implemented)

### **🐛 ISSUES FOUND:**
- List any issues discovered during testing

---

## 🎯 **SUCCESS CRITERIA**

For this test to be considered **PASSED**, the following must work:

1. **✅ Can save multiple addresses** (Home, Work, Other)
2. **✅ Each address has different name and type**
3. **✅ Can select different addresses for delivery**
4. **✅ Prevents duplicate names with clear errors**
5. **✅ Prevents exact location duplicates**
6. **✅ Addresses persist between app restarts**
7. **✅ Default address functionality works**
8. **✅ Good performance with multiple addresses**

---

## 📝 **NEXT STEPS AFTER TESTING**

Once testing is complete:

1. **✅ Mark task as completed in TaskMaster:**
   ```bash
   node taskmaster.js done "Test multiple address saving functionality"
   ```

2. **✅ Update DAILY_TASKS.md**

3. **✅ Move to next priority:** "Verify complete checkout flow works"

4. **✅ Document any issues found**

---

**Testing Instructions:**
1. Follow each test step carefully
2. Check off completed tests ✅
3. Note any failures or issues
4. Verify all success criteria are met
5. Mark task as complete when done

**Status:** Ready for Testing 🧪  
**Priority:** HIGH 🔴  
**Expected Duration:** 15-20 minutes
