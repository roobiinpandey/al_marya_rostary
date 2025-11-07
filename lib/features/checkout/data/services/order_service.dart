import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';

/// Order Service - Handles all order-related API calls
class OrderService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _cachedAuthToken;

  String get baseUrl => '${AppConstants.baseUrl}/api';

  /// Public getter for auth token (for payment integration)
  String? get authToken => _cachedAuthToken;

  /// Load auth token from secure storage
  Future<void> loadAuthToken() async {
    try {
      _cachedAuthToken = await _storage.read(key: 'auth_token');
      debugPrint(
        '🔑 Order Service - Auth token loaded: ${_cachedAuthToken != null ? "YES" : "NO"}',
      );
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

  /// Create a new order
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
    required String paymentStatus,
    required double totalAmount,
    Map<String, dynamic>? deliveryInfo,
    String? specialInstructions,
  }) async {
    try {
      // Load auth token if not already loaded
      if (_cachedAuthToken == null) {
        await loadAuthToken();
      }

      debugPrint('📦 Creating order with ${items.length} items');
      debugPrint('💰 Total amount: $totalAmount');
      debugPrint('💳 Payment method: $paymentMethod');

      final orderData = {
        'items': items
            .map(
              (item) => {
                'productId': item['productId'] ?? item['id'],
                'productName': item['name'],
                'quantity': item['quantity'],
                'price': item['price'],
                'roastLevel': item['roastLevel'],
                'grindSize': item['grindSize'],
              },
            )
            .toList(),
        'shippingAddress': {
          'fullName': shippingAddress['name'],
          'phone': shippingAddress['phone'],
          'addressLine': shippingAddress['address'],
          'city': shippingAddress['city'],
          'emirate': shippingAddress['emirate'],
          'country': 'UAE',
        },
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'totalAmount': totalAmount,
        'deliveryMethod': deliveryInfo?['method'] ?? 'standard',
        'preferredDeliveryDate': deliveryInfo?['date']?.toIso8601String(),
        'preferredDeliveryTime': deliveryInfo?['time'],
        'specialInstructions': specialInstructions,
      };

      debugPrint('📤 Sending order to: $baseUrl/orders');

      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: _getHeaders(),
        body: json.encode(orderData),
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          debugPrint(
            '✅ Order created successfully: ${data['order']['orderNumber']}',
          );
          return {
            'success': true,
            'order': data['order'],
            'message': 'Order placed successfully',
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to create order');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Please login to place an order');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create order');
      }
    } catch (e) {
      debugPrint('❌ Error creating order: $e');
      rethrow;
    }
  }

  /// Get user's orders
  Future<List<Map<String, dynamic>>> getMyOrders() async {
    try {
      if (_cachedAuthToken == null) {
        await loadAuthToken();
      }

      debugPrint('📦 Fetching user orders from: $baseUrl/orders/my-orders');

      final response = await http.get(
        Uri.parse('$baseUrl/orders/my-orders'),
        headers: _getHeaders(),
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final orders = (data['orders'] as List).cast<Map<String, dynamic>>();
          debugPrint('✅ Loaded ${orders.length} orders');
          return orders;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch orders');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Please login to view orders');
      } else {
        throw Exception('Failed to fetch orders');
      }
    } catch (e) {
      debugPrint('❌ Error fetching orders: $e');
      rethrow;
    }
  }

  /// Get order details by ID
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      if (_cachedAuthToken == null) {
        await loadAuthToken();
      }

      debugPrint('📦 Fetching order details: $orderId');

      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          debugPrint('✅ Order details loaded');
          return data['order'];
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch order');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Please login to view order');
      } else {
        throw Exception('Failed to fetch order');
      }
    } catch (e) {
      debugPrint('❌ Error fetching order details: $e');
      rethrow;
    }
  }

  /// Cancel an order
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      if (_cachedAuthToken == null) {
        await loadAuthToken();
      }

      debugPrint('❌ Cancelling order: $orderId');

      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/cancel'),
        headers: _getHeaders(),
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Order cancelled successfully');
        return data['success'] == true;
      } else {
        throw Exception('Failed to cancel order');
      }
    } catch (e) {
      debugPrint('❌ Error cancelling order: $e');
      rethrow;
    }
  }

  /// Create guest order (without authentication)
  Future<Map<String, dynamic>> createGuestOrder({
    required String guestEmail,
    required String guestName,
    required String guestPhone,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
    required double totalAmount,
    Map<String, dynamic>? deliveryInfo,
  }) async {
    try {
      debugPrint('📦 Creating guest order');

      final orderData = {
        'guestInfo': {
          'email': guestEmail,
          'name': guestName,
          'phone': guestPhone,
        },
        'items': items
            .map(
              (item) => {
                'productId': item['productId'] ?? item['id'],
                'productName': item['name'],
                'quantity': item['quantity'],
                'price': item['price'],
                'roastLevel': item['roastLevel'],
                'grindSize': item['grindSize'],
              },
            )
            .toList(),
        'shippingAddress': {
          'fullName': shippingAddress['name'],
          'phone': shippingAddress['phone'],
          'addressLine': shippingAddress['address'],
          'city': shippingAddress['city'],
          'emirate': shippingAddress['emirate'],
          'country': 'UAE',
        },
        'paymentMethod': paymentMethod,
        'paymentStatus': 'pending',
        'totalAmount': totalAmount,
        'deliveryMethod': deliveryInfo?['method'] ?? 'standard',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/orders/guest'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          debugPrint('✅ Guest order created: ${data['order']['orderNumber']}');
          return {
            'success': true,
            'order': data['order'],
            'message': 'Order placed successfully',
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to create order');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create order');
      }
    } catch (e) {
      debugPrint('❌ Error creating guest order: $e');
      rethrow;
    }
  }
}
