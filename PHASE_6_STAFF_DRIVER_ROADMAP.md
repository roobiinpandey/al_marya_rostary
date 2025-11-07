# Phase 6: Staff & Driver Apps - Implementation Plan

## 🎯 Mission
Build complete multi-app ecosystem for Al Marya Rostery with:
- **Staff App:** Order management for cafe staff
- **Driver App:** Delivery management with GPS tracking
- **Real-time Integration:** FCM notifications + GPS tracking

---

## 📊 Current Status

✅ **Phase 1:** Admin User Setup (100%)  
✅ **Phase 2:** Order Workflow Testing (100%)  
✅ **Phase 3:** Stripe Integration + Digital Wallets (100%)  
✅ **Phase 4:** Email Notifications (100%)  
✅ **Phase 5:** Admin Features Testing (82.86% pass rate)  
🔄 **Phase 6:** Staff & Driver Apps (STARTING NOW)

---

## 🏗️ Phase 6 Breakdown

### **Sub-Phase 6.1: Backend Preparation** (3-5 days)

#### Task 1: Create Staff Model
**File:** `backend/models/Staff.js`

```javascript
const staffSchema = new mongoose.Schema({
  firebaseUid: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String, required: true },
  role: {
    type: String,
    enum: ['barista', 'manager', 'cashier'],
    default: 'barista'
  },
  fcmToken: { type: String },
  status: {
    type: String,
    enum: ['active', 'inactive', 'on_break'],
    default: 'active'
  },
  assignedOrders: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Order' }],
  hireDate: { type: Date, default: Date.now },
  isEmailVerified: { type: Boolean, default: false }
}, { timestamps: true });
```

---

#### Task 2: Create Driver Model
**File:** `backend/models/Driver.js`

```javascript
const driverSchema = new mongoose.Schema({
  firebaseUid: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String, required: true },
  vehicleType: {
    type: String,
    enum: ['bike', 'car', 'scooter'],
    required: true
  },
  vehicleNumber: { type: String, required: true },
  fcmToken: { type: String },
  status: {
    type: String,
    enum: ['available', 'on_delivery', 'offline'],
    default: 'offline'
  },
  currentLocation: {
    latitude: Number,
    longitude: Number,
    updatedAt: Date
  },
  activeDelivery: { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
  stats: {
    totalDeliveries: { type: Number, default: 0 },
    completedToday: { type: Number, default: 0 },
    earnings: { type: Number, default: 0 },
    averageRating: { type: Number, default: 0 }
  }
}, { timestamps: true });
```

---

#### Task 3: Update Order Model
**File:** `backend/models/Order.js` (add new fields)

```javascript
// Add these fields to existing Order model:
assignedStaff: {
  type: mongoose.Schema.Types.ObjectId,
  ref: 'Staff'
},
assignedDriver: {
  type: mongoose.Schema.Types.ObjectId,
  ref: 'Driver'
},
tracking: {
  driverLocation: {
    latitude: Number,
    longitude: Number,
    lastUpdated: Date
  },
  estimatedArrival: Date,
  distanceRemaining: Number
},
timestamps: {
  acceptedByStaff: Date,
  preparationStarted: Date,
  markedReady: Date,
  acceptedByDriver: Date,
  pickedUp: Date,
  delivered: Date
}
```

---

#### Task 4: Create Staff Routes
**File:** `backend/routes/staff.js`

```javascript
const express = require('express');
const router = express.Router();

// Authentication
router.post('/login', staffLogin);
router.post('/register', staffRegister);
router.post('/fcm-token', protect, updateStaffFcmToken);

// Order Management
router.get('/orders', protect, getStaffOrders);              // Get pending orders
router.get('/orders/:id', protect, getStaffOrderDetails);
router.post('/orders/:id/accept', protect, acceptOrder);     // Accept order
router.post('/orders/:id/start', protect, startPreparation); // Start prep
router.post('/orders/:id/ready', protect, markOrderReady);   // Mark ready

// Profile
router.get('/profile', protect, getStaffProfile);
router.put('/status', protect, updateStaffStatus);           // active/break
router.get('/stats', protect, getStaffStats);

module.exports = router;
```

