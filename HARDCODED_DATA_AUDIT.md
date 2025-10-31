# Hardcoded/Fallback Data Audit Report

**Date:** October 31, 2025  
**Status:** 🔴 MULTIPLE HARDCODED FALLBACKS FOUND

## 📊 Summary

Your app contains **multiple fallback mechanisms** that show hardcoded data when the backend fails. This is causing the hardcoded banners and products you saw when the server connection failed.

---

## 🎯 Critical Findings

### 1. **Hero Banner Carousel** ⚠️ HIGH PRIORITY
**File:** `lib/features/home/presentation/widgets/hero_banner_carousel.dart`

**Issue:** Lines 66-113 contain hardcoded fallback banners with Unsplash images

```dart
void _loadFallbackBanners() {
  final now = DateTime.now();
  
  setState(() {
    _banners = [
      SliderModel(
        id: 'fallback_1',
        title: 'Premium Arabica Beans',
        description: 'Fresh from the mountains of Yemen',
        image: 'https://images.unsplash.com/photo-...', // ❌ Hardcoded
        // ...
      ),
      // ... 2 more hardcoded banners
    ];
  });
}
```

**Impact:** When backend is unavailable, users see generic coffee images instead of real Al Marya banners

**Recommendation:** Remove fallback or show "No banners available" message

---

### 2. **Coffee Products Repository** ⚠️ HIGH PRIORITY
**File:** `lib/domain/repositories/coffee_repository.dart`

**Issue:** Lines 77-155 contain 6 hardcoded mock coffee products

```dart
List<CoffeeProduct> _getMockCoffeeProducts() {
  return [
    const CoffeeProduct(
      id: '1',
      name: 'Ethiopian Yirgacheffe',  // ❌ Not Al Marya product
      description: '...',
      price: 24.99,
      imageUrl: 'https://images.unsplash.com/...',
    ),
    // ... 5 more mock products
  ];
}
```

**Impact:** Shows fake products when API fails (not Al Marya products)

**Recommendation:** Remove entirely - rely on backend only

---

### 3. **Coffee Provider Fallback** ⚠️ MEDIUM PRIORITY
**File:** `lib/features/coffee/presentation/providers/coffee_provider.dart`

**Issue:** Lines 167-217 contain fallback data

```dart
void _loadMockDataFallback() {
  _coffees = [
    const CoffeeProductModel(
      id: 'fallback-1',
      name: 'Al Marya House Blend',  // ❌ Fake product
      description: 'temporarily using offline data',
      price: 45.0,
      imageUrl: 'assets/images/default-coffee.jpg',
    ),
    // ... 1 more fallback product
  ];
}
```

**Impact:** Shows fake "Al Marya" products that don't exist in database

**Recommendation:** Remove - show error screen instead

---

### 4. **Other Fallback Mechanisms** ℹ️ INFO

**Files with fallback data:**
- `lib/features/account/presentation/providers/referrals_provider.dart` (line 206)
- `lib/features/account/presentation/providers/loyalty_provider.dart` (line 199)
- `lib/features/coffee/presentation/providers/reviews_provider.dart` (line 298)

These providers have mock data methods for fallback scenarios.

---

## ✅ Recommended Actions

### Option 1: **Remove All Fallbacks** (RECOMMENDED)
Show proper error screens when backend is unavailable

### Option 2: **Disable Fallbacks in Production**
Keep fallbacks for development but disable in production

### Option 3: **Replace with Empty State UI**
Show "No products available" instead of fake data

---

## 🔧 Quick Fix Implementation

I recommend **Option 1** - Let's remove all hardcoded fallbacks and show proper error handling instead.

Would you like me to:
1. ✅ Remove all hardcoded banner fallbacks
2. ✅ Remove all mock product data
3. ✅ Add proper error screens with "Retry" buttons
4. ✅ Show "No data available" when backend is down

This ensures users only see **real Al Marya products** from your database, never fake/placeholder data.

---

## 📝 Current Fallback Trigger Conditions

Fallbacks are triggered when:
- ❌ Backend API is unreachable
- ❌ Network request times out
- ❌ API returns error response
- ❌ MongoDB connection fails

**With production backend now live**, these should rarely trigger. But if they do, users should see an error message, not fake data.
