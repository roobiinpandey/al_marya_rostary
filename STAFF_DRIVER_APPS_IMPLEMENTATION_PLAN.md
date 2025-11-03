# Staff & Driver Apps - Complete Implementation Plan

## 📋 Executive Summary

This document provides a **production-ready implementation plan** for creating two companion Flutter apps for Al Marya Rostery:

1. **Staff App** - For cafe staff to manage incoming orders
2. **Driver App** - For delivery drivers with live GPS tracking

Both apps will:
- ✅ Follow your existing clean architecture
- ✅ Reuse core services and utilities
- ✅ Integrate with your existing backend
- ✅ Use Firebase Cloud Messaging (FCM) for notifications
- ✅ Share order status flow with Customer app
- ✅ Maintain identical code style and patterns

---

## 🎯 Project Structure

### Recommended Approach: **Monorepo Structure**

```
al_marya_rostery/
├── customer_app/          # Existing customer app (rename lib/ to customer_app/)
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── staff_app/             # NEW: Staff app
│   ├── lib/
│   │   ├── core/          # Shared core (symlink or package)
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── staff_orders/  # Main feature
│   │   │   └── profile/
│   │   └── main.dart
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── driver_app/            # NEW: Driver app
│   ├── lib/
│   │   ├── core/          # Shared core (symlink or package)
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── delivery_orders/  # Main feature
│   │   │   ├── tracking/         # GPS tracking
│   │   │   └── profile/
│   │   └── main.dart
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── shared/                # NEW: Shared package
│   ├── lib/
│   │   ├── core/          # All core utilities
│   │   ├── models/        # Shared models (Order, User, etc.)
│   │   └── services/      # Shared services
│   └── pubspec.yaml
│
└── backend/               # Existing backend (needs new routes)
    ├── routes/
    │   ├── staff.js       # NEW: Staff routes
    │   └── driver.js      # NEW: Driver routes
    └── models/
        ├── Staff.js       # NEW: Staff model
        └── Driver.js      # NEW: Driver model
```

**Alternative: Separate Repositories** (Recommended if teams are separate)
- Each app in its own repo
- Shared code via pub package
- More complex but better for team autonomy

---

## 🔧 Backend Changes Required

### 1. New Database Models

#### **Staff Model** (`backend/models/Staff.js`)

```javascript
const staffSchema = new mongoose.Schema({
  firebaseUid: {
    type: String,
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true
  },
  phone: {
    type: String,
    required: true
  },
  role: {
    type: String,
    enum: ['barista', 'manager', 'cashier'],
    default: 'barista'
  },
  fcmToken: {
    type: String
  },
  status: {
    type: String,
    enum: ['active', 'inactive', 'on_break'],
    default: 'active'
  },
  assignedOrders: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order'
  }],
  completedOrdersCount: {
    type: Number,
    default: 0
  },
  averagePreparationTime: {
    type: Number,
    default: 0 // in minutes
  }
}, { timestamps: true });
```

#### **Driver Model** (`backend/models/Driver.js`)

```javascript
const driverSchema = new mongoose.Schema({
  firebaseUid: {
    type: String,
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true
  },
  phone: {
    type: String,
    required: true
  },
  vehicleType: {
    type: String,
    enum: ['bike', 'car', 'scooter'],
    required: true
  },
  vehicleNumber: {
    type: String,
    required: true
  },
  fcmToken: {
    type: String
  },
  status: {
    type: String,
    enum: ['available', 'on_delivery', 'offline'],
    default: 'offline'
  },
  currentLocation: {
    latitude: Number,
    longitude: Number,
    lastUpdated: Date
  },
  assignedOrders: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order'
  }],
  completedDeliveriesCount: {
    type: Number,
    default: 0
  },
  averageDeliveryTime: {
    type: Number,
    default: 0 // in minutes
  },
  rating: {
    average: {
      type: Number,
      default: 5.0
    },
    count: {
      type: Number,
      default: 0
    }
  }
}, { timestamps: true });
```

### 2. Update Order Model

Add staff and driver assignment fields to existing `Order` model:

```javascript
// Add to Order schema
assignedStaff: {
  type: mongoose.Schema.Types.ObjectId,
  ref: 'Staff',
  default: null
},
assignedDriver: {
  type: mongoose.Schema.Types.ObjectId,
  ref: 'Driver',
  default: null
},
preparationStartTime: Date,
preparationEndTime: Date,
pickupTime: Date,
deliveryStartTime: Date
```

### 3. New API Routes

#### **Staff Routes** (`backend/routes/staff.js`)

```javascript
// Staff authentication
POST   /api/staff/login
POST   /api/staff/register
POST   /api/staff/fcm-token

// Staff orders management
GET    /api/staff/orders              // Get pending orders
GET    /api/staff/orders/:id          // Get order details
POST   /api/staff/orders/:id/accept   // Accept order
POST   /api/staff/orders/:id/start    // Start preparation
POST   /api/staff/orders/:id/ready    // Mark order ready
POST   /api/staff/orders/:id/complete // Complete order

// Staff profile
GET    /api/staff/profile
PUT    /api/staff/status              // Update status (active/break)
GET    /api/staff/stats                // Get staff statistics
```

#### **Driver Routes** (`backend/routes/driver.js`)

```javascript
// Driver authentication
POST   /api/driver/login
POST   /api/driver/register
POST   /api/driver/fcm-token

// Driver orders management
GET    /api/driver/orders              // Get ready orders
GET    /api/driver/orders/:id          // Get order details
POST   /api/driver/orders/:id/accept   // Accept delivery
POST   /api/driver/orders/:id/pickup   // Mark picked up
POST   /api/driver/orders/:id/deliver  // Mark delivered

// Driver location tracking
POST   /api/driver/location            // Update live location
GET    /api/driver/location/:orderId   // Get driver location for order

// Driver profile
GET    /api/driver/profile
PUT    /api/driver/status              // Update status (available/offline)
GET    /api/driver/stats               // Get driver statistics
```

### 4. FCM Notification Triggers

```javascript
// Notifications to send:

// To Staff:
- New order created → "New order #12345 received!"
- Order assigned → "Order #12345 assigned to you"

// To Driver:
- Order ready for pickup → "Order #12345 is ready!"
- Order assigned → "Delivery #12345 assigned to you"

// To Customer:
- Order accepted by staff → "Your order is being prepared"
- Order ready → "Your order is ready for pickup"
- Driver assigned → "Your order is out for delivery"
- Driver location updated → (Real-time tracking)
- Order delivered → "Your order has been delivered"
```

---

## 📱 Staff App Implementation

### Feature: `staff_orders`

#### **1. Data Layer**

**Model: `staff_order_model.dart`**

```dart
class StaffOrder {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final double totalAmount;
  final StaffOrderStatus status;
  final DateTime createdAt;
  final DateTime? preparationStartTime;
  final DateTime? preparationEndTime;
  final String? specialInstructions;
  
  StaffOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.preparationStartTime,
    this.preparationEndTime,
    this.specialInstructions,
  });
  
  factory StaffOrder.fromJson(Map<String, dynamic> json) {
    return StaffOrder(
      id: json['_id'] ?? json['id'],
      orderNumber: json['orderNumber'],
      customerName: json['user']?['name'] ?? json['guestInfo']?['name'] ?? 'Guest',
      customerPhone: json['user']?['phone'] ?? json['guestInfo']?['phone'] ?? '',
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: StaffOrderStatus.fromString(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      preparationStartTime: json['preparationStartTime'] != null
          ? DateTime.parse(json['preparationStartTime'])
          : null,
      preparationEndTime: json['preparationEndTime'] != null
          ? DateTime.parse(json['preparationEndTime'])
          : null,
      specialInstructions: json['notes'],
    );
  }
}

enum StaffOrderStatus {
  pending,      // New order, not accepted
  preparing,    // Staff accepted and preparing
  ready,        // Order is ready for pickup/delivery
  completed;    // Order completed
  
  static StaffOrderStatus fromString(String status) {
    switch (status) {
      case 'pending':
        return StaffOrderStatus.pending;
      case 'preparing':
      case 'confirmed':
        return StaffOrderStatus.preparing;
      case 'ready':
        return StaffOrderStatus.ready;
      case 'completed':
      case 'delivered':
        return StaffOrderStatus.completed;
      default:
        return StaffOrderStatus.pending;
    }
  }
}
```

