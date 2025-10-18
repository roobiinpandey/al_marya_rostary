# 🔗 Complete Integration Guide
## MongoDB ↔ Firebase ↔ Flutter App Connection

**Last Updated**: October 18, 2025  
**Status**: ✅ All Systems Connected & Working

---

## 📋 Table of Contents

1. [System Architecture Overview](#system-architecture-overview)
2. [How They Connect](#how-they-connect)
3. [Data Flow Examples](#data-flow-examples)
4. [User Journey: Registration to Profile](#user-journey-registration-to-profile)
5. [OAuth Flow (Google/Facebook)](#oauth-flow-googlefacebook)
6. [Firebase ↔ MongoDB Sync](#firebase--mongodb-sync)
7. [Configuration & Setup](#configuration--setup)
8. [Testing the Connection](#testing-the-connection)
9. [Troubleshooting](#troubleshooting)

---

## 🏗️ System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   UI Layer   │  │   Provider   │  │   Services   │         │
│  │   (Pages)    │←→│    (State)   │←→│   (API)      │         │
│  └──────────────┘  └──────────────┘  └───────┬──────┘         │
│                                               │                 │
│  Storage:                                     │ HTTP/HTTPS      │
│  • FlutterSecureStorage (JWT tokens)          │ REST API        │
│  • SharedPreferences (user data)              │ JSON            │
└───────────────────────────────────────────────┼─────────────────┘
                                                │
                                                │
                        ┌───────────────────────┴───────────────────────┐
                        │                                               │
                        ▼                                               ▼
        ┌───────────────────────────┐                 ┌─────────────────────────┐
        │   NODE.JS/EXPRESS API     │                 │   FIREBASE (Google)     │
        │   (Your Backend)          │                 │                         │
        │                           │                 │  ┌──────────────────┐  │
        │  Port: 5001               │                 │  │ Authentication   │  │
        │  URL: localhost/render    │◄────────────────┼──│ • Email/Password │  │
        │                           │  Firebase SDK   │  │ • Google OAuth   │  │
        │  ┌────────────────────┐  │                 │  │ • Facebook OAuth │  │
        │  │ Routes & Controllers│  │                 │  └──────────────────┘  │
        │  ├────────────────────┤  │                 │                         │
        │  │ • /api/auth        │  │                 │  ┌──────────────────┐  │
        │  │ • /api/users       │  │                 │  │ User Management  │  │
        │  │ • /api/coffees     │  │                 │  │ • Create users   │  │
        │  │ • /api/orders      │  │                 │  │ • Enable/disable │  │
        │  │ • /api/admin       │  │                 │  │ • Delete users   │  │
        │  └────────────────────┘  │                 │  └──────────────────┘  │
        │                           │                 │                         │
        │  ┌────────────────────┐  │                 │  ┌──────────────────┐  │
        │  │ Middleware         │  │                 │  │ Firebase Admin   │  │
        │  ├────────────────────┤  │                 │  │ SDK              │  │
        │  │ • JWT Verify       │  │                 │  │ • List users     │  │
        │  │ • Role Check       │  │                 │  │ • Custom claims  │  │
        │  │ • Security Headers │  │                 │  │ • Token verify   │  │
        │  └────────────────────┘  │                 │  └──────────────────┘  │
        │                           │                 │                         │
        │  ┌────────────────────┐  │                 │  Your Project:          │
        │  │ Firebase Admin SDK │  │                 │  qahwat-al-emarat       │
        │  │ • Initialize       │  │                 │  Project ID: ...        │
        │  │ • Auth operations  │  │                 │                         │
        │  │ • User sync        │  │                 │  Region: us-central1    │
        │  └────────────────────┘  │                 └─────────────────────────┘
        └───────────┬───────────────┘
                    │
                    │ Mongoose ODM
                    │ Connection Pool
                    ▼
        ┌───────────────────────────┐
        │   MONGODB ATLAS (Cloud)   │
        │                           │
        │  Cluster: Production      │
        │  Region: AWS/Azure        │
        │  Database: al_marya_...   │
        │                           │
        │  ┌────────────────────┐  │
        │  │ Collections:       │  │
        │  ├────────────────────┤  │
        │  │ users (14 docs)    │  │
        │  │ • _id (ObjectId)   │  │
        │  │ • email (unique)   │  │
        │  │ • password (hash)  │  │
        │  │ • firebaseUid      │  │
        │  │ • authProvider     │  │
        │  │ • roles []         │  │
        │  │ • profile data     │  │
        │  │                    │  │
        │  │ coffees (50+ docs) │  │
        │  │ • name, price      │  │
        │  │ • stock, variants  │  │
        │  │ • category         │  │
        │  │                    │  │
        │  │ orders (100+ docs) │  │
        │  │ • userId           │  │
        │  │ • items []         │  │
        │  │ • status           │  │
        │  │                    │  │
        │  │ categories (8)     │  │
        │  │ settings (20+)     │  │
        │  │ sliders (5)        │  │
        │  └────────────────────┘  │
        │                           │
        │  Indexes for Performance: │
        │  • email (unique)         │
        │  • firebaseUid (unique)   │
        │  • userId, status         │
        └───────────────────────────┘
```

---

## 🔌 How They Connect

### **1. Flutter App ↔ Backend (Express API)**

```dart
// Flutter Side (lib/core/services/api_service.dart)
class ApiService {
  static const String baseUrl = 'https://al-marya-rostary.onrender.com';
  
  Future<Map<String, dynamic>> makeRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    // Get JWT token from secure storage
    final token = await _secureStorage.read(key: 'auth_token');
    
    // Build headers
    final headers = {
      'Content-Type': 'application/json',
      if (requiresAuth && token != null)
        'Authorization': 'Bearer $token',
    };
    
    // Make HTTP request
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    
    return jsonDecode(response.body);
  }
}

// Example: Login
final result = await apiService.makeRequest(
  endpoint: '/api/auth/login',
  method: 'POST',
  body: {
    'email': 'user@example.com',
    'password': 'password123',
  },
);

// Response from backend:
{
  "success": true,
  "data": {
    "user": { id, name, email, roles },
    "token": "JWT_TOKEN_HERE",
    "refreshToken": "REFRESH_TOKEN"
  }
}
```

**Connection Details:**
- **Protocol**: HTTPS (REST API)
- **Format**: JSON
- **Authentication**: JWT Bearer tokens
- **Headers**: Content-Type, Authorization
- **Endpoints**: /api/auth, /api/users, /api/coffees, etc.

---

### **2. Backend (Express) ↔ MongoDB Atlas**

```javascript
// Backend Side (backend/config/database.js)

const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI, {
      // Connection options
      maxPoolSize: 50,        // Max 50 concurrent connections
      minPoolSize: 10,        // Min 10 connections in pool
      serverSelectionTimeoutMS: 30000,
      socketTimeoutMS: 45000,
    });
    
    console.log(`✅ MongoDB connected: ${conn.connection.host}`);
    console.log(`📊 Database: ${conn.connection.name}`);
    
    // Monitor connection
    mongoose.connection.on('connected', () => {
      console.log('✅ Mongoose connected to MongoDB');
    });
    
    mongoose.connection.on('error', (err) => {
      console.error('❌ Mongoose connection error:', err);
    });
    
    mongoose.connection.on('disconnected', () => {
      console.log('⚠️  Mongoose disconnected');
    });
    
    return conn;
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error.message);
    process.exit(1);
  }
};

// Usage in server.js
connectDB();

// Now you can use models
const User = require('./models/User');
const users = await User.find({ isActive: true });
```

**Connection String Format:**
```
mongodb+srv://username:password@cluster.mongodb.net/al_marya_rostery?retryWrites=true&w=majority
```

**Connection Details:**
- **Protocol**: MongoDB Wire Protocol (over TCP/TLS)
- **Driver**: Mongoose (ODM - Object Document Mapper)
- **Features**:
  - Connection pooling (reuse connections)
  - Automatic reconnection on failure
  - Query optimization
  - Schema validation
  - Indexes for fast queries

---

### **3. Backend (Express) ↔ Firebase**

```javascript
// Backend Side (backend/config/firebase.js)

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
  }),
});

