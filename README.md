# Al Marya Rostery - Coffee Delivery System

A complete coffee delivery ecosystem built with Flutter and Node.js.

## 📱 Project Structure

```
Al Marya Rostery APP/
├── al_marya_rostery/       # User mobile app (Customer)
├── al_marya_staff_app/     # Staff management app
├── al_marya_driver_app/    # Driver delivery app
├── backend/                # Node.js Express API
└── functions/              # Firebase Cloud Functions
```

## 🚀 Quick Start

### User App
```bash
cd al_marya_rostery
flutter pub get
flutter run
```

### Staff App
```bash
cd al_marya_staff_app
flutter pub get
flutter run
```

### Driver App
```bash
cd al_marya_driver_app
flutter pub get
flutter run
```

### Backend
```bash
cd backend
npm install
npm start
```

## 🛠️ Maintenance Scripts

- `build_all_apks.sh` - Build APKs for all apps
- `cleanup_for_production.sh` - Clean project for production
- `pre-push-security-check.sh` - Security checks before git push

## 📦 Tech Stack

- **Mobile:** Flutter (Dart)
- **Backend:** Node.js, Express, MongoDB
- **Cloud:** Firebase (Auth, Firestore, Functions, FCM)
- **Payment:** Stripe

---
Last cleaned: November 15, 2025