**Service: `staff_api_service.dart`**

```dart
class StaffApiService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  
  StaffApiService({Dio? dio, FlutterSecureStorage? secureStorage})
      : _dio = dio ?? Dio(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _dio.options.baseUrl = AppConstants.baseUrl;
  }
  
  /// Fetch pending and preparing orders
  Future<List<StaffOrder>> fetchOrders({String? status}) async {
    try {
      final token = await _secureStorage.read(key: 'staff_auth_token');
      final response = await _dio.get(
        '/api/staff/orders',
        queryParameters: status != null ? {'status': status} : null,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> ordersJson = response.data['orders'];
        return ordersJson.map((json) => StaffOrder.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch orders');
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }
  
  /// Accept an order
  Future<StaffOrder> acceptOrder(String orderId) async {
    try {
      final token = await _secureStorage.read(key: 'staff_auth_token');
      final response = await _dio.post(
        '/api/staff/orders/$orderId/accept',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.statusCode == 200) {
        return StaffOrder.fromJson(response.data['order']);
      }
      throw Exception('Failed to accept order');
    } catch (e) {
      throw Exception('Error accepting order: $e');
    }
  }
  
  /// Start preparing order
  Future<StaffOrder> startPreparation(String orderId) async {
    try {
      final token = await _secureStorage.read(key: 'staff_auth_token');
      final response = await _dio.post(
        '/api/staff/orders/$orderId/start',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.statusCode == 200) {
        return StaffOrder.fromJson(response.data['order']);
      }
      throw Exception('Failed to start preparation');
    } catch (e) {
      throw Exception('Error starting preparation: $e');
    }
  }
  
  /// Mark order as ready
  Future<StaffOrder> markOrderReady(String orderId) async {
    try {
      final token = await _secureStorage.read(key: 'staff_auth_token');
      final response = await _dio.post(
        '/api/staff/orders/$orderId/ready',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.statusCode == 200) {
        return StaffOrder.fromJson(response.data['order']);
      }
      throw Exception('Failed to mark order ready');
    } catch (e) {
      throw Exception('Error marking order ready: $e');
    }
  }
}
```

#### **2. Provider Layer**

**Provider: `staff_order_provider.dart`**

```dart
class StaffOrderProvider extends ChangeNotifier {
  final StaffApiService _apiService;
  
  List<StaffOrder> _pendingOrders = [];
  List<StaffOrder> _preparingOrders = [];
  List<StaffOrder> _readyOrders = [];
  bool _isLoading = false;
  String? _error;
  
  StaffOrderProvider(this._apiService);
  
  List<StaffOrder> get pendingOrders => _pendingOrders;
  List<StaffOrder> get preparingOrders => _preparingOrders;
  List<StaffOrder> get readyOrders => _readyOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Load all orders
  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final allOrders = await _apiService.fetchOrders();
      
      _pendingOrders = allOrders
          .where((o) => o.status == StaffOrderStatus.pending)
          .toList();
      _preparingOrders = allOrders
          .where((o) => o.status == StaffOrderStatus.preparing)
          .toList();
      _readyOrders = allOrders
          .where((o) => o.status == StaffOrderStatus.ready)
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Accept order
  Future<void> acceptOrder(String orderId) async {
    try {
      final updatedOrder = await _apiService.acceptOrder(orderId);
      
      // Move from pending to preparing
      _pendingOrders.removeWhere((o) => o.id == orderId);
      _preparingOrders.add(updatedOrder);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  /// Start preparation
  Future<void> startPreparation(String orderId) async {
    try {
      await _apiService.startPreparation(orderId);
      
      // Update order in preparing list
      final index = _preparingOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final updatedOrder = _preparingOrders[index];
        _preparingOrders[index] = StaffOrder(
          id: updatedOrder.id,
          orderNumber: updatedOrder.orderNumber,
          customerName: updatedOrder.customerName,
          customerPhone: updatedOrder.customerPhone,
          items: updatedOrder.items,
          totalAmount: updatedOrder.totalAmount,
          status: updatedOrder.status,
          createdAt: updatedOrder.createdAt,
          preparationStartTime: DateTime.now(),
          preparationEndTime: updatedOrder.preparationEndTime,
          specialInstructions: updatedOrder.specialInstructions,
        );
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  /// Mark order ready
  Future<void> markOrderReady(String orderId) async {
    try {
      final updatedOrder = await _apiService.markOrderReady(orderId);
      
      // Move from preparing to ready
      _preparingOrders.removeWhere((o) => o.id == orderId);
      _readyOrders.add(updatedOrder);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
```