console.log('✅ Firebase Admin SDK initialized');

// Export auth instance
const firebaseAuth = admin.auth();

module.exports = { firebaseAuth, admin };

// Usage in controllers
const { firebaseAuth } = require('../config/firebase');

// List Firebase users
const listUsers = await firebaseAuth.listUsers(1000);

// Create Firebase user
const newUser = await firebaseAuth.createUser({
  email: 'user@example.com',
  password: 'password123',
  displayName: 'John Doe',
});

// Verify ID token from Google Sign-In
const decodedToken = await firebaseAuth.verifyIdToken(idToken);

// Delete Firebase user
await firebaseAuth.deleteUser(uid);
```

**Connection Details:**
- **Protocol**: HTTPS (Firebase REST API)
- **Authentication**: Service Account Credentials
- **Operations**:
  - Create/update/delete users
  - Verify OAuth tokens
  - List all users
  - Set custom claims (roles)
  - Enable/disable accounts

---

### **4. Flutter App ↔ Firebase (Direct)**

```dart
// Flutter Side (OAuth login)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class OAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  Future<Map<String, dynamic>> signInWithGoogle() async {
    // 1. Google Sign-In (opens browser/native flow)
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    
    // 2. Get Google auth credentials
    final GoogleSignInAuthentication googleAuth = 
        await googleUser!.authentication;
    
    // 3. Create Firebase credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    // 4. Sign in to Firebase
    final UserCredential userCredential = 
        await _auth.signInWithCredential(credential);
    
    // 5. Get Firebase ID token
    final String? idToken = await userCredential.user?.getIdToken();
    
    // 6. Send to your backend for MongoDB sync
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    
    // 7. Backend verifies token, creates/updates user in MongoDB
    // 8. Backend returns JWT token for your API
    final data = jsonDecode(response.body);
    return data; // Contains JWT token + user data
  }
}
```

**Connection Details:**
- **Protocol**: HTTPS (Firebase Auth SDK)
- **Flow**:
  1. User clicks "Sign in with Google"
  2. Flutter opens Google Sign-In
  3. User authenticates with Google
  4. Google returns auth credentials
  5. Firebase verifies with Google
  6. Firebase returns ID token
  7. Flutter sends token to your backend
  8. Backend verifies token via Firebase Admin SDK
  9. Backend creates/updates user in MongoDB
  10. Backend returns JWT token
  11. Flutter uses JWT for all API calls

---

## 🔄 Data Flow Examples

### **Example 1: User Registration (Email/Password)**

```
┌─────────────┐
│ Flutter App │
│             │
│ 1. User fills registration form:
│    • Name: John Doe
│    • Email: john@example.com
│    • Password: SecurePass123
│    • Phone: +971501234567
│
│ 2. Validates input locally
│
│ 3. Sends POST request
└──────┬──────┘
       │
       │ POST /api/auth/register
       │ {
       │   "name": "John Doe",
       │   "email": "john@example.com",
       │   "password": "SecurePass123",
       │   "phone": "+971501234567"
       │ }
       ▼