---

#### Task 5: Create Driver Routes
**File:** `backend/routes/driver.js`

```javascript
const express = require('express');
const router = express.Router();

// Authentication
router.post('/login', driverLogin);
router.post('/register', driverRegister);
router.post('/fcm-token', protect, updateDriverFcmToken);

// Order Management
router.get('/orders', protect, getAvailableOrders);         // Get ready orders
router.get('/orders/:id', protect, getDriverOrderDetails);
router.post('/orders/:id/accept', protect, acceptDelivery); // Accept delivery
router.post('/orders/:id/pickup', protect, pickupOrder);    // Mark picked up
router.post('/orders/:id/deliver', protect, deliverOrder);  // Mark delivered

// Location Tracking
router.post('/location', protect, updateDriverLocation);    // Update GPS
router.get('/location/:orderId', getDriverLocation);        // Get location

// Profile & Stats
router.get('/profile', protect, getDriverProfile);
router.put('/status', protect, updateDriverStatus);         // available/offline
router.get('/stats', protect, getDriverStats);

module.exports = router;
```

---

#### Task 6: Implement FCM Notification Service
**File:** `backend/services/notificationService.js` (extend existing)

```javascript
// Add these notification triggers:

// 1. New order → Notify all active staff
async function notifyStaffNewOrder(order) {
  const staffList = await Staff.find({ 
    status: 'active',
    fcmToken: { $exists: true, $ne: null }
  });
  
  const tokens = staffList.map(s => s.fcmToken);
  
  await pushNotificationService.sendToDevices(tokens, {
    title: `New Order #${order.orderNumber}`,
    body: `${order.items.length} items - AED ${order.totalAmount}`,
    data: { orderId: order._id, type: 'new_order' }
  });
}

// 2. Order ready → Notify available drivers
async function notifyDriversOrderReady(order) {
  const drivers = await Driver.find({ 
    status: 'available',
    fcmToken: { $exists: true, $ne: null }
  });
  
  const tokens = drivers.map(d => d.fcmToken);
  
  await pushNotificationService.sendToDevices(tokens, {
    title: `Delivery Available`,
    body: `Order #${order.orderNumber} ready for pickup`,
    data: { orderId: order._id, type: 'order_ready' }
  });
}

// 3. Driver assigned → Notify customer
async function notifyCustomerDriverAssigned(order, driver) {
  if (order.user && order.user.fcmToken) {
    await pushNotificationService.sendToDevice(order.user.fcmToken, {
      title: `Driver Assigned`,
      body: `${driver.name} will deliver your order`,
      data: { orderId: order._id, driverId: driver._id, type: 'driver_assigned' }
    });
  }
}