#### **3. UI Layer**

**Page: `staff_orders_page.dart`**

```dart
class StaffOrdersPage extends StatefulWidget {
  const StaffOrdersPage({Key? key}) : super(key: key);

  @override
  State<StaffOrdersPage> createState() => _StaffOrdersPageState();
}

class _StaffOrdersPageState extends State<StaffOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load orders on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffOrderProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Preparing'),
            Tab(text: 'Ready'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<StaffOrderProvider>().loadOrders();
            },
          ),
        ],
      ),
      body: Consumer<StaffOrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () => provider.loadOrders(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(provider.pendingOrders, 'pending'),
              _buildOrdersList(provider.preparingOrders, 'preparing'),
              _buildOrdersList(provider.readyOrders, 'ready'),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildOrdersList(List<StaffOrder> orders, String status) {
    if (orders.isEmpty) {
      return Center(
        child: Text('No $status orders'),
      );
    }
    
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return StaffOrderCard(
          order: order,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StaffOrderDetailPage(order: order),
              ),
            );
          },
        );
      },
    );
  }
}
```

**Widget: `staff_order_card.dart`**

```dart
class StaffOrderCard extends StatelessWidget {
  final StaffOrder order;
  final VoidCallback onTap;
  
  const StaffOrderCard({
    Key? key,
    required this.order,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 8),
              Text('Customer: ${order.customerName}'),
              Text('Phone: ${order.customerPhone}'),
              const SizedBox(height: 8),
              Text(
                '${order.items.length} items • AED ${order.totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Ordered ${_formatTime(order.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (order.preparationStartTime != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Prep started ${_formatTime(order.preparationStartTime!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusBadge(StaffOrderStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case StaffOrderStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case StaffOrderStatus.preparing:
        color = Colors.blue;
        text = 'Preparing';
        break;
      case StaffOrderStatus.ready:
        color = Colors.green;
        text = 'Ready';
        break;
      case StaffOrderStatus.completed:
        color = Colors.grey;
        text = 'Completed';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
```

---

## 📱 Driver App Implementation

### Feature: `delivery_orders` + `tracking`

#### **1. Data Layer**

**Model: `driver_order_model.dart`**