┌──────────────────────┐
│ Express Backend      │
│                      │
│ 4. authController.register()
│    • Validate input (express-validator)
│    • Check email doesn't exist
│      → User.findOne({ email })
│
│ 5. Hash password
│    const salt = await bcrypt.genSalt(12);
│    const hashedPassword = await bcrypt.hash(password, salt);
│    Result: "$2a$12$hashed..."
│
│ 6. Create user in MongoDB
│    const user = await User.create({
│      name, email, password: hashedPassword, phone
│    });
│
│ 7. Generate JWT token
│    const token = jwt.sign(
│      { userId: user._id },
│      JWT_SECRET,
│      { expiresIn: '7d' }
│    );
│
│ 8. Return response
└──────┬───────────────┘
       │
       │ Response:
       │ {
       │   "success": true,
       │   "data": {
       │     "user": {
       │       "id": "670e...",
       │       "name": "John Doe",
       │       "email": "john@example.com",
       │       "roles": ["customer"]
       │     },
       │     "token": "eyJhbGciOiJIUzI1NiIs...",
       │     "refreshToken": "..."
       │   }
       │ }
       ▼
┌─────────────┐
│ Flutter App │
│             │
│ 9. Receives response
│
│ 10. Stores data:
│     await _secureStorage.write(
│       key: 'auth_token',
│       value: token
│     );
│
│ 11. Updates state:
│     authProvider.setUser(user);
│     authProvider.setAuthenticated(true);
│
│ 12. Navigates to home page
└─────────────┘

Meanwhile in MongoDB:
┌───────────────────────┐
│ MongoDB Atlas         │
│                       │
│ New document in       │
│ 'users' collection:   │
│ {                     │
│   _id: ObjectId("..."),│
│   name: "John Doe",   │
│   email: "john@...",  │
│   password: "$2a$...",│
│   phone: "+971...",   │
│   roles: ["customer"],│
│   isActive: true,     │
│   createdAt: ISODate()│
│ }                     │
└───────────────────────┘
```

---

### **Example 2: Google OAuth Sign-In**

```
┌─────────────┐
│ Flutter App │
│             │
│ 1. User taps "Sign in with Google" button
│
│ 2. OAuthService.signInWithGoogle()
└──────┬──────┘
       │
       │ Google Sign-In Flow
       ▼
