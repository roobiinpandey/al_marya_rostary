# 🚀 Real-Time Delivery Tracking System - Full Implementation Guide

## 📋 Overview

Complete real-time delivery tracking system with WebSocket communication, GPS broadcasting, and payment confirmation for Al Marya Rostery.

### ✅ Implementation Status

- ✅ **Phase 1: Backend** - Socket.IO server with tracking service
- ✅ **Phase 2: User App** - WebSocket service + real-time tracking screen
- ✅ **Phase 3: Driver App** - Location tracking service + COD payment dialog
- ✅ **Phase 4: Payment Webhooks** - Stripe webhook handler with Socket.IO events

---

## 🏗️ Architecture

```
┌─────────────────┐         WebSocket          ┌──────────────────┐
│   User App      │◄──────────────────────────►│                  │
│  (Flutter)      │    Real-time Updates       │   Socket.IO      │
└─────────────────┘                             │   Server         │
                                                 │                  │
┌─────────────────┐         WebSocket          │  (Port 5001)     │
│   Driver App    │◄──────────────────────────►│                  │
│  (Flutter)      │    GPS Every 3s            └──────────────────┘
└─────────────────┘                                      │
                                                         │
┌─────────────────┐         HTTPS                       │
│   Stripe        │────────────────────────────────────►│
│  Webhooks       │    Payment Events                   │
└─────────────────┘                                      ▼
                                                 ┌──────────────────┐
                                                 │   MongoDB        │
                                                 │   Orders DB      │
                                                 └──────────────────┘
```

---

## 📦 Implementation Details

### Phase 1: Backend (Already Complete)

**Files Created:**
- `backend/services/trackingService.js` - Socket.IO server
- `backend/routes/trackingRoutes.js` - REST API endpoints

**Key Features:**
- Socket.IO server on port 5001
- JWT authentication
- Room-based broadcasting (order_${orderId})
- Events: `delivery_update`, `driver_location_update`, `payment_update`, `order_status_change`

### Phase 2: User App - WebSocket Integration

#### 1. Dependencies Added
```yaml
# pubspec.yaml
dependencies:
  socket_io_client: ^2.0.3+1
```

#### 2. WebSocketService Created
**File:** `lib/core/services/websocket_service.dart`

**Features:**
- Singleton pattern for app-wide access
- Auto-reconnection with 5 attempts
- Broadcast streams for reactive updates
- Methods: `connect()`, `joinOrderRoom()`, `disconnect()`

**Usage Example:**
```dart
final wsService = WebSocketService();

// Connect
await wsService.connect(authToken, isDevelopment: false);

// Join order room
wsService.joinOrderRoom(orderId);

// Listen to driver location
wsService.driverLocationUpdates.listen((data) {
  final lat = data['location']['lat'];
  final lng = data['location']['lng'];
  // Update map marker
});

// Listen to payment updates
wsService.paymentUpdates.listen((data) {
  if (data['status'] == 'paid') {
    // Show payment confirmed
  }
});

// Clean up
wsService.leaveOrderRoom(orderId);
wsService.dispose();
```

#### 3. Real-Time Tracking Screen Created
**File:** `lib/features/checkout/presentation/pages/order_tracking_realtime_page.dart`

**Features:**
- Google Maps with real-time driver location
- Live status updates with notifications
- Payment confirmation display
- Driver info card with call button
- Auto-camera bounds adjustment

**Navigation:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => OrderTrackingRealtimePage(
      orderNumber: '12345',
      orderId: 'order_id_here',
      orderData: orderData, // Optional
    ),
  ),
);
```

### Phase 3: Driver App - Location Tracking

#### 1. Dependencies Added
```yaml
# al_marya_driver_app/pubspec.yaml
dependencies:
  socket_io_client: ^2.0.3+1
  geolocator: ^14.0.2  # Already exists
```

#### 2. LocationTrackingService Created
**File:** `lib/core/services/location_tracking_service.dart`

**Features:**
- GPS tracking every 3 seconds
- Auto permission handling
- WebSocket broadcasting
- Battery-optimized (10m distance filter)
- COD payment confirmation method

**Usage Example:**
```dart
final trackingService = LocationTrackingService();

// Start tracking when driver picks up order
await trackingService.startTracking(orderId);

// Confirm cash payment
await trackingService.confirmCashPayment(orderId, 150.00);

// Update order status
await trackingService.updateOrderStatus(orderId, 'delivered');

// Stop tracking when delivery complete
trackingService.stopTracking();
```

#### 3. COD Payment Dialog Created
**File:** `lib/features/deliveries/widgets/cod_payment_dialog.dart`

**Features:**
- Amount display in AED
- Confirm/Cancel buttons
- Loading state
- Information tooltip

**Usage Example:**
```dart
final confirmed = await showCodPaymentDialog(
  context: context,
  orderNumber: '12345',
  amount: 150.00,
  onConfirm: () async {
    await trackingService.confirmCashPayment(orderId, 150.00);
  },
);

