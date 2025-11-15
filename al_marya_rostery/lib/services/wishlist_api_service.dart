import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../data/models/coffee_product_model.dart';

/// Wishlist API Service - Manages user wishlist/favorites
class WishlistApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _cachedAuthToken;

  String get baseUrl => '${AppConstants.baseUrl}/api';

  /// Load auth token from secure storage
  Future<void> loadAuthToken() async {
    try {
      _cachedAuthToken = await _storage.read(key: 'auth_token');
    } catch (e) {
      debugPrint('❌ Error loading auth token: $e');
      _cachedAuthToken = null;
    }
  }

  /// Get headers with auth token
  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_cachedAuthToken != null) {
      headers['Authorization'] = 'Bearer $_cachedAuthToken';
    }
    return headers;
  }

  /// Get user's wishlist
  Future<List<CoffeeProductModel>> getWishlist() async {
    try {
      if (_cachedAuthToken == null) {
        await loadAuthToken();
      }

      debugPrint('📋 Fetching wishlist from: $baseUrl/wishlist');

      final response = await http.get(
        Uri.parse('$baseUrl/wishlist'),
        headers: _getHeaders(),
      );

      debugPrint('📡 Wishlist response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] is List) {
          final List<dynamic> items = data['data'];
          return items
              .map((item) => CoffeeProductModel.fromJson(item))
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error fetching wishlist: $e');
      return [];
    }
  }

  /// Add product to wishlist
  Future<bool> addToWishlist(
    String productId, [
    String productType = 'Coffee',
  ]) async {
    try {
      if (_cachedAuthToken == null) {
        await loadAuthToken();
      }

      debugPrint(
        '➕ Adding product to wishlist: $productId (type: $productType)',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/wishlist'),
        headers: _getHeaders(),
        body: json.encode({'productId': productId, 'productType': productType}),
      );

      debugPrint('📡 Add to wishlist response: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Added to wishlist successfully');
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error adding to wishlist: $e');
      return false;
    }
  }

  /// Remove product from wishlist
  Future<bool> removeFromWishlist(String productId) async {
    try {
      if (_cachedAuthToken == null) {
        await loadAuthToken();
      }

      debugPrint('➖ Removing product from wishlist: $productId');

      final response = await http.delete(
        Uri.parse('$baseUrl/wishlist/$productId'),
        headers: _getHeaders(),
      );

      debugPrint('📡 Remove from wishlist response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Removed from wishlist successfully');
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error removing from wishlist: $e');
      return false;
    }
  }

  /// Check if product is in wishlist
  Future<bool> isInWishlist(String productId) async {
    try {
      if (_cachedAuthToken == null) {
        await loadAuthToken();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/wishlist/check/$productId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['inWishlist'] ?? false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking wishlist: $e');
      return false;
    }
  }

  /// Toggle product in wishlist (add if not present, remove if present)
  Future<bool> toggleWishlist(String productId) async {
    final isInList = await isInWishlist(productId);
    if (isInList) {
      return await removeFromWishlist(productId);
    } else {
      return await addToWishlist(productId);
    }
  }

  /// Get wishlist count
  Future<int> getWishlistCount() async {
    try {
      if (_cachedAuthToken == null) {
        await loadAuthToken();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/wishlist/count'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['count'] ?? 0;
      }

      return 0;
    } catch (e) {
      debugPrint('❌ Error getting wishlist count: $e');
      return 0;
    }
  }

  /// Clear entire wishlist
  Future<bool> clearWishlist() async {
    try {
      if (_cachedAuthToken == null) {
        await loadAuthToken();
      }

      debugPrint('🗑️ Clearing wishlist');

      final response = await http.delete(
        Uri.parse('$baseUrl/wishlist/clear'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Wishlist cleared successfully');
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error clearing wishlist: $e');
      return false;
    }
  }
}
