import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

/// LocationTrackingService handles GPS tracking and broadcasting
/// driver location to the backend every 3 seconds
class LocationTrackingService {
  static final LocationTrackingService _instance =
      LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  IO.Socket? _socket;
  Timer? _locationTimer;
  String? _currentOrderId;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  /// Start location tracking for an order
  Future<void> startTracking(String orderId) async {
    if (_isTracking) {
      debugPrint('⚠️ Already tracking location');
      return;
    }

    _currentOrderId = orderId;

    // Check location permissions
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      debugPrint('❌ Location permission denied');
      throw Exception('Location permission required');
    }

    // Connect to WebSocket
    await _connectWebSocket();

    // Start broadcasting location every 3 seconds
    _startLocationBroadcast();

    _isTracking = true;
    debugPrint('✅ Started location tracking for order: $orderId');
  }

  /// Stop location tracking
  void stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _currentOrderId = null;
    _isTracking = false;

    _socket?.disconnect();
    _socket = null;

    debugPrint('🛑 Stopped location tracking');
  }

  /// Check and request location permissions
  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Location permissions are permanently denied');
      return false;
    }

    if (permission == LocationPermission.denied) {
      debugPrint('❌ Location permissions are denied');
      return false;
    }

    // Check if location service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Location services are disabled');
      return false;
    }

    return true;
  }

  /// Connect to WebSocket server
  Future<void> _connectWebSocket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        throw Exception('No auth token found');
      }

      // Use production URL or localhost for development
      const serverUrl =
          'https://api.almaryarostery.com'; // Change to localhost:5001 for dev

      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .setAuth({'token': token})
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('✅ WebSocket connected');
      });

      _socket!.onDisconnect((_) {
        debugPrint('❌ WebSocket disconnected');
      });

      _socket!.onConnectError((error) {
        debugPrint('❌ WebSocket connection error: $error');
      });

      _socket!.connect();
    } catch (e) {
      debugPrint('❌ Error connecting to WebSocket: $e');
      rethrow;
    }
  }

  /// Start periodic location broadcast (every 3 seconds)
  void _startLocationBroadcast() {
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _broadcastLocation();
    });
  }

  /// Get current location and broadcast to server
  Future<void> _broadcastLocation() async {
    if (_socket == null || !_socket!.connected || _currentOrderId == null) {
      debugPrint('⚠️ Cannot broadcast - not connected');
      return;
    }

    try {
      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Only update if moved 10 meters
        ),
      );

      // Prepare location data
      final locationData = {
        'orderId': _currentOrderId,
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
          'accuracy': position.accuracy,
          'heading': position.heading,
          'speed': position.speed,
          'altitude': position.altitude,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Emit location update to backend
      _socket!.emit('driver_location_update', locationData);

      debugPrint(
        '📍 Location broadcast: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      debugPrint('❌ Error broadcasting location: $e');
    }
  }

  /// Confirm cash payment (COD)
  Future<void> confirmCashPayment(String orderId, double amount) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Not connected to server');
    }

    _socket!.emit('payment_confirm', {
      'orderId': orderId,
      'paymentMethod': 'cash',
      'amount': amount,
      'status': 'paid',
      'timestamp': DateTime.now().toIso8601String(),
    });

    debugPrint('💰 Cash payment confirmed: AED $amount');
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Not connected to server');
    }

    _socket!.emit('order_status_update', {
      'orderId': orderId,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
    });

    debugPrint('📊 Order status updated: $status');
  }

  /// Get current location once (without tracking)
  Future<Position> getCurrentLocation() async {
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      throw Exception('Location permission required');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Calculate distance to destination in meters
  Future<double> getDistanceToDestination(
    double destLat,
    double destLng,
  ) async {
    try {
      final currentPosition = await getCurrentLocation();

      return Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        destLat,
        destLng,
      );
    } catch (e) {
      debugPrint('❌ Error calculating distance: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}