if (confirmed == true) {
  // Payment confirmed, proceed with delivery completion
}
```

### Phase 4: Payment Webhooks

#### 1. Webhook Route Created
**File:** `backend/routes/webhooks.js`

**Features:**
- Stripe signature verification
- `payment_intent.succeeded` handler
- `payment_intent.payment_failed` handler
- `charge.refunded` handler
- Real-time payment updates via Socket.IO

**Registered in server.js:**
```javascript
app.use('/api/webhooks', require('./routes/webhooks'));
```

#### 2. Environment Variables Required
```bash
# .env
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

#### 3. Webhook Setup in Stripe Dashboard
1. Go to Stripe Dashboard → Developers → Webhooks
2. Add endpoint: `https://api.almaryarostery.com/api/webhooks/stripe`
3. Select events:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `charge.refunded`
4. Copy webhook secret to `.env`

---

## 🔌 WebSocket Events Reference

### Server → Client Events

| Event | Data | Description |
|-------|------|-------------|
| `delivery_update` | `{ orderId, status, timestamp }` | Order status changed |
| `driver_location_update` | `{ orderId, location: { lat, lng }, driverName, driverPhone }` | Driver GPS update (every 3s) |
| `payment_update` | `{ orderId, status, amount, method, timestamp }` | Payment status changed |
| `order_status_change` | `{ orderId, status, estimatedArrival }` | Order status updated |

### Client → Server Events

| Event | Data | Description |
|-------|------|-------------|
| `join_order_room` | `{ orderId }` | Join order-specific room |
| `leave_order_room` | `{ orderId }` | Leave order room |
| `driver_location_update` | `{ orderId, location, timestamp }` | Driver broadcasts GPS |
| `payment_confirm` | `{ orderId, amount, method, status }` | Driver confirms COD payment |
| `order_status_update` | `{ orderId, status, timestamp }` | Status change from driver |

---

## 🧪 Testing Guide

### 1. Backend Testing

```bash
# Start Socket.IO server
cd backend
npm start

# Server should log:
# ✅ Socket.IO server running on port 5001
```

### 2. User App Testing

```dart
// In your order tracking screen
void initState() {
  super.initState();
  _testWebSocket();
}

Future<void> _testWebSocket() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token') ?? '';
  
  await wsService.connect(token, isDevelopment: true); // Use localhost
  wsService.joinOrderRoom('test_order_123');
  
  // Listen for events
  wsService.driverLocationUpdates.listen((data) {
    print('📍 Driver location: ${data['location']}');
  });
}
```

**Expected Console Output:**
```
🔌 Connecting to WebSocket server: http://localhost:5001
✅ WebSocket connected
🚪 Joined order room: test_order_123
```

### 3. Driver App Testing

```dart
// In delivery detail screen
Future<void> _startDelivery() async {
  await trackingService.startTracking(widget.order.id);
  
  // Should see in console:
  // ✅ Started location tracking for order: abc123
  // 📍 Location broadcast: 25.2048, 55.2708 (every 3s)
}
```

### 4. Payment Webhook Testing

Use Stripe CLI for local testing:

```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Login
stripe login

# Forward webhooks to local server
stripe listen --forward-to localhost:5000/api/webhooks/stripe

# Trigger test payment
stripe trigger payment_intent.succeeded
```

**Expected Backend Log:**
```
✅ Stripe webhook verified: payment_intent.succeeded
💳 Processing successful payment: pi_123...
✅ Order AMR-2024-0001 payment confirmed
📡 Payment update broadcasted via WebSocket
```

---

## 🌍 Environment Configuration

### Development (Local Testing)

**User App:**
```dart
await wsService.connect(token, isDevelopment: true);
// Connects to: http://localhost:5001
```

**Driver App:**
```dart
// In location_tracking_service.dart
const serverUrl = 'http://localhost:5001'; // Line 98
```

**Backend:**
```bash
# .env
PORT=5001
SOCKET_PORT=5001
NODE_ENV=development
```

**Note:** Both HTTP API and Socket.IO run on port 5001 (same server).

### Production

**User App:**
```dart
await wsService.connect(token, isDevelopment: false);
// Connects to: https://api.almaryarostery.com
```

**Driver App:**
```dart
const serverUrl = 'https://api.almaryarostery.com';
```

**Backend:**
```bash
# .env
PORT=443
SOCKET_PORT=5001
NODE_ENV=production
STRIPE_WEBHOOK_SECRET=whsec_live_...
```

---

## 📱 Integration Examples

### Example 1: User Places Order → Tracks Delivery

```dart
// After successful checkout
class OrderSuccessPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('Order Confirmed!'),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderTrackingRealtimePage(
                    orderNumber: orderNumber,
                    orderId: orderId,
                    orderData: orderData,
                  ),
                ),
              );
            },
            child: Text('Track Order'),
          ),
        ],
      ),
    );
  }
}
```

### Example 2: Driver Accepts → Delivers Order