┌──────────────────────┐
│ Google OAuth         │
│                      │
│ 3. Opens Google login screen
│ 4. User authenticates
│ 5. Returns auth credentials:
│    • accessToken: "ya29.a0AfH6..."
│    • idToken: "eyJhbGciOiJSUzI1NiIs..."
└──────┬───────────────┘
       │
       ▼
┌─────────────┐
│ Flutter App │
│             │
│ 6. Creates Firebase credential
│    GoogleAuthProvider.credential(
│      accessToken: token,
│      idToken: idToken
│    )
│
│ 7. Signs in to Firebase
│    await _auth.signInWithCredential(credential)
└──────┬──────┘
       │
       ▼
┌──────────────────────┐
│ Firebase             │
│                      │
│ 8. Verifies with Google
│ 9. Creates/updates Firebase user
│ 10. Returns Firebase ID token
└──────┬───────────────┘
       │
       │ Firebase ID Token
       ▼
┌─────────────┐
│ Flutter App │
│             │
│ 11. Gets Firebase ID token
│     final idToken = await user.getIdToken();
│
│ 12. Sends to backend
└──────┬──────┘
       │
       │ POST /api/auth/google
       │ {
       │   "idToken": "eyJhbGciOiJSUzI1NiIs..."
       │ }
       ▼
┌──────────────────────┐
│ Express Backend      │
│                      │
│ 13. oauthController.googleAuth()
│     • Verify ID token with Firebase
│       const decodedToken = await 
│         firebaseAuth.verifyIdToken(idToken);
│
│     • Extract user info:
│       {
│         uid: "firebase-uid-123",
│         email: "john@gmail.com",
│         name: "John Doe",
│         picture: "https://..."
│       }
│
│ 14. Check if user exists in MongoDB
│     let user = await User.findOne({
│       firebaseUid: decodedToken.uid
│     });
│
│ 15. If not exists, create new user
│     if (!user) {
│       user = await User.create({
│         firebaseUid: decodedToken.uid,
│         email: decodedToken.email,
│         name: decodedToken.name,
│         avatar: decodedToken.picture,
│         authProvider: 'google',
│         isEmailVerified: true,
│         roles: ['customer']
│       });
│     }
│
│ 16. Update last login
│     user.lastLogin = new Date();
│     await user.save();
│
│ 17. Generate JWT token
│     const token = jwt.sign(
│       { userId: user._id },
│       JWT_SECRET,
│       { expiresIn: '7d' }
│     );
│
│ 18. Return response
└──────┬───────────────┘
       │
       │ Response:
       │ {
       │   "success": true,
       │   "data": {
       │     "user": { ... },
       │     "token": "YOUR_JWT_TOKEN"
       │   }
       │ }
       ▼
┌─────────────┐
│ Flutter App │
│             │
│ 19. Stores JWT token
│ 20. Updates UI state
│ 21. Navigates to home
└─────────────┘

Meanwhile in MongoDB:
┌───────────────────────┐
│ MongoDB Atlas         │
│                       │
│ Document in 'users':  │
│ {                     │
│   _id: ObjectId("..."),│
│   firebaseUid: "fb...",│
│   email: "john@...",  │
│   name: "John Doe",   │
│   avatar: "https://...",│
│   authProvider: "google",│
│   isEmailVerified: true,│
│   roles: ["customer"],│
│   lastLogin: ISODate()│
│ }                     │
└───────────────────────┘

And in Firebase:
┌───────────────────────┐
│ Firebase Auth         │
│                       │
│ User record:          │
│ {                     │
│   uid: "firebase-...",│
│   email: "john@...",  │
│   displayName: "John",│
│   photoURL: "https...",│
│   providers: ["google"],│
│   metadata: {         │
│     creationTime,     │
│     lastSignInTime    │
│   }                   │
│ }                     │
└───────────────────────┘
```

---

### **Example 3: Fetching Products (Authenticated Request)**

```
┌─────────────┐
│ Flutter App │
│             │
│ 1. User opens Products page
│
│ 2. ProductProvider.fetchProducts()
│
│ 3. Get stored JWT token
│    final token = await _secureStorage.read(
│      key: 'auth_token'
│    );
└──────┬──────┘
       │
       │ GET /api/coffees?page=1&limit=20&category=single-origin
       │ Headers:
       │   Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
       ▼
