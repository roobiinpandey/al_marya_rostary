import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Real-time Order Tracking Page with live driver location
class OrderTrackingRealtimePage extends StatefulWidget {
  final String orderNumber;
  final String orderId;
  final Map<String, dynamic>? orderData;

  const OrderTrackingRealtimePage({
    super.key,
    required this.orderNumber,
    required this.orderId,
    this.orderData,
  });

  @override
  State<OrderTrackingRealtimePage> createState() =>
      _OrderTrackingRealtimePageState();
}

class _OrderTrackingRealtimePageState extends State<OrderTrackingRealtimePage> {
  final WebSocketService _wsService = WebSocketService();
  GoogleMapController? _mapController;

  // Location tracking
  LatLng? _driverLocation;
  LatLng? _deliveryLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Order state
  String _currentStatus = 'pending';
  String? _driverName;
  String? _driverPhone;
  String? _estimatedArrival;
  bool _paymentConfirmed = false;

  // Subscriptions
  StreamSubscription<Map<String, dynamic>>? _driverLocationSub;
  StreamSubscription<Map<String, dynamic>>? _orderStatusSub;
  StreamSubscription<Map<String, dynamic>>? _paymentUpdateSub;

  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
    _extractDeliveryLocation();
  }

  @override
  void dispose() {
    _driverLocationSub?.cancel();
    _orderStatusSub?.cancel();
    _paymentUpdateSub?.cancel();
    _wsService.leaveOrderRoom(widget.orderId);
    _mapController?.dispose();
    super.dispose();
  }

  /// Initialize WebSocket connection and listeners
  Future<void> _initializeTracking() async {
    try {
      // Get auth token from secure storage
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        debugPrint('⚠️ No auth token found');
        return;
      }

      // Connect to WebSocket (use isDevelopment: true for local testing)
      await _wsService.connect(token, isDevelopment: false);

      // Join order room
      _wsService.joinOrderRoom(widget.orderId);

      // Listen to driver location updates
      _driverLocationSub = _wsService.driverLocationUpdates.listen((data) {
        setState(() {
          final location = data['location'] as Map<String, dynamic>?;
          if (location != null) {
            _driverLocation = LatLng(
              location['lat'] as double,
              location['lng'] as double,
            );
            _updateMapMarkers();
            _showMap = true;
          }

          _driverName = data['driverName'] as String?;
          _driverPhone = data['driverPhone'] as String?;
        });
      });

      // Listen to order status changes
      _orderStatusSub = _wsService.orderStatusUpdates.listen((data) {
        setState(() {
          _currentStatus = data['status'] as String? ?? _currentStatus;
          _estimatedArrival = data['estimatedArrival'] as String?;
        });

        // Show status notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getStatusMessage(data['status'] as String)),
              backgroundColor: AppTheme.primaryBrown,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });

      // Listen to payment updates
      _paymentUpdateSub = _wsService.paymentUpdates.listen((data) {
        setState(() {
          _paymentConfirmed = data['status'] == 'paid';
        });

        if (_paymentConfirmed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('✅ Payment Confirmed!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      });

      // Request initial status
      _wsService.requestOrderStatus(widget.orderId);
      _wsService.requestDriverLocation(widget.orderId);
    } catch (e) {
      debugPrint('❌ Error initializing tracking: $e');
    }
  }

  /// Extract delivery location from order data
  void _extractDeliveryLocation() {
    final shippingAddress =
        widget.orderData?['shippingAddress'] as Map<String, dynamic>?;

    if (shippingAddress != null) {
      final lat = shippingAddress['latitude'] as double?;
      final lng = shippingAddress['longitude'] as double?;

      if (lat != null && lng != null) {
        _deliveryLocation = LatLng(lat, lng);
        _updateMapMarkers();
      }
    }
  }

  /// Update map markers for driver and delivery location
  void _updateMapMarkers() {
    _markers.clear();
    _polylines.clear();

    // Add driver marker
    if (_driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: _driverName ?? 'Driver',
            snippet: 'On the way to you',
          ),
        ),
      );
    }

    // Add delivery location marker
    if (_deliveryLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: _deliveryLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'Delivery Location',
            snippet: 'Your address',
          ),
        ),
      );
    }

    // Draw route polyline
    if (_driverLocation != null && _deliveryLocation != null) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_driverLocation!, _deliveryLocation!],
          color: AppTheme.primaryBrown,
          width: 4,
        ),
      );

      // Animate camera to show both markers
      _animateCameraToBounds();
    }

    setState(() {});
  }

  /// Animate camera to show both driver and delivery location
  void _animateCameraToBounds() {
    if (_mapController == null ||
        _driverLocation == null ||
        _deliveryLocation == null)
      return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _driverLocation!.latitude < _deliveryLocation!.latitude
            ? _driverLocation!.latitude
            : _deliveryLocation!.latitude,
        _driverLocation!.longitude < _deliveryLocation!.longitude
            ? _driverLocation!.longitude
            : _deliveryLocation!.longitude,
      ),
      northeast: LatLng(
        _driverLocation!.latitude > _deliveryLocation!.latitude
            ? _driverLocation!.latitude
            : _deliveryLocation!.latitude,
        _driverLocation!.longitude > _deliveryLocation!.longitude
            ? _driverLocation!.longitude
            : _deliveryLocation!.longitude,
      ),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'confirmed':
        return '✅ Order Confirmed';
      case 'preparing':
        return '☕ Preparing your order';
      case 'ready':
        return '📦 Order ready for pickup';
      case 'out-for-delivery':
        return '🚗 Driver is on the way!';
      case 'delivered':
        return '✅ Order Delivered!';
      default:
        return 'Order status updated';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Track Order #${widget.orderNumber}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryBrown,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_wsService.isConnected)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: Icon(Icons.wifi, color: Colors.green, size: 20),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Map view (only when driver is on the way)
          if (_showMap && _driverLocation != null)
            Expanded(
              flex: 2,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _driverLocation ?? const LatLng(25.2048, 55.2708),
                  zoom: 14,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_driverLocation != null && _deliveryLocation != null) {
                    _animateCameraToBounds();
                  }
                },
              ),
            ),

          // Order information
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order status card
                  _buildStatusCard(),
                  const SizedBox(height: 16),

                  // Driver info (when assigned)
                  if (_driverName != null) _buildDriverCard(),
                  if (_driverName != null) const SizedBox(height: 16),

                  // Payment status
                  if (_paymentConfirmed) _buildPaymentConfirmedCard(),
                  if (_paymentConfirmed) const SizedBox(height: 16),

                  // Delivery details
                  _buildDeliveryDetailsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: AppTheme.primaryBrown,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getStatusDescription(),
                        style: TextStyle(
                          color: AppTheme.textMedium,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_estimatedArrival != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Estimated arrival: $_estimatedArrival',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Driver',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryBrown,
                  child: Text(
                    (_driverName ?? 'D')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _driverName ?? 'Driver',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (_driverPhone != null)
                        Text(
                          _driverPhone!,
                          style: TextStyle(
                            color: AppTheme.textMedium,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_driverPhone != null)
                  IconButton(
                    icon: const Icon(Icons.phone, color: AppTheme.primaryBrown),
                    onPressed: () {
                      // TODO: Implement phone call
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling $_driverPhone...')),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentConfirmedCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Confirmed',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Cash payment received by driver',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetailsCard() {
    final shippingAddress =
        widget.orderData?['shippingAddress'] as Map<String, dynamic>?;

    if (shippingAddress == null) return const SizedBox();

    final name = shippingAddress['name'] as String? ?? 'N/A';
    final address = shippingAddress['address'] as String? ?? 'N/A';
    final city = shippingAddress['city'] as String? ?? '';
    final emirate = shippingAddress['emirate'] as String? ?? '';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryBrown),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(address),
                      if (city.isNotEmpty || emirate.isNotEmpty)
                        Text('$city, $emirate'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (_currentStatus) {
      case 'confirmed':
        return Icons.check_circle;
      case 'preparing':
        return Icons.coffee_maker;
      case 'ready':
        return Icons.inventory;
      case 'out-for-delivery':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.home;
      default:
        return Icons.info;
    }
  }

  String _getStatusTitle() {
    switch (_currentStatus) {
      case 'confirmed':
        return 'Order Confirmed';
      case 'preparing':
        return 'Preparing Your Order';
      case 'ready':
        return 'Ready for Pickup';
      case 'out-for-delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      default:
        return 'Processing';
    }
  }

  String _getStatusDescription() {
    switch (_currentStatus) {
      case 'confirmed':
        return 'Your order has been confirmed';
      case 'preparing':
        return 'We\'re carefully preparing your coffee';
      case 'ready':
        return 'Order ready, waiting for driver pickup';
      case 'out-for-delivery':
        return 'Your driver is on the way!';
      case 'delivered':
        return 'Order successfully delivered. Enjoy!';
      default:
        return 'Order is being processed';
    }
  }
}
