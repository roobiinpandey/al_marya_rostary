# ☕ Al Marya Rostery

A premium coffee ordering Flutter application for Al Marya Rostery with comprehensive features including e-commerce, loyalty programs, subscriptions, and more.

## 🚀 Project Overview

**Tech Stack:**
- **Frontend:** Flutter (iOS/Android)
- **Backend:** Node.js + Express
- **Database:** MongoDB Atlas
- **Admin Panel:** Vanilla JavaScript SPA
- **Authentication:** Firebase Auth + JWT

**Status:** ✅ Production Ready (100% Feature Complete)

## 📱 Features

- 🛍️ Product browsing and ordering
- 🛒 Shopping cart and checkout
- 📍 Location-based delivery
- 💳 Multiple payment options
- ⭐ Product reviews and ratings
- 🎁 Loyalty rewards program
- 🔄 Referral system
- 📅 Subscription plans
- 👤 User account management
- 📦 Order tracking
- 🎫 Support tickets
- 📧 Newsletter subscription
- 💬 Customer feedback

## 🏗️ Project Structure

```
al_marya_rostery/
├── lib/                    # Flutter source code
├── android/                # Android platform files
├── ios/                    # iOS platform files
├── backend/                # Node.js backend API
├── assets/                 # Images, fonts, icons
├── test/                   # Test files
└── docs/                   # Documentation
```

## 📚 Documentation

- [**Comprehensive Project Mapping**](COMPREHENSIVE_PROJECT_MAPPING_ANALYSIS.md) - Complete feature mapping and architecture
- [**Project Coverage Summary**](PROJECT_COVERAGE_SUMMARY.md) - Visual coverage overview
- [**Deployment Guide**](DEPLOYMENT_READY.md) - Production deployment instructions
- [**Installation Guide**](INSTALL_TO_PHONE_GUIDE.md) - Install on physical devices
- [**User Management**](USER_MANAGEMENT_ACCESS_GUIDE.md) - Admin user management guide
- [**Security Best Practices**](SECURITY_CREDENTIALS_BEST_PRACTICES.md) - Security guidelines
- [**Cleanup Report**](PROJECT_CLEANUP_COMPLETE.md) - Latest cleanup summary

## 🛠️ Setup & Installation

### Prerequisites
- Flutter SDK (latest stable)
- Node.js (v14+)
- MongoDB Atlas account
- Firebase project
- iOS: Xcode 14+
- Android: Android Studio

### Frontend Setup
```bash
# Install Flutter dependencies
flutter pub get

# Run the app
flutter run
```

### Backend Setup
```bash
# Navigate to backend
cd backend

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your credentials

# Start the server
npm start
```

## 🧪 Testing

```bash
# Run Flutter tests
flutter test

# Clean build files
flutter clean
flutter pub get
```

## 📦 Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🔧 Admin Panel

Access the admin panel at `http://localhost:5001` after starting the backend.

**Features:**
- Dashboard analytics
- Product management
- Order management
- User management
- Reviews moderation
- Loyalty management
- Referral tracking
- Subscription management
- Newsletter management
- Support tickets
- Feedback management
- Settings configuration

## 🧹 Maintenance

### Cleanup
```bash
# Run cleanup script to remove build artifacts
./cleanup.sh
```

### Update Dependencies
```bash
# Flutter
flutter pub upgrade

# Backend
cd backend && npm update
```

## 📈 Project Status

- **Coverage:** 100% ✅
- **Features:** 50+ pages/screens
- **Backend APIs:** 20+ routes
- **Admin Sections:** 14 modules
- **Documentation:** Up to date

## 🤝 Contributing

This is a private project. For internal development only.

## 📄 License

Proprietary - All rights reserved by Al Marya Rostery

## 📞 Support

For technical issues or questions, contact the development team.

---

**Last Updated:** October 24, 2025  
**Version:** 1.0.0  
**Status:** Production Ready 🚀