┌──────────────────────┐
│ Express Backend      │
│                      │
│ 4. Middleware chain executes:
│
│    a) performanceMonitoring
│       → Start timer
│
│    b) helmet (security headers)
│       → Add CSP, X-Frame-Options, etc.
│
│    c) CORS
│       → Verify origin allowed
│
│    d) rateLimiting
│       → Check: < 100 requests in 15min?
│
│    e) sanitizeInput
│       → Remove $ and . from query params
│
│    f) optionalAuth (for products)
│       → Extract token from header
│       → Verify JWT signature
│       → Decode userId
│       → Query user from MongoDB:
│         const user = await User.findById(userId);
│       → Attach to request:
│         req.user = user;
│
│ 5. coffeeController.getCoffees()
│    • Build query from filters:
│      const query = {
│        isActive: true,
│        category: 'single-origin'
│      };
│
│    • Check cache first:
│      const cacheKey = 'coffees:page=1&limit=20&...';
│      const cached = cache.get(cacheKey);
│      if (cached) return cached;
│
│    • Query MongoDB:
│      const coffees = await Coffee.find(query)
│        .populate('category')
│        .sort({ isFeatured: -1, createdAt: -1 })
│        .skip(0)
│        .limit(20);
│
│    • Count total:
│      const total = await Coffee.countDocuments(query);
│
│    • Cache result (5 minutes):
│      cache.set(cacheKey, result, 300);
│
│    • Return response
└──────┬───────────────┘
       │
       │ Response:
       │ {
       │   "success": true,
       │   "data": {
       │     "coffees": [
       │       {
       │         "id": "abc...",
       │         "name": "Ethiopian Yirgacheffe",
       │         "price": 85.00,
       │         "origin": "Ethiopia",
       │         "roastLevel": "Light",
       │         "inStock": true,
       │         "imageUrl": "/uploads/coffee.jpg",
       │         "category": {
       │           "id": "cat...",
       │           "name": "Single Origin"
       │         }
       │       },
       │       ... 19 more products
       │     ],
       │     "pagination": {
       │       "total": 50,
       │       "page": 1,
       │       "limit": 20,
       │       "pages": 3
       │     }
       │   }
       │ }
       ▼
┌─────────────┐
│ Flutter App │
│             │
│ 6. Receives product list
│
│ 7. Updates state:
│    productProvider.setProducts(coffees);
│    productProvider.setPagination(pagination);
│
│ 8. UI rebuilds with data:
│    ListView.builder(
│      itemCount: products.length,
│      itemBuilder: (context, index) {
│        return CoffeeCard(product: products[index]);
│      }
│    )
└─────────────┘
```

---

### **Example 4: Admin Viewing Firebase Users**

```
┌─────────────────┐
│ Admin Panel     │
│ (Flutter Web)   │
│                 │
│ 1. Admin logs in
└──────┬──────────┘
       │
       │ POST /api/auth/admin-login
       │ {
       │   "username": "admin",
       │   "password": "almarya2024"
       │ }
       ▼
┌──────────────────────┐
│ Express Backend      │
│                      │
│ 2. authController.adminLogin()
│    • Check credentials:
│      if (username === ADMIN_USERNAME &&
│          password === ADMIN_PASSWORD)
│
│    • Generate admin JWT:
│      const token = jwt.sign(
│        { userId: 'admin', role: 'admin' },
│        JWT_SECRET,
│        { expiresIn: '7d' }
│      );
│
│    • Return token
└──────┬───────────────┘
       │
       │ Response: { token: "ADMIN_JWT" }
       ▼
┌─────────────────┐
│ Admin Panel     │
│                 │
│ 3. Stores admin token
│
│ 4. Navigates to Firebase Users page
│
│ 5. FirebaseUsersProvider.fetchFirebaseUsers()
└──────┬──────────┘
       │
       │ GET /api/admin/firebase-users?page=1&limit=20
       │ Headers:
       │   Authorization: Bearer ADMIN_JWT
       ▼
