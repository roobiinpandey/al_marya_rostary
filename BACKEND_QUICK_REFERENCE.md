# 🚀 Backend Quick Reference Guide
## Al Marya Rostery - For Developers

---

## 📚 Full Documentation
👉 **[Read Complete Architecture Explanation](./BACKEND_ARCHITECTURE_EXPLAINED.md)** (700+ lines)

---

## ⚡ Quick Start

### Backend URLs
```
Production: https://al-marya-rostary.onrender.com
Local: http://localhost:5001
```

### Start Backend Locally
```bash
cd backend
npm install
npm start
```

---

## 🔑 Authentication Cheat Sheet

### Register User
```javascript
POST /api/auth/register
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "SecurePass123",
  "phone": "+971501234567"
}

Response:
{
  "success": true,
  "data": {
    "user": { id, name, email, roles },
    "token": "JWT_ACCESS_TOKEN",
    "refreshToken": "JWT_REFRESH_TOKEN"
  }
}
```

### Login
```javascript
POST /api/auth/login
{
  "email": "user@example.com",
  "password": "password123"
}

Response: Same as register
```

### Admin Login
```javascript
POST /api/auth/admin-login
{
  "username": "admin",
  "password": "almarya2024"
}

Response:
{
  "success": true,
  "data": {
    "token": "ADMIN_JWT_TOKEN"
  }
}
```

### Use Token in Requests
```javascript
Headers:
Authorization: Bearer YOUR_JWT_TOKEN_HERE
```

---

## 👤 User Endpoints

### Get Current User Profile
```javascript
GET /api/auth/me
Headers: Authorization: Bearer <token>

Response:
{
  "success": true,
  "data": {
    "user": {
      "id": "670e...",
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+971501234567",
      "avatar": "/uploads/profile.jpg",
      "roles": ["customer"],
      "isEmailVerified": true,
      "loyaltyProgram": {
        "points": 150,
        "tier": "Silver"
      }
    }
  }
}
```

### Update Profile
```javascript
PUT /api/auth/profile
Headers: Authorization: Bearer <token>
Body: {
  "name": "New Name",
  "phone": "+971509999999"
}
```

### Password Reset
```javascript
1. Request Reset:
POST /api/auth/forgot-password
{ "email": "user@example.com" }

2. Reset Password:
POST /api/auth/reset-password
{
  "token": "JWT_RESET_TOKEN",
  "newPassword": "NewPass123",
  "confirmPassword": "NewPass123"
}
```

---

## ☕ Product Endpoints

### Get All Products
```javascript
GET /api/coffees?page=1&limit=20&category=single-origin&roastLevel=Medium

Response:
{
  "success": true,
  "data": {
    "coffees": [
      {
        "id": "abc...",
        "name": "Ethiopian Yirgacheffe",
        "price": 85.00,
        "origin": "Ethiopia",
        "roastLevel": "Light",
        "inStock": true,
        "imageUrl": "/uploads/coffee.jpg"
      }
    ],
    "pagination": {
      "total": 50,
      "page": 1,
      "pages": 3
    }
  }
}
```

### Get Single Product
```javascript
GET /api/coffees/:id

Response: Full product details with category, reviews, etc.
```

### Create Product (Admin Only)
```javascript
POST /api/coffees
Headers: Authorization: Bearer <admin-token>
Content-Type: multipart/form-data

Body:
{
  "name": "New Coffee",
  "price": 75.00,
  "origin": "Colombia",
  "roastLevel": "Medium",
  "description": "Amazing coffee...",
  "stock": 100,
  "image": [FILE]
}
```

---

## 📦 Order Endpoints

### Create Order
```javascript
POST /api/orders
Headers: Authorization: Bearer <token>
{
  "items": [
    {
      "coffeeId": "abc123",
      "quantity": 2,
      "size": "500g",
      "price": 160.00
    }
  ],
  "deliveryAddress": {
    "street": "123 Main St",
    "city": "Dubai",
    "zipCode": "12345"
  },
  "paymentMethod": "card",
  "totalAmount": 320.00
}
```

### Get User Orders
```javascript
GET /api/orders
Headers: Authorization: Bearer <token>

Response:
{
  "success": true,
  "data": {
    "orders": [
      {
        "orderNumber": "ORD-20251018-001",
        "status": "delivered",
        "totalAmount": 320.00,
        "items": [...],
        "createdAt": "2025-10-18T12:00:00Z"
      }
    ]
  }
}
```