```dart
class DriverOrder {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final DeliveryAddress deliveryAddress;
  final List<OrderItem> items;
  final double totalAmount;
  final DriverOrderStatus status;
  final DateTime createdAt;
  final DateTime? pickupTime;
  final DateTime? deliveryStartTime;
  final String? specialInstructions;
  
  DriverOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.pickupTime,
    this.deliveryStartTime,
    this.specialInstructions,
  });
  
  factory DriverOrder.fromJson(Map<String, dynamic> json) {
    return DriverOrder(
      id: json['_id'] ?? json['id'],
      orderNumber: json['orderNumber'],
      customerName: json['user']?['name'] ?? json['guestInfo']?['name'] ?? 'Guest',
      customerPhone: json['user']?['phone'] ?? json['guestInfo']?['phone'] ?? '',
      deliveryAddress: DeliveryAddress.fromJson(json['deliveryAddress']),
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: DriverOrderStatus.fromString(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      pickupTime: json['pickupTime'] != null
          ? DateTime.parse(json['pickupTime'])
          : null,
      deliveryStartTime: json['deliveryStartTime'] != null
          ? DateTime.parse(json['deliveryStartTime'])
          : null,
      specialInstructions: json['deliveryAddress']?['instructions'],
    );
  }
}

enum DriverOrderStatus {
  ready,        // Ready for pickup
  picked_up,    // Driver picked up
  on_the_way,   // Driver on the way
  delivered;    // Delivered
  
  static DriverOrderStatus fromString(String status) {
    switch (status) {
      case 'ready':
        return DriverOrderStatus.ready;
      case 'picked_up':
      case 'out_for_delivery':
        return DriverOrderStatus.picked_up;
      case 'on_the_way':
        return DriverOrderStatus.on_the_way;
      case 'delivered':
      case 'completed':
        return DriverOrderStatus.delivered;
      default:
        return DriverOrderStatus.ready;
    }
  }
}

class DeliveryAddress {
  final String street;
  final String city;
  final String? zipCode;
  final String? instructions;
  final double? latitude;
  final double? longitude;
  
  DeliveryAddress({
    required this.street,
    required this.city,
    this.zipCode,
    this.instructions,
    this.latitude,
    this.longitude,
  });
  
  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      zipCode: json['zipCode'],
      instructions: json['instructions'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }
  
  String get fullAddress => '$street, $city${zipCode != null ? ", $zipCode" : ""}';
}
```

#### **2. GPS Tracking Service**

**Service: `location_tracking_service.dart`**

```dart
import 'package:geolocator/geolocator.dart';

class LocationTrackingService {
  final DriverApiService _apiService;
  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;
  
  LocationTrackingService(this._apiService);
  
  /// Start tracking driver location
  Future<void> startTracking(String orderId) async {
    // Check permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
    
    // Start position stream
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _onLocationUpdate(position, orderId);
    });
  }
  
  /// Stop tracking
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }
  
  /// Handle location update
  Future<void> _onLocationUpdate(Position position, String orderId) async {
    _lastPosition = position;
    
    // Send to backend (throttle updates to every 10 seconds)
    try {
      await _apiService.updateLocation(
        orderId: orderId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      print('Error updating location: $e');
    }
  }
  
  /// Get current position once
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
  
  Position? get lastPosition => _lastPosition;
}
```

#### **3. Provider Layer**

**Provider: `driver_order_provider.dart`**

```dart
class DriverOrderProvider extends ChangeNotifier {
  final DriverApiService _apiService;
  final LocationTrackingService _locationService;
  
  List<DriverOrder> _availableOrders = [];
  DriverOrder? _activeOrder;
  bool _isLoading = false;
  String? _error;
  DriverStatus _status = DriverStatus.offline;
  
  DriverOrderProvider(this._apiService, this._locationService);
  
  List<DriverOrder> get availableOrders => _availableOrders;
  DriverOrder? get activeOrder => _activeOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DriverStatus get status => _status;
  
  /// Load available orders
  Future<void> loadAvailableOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _availableOrders = await _apiService.fetchAvailableOrders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Accept delivery
  Future<void> acceptDelivery(String orderId) async {
    try {
      final order = await _apiService.acceptDelivery(orderId);
      _activeOrder = order;
      _availableOrders.removeWhere((o) => o.id == orderId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  /// Mark order picked up and start tracking
  Future<void> pickupOrder(String orderId) async {
    try {
      final order = await _apiService.pickupOrder(orderId);
      _activeOrder = order;
      
      // Start location tracking
      await _locationService.startTracking(orderId);
      
      _status = DriverStatus.on_delivery;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  /// Mark order delivered
  Future<void> deliverOrder(String orderId) async {
    try {
      await _apiService.deliverOrder(orderId);
      
      // Stop location tracking
      _locationService.stopTracking();
      
      _activeOrder = null;
      _status = DriverStatus.available;
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  /// Update driver status
  Future<void> updateStatus(DriverStatus newStatus) async {
    try {
      await _apiService.updateStatus(newStatus.name);
      _status = newStatus;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}

enum DriverStatus {
  offline,
  available,
  on_delivery
}
```