┌──────────────────────┐
│ Express Backend      │
│                      │
│ 6. Middleware:
│    protect → Verify admin JWT
│    • Decode token
│    • Check userId === 'admin'
│    • Attach req.user = { userId: 'admin', role: 'admin' }
│
│ 7. firebaseController.getAllFirebaseUsers()
│    • Query Firebase Admin SDK:
│      const listUsersResult = await 
│        firebaseAuth.listUsers(1000);
│
│    • Get all Firebase users:
│      const firebaseUsers = listUsersResult.users.map(u => ({
│        uid: u.uid,
│        email: u.email,
│        displayName: u.displayName,
│        photoURL: u.photoURL,
│        disabled: u.disabled,
│        metadata: u.metadata
│      }));
│
│    • For each Firebase user, check MongoDB:
│      for (const fbUser of firebaseUsers) {
│        const localUser = await User.findOne({
│          firebaseUid: fbUser.uid
│        });
│        
│        fbUser.syncStatus = {
│          isLinked: !!localUser,
│          localUserId: localUser?._id,
│          syncStatus: localUser ? 'synced' : 'not_synced'
│        };
│      }
│
│    • Apply pagination
│    • Return enriched data
└──────┬───────────────┘
       │
       │ Response:
       │ {
       │   "success": true,
       │   "data": {
       │     "users": [
       │       {
       │         "uid": "firebase-uid-1",
       │         "email": "user1@example.com",
       │         "displayName": "User One",
       │         "disabled": false,
       │         "syncStatus": {
       │           "isLinked": true,
       │           "localUserId": "mongo-id-1",
       │           "syncStatus": "synced"
       │         }
       │       },
       │       ... 13 more users
       │     ],
       │     "pagination": {
       │       "total": 14,
       │       "page": 1,
       │       "limit": 20
       │     }
       │   }
       │ }
       ▼
┌─────────────────┐
│ Admin Panel     │
│                 │
│ 8. Displays users in table:
│    • Email
│    • Display Name
│    • Status (Active/Disabled)
│    • Sync Status (badge)
│    • Actions (Enable/Disable/Delete)
└─────────────────┘
```

---

## 🔄 Firebase ↔ MongoDB Sync

### **Why Sync?**

Firebase and MongoDB serve different purposes:

| Firebase | MongoDB |
|----------|---------|
| Authentication only | Complete user data |
| OAuth providers | Products, orders, settings |
| Fast token verification | Rich queries & relationships |
| Limited user data | Full profile, addresses, preferences |

**Solution**: Keep both in sync - Firebase for auth, MongoDB as source of truth.

### **Sync Strategies**

#### **1. Auto-Sync on User Creation**

```javascript
// backend/controllers/authController.js

exports.register = async (req, res) => {
  const { email, password, name } = req.body;
  
  // 1. Create in MongoDB (source of truth)
  const user = await User.create({
    email,
    password,
    name,
    authProvider: 'email',
    roles: ['customer']
  });
  
  // 2. Create in Firebase (for authentication)
  try {
    const firebaseUser = await firebaseAuth.createUser({
      uid: user._id.toString(), // Use MongoDB ID
      email: user.email,
      password: password, // Firebase will hash it
      displayName: user.name,
    });
    
    // 3. Link Firebase UID to MongoDB user
    user.firebaseUid = firebaseUser.uid;
    await user.save();
    
    console.log('✅ User synced to Firebase');
  } catch (firebaseError) {
    console.warn('⚠️  Firebase sync failed:', firebaseError.message);
    // Continue without Firebase (MongoDB is source of truth)
  }
  
  // 4. Return JWT token
  const token = generateToken(user._id);
  
  res.status(201).json({
    success: true,
    data: { user, token }
  });
};
```

#### **2. Auto-Sync Service (Background)**

```javascript
// backend/services/autoSyncService.js

const syncFirebaseToMongoDB = async () => {
  console.log('🔄 Starting Firebase → MongoDB sync...');
  
  // 1. Get all Firebase users
  const listUsersResult = await firebaseAuth.listUsers(1000);
  
  let synced = 0;
  let created = 0;
  let errors = 0;
  
  // 2. For each Firebase user
  for (const fbUser of listUsersResult.users) {
    try {
      // 3. Check if exists in MongoDB
      let localUser = await User.findOne({ 
        firebaseUid: fbUser.uid 
      });
      
      if (!localUser) {
        // 4. Create if doesn't exist
        localUser = await User.create({
          firebaseUid: fbUser.uid,
          email: fbUser.email,
          name: fbUser.displayName || 'User',
          avatar: fbUser.photoURL,
          authProvider: 'google', // or 'facebook'
          isEmailVerified: fbUser.emailVerified,
          roles: ['customer'],
        });
        created++;
      } else {
        // 5. Update if exists
        localUser.name = fbUser.displayName || localUser.name;
        localUser.avatar = fbUser.photoURL || localUser.avatar;
        localUser.isEmailVerified = fbUser.emailVerified;
        await localUser.save();
        synced++;
      }
    } catch (error) {
      console.error(`❌ Sync error for ${fbUser.email}:`, error.message);
      errors++;
    }
  }
  
  console.log(`✅ Sync complete: ${synced} updated, ${created} created, ${errors} errors`);
};