```dart
class DeliveryDetailScreen extends StatefulWidget {
  @override
  State createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State {
  final _trackingService = LocationTrackingService();
  
  Future<void> _startDelivery() async {
    // Start GPS tracking
    await _trackingService.startTracking(widget.order.id);
    
    // Update status
    await _trackingService.updateOrderStatus(
      widget.order.id,
      'out-for-delivery',
    );
    
    setState(() {
      _isDelivering = true;
    });
  }
  
  Future<void> _completeDelivery() async {
    if (widget.order.paymentMethod == 'cash') {
      // Show COD confirmation
      final confirmed = await showCodPaymentDialog(
        context: context,
        orderNumber: widget.order.orderNumber,
        amount: widget.order.totalAmount,
        onConfirm: () async {
          await _trackingService.confirmCashPayment(
            widget.order.id,
            widget.order.totalAmount,
          );
        },
      );
      
      if (confirmed != true) return;
    }
    
    // Update status to delivered
    await _trackingService.updateOrderStatus(
      widget.order.id,
      'delivered',
    );
    
    // Stop GPS tracking
    _trackingService.stopTracking();
    
    Navigator.pop(context);
  }
}
```

---

## 🔧 Troubleshooting

### Issue: WebSocket not connecting

**Symptoms:**
- Console shows: `❌ WebSocket connection error`
- User app doesn't receive updates

**Solutions:**
1. Check auth token:
```dart
final prefs = await SharedPreferences.getInstance();
print('Token: ${prefs.getString('auth_token')}');
```

2. Verify backend is running:
```bash
curl http://localhost:5001/socket.io/
# Should return: {"code":0,"message":"Transport unknown"}
```

3. Check CORS settings in `backend/server.js`:
```javascript
const io = socketIO(httpServer, {
  cors: {
    origin: "*", // Allow all origins in development
    methods: ["GET", "POST"]
  }
});
```

### Issue: Driver location not updating

**Symptoms:**
- User sees no marker on map
- Console shows: `⚠️ Cannot broadcast - not connected`

**Solutions:**
1. Check location permissions:
```dart
final permission = await Geolocator.checkPermission();
print('Permission: $permission'); // Should be: always or whileInUse
```

2. Verify GPS is enabled:
```dart
final serviceEnabled = await Geolocator.isLocationServiceEnabled();
print('GPS enabled: $serviceEnabled');
```

3. Check WebSocket connection in driver app:
```dart
print('Tracking active: ${_trackingService.isTracking}');
```

### Issue: Payment webhook not working

**Symptoms:**
- Order payment status not updating
- User doesn't see "Payment Confirmed"

**Solutions:**
1. Verify webhook secret in `.env`:
```bash
STRIPE_WEBHOOK_SECRET=whsec_...
```

2. Check Stripe webhook logs in dashboard
3. Test with Stripe CLI:
```bash
stripe trigger payment_intent.succeeded --add payment_intent:metadata.orderId=test123
```

4. Check backend logs:
```bash
tail -f backend.log | grep webhook
```

---

## 🚀 Deployment Checklist

### Backend
- [ ] Set `NODE_ENV=production` in `.env`
- [ ] Configure Stripe webhook URL: `https://api.almaryarostery.com/api/webhooks/stripe`
- [ ] Set production `STRIPE_WEBHOOK_SECRET`
- [ ] Enable HTTPS for Socket.IO
- [ ] Configure firewall to allow port 5001

### User App
- [ ] Change `isDevelopment: false` in WebSocket connect
- [ ] Update Google Maps API key for production
- [ ] Test on physical device (not emulator)
- [ ] Enable location permissions in AndroidManifest.xml / Info.plist

### Driver App
- [ ] Change `serverUrl` to production URL
- [ ] Enable background location updates
- [ ] Request "Always" location permission
- [ ] Test battery optimization settings

---

## 📊 Performance Metrics

### Expected Performance
- **GPS Update Frequency:** Every 3 seconds
- **WebSocket Latency:** < 100ms
- **Battery Impact (Driver):** ~5-8% per hour
- **Data Usage:** ~500KB per delivery
- **Map Update Smoothness:** 60 FPS

### Monitoring
```javascript
// Backend: Track active connections
io.on('connection', (socket) => {
  console.log(`Active connections: ${io.engine.clientsCount}`);
});
```

---

## 📚 Additional Resources

- [Socket.IO Documentation](https://socket.io/docs/v4/)
- [Geolocator Plugin](https://pub.dev/packages/geolocator)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- [Stripe Webhooks Guide](https://stripe.com/docs/webhooks)

---

## ✅ Summary

### Files Created
1. **User App (al_marya_rostery):**
   - `lib/core/services/websocket_service.dart`
   - `lib/features/checkout/presentation/pages/order_tracking_realtime_page.dart`

2. **Driver App (al_marya_driver_app):**
   - `lib/core/services/location_tracking_service.dart`
   - `lib/features/deliveries/widgets/cod_payment_dialog.dart`

3. **Backend:**
   - `backend/routes/webhooks.js`
   - Updated `backend/server.js`

### Dependencies Added
```yaml
# Both apps
socket_io_client: ^2.0.3+1
```

### Next Steps
1. Test complete flow in development
2. Configure production environment
3. Deploy backend with SSL
4. Test on physical devices
5. Monitor performance metrics

---

**Implementation Date:** November 2024  
**Status:** ✅ Complete - Ready for Testing  
**Estimated Implementation Time:** 8-10 hours (3-4 hours per phase)