#### **4. UI Layer**

**Page: `driver_orders_page.dart`**

```dart
class DriverOrdersPage extends StatelessWidget {
  const DriverOrdersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deliveries'),
        actions: [
          Consumer<DriverOrderProvider>(
            builder: (context, provider, child) {
              return DropdownButton<DriverStatus>(
                value: provider.status,
                items: const [
                  DropdownMenuItem(
                    value: DriverStatus.offline,
                    child: Text('Offline'),
                  ),
                  DropdownMenuItem(
                    value: DriverStatus.available,
                    child: Text('Available'),
                  ),
                ],
                onChanged: (status) {
                  if (status != null) {
                    provider.updateStatus(status);
                  }
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DriverOrderProvider>().loadAvailableOrders();
            },
          ),
        ],
      ),
      body: Consumer<DriverOrderProvider>(
        builder: (context, provider, child) {
          // Show active delivery if exists
          if (provider.activeOrder != null) {
            return ActiveDeliveryWidget(order: provider.activeOrder!);
          }
          
          // Show available orders
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          
          if (provider.availableOrders.isEmpty) {
            return const Center(
              child: Text('No deliveries available'),
            );
          }
          
          return ListView.builder(
            itemCount: provider.availableOrders.length,
            itemBuilder: (context, index) {
              final order = provider.availableOrders[index];
              return DriverOrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}
```

**Widget: `active_delivery_widget.dart`** (with map integration)

```dart
class ActiveDeliveryWidget extends StatelessWidget {
  final DriverOrder order;
  
  const ActiveDeliveryWidget({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map showing route to customer
        Expanded(
          flex: 2,
          child: GoogleMapWidget(
            destinationLat: order.deliveryAddress.latitude ?? 0,
            destinationLng: order.deliveryAddress.longitude ?? 0,
          ),
        ),
        
        // Order details
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.orderNumber}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('Customer: ${order.customerName}'),
                Text('Phone: ${order.customerPhone}'),
                const SizedBox(height: 8),
                Text(
                  'Delivery Address:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(order.deliveryAddress.fullAddress),
                if (order.specialInstructions != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Instructions: ${order.specialInstructions}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 16),
                
                // Action buttons
                if (order.status == DriverOrderStatus.ready)
                  ElevatedButton(
                    onPressed: () {
                      context.read<DriverOrderProvider>().pickupOrder(order.id);
                    },
                    child: const Text('Mark as Picked Up'),
                  ),
                  
                if (order.status == DriverOrderStatus.picked_up ||
                    order.status == DriverOrderStatus.on_the_way)
                  ElevatedButton(
                    onPressed: () {
                      _showDeliveryConfirmation(context, order.id);
                    },
                    child: const Text('Mark as Delivered'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  void _showDeliveryConfirmation(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: const Text('Has the order been delivered to the customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DriverOrderProvider>().deliverOrder(orderId);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
```

---

## 🔔 FCM Integration

### **Service: `fcm_service.dart`** (Shared across all apps)

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  /// Initialize FCM
  Future<void> initialize({
    required Function(RemoteMessage) onMessageReceived,
    required Function(RemoteMessage) onMessageOpenedApp,
  }) async {
    // Request permission (iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Get FCM token
    final token = await _messaging.getToken();
    print('FCM Token: $token');
    
    // Save token to backend
    await _saveTokenToBackend(token);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(onMessageReceived);
    
    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);
    
    // Handle terminated state message tap
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      onMessageOpenedApp(initialMessage);
    }
  }
  
  Future<void> _saveTokenToBackend(String? token) async {
    if (token == null) return;
    
    // Save to backend based on app type
    // Staff app: POST /api/staff/fcm-token
    // Driver app: POST /api/driver/fcm-token
    // Customer app: POST /api/user/fcm-token
  }
}
```

---

## 📊 Order Status Flow

```
CUSTOMER APP                  STAFF APP                   DRIVER APP
─────────────                ───────────                 ──────────

User places order
     │
     ▼