// Run every 5 minutes
setInterval(syncFirebaseToMongoDB, 5 * 60 * 1000);
```

#### **3. Manual Sync Endpoint**

```javascript
// POST /api/firebase-sync
exports.syncFirebaseUsers = async (req, res) => {
  await syncFirebaseToMongoDB();
  
  res.json({
    success: true,
    message: 'Sync completed'
  });
};
```

### **Sync Status Check**

```javascript
// Check sync status for a user

const user = await User.findOne({ email: 'user@example.com' });

if (user.firebaseUid) {
  try {
    const fbUser = await firebaseAuth.getUser(user.firebaseUid);
    console.log('✅ Synced - Firebase user exists');
  } catch (error) {
    console.log('❌ Not synced - Firebase user not found');
  }
} else {
  console.log('⚠️  No Firebase UID - user not synced');
}
```

---

## ⚙️ Configuration & Setup

### **1. MongoDB Atlas Setup**

```bash
# Already configured in your .env
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/al_marya_rostery

# Connection test
node -e "
  const mongoose = require('mongoose');
  mongoose.connect(process.env.MONGO_URI)
    .then(() => console.log('✅ Connected'))
    .catch(err => console.error('❌ Error:', err));
"
```

**MongoDB Atlas Settings:**
- ✅ IP Whitelist: 0.0.0.0/0 (allow all)
- ✅ Database User: Read/write access
- ✅ Network Access: Enabled
- ✅ Region: Choose closest to your users

### **2. Firebase Setup**

```bash
# .env configuration
FIREBASE_PROJECT_ID=qahwat-al-emarat
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

**Firebase Console Settings:**
- ✅ Authentication enabled
- ✅ Email/Password provider enabled
- ✅ Google provider enabled (optional)
- ✅ Facebook provider enabled (optional)
- ✅ Service account created
- ✅ Private key downloaded

### **3. Flutter App Configuration**

```dart
// lib/core/config/api_config.dart
class ApiConfig {
  // Backend URL
  static const String baseUrl = 'https://al-marya-rostary.onrender.com';
  
  // Endpoints
  static const String auth = '/api/auth';
  static const String users = '/api/users';
  static const String coffees = '/api/coffees';
  static const String orders = '/api/orders';
  static const String admin = '/api/admin';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

// lib/firebase_options.dart (generated by FlutterFire CLI)
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSy...',
  appId: '1:123456:android:abc123',
  messagingSenderId: '123456',
  projectId: 'qahwat-al-emarat',
);
```

---

## 🧪 Testing the Connection

### **Test 1: MongoDB Connection**

```bash
cd backend
node -e "
  require('dotenv').config();
  const mongoose = require('mongoose');
  
  mongoose.connect(process.env.MONGO_URI)
    .then(() => {
      console.log('✅ MongoDB connected');
      return mongoose.connection.db.admin().listDatabases();
    })
    .then(result => {
      console.log('📊 Databases:', result.databases.map(d => d.name));
      process.exit(0);
    })
    .catch(err => {
      console.error('❌ Error:', err.message);
      process.exit(1);
    });
"
```

Expected output:
```
✅ MongoDB connected
📊 Databases: [ 'admin', 'al_marya_rostery', 'local' ]
```

### **Test 2: Firebase Connection**

```bash
cd backend
node -e "
  require('dotenv').config();
  const admin = require('firebase-admin');
  
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\\\n/g, '\\n'),
    }),
  });
  
  admin.auth().listUsers(5)
    .then(result => {
      console.log('✅ Firebase connected');
      console.log('👥 Users:', result.users.length);
      result.users.forEach(u => {
        console.log('  -', u.email);
      });
      process.exit(0);
    })
    .catch(err => {
      console.error('❌ Error:', err.message);
      process.exit(1);
    });
"
```

Expected output:
```
✅ Firebase connected
👥 Users: 5
  - user1@example.com
  - user2@example.com
  - user3@example.com
  - user4@example.com
  - user5@example.com
```

### **Test 3: Backend API**

```bash
# Start backend
cd backend
npm start

# Test health endpoint
curl http://localhost:5001/health

# Expected: {"status":"healthy","mongodb":"connected","uptime":123}

# Test admin login
curl -X POST http://localhost:5001/api/auth/admin-login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"almarya2024"}'

# Expected: {"success":true,"data":{"token":"JWT_TOKEN"}}

# Test Firebase users (use token from above)
curl -X GET "http://localhost:5001/api/admin/firebase-users?page=1&limit=5" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"

# Expected: {"success":true,"data":{"users":[...],"pagination":{...}}}
```

### **Test 4: Flutter App Connection**