---

## 👨‍💼 Admin Endpoints

### Get All Users
```javascript
GET /api/admin/users?page=1&limit=20
Headers: Authorization: Bearer <admin-token>
```

### Get Firebase Users
```javascript
GET /api/admin/firebase-users?page=1&limit=20
Headers: Authorization: Bearer <admin-token>

Response:
{
  "success": true,
  "data": {
    "users": [
      {
        "uid": "firebase-uid...",
        "email": "user@example.com",
        "displayName": "John Doe",
        "disabled": false,
        "syncStatus": {
          "isLinked": true,
          "localUserId": "mongo-id...",
          "syncStatus": "synced"
        }
      }
    ],
    "pagination": { "total": 14 }
  }
}
```

### Get All Orders (Admin)
```javascript
GET /api/admin/orders?status=pending&page=1
Headers: Authorization: Bearer <admin-token>
```

### Update Order Status
```javascript
PUT /api/admin/orders/:id
Headers: Authorization: Bearer <admin-token>
{
  "status": "processing" // pending, processing, shipped, delivered, cancelled
}
```

---

## 🔒 Middleware & Security

### Authentication Middleware
```javascript
const { protect, authorize } = require('./middleware/auth');

// Protect route (requires JWT)
router.get('/profile', protect, getProfile);

// Protect + authorize (requires JWT + specific role)
router.delete('/users/:id', protect, authorize('admin'), deleteUser);

// Optional auth (token not required but will be used if present)
router.get('/products', optionalAuth, getProducts);
```

### How Middleware Works
```javascript
Request Flow:
1. Client sends request with JWT token
2. protect middleware:
   • Extracts token from Authorization header
   • Verifies JWT signature
   • Decodes userId from token
   • Queries user from MongoDB
   • Attaches user to req.user
3. authorize middleware (if used):
   • Checks if user has required role
   • Returns 403 if unauthorized
4. Route handler executes
5. Response sent back
```

---

## 🗄️ Database Models

### User Model
```javascript
{
  name: String,
  email: String (unique),
  password: String (bcrypt hashed),
  phone: String,
  avatar: String,
  roles: ["customer"] or ["admin"],
  isActive: Boolean,
  isEmailVerified: Boolean,
  firebaseUid: String (unique, sparse),
  authProvider: "email" | "google" | "facebook",
  addresses: [AddressSchema],
  preferences: Object,
  loyaltyProgram: {
    points: Number,
    tier: String
  }
}
```

### Coffee Model
```javascript
{
  name: {
    en: String,
    ar: String
  },
  description: {
    en: String,
    ar: String
  },
  price: Number,
  image: String,
  origin: String,
  roastLevel: "Light" | "Medium" | "Dark",
  stock: Number,
  categories: [String],
  variants: [
    {
      size: "250gm" | "500gm" | "1kg",
      price: Number,
      stock: Number
    }
  ],
  isActive: Boolean,
  isFeatured: Boolean
}
```

### Order Model
```javascript
{
  orderNumber: String (unique),
  userId: ObjectId,
  items: [
    {
      coffeeId: ObjectId,
      quantity: Number,
      size: String,
      price: Number
    }
  ],
  status: "pending" | "processing" | "shipped" | "delivered" | "cancelled",
  paymentStatus: "pending" | "paid" | "failed",
  totalAmount: Number,
  deliveryAddress: Object,
  createdAt: Date
}
```

---

## ⚙️ Environment Variables

```bash
# Server
PORT=5001
NODE_ENV=production

# Database
MONGO_URI=***REMOVED***user:pass@cluster.mongodb.net/al_marya_rostery

# JWT
JWT_SECRET=your-super-secret-64-character-key-here
JWT_EXPIRE=7d
JWT_REFRESH_SECRET=your-refresh-secret
JWT_REFRESH_EXPIRE=30d

# Admin Credentials
ADMIN_USERNAME=admin
ADMIN_PASSWORD=almarya2024

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=noreply@almaryah.com
SMTP_PASS=your-app-password

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=service-account@project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----...
```

---

## 🎯 Common Tasks

