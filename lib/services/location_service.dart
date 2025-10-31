import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Service to handle location permissions and fetching
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  String? _cachedLocation;
  Position? _cachedPosition;
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(minutes: 30);

  /// Get current location as formatted string (City, Country)
  /// Throws exception if location cannot be determined
  Future<String> getCurrentLocation() async {
    // Return cached location if still valid
    if (_cachedLocation != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _cachedLocation!;
    }

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable location in settings.',
      );
    }

    // Check and request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission denied. Please grant location access.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. Please enable in settings.',
      );
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    // Get address from coordinates
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty) {
      throw Exception('Unable to determine address from location.');
    }

    Placemark place = placemarks.first;
    String location = _formatLocation(place);

    // Cache the result
    _cachedLocation = location;
    _cachedPosition = position;
    _lastFetchTime = DateTime.now();

    return location;
  }

  /// Get current position (coordinates)
  /// Returns Position object with latitude and longitude
  Future<Position> getCurrentPosition() async {
    // Return cached position if still valid
    if (_cachedPosition != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _cachedPosition!;
    }

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable location in settings.',
      );
    }

    // Check and request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission denied. Please grant location access.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. Please enable in settings.',
      );
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    // Cache the result
    _cachedPosition = position;
    _lastFetchTime = DateTime.now();

    return position;
  }

  /// Format placemark into readable location string
  String _formatLocation(Placemark place) {
    // Try different combinations to get a good location string
    String? city = place.locality?.trim().isNotEmpty == true
        ? place.locality
        : place.subAdministrativeArea?.trim().isNotEmpty == true
        ? place.subAdministrativeArea
        : place.administrativeArea?.trim().isNotEmpty == true
        ? place.administrativeArea
        : place.subLocality?.trim().isNotEmpty == true
        ? place.subLocality
        : null;

    String? country = place.country?.trim().isNotEmpty == true
        ? place.country
        : null;

    // Debug print to see what we're getting
    print('🏠 Location parts - City: "$city", Country: "$country"');
    print(
      '🏠 Raw placemark - locality: "${place.locality}", subAdmin: "${place.subAdministrativeArea}", admin: "${place.administrativeArea}", subLocality: "${place.subLocality}"',
    );

    if (city != null &&
        city.isNotEmpty &&
        country != null &&
        country.isNotEmpty) {
      return '$city, $country';
    } else if (city != null && city.isNotEmpty) {
      return city;
    } else if (country != null && country.isNotEmpty) {
      return country;
    } else {
      return 'Current Location';
    }
  }

  /// Clear cached location to force refresh
  void clearCache() {
    _cachedLocation = null;
    _cachedPosition = null;
    _lastFetchTime = null;
  }

  /// Get last known position (faster but may be outdated)
  /// Returns null if no last known location available
  Future<String?> getLastKnownLocation() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();

      if (position != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          return _formatLocation(placemarks.first);
        }
      }
    } catch (e) {
      debugPrint('Error getting last known location: $e');
    }

    return null; // No fallback
  }

  /// Check if location permission is granted
  Future<bool> hasPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Open app settings for location permission
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Get detailed location info (for debugging)
  Future<Map<String, dynamic>> getDetailedLocation() async {
    try {
      // Add more detailed logging
      print('🔍 Starting location detection...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 Location services enabled: $serviceEnabled');

      if (!serviceEnabled) {
        return {'error': 'Location services disabled'};
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      print('🔐 Location permission: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('🔐 Permission after request: $permission');
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return {'error': 'Location permission denied: $permission'};
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      print('📍 Position: ${position.latitude}, ${position.longitude}');

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      print('🏠 Placemarks found: ${placemarks.length}');

      Placemark? place = placemarks.isNotEmpty ? placemarks.first : null;

      final result = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'locality': place?.locality,
        'subLocality': place?.subLocality,
        'administrativeArea': place?.administrativeArea,
        'country': place?.country,
        'postalCode': place?.postalCode,
        'street': place?.street,
        'formatted': place != null
            ? _formatLocation(place)
            : 'No address found',
      };

      print('📋 Final result: $result');
      return result;
    } catch (e) {
      print('❌ Location error: $e');
      return {'error': e.toString()};
    }
  }
}