```dart
// Run in Flutter app

void testBackendConnection() async {
  try {
    // Test 1: Health check
    final response = await http.get(
      Uri.parse('https://al-marya-rostary.onrender.com/health'),
    );
    
    if (response.statusCode == 200) {
      print('✅ Backend reachable');
      print(response.body);
    } else {
      print('❌ Backend returned ${response.statusCode}');
    }
    
    // Test 2: Login
    final loginResponse = await http.post(
      Uri.parse('https://al-marya-rostary.onrender.com/api/auth/admin-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': 'admin',
        'password': 'almarya2024',
      }),
    );
    
    if (loginResponse.statusCode == 200) {
      print('✅ Login successful');
      final data = jsonDecode(loginResponse.body);
      print('Token: ${data['data']['token'].substring(0, 20)}...');
    } else {
      print('❌ Login failed');
    }
  } catch (e) {
    print('❌ Connection error: $e');
  }
}
```

---

## 🔧 Troubleshooting

### **Problem: MongoDB Connection Failed**

```
Error: MongooseServerSelectionError: connect ECONNREFUSED
```

**Solutions:**
1. Check MONGO_URI in .env
2. Verify MongoDB Atlas IP whitelist (0.0.0.0/0)
3. Check database user permissions
4. Test internet connection
5. Verify cluster is running

### **Problem: Firebase SDK Error**

```
Error: Failed to parse private key
```

**Solutions:**
1. Check FIREBASE_PRIVATE_KEY format in .env
2. Ensure newlines are preserved: `"-----BEGIN PRIVATE KEY-----\n..."`
3. Verify project ID matches Firebase Console
4. Check service account has admin permissions

### **Problem: JWT Token Invalid**

```
401 Unauthorized - Invalid token
```

**Solutions:**
1. Check token format: `Bearer YOUR_TOKEN`
2. Verify token not expired (7 days)
3. Ensure JWT_SECRET matches across all services
4. Check user still exists and is active
5. Try logging in again to get fresh token

### **Problem: Firebase Users Not Loading**

```
Infinite loading spinner in admin panel
```

**Solutions:**
1. Check auth token loaded before API call ✅ (FIXED)
2. Verify admin token is valid
3. Check backend running and accessible
4. Verify Firebase Admin SDK initialized
5. Check network tab for errors

### **Problem: OAuth Login Fails**

```
Error: Google Sign-In failed
```

**Solutions:**
1. Verify Google OAuth enabled in Firebase Console
2. Check SHA-1 fingerprint registered (Android)
3. Verify GoogleService-Info.plist (iOS)
4. Check redirect URLs configured
5. Test internet connection

---

## 📊 Connection Health Monitoring

### **Backend Monitoring Endpoints**

```bash
# Health check
GET /health
{
  "status": "healthy",
  "mongodb": "connected",
  "firebase": "initialized",
  "uptime": 3600,
  "memory": "45MB / 512MB"
}

# Performance metrics
GET /api/admin/performance
{
  "requests": {
    "total": 15234,
    "successful": 14980,
    "failed": 254
  },
  "responseTime": {
    "avg": 45,
    "p95": 120,
    "p99": 250
  }
}

# Cache statistics
GET /api/admin/cache-stats
{
  "keys": 127,
  "hits": 8540,
  "misses": 2130,
  "hitRate": 0.80
}
```

---

## 🎉 Summary

Your system is fully connected:

```
Flutter App
    ↕ (HTTPS/JSON/JWT)
Express Backend
    ↕ (Mongoose ODM)         ↕ (Firebase Admin SDK)
MongoDB Atlas           Firebase Auth
```

### **Data Flow:**
1. User interacts with Flutter app
2. Flutter sends HTTP request with JWT token
3. Backend verifies token (JWT or Firebase)
4. Backend queries/updates MongoDB
5. Backend syncs with Firebase (if needed)
6. Backend returns JSON response
7. Flutter updates UI

### **Authentication Flow:**
1. Email/Password → MongoDB → JWT
2. Google/Facebook → Firebase → Backend verifies → MongoDB → JWT
3. All subsequent requests → JWT verification → Access granted

### **Key Points:**
- ✅ MongoDB is source of truth for all data
- ✅ Firebase handles OAuth (Google/Facebook)
- ✅ Backend syncs Firebase ↔ MongoDB
- ✅ JWT tokens secure API access
- ✅ All connections encrypted (HTTPS/TLS)

---

**Everything is working properly! 🚀**

Your backend correctly connects MongoDB, Firebase, and your Flutter app with proper authentication, data sync, and security.

