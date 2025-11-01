# 🚀 DEPLOY NOW - Simple 3-Step Guide

## ✅ CODE IS READY!
**Last commit:** 72e181d - Backend crash fixed
**Status:** Production ready, pushed to GitHub

---

## STEP 1: Update Render.com (5 min) 🔴

1. Go to: https://dashboard.render.com
2. Click your backend service
3. **Environment** tab
4. Find `MONGODB_URI` → Click **Edit**
5. Paste this:
   ```
   mongodb+srv://roobiinpandey_db_user:50S5UtRawzRf2qMw@almaryarostery.2yel8zi.mongodb.net/al_marya_rostery?retryWrites=true&w=majority
   ```
6. Click **Save Changes**
7. Wait 3-5 minutes for deploy

**Verify:** Visit https://almaryarostary.onrender.com/health
Should show: `"mongodb": "connected"`

---

## STEP 2: Build APK (10 min)

```bash
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"
flutter clean
flutter pub get
flutter build apk --release
```

**APK location:** `build/app/outputs/flutter-apk/app-release.apk`

---

## STEP 3: Test APK (15 min)

1. Copy APK to phone
2. Install
3. Test:
   - [ ] App launches
   - [ ] Products show (8 coffees)
   - [ ] Can add to cart
   - [ ] Login works
   - [ ] Can place order

---

## ✅ DONE!

**Monday submission:** READY
**Total time:** ~30 minutes

---

## 🆘 If something fails:

**Backend not deploying?**
- Check Render.com logs
- Click "Manual Deploy" → "Clear build cache & deploy"

**APK not building?**
- Run: `flutter doctor`
- Check Android SDK is installed

**App crashes?**
- Check if Render backend is running
- Test: `curl https://almaryarostary.onrender.com/api/coffee`

---

**Need help?** Check PRODUCTION_CHECKLIST.md for detailed steps.