// 4. Location update → Notify customer (throttled)
async function notifyCustomerLocationUpdate(order, location) {
  // Send only every 2 minutes
  if (order.user && order.user.fcmToken) {
    await pushNotificationService.sendToDevice(order.user.fcmToken, {
      title: `Your Order is On the Way`,
      body: `Track your delivery in real-time`,
      data: { 
        orderId: order._id, 
        latitude: location.latitude,
        longitude: location.longitude,
        type: 'location_update' 
      }
    });
  }
}
```

---

#### Task 7: Create Test Scripts
**Files:**
- `backend/test-staff-endpoints.sh`
- `backend/test-driver-endpoints.sh`
- `backend/test-fcm-notifications.sh`

**Test Coverage:**
- Staff registration & login
- Staff order management
- Driver registration & login  
- Driver order management
- Location updates
- FCM notifications

---

### **Sub-Phase 6.2: Staff App Development** (5-7 days)

#### Structure:
```
staff_app/
├── lib/
│   ├── core/
│   │   ├── api/
│   │   │   └── staff_api_service.dart
│   │   ├── models/
│   │   │   ├── staff_order.dart
│   │   │   └── staff_user.dart
│   │   └── services/
│   │       ├── fcm_service.dart
│   │       └── notification_handler.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   ├── staff_login_page.dart
│   │   │       │   └── staff_register_page.dart
│   │   │       └── providers/
│   │   │           └── staff_auth_provider.dart
│   │   ├── orders/
│   │   │   ├── data/
│   │   │   │   └── staff_order_repository.dart
│   │   │   ├── presentation/
│   │   │   │   ├── pages/
│   │   │   │   │   ├── staff_orders_page.dart
│   │   │   │   │   └── staff_order_detail_page.dart
│   │   │   │   ├── providers/
│   │   │   │   │   └── staff_order_provider.dart
│   │   │   │   └── widgets/
│   │   │   │       └── staff_order_card.dart
│   │   └── profile/
│   └── main.dart
├── android/
├── ios/
└── pubspec.yaml
```

#### Key Features:
1. **Authentication**
   - Firebase Auth integration
   - Email/Password login
   - Secure token storage

2. **Order Management**
   - View pending orders (real-time)
   - Accept orders
   - Start preparation
   - Mark ready for delivery
   - Order history

3. **Notifications**
   - FCM for new orders
   - Sound alerts
   - Badge count

4. **UI/UX**
   - Tab navigation (Pending, Preparing, Ready)
   - Pull-to-refresh
   - Order details with items list
   - Status update buttons

---

### **Sub-Phase 6.3: Driver App Development** (10-14 days)

#### Structure:
```
driver_app/
├── lib/
│   ├── core/
│   │   ├── api/
│   │   │   └── driver_api_service.dart
│   │   ├── models/
│   │   │   ├── driver_order.dart
│   │   │   └── driver_user.dart
│   │   └── services/
│   │       ├── fcm_service.dart
│   │       ├── location_service.dart
│   │       └── map_service.dart
│   ├── features/
│   │   ├── auth/
│   │   ├── orders/
│   │   │   ├── data/
│   │   │   ├── presentation/
│   │   │   │   ├── pages/
│   │   │   │   │   ├── driver_orders_page.dart
│   │   │   │   │   ├── active_delivery_page.dart
│   │   │   │   │   └── delivery_complete_page.dart
│   │   │   │   ├── providers/
│   │   │   │   │   ├── driver_order_provider.dart
│   │   │   │   │   └── location_provider.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── driver_order_card.dart
│   │   │   │       └── map_widget.dart
│   │   └── tracking/
│   │       ├── services/
│   │       │   └── gps_tracking_service.dart
│   │       └── pages/
│   │           └── navigation_page.dart
│   └── main.dart
├── android/
├── ios/
└── pubspec.yaml
```

#### Key Features:
1. **Authentication**
   - Firebase Auth
   - Driver registration with vehicle info
   - Profile management

2. **Order Management**
   - View available deliveries
   - Accept delivery
   - Mark picked up
   - Mark delivered
   - Order history

3. **GPS Tracking**
   - Real-time location updates (every 10 seconds)
   - Google Maps integration
   - Route navigation to customer
   - ETA calculation
   - Background location updates

4. **Driver Dashboard**
   - Earnings tracker
   - Delivery count
   - Average rating
   - Online/Offline toggle

5. **Notifications**
   - FCM for new delivery opportunities
   - Order updates
   - Customer messages

#### Dependencies:
```yaml
dependencies:
  # State Management
  provider: ^6.0.5
  
  # Firebase
  firebase_core: latest
  firebase_auth: latest
  firebase_messaging: latest
  
  # Location & Maps
  geolocator: ^11.0.0
  google_maps_flutter: ^2.5.0
  location: ^5.0.0
  
  # Network
  dio: latest
  
  # Storage
  flutter_secure_storage: latest
  
  # UI
  intl: latest
