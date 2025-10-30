import 'dart:convert';
import 'dart:math' show sin, cos, atan2, sqrt, pi;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_address.dart';

class AddressService {
  static const String _addressesKey = 'saved_addresses';
  static const String _defaultAddressKey = 'default_address_id';

  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

  List<SavedAddress> _cachedAddresses = [];
  String? _defaultAddressId;

  /// Get all saved addresses
  Future<List<SavedAddress>> getSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = prefs.getStringList(_addressesKey) ?? [];

      _cachedAddresses = addressesJson
          .map((json) => SavedAddress.fromJson(jsonDecode(json)))
          .toList();

      // Sort by creation date, most recent first
      _cachedAddresses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return _cachedAddresses;
    } catch (e) {
      // Log error in debug mode only
      assert(() {
        print('Error loading saved addresses: $e');
        return true;
      }());
      return [];
    }
  }

  /// Save a new address
  Future<bool> saveAddress(SavedAddress address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = prefs.getStringList(_addressesKey) ?? [];

      // Check if address already exists (same coordinates AND same name)
      final existingAddresses = addressesJson
          .map((json) => SavedAddress.fromJson(jsonDecode(json)))
          .toList();

      final isDuplicate = existingAddresses.any(
        (existing) =>
            existing.name.toLowerCase() == address.name.toLowerCase() ||
            (_calculateDistance(
                  existing.latitude,
                  existing.longitude,
                  address.latitude,
                  address.longitude,
                ) <
                0.01), // Within 10 meters AND same coordinates (very close)
      );

      if (isDuplicate) {
        return false; // Address already exists
      }

      // Add new address
      addressesJson.add(jsonEncode(address.toJson()));
      await prefs.setStringList(_addressesKey, addressesJson);

      // If this is the first address or marked as default, set as default
      if (addressesJson.length == 1 || address.isDefault) {
        await setDefaultAddress(address.id);
      }

      // Update cache
      _cachedAddresses.add(address);
      _cachedAddresses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return true;
    } catch (e) {
      // Log error in debug mode only
      assert(() {
        print('Error saving address: $e');
        return true;
      }());
      return false;
    }
  }

  /// Delete an address
  Future<bool> deleteAddress(String addressId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = prefs.getStringList(_addressesKey) ?? [];

      final filteredAddresses = addressesJson
          .map((json) => SavedAddress.fromJson(jsonDecode(json)))
          .where((address) => address.id != addressId)
          .map((address) => jsonEncode(address.toJson()))
          .toList();

      await prefs.setStringList(_addressesKey, filteredAddresses);

      // If deleted address was default, clear default
      if (_defaultAddressId == addressId) {
        await prefs.remove(_defaultAddressKey);
        _defaultAddressId = null;
      }

      // Update cache
      _cachedAddresses.removeWhere((address) => address.id == addressId);

      return true;
    } catch (e) {
      // Log error in debug mode only
      assert(() {
        print('Error deleting address: $e');
        return true;
      }());
      return false;
    }
  }

  /// Set default address
  Future<void> setDefaultAddress(String addressId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_defaultAddressKey, addressId);
      _defaultAddressId = addressId;
    } catch (e) {
      // Log error in debug mode only
      assert(() {
        print('Error setting default address: $e');
        return true;
      }());
    }
  }

  /// Get default address
  Future<SavedAddress?> getDefaultAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _defaultAddressId = prefs.getString(_defaultAddressKey);

      if (_defaultAddressId == null) return null;

      final addresses = await getSavedAddresses();
      return addresses.firstWhere(
        (address) => address.id == _defaultAddressId,
        orElse: () => addresses.isNotEmpty
            ? addresses.first
            : SavedAddress(
                id: '',
                name: '',
                fullAddress: '',
                latitude: 0,
                longitude: 0,
                type: AddressType.other,
                createdAt: DateTime.now(),
              ),
      );
    } catch (e) {
      // Log error in debug mode only
      assert(() {
        print('Error getting default address: $e');
        return true;
      }());
      return null;
    }
  }

  /// Search addresses by query
  Future<List<SavedAddress>> searchAddresses(String query) async {
    if (query.isEmpty) {
      return await getSavedAddresses();
    }

    final addresses = await getSavedAddresses();
    final searchQuery = query.toLowerCase();

    return addresses.where((address) {
      return address.name.toLowerCase().contains(searchQuery) ||
          address.fullAddress.toLowerCase().contains(searchQuery) ||
          (address.buildingDetails?.toLowerCase().contains(searchQuery) ??
              false) ||
          (address.landmark?.toLowerCase().contains(searchQuery) ?? false);
    }).toList();
  }

  /// Calculate distance between two coordinates (in kilometers)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Clear all addresses (for testing/reset)
  Future<void> clearAllAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_addressesKey);
      await prefs.remove(_defaultAddressKey);
      _cachedAddresses.clear();
      _defaultAddressId = null;
    } catch (e) {
      // Log error in debug mode only
      assert(() {
        print('Error clearing addresses: $e');
        return true;
      }());
    }
  }
}
