import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import './pin_auth_service.dart';

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final _authService = PinAuthService();
  Timer? _locationUpdateTimer;
  Position? _lastPosition;
  bool _isTracking = false;

  bool get isTracking => _isTracking;
  Position? get lastPosition => _lastPosition;

  // Check if location services are enabled
  Future<bool> checkLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permissions
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permissions
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  // Initialize location service and request permissions
  Future<Map<String, dynamic>> initialize() async {
    // Check if location services are enabled
    final serviceEnabled = await checkLocationServiceEnabled();
    if (!serviceEnabled) {
      return {
        'success': false,
        'message':
            'Location services are disabled. Please enable location services.',
      };
    }

    // Check and request permissions
    LocationPermission permission = await checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return {
          'success': false,
          'message':
              'Location permissions are denied. Please enable location permissions in settings.',
        };
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return {
        'success': false,
        'message':
            'Location permissions are permanently denied. Please enable them in app settings.',
      };
    }

    return {
      'success': true,
      'message': 'Location service initialized successfully',
    };
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(Duration(seconds: AppConstants.locationTimeout));

      _lastPosition = position;
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Send location to backend
  Future<bool> sendLocationToBackend(Position position) async {
    if (!_authService.isAuthenticated) {
      print('Not authenticated, skipping location update');
      return false;
    }

    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.updateLocationEndpoint),
            headers: _authService.getAuthHeaders(),
            body: jsonEncode({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        print('Location updated successfully');
        return true;
      } else {
        print('Failed to update location: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error sending location to backend: $e');
      return false;
    }
  }

  // Start tracking location
  Future<void> startTracking() async {
    if (_isTracking) {
      print('Location tracking already started');
      return;
    }

    // Initialize if not already done
    final initResult = await initialize();
    if (!initResult['success']) {
      print('Failed to initialize location service: ${initResult['message']}');
      return;
    }

    _isTracking = true;
    print('Starting location tracking...');

    // Send initial location
    final initialPosition = await getCurrentLocation();
    if (initialPosition != null) {
      await sendLocationToBackend(initialPosition);
    }

    // Start periodic updates
    _locationUpdateTimer = Timer.periodic(
      Duration(seconds: AppConstants.locationUpdateInterval.toInt()),
      (timer) async {
        if (!_isTracking) {
          timer.cancel();
          return;
        }

        final position = await getCurrentLocation();
        if (position != null) {
          // Check if driver moved enough distance to send update
          if (_lastPosition != null) {
            final distance = Geolocator.distanceBetween(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
              position.latitude,
              position.longitude,
            );

            // Only send update if moved more than minimum distance
            if (distance >= AppConstants.minDistanceForUpdate) {
              await sendLocationToBackend(position);
            }
          } else {
            await sendLocationToBackend(position);
          }
        }
      },
    );
  }

  // Stop tracking location
  void stopTracking() {
    if (_locationUpdateTimer != null) {
      _locationUpdateTimer!.cancel();
      _locationUpdateTimer = null;
    }
    _isTracking = false;
    print('Location tracking stopped');
  }

  // Update driver status and start/stop tracking accordingly
  Future<void> updateDriverStatus(String status) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.updateStatusEndpoint),
            headers: _authService.getAuthHeaders(),
            body: jsonEncode({'status': status}),
          )
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        print('Driver status updated to: $status');

        // Start tracking if status is on_delivery or available
        if (status == AppConstants.statusOnDelivery ||
            status == AppConstants.statusAvailable) {
          await startTracking();
        } else {
          stopTracking();
        }
      }
    } catch (e) {
      print('Error updating driver status: $e');
    }
  }

  // Calculate distance between two positions
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // Format distance for display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  // Clean up when app is closed
  void dispose() {
    stopTracking();
  }
}
