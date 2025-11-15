import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/services/pin_auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../models/order_model.dart';

class DeliveriesService {
  // Singleton pattern
  static final DeliveriesService _instance = DeliveriesService._internal();
  factory DeliveriesService() => _instance;
  DeliveriesService._internal();

  final _authService = PinAuthService();
  final _notificationService = NotificationService();

  // Fetch available deliveries (orders ready for pickup)
  Future<List<Order>> fetchAvailableDeliveries() async {
    try {
      print('🔍 Fetching available deliveries...');
      print('   URL: ${AppConstants.availableDeliveriesEndpoint}');
      final headers = _authService.getAuthHeaders();
      print('   Headers: $headers');

      final response = await http
          .get(
            Uri.parse(AppConstants.availableDeliveriesEndpoint),
            headers: headers,
          )
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      print('   Response Status: ${response.statusCode}');
      print(
        '   Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ordersList = data['orders'] as List?;
        if (ordersList == null) {
          print('   ⚠️ Orders list is null');
          return [];
        }
        final orders = ordersList.map((json) => Order.fromJson(json)).toList();
        print('   ✅ Loaded ${orders.length} available deliveries');

        // Send notification if there are available deliveries (don't block if this fails)
        if (orders.isNotEmpty && _notificationService.isEnabled) {
          try {
            await _notificationService.showMultipleDeliveriesNotification(
              orders.length,
            );
            print('   📬 Notification sent for ${orders.length} deliveries');
          } catch (e) {
            print('   ⚠️ Could not send notification: $e');
          }
        }

        return orders;
      } else {
        print('   ❌ Failed with status ${response.statusCode}');
        final data = jsonDecode(response.body);
        print('   Error message: ${data['message']}');
        throw Exception(
          'Failed to load available deliveries: ${data['message']}',
        );
      }
    } catch (e) {
      print('   💥 Exception fetching available deliveries: $e');
      rethrow;
    }
  }

  // Fetch driver's assigned deliveries
  Future<List<Order>> fetchMyDeliveries() async {
    try {
      final response = await http
          .get(
            Uri.parse(AppConstants.myDeliveriesEndpoint),
            headers: _authService.getAuthHeaders(),
          )
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ordersList = data['orders'] as List?;
        if (ordersList == null) {
          return [];
        }
        final orders = ordersList.map((json) => Order.fromJson(json)).toList();
        return orders;
      } else {
        throw Exception('Failed to load my deliveries');
      }
    } catch (e) {
      print('Error fetching my deliveries: $e');
      rethrow;
    }
  }

  // Fetch completed deliveries
  Future<List<Order>> fetchCompletedDeliveries() async {
    try {
      final response = await http
          .get(
            Uri.parse(AppConstants.completedDeliveriesEndpoint),
            headers: _authService.getAuthHeaders(),
          )
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ordersList = data['orders'] as List?;
        if (ordersList == null) {
          return [];
        }
        final orders = ordersList.map((json) => Order.fromJson(json)).toList();
        return orders;
      } else {
        throw Exception('Failed to load completed deliveries');
      }
    } catch (e) {
      print('Error fetching completed deliveries: $e');
      rethrow;
    }
  }

  // Accept a delivery
  Future<Map<String, dynamic>> acceptDelivery(String orderId) async {
    try {
      print('📦 ACCEPT DELIVERY DEBUG:');
      print('   Order ID: $orderId');
      final url = '${AppConstants.driverOrdersUrl}/$orderId/accept';
      print('   Full URL: $url');
      final headers = _authService.getAuthHeaders();
      print('   Headers: $headers');

      final response = await http
          .post(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      print('   Response Status: ${response.statusCode}');
      print('   Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('   ✅ Success!');
        return {
          'success': true,
          'message': data['message'] ?? 'Delivery accepted',
          'order': Order.fromJson(data['order']),
        };
      } else {
        print('   ❌ Failed: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to accept delivery',
        };
      }
    } catch (e) {
      print('   💥 Exception: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
      };
    }
  }

  // Start delivery (driver is on the way)
  Future<Map<String, dynamic>> startDelivery(String orderId) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.driverOrdersUrl}/$orderId/start'),
            headers: _authService.getAuthHeaders(),
          )
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Delivery started',
          'order': Order.fromJson(data['order']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to start delivery',
        };
      }
    } catch (e) {
      print('Error starting delivery: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
      };
    }
  }

  // Complete delivery
  Future<Map<String, dynamic>> completeDelivery(String orderId) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.driverOrdersUrl}/$orderId/complete'),
            headers: _authService.getAuthHeaders(),
          )
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Delivery completed',
          'order': Order.fromJson(data['order']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to complete delivery',
        };
      }
    } catch (e) {
      print('Error completing delivery: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
      };
    }
  }

  // Update driver status
  Future<Map<String, dynamic>> updateDriverStatus(String status) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.updateStatusEndpoint),
            headers: _authService.getAuthHeaders(),
            body: jsonEncode({'status': status}),
          )
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Status updated',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update status',
        };
      }
    } catch (e) {
      print('Error updating driver status: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
      };
    }
  }
}
