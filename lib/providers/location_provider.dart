import 'package:flutter/foundation.dart';
import '../services/location_service.dart';

/// Provider for managing location state
class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  String? _currentLocation;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  String? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  /// Initialize and fetch location
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Try to get last known location first (faster)
    final lastKnown = await _locationService.getLastKnownLocation();
    if (lastKnown != null) {
      _currentLocation = lastKnown;
      _isLoading = false;
      notifyListeners();
    }

    // Then fetch current location (more accurate)
    await fetchCurrentLocation();
  }

  /// Fetch current location
  Future<void> fetchCurrentLocation() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final location = await _locationService.getCurrentLocation();
      _currentLocation = location;
      _hasError = false;
      _errorMessage = null;
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
      _currentLocation = null; // Clear any cached location on error
      debugPrint('Location error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh location (clear cache and fetch again)
  Future<void> refreshLocation() async {
    _locationService.clearCache();
    await fetchCurrentLocation();
  }

  /// Check if location permission is granted
  Future<bool> hasPermission() async {
    return await _locationService.hasPermission();
  }

  /// Open location settings
  Future<void> openSettings() async {
    await _locationService.openLocationSettings();
  }

  /// Get formatted location with loading indicator
  String getDisplayLocation() {
    if (_isLoading) {
      return 'Getting location...';
    }
    if (_hasError) {
      return 'Location unavailable';
    }
    if (_currentLocation != null) {
      return _currentLocation!;
    }
    return 'Location not set';
  }
}