### Test Backend Locally
```bash
# 1. Start MongoDB (if local)
mongod

# 2. Start backend
cd backend
npm start

# 3. Test with curl
curl http://localhost:5001/health

# 4. Test login
curl -X POST http://localhost:5001/api/auth/admin-login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"almarya2024"}'
```

### Debug Issues
```bash
# Check logs
cd backend
npm start

# Look for:
✅ MongoDB connected successfully
✅ Server running on port 5001
✅ Firebase initialized

# Common errors:
❌ MONGO_URI not found → Check .env file
❌ JWT_SECRET not set → Add to .env
❌ Port already in use → Kill process on port 5001
```

### Add New Endpoint
```javascript
// 1. Create route handler (routes/myroute.js)
const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');

router.get('/', protect, async (req, res) => {
  try {
    // Your logic here
    res.json({ success: true, data: {} });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;

// 2. Register in server.js
const myRoute = require('./routes/myroute');
app.use('/api/myroute', myRoute);
```

---

## 🔄 Request/Response Flow

```
┌─────────────┐
│ Flutter App │
└──────┬──────┘
       │ POST /api/auth/login + credentials
       ▼
┌──────────────────────┐
│ Express Middleware   │
│ 1. Security headers  │
│ 2. CORS              │
│ 3. Rate limiting     │
│ 4. Input sanitize    │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Auth Controller      │
│ • Find user by email │
│ • Compare password   │
│ • Generate JWT       │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ MongoDB Query        │
│ User.findOne({email})│
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Response             │
│ { token, user }      │
└──────┬───────────────┘
       │
       ▼
┌─────────────┐
│ Flutter App │
│ Store token │
│ Navigate    │
└─────────────┘
```

---

## 📊 Performance Tips

### Caching
```javascript
// Products cached for 5 minutes
GET /api/coffees → Check cache first

// Clear cache after update
PUT /api/coffees/:id → Clear cache
```

### Database Indexes
```javascript
// Fast queries with indexes:
User.findOne({ email }) → O(1) with email index
Coffee.find({ category }) → O(log n) with category index
Order.find({ userId }) → O(log n) with userId index
```

### Pagination
```javascript
// Always paginate large datasets
GET /api/coffees?page=1&limit=20
GET /api/orders?page=1&limit=10

// Don't fetch all at once (slow)
```

---

## 🛠️ Troubleshooting

### User Data Not Loading
```javascript
Problem: Firebase users not loading in admin panel

Solution:
1. Make sure auth token is loaded first
2. Check backend is running
3. Verify admin token is valid
4. Check network tab in browser

Fixed in: lib/features/admin/presentation/pages/firebase_users_page.dart
```

### JWT Token Invalid
```javascript
Problem: 401 Unauthorized errors

Check:
1. Token format: "Bearer YOUR_TOKEN"
2. Token not expired (7 days)
3. JWT_SECRET matches between frontend/backend
4. User still exists and is active
```

### MongoDB Connection Failed
```javascript
Problem: Cannot connect to database

Check:
1. MONGO_URI in .env is correct
2. MongoDB Atlas IP whitelist (allow all: 0.0.0.0/0)
3. Database user has read/write permissions
4. Internet connection
```

---

## 📱 Flutter Integration

### API Service Example
```dart
class ApiService {
  static const String baseUrl = 'https://al-marya-rostary.onrender.com';
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed');
    }
  }
  
  Future<List<Coffee>> getCoffees(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/coffees'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data']['coffees'] as List)
          .map((e) => Coffee.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to load coffees');
    }
  }
}
```

---

## 🎉 Summary

Your backend provides:
- ✅ **JWT Authentication** (register, login, OAuth)
- ✅ **User Management** (CRUD, profile, password reset)
- ✅ **Product Catalog** (coffees, categories, search)
- ✅ **Order System** (create, track, admin management)
- ✅ **Admin Panel** (user mgmt, orders, Firebase sync)
- ✅ **Security** (rate limiting, input validation, bcrypt)
- ✅ **Performance** (caching, indexing, monitoring)
- ✅ **Production Ready** (error handling, logging, health checks)

---

**For detailed explanations, read**: [BACKEND_ARCHITECTURE_EXPLAINED.md](./BACKEND_ARCHITECTURE_EXPLAINED.md)

**Status**: ✅ Production Ready  
**Last Updated**: October 18, 2025