[Pending] ──────FCM────────▶ [New Order Alert]
                                     │
                                     │ Staff accepts
                                     ▼
                              [Preparing]
                                     │
                                     │ Staff marks ready
                                     ▼
                              [Ready] ──────FCM────────▶ [New Delivery Alert]
                                                                │
                                                                │ Driver accepts
                                                                ▼
[Order Assigned] ◀──────────────────────────────────── [Assigned to Driver]
     │                                                          │
     │                                                          │ Driver picks up
     ▼                                                          ▼
[Out for Delivery] ◀─────────────────────────────────── [Picked Up]
     │                                                          │
     │ (GPS tracking updates)                                  │ Start navigation
     ▼                                                          ▼
[Track on Map]                                           [En route]
     │                                                          │
     │                                                          │ Driver delivers
     ▼                                                          ▼
[Delivered] ◀───────────────────────────────────────── [Mark Delivered]
```

---

## 🚀 Implementation Checklist

### Phase 1: Backend (Week 1)
- [ ] Create Staff and Driver models
- [ ] Update Order model with assignment fields
- [ ] Implement Staff API routes
- [ ] Implement Driver API routes
- [ ] Set up FCM notification triggers
- [ ] Test all endpoints with Postman

### Phase 2: Staff App (Week 2)
- [ ] Create new Flutter project with clean architecture
- [ ] Implement auth feature
- [ ] Implement staff_orders feature
  - [ ] Data layer (models, services)
  - [ ] Provider layer
  - [ ] UI layer (orders list, order details)
- [ ] Integrate FCM
- [ ] Test end-to-end flow

### Phase 3: Driver App (Week 3)
- [ ] Create new Flutter project with clean architecture
- [ ] Implement auth feature
- [ ] Implement delivery_orders feature
- [ ] Implement GPS tracking service
- [ ] Integrate Google Maps
- [ ] Integrate FCM
- [ ] Test end-to-end flow

### Phase 4: Integration & Testing (Week 4)
- [ ] Test complete order flow (Customer → Staff → Driver)
- [ ] Test FCM notifications across all apps
- [ ] Test GPS tracking accuracy
- [ ] Performance testing
- [ ] Bug fixes

---

## 📦 Required Dependencies

### Staff App `pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.0.5
  
  # Firebase
  firebase_core: latest
  firebase_auth: latest
  firebase_messaging: latest
  cloud_firestore: latest
  
  # Network
  dio: latest
  
  # Storage
  flutter_secure_storage: latest
  
  # UI
  intl: latest
```

### Driver App `pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.0.5
  
  # Firebase
  firebase_core: latest
  firebase_auth: latest
  firebase_messaging: latest
  cloud_firestore: latest
  
  # Network
  dio: latest
  
  # Storage
  flutter_secure_storage: latest
  
  # Location & Maps
  geolocator: ^11.0.0
  google_maps_flutter: ^2.5.0
  
  # UI
  intl: latest
```

---

## ✅ Recommendation

### **YES, THIS IS FULLY IMPLEMENTABLE** ✅

**Reasons:**
1. ✅ Your existing architecture is perfect for this expansion
2. ✅ Your backend already has Order model - just needs extensions
3. ✅ Clean architecture makes code reuse easy
4. ✅ All required packages are mature and well-supported
5. ✅ FCM is already integrated in your project
6. ✅ Pattern consistency across all three apps

**Estimated Timeline:**
- Backend: 1 week
- Staff App: 1 week
- Driver App: 2 weeks (GPS tracking is complex)
- Testing & Integration: 1 week
- **Total: 4-5 weeks**

**Complexity Level:** Medium
- Staff App: Low complexity ⭐⭐
- Driver App: Medium complexity ⭐⭐⭐⭐ (GPS tracking)
- Backend Changes: Low complexity ⭐⭐

---

## 🎯 Next Steps

Would you like me to:

1. **Generate complete code** for Staff App?
2. **Generate complete code** for Driver App?
3. **Create backend routes and controllers** first?
4. **Set up the monorepo structure**?
5. **Create a shared package** for common code?

Let me know which part you'd like to tackle first, and I'll generate production-ready code following your exact architecture patterns! 🚀
