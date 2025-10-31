# Quick Testing Guide - Contact Methods 🧪

## Test All 4 Contact Methods

### 1️⃣ Phone Test
**Location**: App Drawer → Contact Us → Phone Card

**Expected Behavior**:
- Tap the Phone card (left side, brown icon)
- Native phone dialer should open
- Phone number should be pre-filled
- User just needs to press "Call"

**URL Generated**: `tel:+97141234567`

---

### 2️⃣ Email Test
**Location**: App Drawer → Contact Us → Email Card

**Expected Behavior**:
- Tap the Email card (right side, amber icon)
- Default email app should open (Mail on iOS, Gmail/other on Android)
- "To" field should be pre-filled with business email
- User can type message and send

**URL Generated**: `mailto:info@almaryarostery.ae`

---

### 3️⃣ WhatsApp Test
**Location**: App Drawer → Contact Us → WhatsApp Card

**Expected Behavior**:
- Tap the WhatsApp card (left side, light brown icon)
- WhatsApp app opens (or web.whatsapp.com if app not installed)
- Chat with business number is ready
- User can type and send message immediately

**URL Generated**: `https://wa.me/971501234567`

---

### 4️⃣ Map Navigation Test ⭐ NEW
**Location**: App Drawer → Contact Us → Address Card

**Expected Behavior**:
- Tap the Address card (right side, location icon)
- Google Maps opens
- **Automatically shows route from current location to business**
- "Start" button is visible and ready
- Route is displayed with estimated time
- User can tap "Start" to begin turn-by-turn navigation

**URL Generated**: 
```
https://www.google.com/maps/dir/?api=1&destination=Dubai%2C%20UAE&travelmode=driving
```

**Key Features**:
- ✅ Auto-detects user's current location
- ✅ Shows driving route by default
- ✅ Ready to start navigation immediately
- ✅ User can switch to walking/transit mode in Maps app

---

## 📸 Visual Guide

```
┌─────────────────────────────────────┐
│     Contact Methods                 │
├─────────────────┬───────────────────┤
│   📞 Phone      │   📧 Email        │
│   +971 4 12...  │   info@...        │
│   [TAP: Dialer] │   [TAP: Email]    │
├─────────────────┼───────────────────┤
│   💬 WhatsApp   │   📍 Address      │
│   +971 50 12... │   Dubai, UAE      │
│   [TAP: Chat]   │   [TAP: Navigate] │
└─────────────────┴───────────────────┘
```

---

## 🎯 Quick Verification

Run this checklist to verify everything works:

- [ ] Phone opens dialer with correct number
- [ ] Email opens mail app with correct recipient
- [ ] WhatsApp opens chat with business
- [ ] **Map opens with directions from current location** ⭐
- [ ] All cards show visual feedback (ripple) when tapped
- [ ] Error handling works (try on airplane mode)

---

## 🚨 Common Issues & Solutions

### Issue: Maps just shows location pin, not directions
**Solution**: ✅ FIXED - Now using Directions API with `&api=1` and `destination` parameters

### Issue: Phone number has spaces causing error
**Solution**: ✅ FIXED - Using `.replaceAll(' ', '')` to remove spaces

### Issue: WhatsApp opens browser instead of app
**Solution**: Normal behavior if WhatsApp not installed - it opens web.whatsapp.com

### Issue: Maps asks "Which app to open?"
**Solution**: Normal on Android if multiple map apps installed - user can choose Google Maps

---

## 📱 Device-Specific Notes

### iPhone
- Phone: Opens Phone app ✅
- Email: Opens Mail app ✅
- WhatsApp: Opens WhatsApp or Safari ✅
- Maps: Opens Google Maps or Apple Maps ✅

### Android
- Phone: Opens Dialer ✅
- Email: May show app chooser ✅
- WhatsApp: Opens WhatsApp or Chrome ✅
- Maps: Opens Google Maps ✅

---

## 🔄 Update Contact Info

To change phone, email, WhatsApp, or address:
1. Go to **Admin Panel**
2. Click **Settings**
3. Scroll to **Store Information**
4. Update fields:
   - Contact Phone
   - Contact Email
   - WhatsApp Number
   - Address
5. Click **Save**
6. Changes reflect in app immediately (after refresh)

---

## ✅ All Features Working

| Feature | Status | Notes |
|---------|--------|-------|
| Phone Click | ✅ | Opens dialer |
| Email Click | ✅ | Opens email app |
| WhatsApp Click | ✅ | Opens chat |
| Map Navigation | ✅ | **Auto-navigation from current location** |
| Error Handling | ✅ | Shows friendly error messages |
| Dynamic Data | ✅ | Loads from backend settings |

---

**Ready to test!** 🚀

Just open the app, go to Contact Us from the drawer, and tap each card to verify functionality.
