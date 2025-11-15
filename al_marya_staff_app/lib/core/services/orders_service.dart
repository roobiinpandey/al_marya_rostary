import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrdersService {
  // Use production URL
  static const String baseUrl = 'https://almaryarostary.onrender.com/api/staff';

  // Local Development URL (uncomment for development)
  // static const String baseUrl = 'http://127.0.0.1:5001/api/staff';

  /// Fetch orders for staff
  /// [status] can be 'pending', 'assigned', or null for all
  Future<Map<String, dynamic>> getOrders({String? status}) async {
    try {
      print('📦 Fetching orders from: $baseUrl/orders');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('staff_token');

      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final uri = status != null
          ? Uri.parse('$baseUrl/orders?status=$status')
          : Uri.parse('$baseUrl/orders');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📦 Orders response status: ${response.statusCode}');
      print('📦 Orders response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'orders': data['orders'] ?? [],
          'count': data['count'] ?? 0,
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to fetch orders',
        };
      }
    } catch (e) {
      print('❌ Orders fetch error: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Get order details by ID
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      print('📦 Fetching order details for: $orderId');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('staff_token');

      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📦 Order details response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'order': data['order']};
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to fetch order details',
        };
      }
    } catch (e) {
      print('❌ Order details error: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Accept/claim an order
  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    try {
      print('✅ Accepting order: $orderId');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('staff_token');

      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('✅ Accept order response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Order accepted',
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to accept order',
        };
      }
    } catch (e) {
      print('❌ Accept order error: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Update order status (e.g., preparing, ready)
  Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    String status,
  ) async {
    try {
      print('🔄 Updating order $orderId to status: $status');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('staff_token');

      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      print('🔄 Update status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Order status updated',
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to update order status',
        };
      }
    } catch (e) {
      print('❌ Update status error: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
}
