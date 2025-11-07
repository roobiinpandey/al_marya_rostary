# 📱 Real-Time Order Notifications Implementation Guide

## ✅ What's Been Implemented

### Backend Changes

#### 1. **User Model Updates** (`backend/models/User.js`)
- ✅ Added `fcmToken` field to store Firebase Cloud Messaging token
- ✅ Added `fcmTokenUpdatedAt` timestamp
- ✅ Tokens are secured with `select: false` by default

#### 2. **FCM Token Endpoint** (`backend/routes/users.js`)
```javascript
POST /api/users/me/fcm-token
Headers: Authorization: Bearer <firebase_token>
Body: { "fcmToken": "device_fcm_token" }
```
- Saves user's FCM token when they log in
- Updates timestamp for token tracking

#### 3. **Order Status Notifications** (`backend/routes/staff.js`)

**Triggers automatic push notifications to customers when:**

| Staff Action | Customer Notification |
|-------------|----------------------|
| ✅ **Accept Order** | "✅ Order Accepted! Your order #XXX has been accepted and is now being prepared." |
| 👨‍🍳 **Update to Preparing** | "👨‍🍳 Order Preparing - Your order #XXX is now being prepared by our barista." |
| ✅ **Mark as Ready** | "✅ Order Ready! Your order #XXX is ready for pickup or delivery." |
| 🚚 **Hand to Driver** | "🚚 Out for Delivery! Your order #XXX is on its way! Our driver will be there soon." |
| 🎉 **Complete Order** | "🎉 Order Delivered! Your order #XXX has been completed. Enjoy your coffee!" |
| ❌ **Reject Order** | "❌ Order Update - Unfortunately, order #XXX could not be processed." |
| ⏸️ **Put on Hold** | "⏸️ Order On Hold - Your order #XXX is temporarily on hold." |

**Notification Data Payload:**
```json
{
  "orderId": "order_id",
  "orderNumber": "ORD-123456",
  "status": "preparing",
  "screen": "order_tracking"
}
```

### Frontend Changes (Customer App)

#### 4. **Dependencies Added** (`pubspec.yaml`)
```yaml
firebase_messaging: ^15.1.5
flutter_local_notifications: ^18.0.1
```

#### 5. **FCM Service Created** (`lib/services/fcm_service.dart`)

**Features:**
- ✅ Requests notification permissions (iOS/Android)
- ✅ Obtains and saves FCM token to backend
- ✅ Handles foreground notifications (app open)
- ✅ Handles background notifications (app in background)
- ✅ Handles notification tap to navigate to order screen
- ✅ Auto-refreshes token when changed
- ✅ Displays local notifications with custom styling
- ✅ Broadcasts order updates via Stream

**Usage:**
```dart
// Initialize in main.dart (already added)
await FCMService().initialize();

// Listen to order updates in any screen
FCMService().orderUpdates.listen((data) {
  final orderId = data['orderId'];
  final status = data['status'];
  // Navigate to order tracking screen
});
```

#### 6. **Main.dart Integration**
- ✅ FCM initialized after Firebase
- ✅ Background message handler registered
- ✅ Token auto-saved on login

---

## 🚀 How It Works

### Customer Flow:

1. **Customer logs in**
   - App requests notification permission
   - FCM token generated and saved to backend

2. **Customer places order**
   - Order appears in staff dashboard
   - Status: `pending`

3. **Staff accepts order**
   - 📱 Customer receives: "✅ Order Accepted!"
   - Status changes to: `preparing`
   - Notification includes order number and action button

4. **Staff marks as ready**
   - 📱 Customer receives: "✅ Order Ready!"
   - Status: `ready`

5. **Staff hands to driver**
   - 📱 Customer receives: "🚚 Out for Delivery!"
   - Status: `out-for-delivery`

6. **Order delivered**
   - 📱 Customer receives: "🎉 Order Delivered!"
   - Status: `completed`

### Technical Flow:

```
[Staff Action] → [Backend Route] → [Order Status Update] 
    ↓
[Fetch User FCM Token] → [Push Notification Service]
    ↓
[Firebase Cloud Messaging] → [Customer's Device]
    ↓
[FCM Service Handles] → [Show Notification] → [Broadcast to App]
    ↓
[Order Tracking Screen Updates] (if open)
```

---

## 📋 Next Steps to Complete Implementation

### 1. **Run Flutter Pub Get**
```bash
cd al_marya_rostery
flutter pub get
```

### 2. **Update iOS Configuration** (if targeting iOS)

**File: `ios/Runner/AppDelegate.swift`**
```swift
import UIKit
import Flutter
import Firebase // Add this

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure() // Add this if not already present
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**File: `ios/Runner/Info.plist`**
Add before `</dict>`:
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

### 3. **Update Android Configuration**

**File: `android/app/build.gradle`**
Check that minSdkVersion is at least 21:
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Already set in pubspec
    }
}
```

**File: `android/app/src/main/AndroidManifest.xml`**
Add inside `<application>`:
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="order_updates" />

<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@mipmap/ic_launcher" />

<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/colorPrimary" />
```

### 4. **Create Order Tracking Screen with Live Updates**

Create: `lib/features/orders/screens/order_tracking_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:qahwat_al_emarat/services/fcm_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  
  const OrderTrackingScreen({
    Key? key,
    required this.orderId,
    required this.orderNumber,
  }) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  String _currentStatus = 'pending';
  late StreamSubscription _orderUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
    _listenToOrderUpdates();
  }

  void _listenToOrderUpdates() {
    _orderUpdateSubscription = FCMService().orderUpdates.listen((data) {
      if (data['orderId'] == widget.orderId) {
        setState(() {
          _currentStatus = data['status'] ?? _currentStatus;
        });
        
        // Show snackbar for status update
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getStatusMessage(_currentStatus)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'preparing':
        return '👨‍🍳 Your order is being prepared';
      case 'ready':
        return '✅ Your order is ready!';
      case 'out-for-delivery':
        return '🚚 Your order is on the way!';
      case 'completed':
        return '🎉 Order delivered! Enjoy!';
      default:
        return 'Order status updated';
    }
  }

  @override
  void dispose() {
    _orderUpdateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${widget.orderNumber}'),
      ),
      body: Column(
        children: [
          _buildStatusTimeline(),
          // Add order details here
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    return ListView(
      shrinkWrap: true,
      children: [
        _buildStatusStep('Placed', 'pending', Icons.shopping_cart),
        _buildStatusStep('Preparing', 'preparing', Icons.restaurant),
        _buildStatusStep('Ready', 'ready', Icons.check_circle),
        _buildStatusStep('Out for Delivery', 'out-for-delivery', Icons.local_shipping),
        _buildStatusStep('Delivered', 'completed', Icons.done_all),
      ],
    );
  }

  Widget _buildStatusStep(String title, String status, IconData icon) {
    final isCompleted = _isStatusCompleted(status);
    final isCurrent = _currentStatus == status;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isCompleted ? Colors.green : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          color: isCompleted ? Colors.green : Colors.grey,
        ),
      ),
      trailing: isCompleted ? Icon(Icons.check, color: Colors.green) : null,
    );
  }

  bool _isStatusCompleted(String status) {
    final statusOrder = ['pending', 'preparing', 'ready', 'out-for-delivery', 'completed'];
    final currentIndex = statusOrder.indexOf(_currentStatus);
    final stepIndex = statusOrder.indexOf(status);
    return currentIndex >= stepIndex;
  }

  Future<void> _loadOrderDetails() async {
    // Load order details from API
  }
}
```

### 5. **Update Navigation to Handle Notification Taps**

**File: `lib/utils/app_router.dart`**
Add route for order tracking:
```dart
'/order-tracking': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  return OrderTrackingScreen(
    orderId: args['orderId'],
    orderNumber: args['orderNumber'],
  );
},
```

**Handle notification navigation in home screen or root:**
```dart
@override
void initState() {
  super.initState();
  
  // Listen for notification taps
  FCMService().orderUpdates.listen((data) {
    if (data['tapped'] == true && data['orderId'] != null) {
      Navigator.pushNamed(
        context,
        '/order-tracking',
        arguments: {
          'orderId': data['orderId'],
          'orderNumber': data['orderNumber'],
        },
      );
    }
  });
}
```

### 6. **Restart Backend**
```bash
cd backend
npm start
```

### 7. **Test the Flow**

#### Test Scenario:
1. **Customer App:** Login and place an order
2. **Staff App:** Login and accept the order
3. **Customer App:** Should receive "Order Accepted" notification
4. **Staff App:** Mark order as ready
5. **Customer App:** Should receive "Order Ready" notification
6. **Staff App:** Hand to driver
7. **Customer App:** Should receive "Out for Delivery" notification

---

## 🔍 Troubleshooting

### Issue: No notifications received

**Check:**
1. FCM token is saved (`console.log` in FCMService)
2. Backend has user's FCM token (`User.findById().select('+fcmToken')`)
3. Firebase Admin SDK is initialized in backend
4. Notification permissions are granted

**Debug Backend:**
```javascript
// In staff.js, check if notification is sent:
console.log('📱 Sending notification to user:', user.email);
console.log('📱 FCM Token:', user.fcmToken);
const result = await pushNotificationService.sendToDevices(...);
console.log('📱 Notification result:', result);
```

**Debug Frontend:**
```dart
// In FCMService
debugPrint('📱 Current FCM Token: $_fcmToken');
debugPrint('📱 Message received: ${message.notification?.title}');
```

### Issue: Notifications work but don't open order screen

**Check:**
1. Order tracking screen route is registered
2. Navigation listener is set up
3. Data payload includes 'orderId' and 'screen' fields

### Issue: iOS notifications not showing

**Check:**
1. Notification permissions granted
2. AppDelegate configured correctly
3. Run on physical device (simulator may not support push)

---

## 📊 Notification Status Reference

| Status | Icon | Title | Customer Message |
|--------|------|-------|------------------|
| `pending` | 🛒 | Order Placed | Your order has been received |
| `preparing` | 👨‍🍳 | Order Preparing | Your order is being prepared |
| `ready` | ✅ | Order Ready | Your order is ready! |
| `out-for-delivery` | 🚚 | Out for Delivery | Your order is on the way! |
| `completed` | 🎉 | Order Delivered | Enjoy your coffee! |
| `rejected` | ❌ | Order Update | Could not process order |
| `on-hold` | ⏸️ | Order On Hold | Temporarily on hold |

---

## 🎨 Notification Customization

**Backend (`routes/staff.js`):**
Change notification title/message:
```javascript
title: '🎉 Custom Title';
message: `Custom message for order ${order.orderNumber}`;
```

**Frontend (`services/fcm_service.dart`):**
Change notification appearance:
```dart
const androidDetails = AndroidNotificationDetails(
  'order_updates',
  'Order Updates',
  importance: Importance.max,  // Make notification more prominent
  priority: Priority.high,
  color: Color(0xFFA89A6A),   // Your brand color
  playSound: true,
  enableVibration: true,
  sound: RawResourceAndroidNotificationSound('notification_sound'),
);
```

---

## ✅ Checklist

- [x] FCM token field added to User model
- [x] FCM token save endpoint created
- [x] Push notifications added to all status updates
- [x] FCM service created in Flutter
- [x] FCM initialized in main.dart
- [ ] Run `flutter pub get`
- [ ] Configure iOS (if needed)
- [ ] Configure Android (if needed)
- [ ] Create order tracking screen
- [ ] Test notification flow
- [ ] Deploy to production

---

## 📱 Production Deployment

### Backend:
1. Ensure Firebase Admin SDK is properly configured
2. Check that FIREBASE_SERVICE_ACCOUNT_KEY is in production .env
3. Verify pushNotificationService is initialized

### Frontend:
1. Update API base URL to production
2. Test on physical devices (both iOS and Android)
3. Submit to App Store/Play Store with push notification capability

---

**🎉 You're now ready to notify customers in real-time about their order status!**