```

---

### **Sub-Phase 6.4: Integration & Testing** (3-5 days)

#### End-to-End Test Scenarios:

**Scenario 1: Happy Path**
1. Customer places order via customer app
2. Staff receives FCM notification
3. Staff opens staff app, sees new order
4. Staff accepts order
5. Customer app shows "Preparing"
6. Staff marks order ready
7. Driver receives FCM notification
8. Driver accepts delivery
9. Customer app shows "Driver Assigned"
10. Driver picks up order
11. GPS tracking starts
12. Customer sees driver location on map
13. Driver delivers order
14. Order status: "Delivered"

**Scenario 2: Multiple Orders**
1. Multiple customers place orders
2. Staff sees all pending orders
3. Staff processes orders one by one
4. Multiple drivers available
5. Each order assigned to different driver
6. All deliveries tracked independently

**Scenario 3: Driver Offline**
1. All drivers offline
2. Order marked ready
3. Order waits in queue
4. Driver comes online
5. Driver sees available order
6. Driver accepts and delivers

#### Test Checklist:
- [ ] Staff registration & login
- [ ] Staff order acceptance
- [ ] Staff order preparation
- [ ] Staff marks order ready
- [ ] Driver registration & login
- [ ] Driver sees available orders
- [ ] Driver accepts delivery
- [ ] Driver GPS tracking working
- [ ] Customer sees driver location
- [ ] Driver delivers order
- [ ] FCM notifications working (all apps)
- [ ] Order status sync across apps
- [ ] Background location updates
- [ ] Multiple simultaneous orders
- [ ] Edge cases (offline, no GPS, etc.)

---

## 📅 Timeline

| Phase | Duration | Start Date | End Date |
|-------|----------|------------|----------|
| 6.1: Backend Prep | 3-5 days | Nov 6 | Nov 10 |
| 6.2: Staff App | 5-7 days | Nov 11 | Nov 17 |
| 6.3: Driver App | 10-14 days | Nov 18 | Dec 1 |
| 6.4: Integration | 3-5 days | Dec 2 | Dec 6 |
| **Total** | **21-31 days** | **Nov 6** | **Dec 6** |

---

## 🎯 Success Criteria

### Backend (Sub-Phase 6.1):
- [ ] Staff model created and tested
- [ ] Driver model created and tested
- [ ] Order model updated with new fields
- [ ] Staff routes implemented (8 endpoints)
- [ ] Driver routes implemented (10 endpoints)
- [ ] FCM notifications configured
- [ ] All endpoints tested with Postman
- [ ] Test scripts pass (>80%)

### Staff App (Sub-Phase 6.2):
- [ ] Clean architecture implemented
- [ ] Firebase Auth working
- [ ] Staff can view orders
- [ ] Staff can accept orders
- [ ] Staff can mark orders ready
- [ ] FCM notifications working
- [ ] UI/UX polished
- [ ] No critical bugs

### Driver App (Sub-Phase 6.3):
- [ ] Clean architecture implemented
- [ ] Firebase Auth working
- [ ] Driver can view available orders
- [ ] Driver can accept deliveries
- [ ] GPS tracking functional
- [ ] Google Maps integration working
- [ ] Real-time location updates
- [ ] FCM notifications working
- [ ] Driver dashboard with stats
- [ ] Online/Offline toggle
- [ ] No critical bugs

### Integration (Sub-Phase 6.4):
- [ ] End-to-end flow working
- [ ] All 3 apps communicate correctly
- [ ] FCM notifications across all apps
- [ ] GPS tracking visible in customer app
- [ ] Order status sync working
- [ ] Performance acceptable
- [ ] No crashes or major bugs

---

## 💡 Best Practices

### Code Quality:
- Follow existing clean architecture
- Maintain consistent naming conventions
- Write reusable widgets
- Use proper error handling
- Add comments for complex logic

### Testing:
- Test each feature after implementation
- Use Postman for API testing
- Test FCM notifications on real devices
- Test GPS tracking outdoors
- Test with multiple devices

### Security:
- Validate all API inputs
- Use secure token storage
- Implement proper authentication
- Validate FCM tokens
- Sanitize location data

---

## 📝 Next Action

**IMMEDIATE NEXT STEP:**  
Start Sub-Phase 6.1: Backend Preparation

**First Task:**  
Create Staff Model (`backend/models/Staff.js`)

**Ready to proceed?** 🚀

---

**Document Created:** November 5, 2025  
**Status:** Ready to Start Phase 6  
**Estimated Completion:** December 6, 2025
