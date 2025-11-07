# Al Marya Rostery - Coffee E-Commerce App

Complete Flutter mobile app with Node.js backend for coffee e-commerce.

## 🚀 Quick Start

### Backend
```bash
cd backend
npm install
npm start
```

### Flutter App
```bash
flutter pub get
flutter run
```

### Production Build
```bash
flutter build apk --release
```

## 📱 Features

- Authentication (Email/Google/Phone)
- Product Catalog
- Shopping Cart
- Coffee Subscriptions
- **Order Tracking** with Unified Order Numbers (ALM-YYYYMMDD-XXXXXX)
- Loyalty Rewards
- Brewing Guides

## 🔢 Order Number System

All orders use a **unified, professional order number format**:

```
ALM-20251106-000123
```

- **ALM** = Al Marya brand prefix
- **20251106** = Date (November 6, 2025)
- **000123** = Sequential number (resets daily)

**Benefits:**
✅ Consistent across all apps (Customer, Staff, Driver, Admin)
✅ Human-readable and professional
✅ Date embedded for easy tracking
✅ Sequential numbering

📚 [Full Documentation →](./ORDER_NUMBER_README.md)

## 🌐 Production

- **Backend**: https://almaryarostary.onrender.com
- **Database**: MongoDB Atlas
- **Status**: Ready ✅

## 📄 License

© 2025 Al Marya Rostery
