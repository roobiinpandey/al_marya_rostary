import '../../models/order.dart';
import '../../models/staff.dart';
import '../api/api_client.dart';
import '../constants/api_endpoints.dart';

/// Service for staff-specific API operations
class StaffApiService {
  final ApiClient _apiClient = ApiClient();

  // ===== Profile Management =====

  /// Get staff profile
  Future<Staff> getProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.getProfile);

      final staffData = response['staff'] as Map<String, dynamic>?;
      if (staffData == null) {
        throw Exception('No staff data received');
      }

      return Staff.fromJson(staffData);
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  /// Update staff status (active, on_break, inactive)
  Future<Staff> updateStatus(String status) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.updateStatus, {
        'status': status,
      });

      final staffData = response['staff'] as Map<String, dynamic>?;
      if (staffData == null) {
        throw Exception('No staff data received');
      }

      return Staff.fromJson(staffData);
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }

  /// Get staff statistics
  Future<StaffStats> getStats() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.getStats);

      final statsData = response['stats'] as Map<String, dynamic>?;
      if (statsData == null) {
        throw Exception('No stats data received');
      }

      return StaffStats.fromJson(statsData);
    } catch (e) {
      throw Exception('Failed to load stats: $e');
    }
  }

  // ===== Order Management =====

  /// Get orders list
  /// Optional filters: status, limit
  Future<List<Order>> getOrders({String? status, int? limit}) async {
    try {
      // Build query parameters
      String endpoint = ApiEndpoints.getOrders;
      final params = <String>[];

      if (status != null) {
        params.add('status=$status');
      }
      if (limit != null) {
        params.add('limit=$limit');
      }

      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }

      final response = await _apiClient.get(endpoint);

      final ordersData = response['orders'] as List?;
      if (ordersData == null) {
        return [];
      }

      return ordersData
          .map((order) => Order.fromJson(order as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load orders: $e');
    }
  }

  /// Get order details by ID
  Future<Order> getOrderDetails(String orderId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.getOrderDetails(orderId),
      );

      final orderData = response['order'] as Map<String, dynamic>?;
      if (orderData == null) {
        throw Exception('No order data received');
      }

      return Order.fromJson(orderData);
    } catch (e) {
      throw Exception('Failed to load order details: $e');
    }
  }

  /// Accept order
  Future<Order> acceptOrder(String orderId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.acceptOrder(orderId),
        {},
      );

      final orderData = response['order'] as Map<String, dynamic>?;
      if (orderData == null) {
        throw Exception('No order data received');
      }

      return Order.fromJson(orderData);
    } catch (e) {
      throw Exception('Failed to accept order: $e');
    }
  }

  /// Start preparation
  Future<Order> startPreparation(String orderId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.startPreparation(orderId),
        {},
      );

      final orderData = response['order'] as Map<String, dynamic>?;
      if (orderData == null) {
        throw Exception('No order data received');
      }

      return Order.fromJson(orderData);
    } catch (e) {
      throw Exception('Failed to start preparation: $e');
    }
  }

  /// Mark order ready
  /// This will trigger notification to drivers
  Future<Order> markOrderReady(String orderId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.markOrderReady(orderId),
        {},
      );

      final orderData = response['order'] as Map<String, dynamic>?;
      if (orderData == null) {
        throw Exception('No order data received');
      }

      return Order.fromJson(orderData);
    } catch (e) {
      throw Exception('Failed to mark order ready: $e');
    }
  }

  // ===== Order Workflow Helper =====

  /// Complete workflow: accept → start → ready
  Future<Order> processOrder(String orderId) async {
    try {
      // Step 1: Accept order
      var order = await acceptOrder(orderId);

      // Small delay for UI feedback
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: Start preparation
      order = await startPreparation(orderId);

      // Wait for actual preparation (this would be manual in real app)
      // For testing purposes only
      await Future.delayed(const Duration(seconds: 2));

      // Step 3: Mark ready
      order = await markOrderReady(orderId);

      return order;
    } catch (e) {
      throw Exception('Failed to process order: $e');
    }
  }
}
