import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Service for handling order cancellation functionality
/// Allows customers to cancel orders within 15 minutes of placement
class OrderCancellationService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Cancel an order with the given reason
  ///
  /// Returns a map containing:
  /// - success: bool
  /// - message: String
  /// - order: Map<String, dynamic>
  /// - refund: Map<String, dynamic>? (if applicable)
  ///
  /// Throws Exception if cancellation fails
  Future<Map<String, dynamic>> cancelOrder(
    String orderId,
    String reason,
  ) async {
    try {
      final token = await _storage.read(key: 'auth_token');

      if (token == null) {
        throw Exception('Authentication required. Please log in again.');
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/orders/$orderId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error cancelling order: $e');
    }
  }

  /// Check if an order can be cancelled
  ///
  /// An order can be cancelled if:
  /// - Status is 'pending' or 'preparing'
  /// - Order was placed within the last 15 minutes
  bool canCancelOrder(DateTime orderCreatedAt, String orderStatus) {
    // Check status - only pending or preparing orders can be cancelled
    if (!['pending', 'preparing'].contains(orderStatus)) {
      return false;
    }

    // Check time limit (15 minutes)
    final minutesSinceOrder = DateTime.now()
        .difference(orderCreatedAt)
        .inMinutes;
    return minutesSinceOrder <= 15;
  }

  /// Get the remaining minutes before cancellation window expires
  ///
  /// Returns a number between 0 and 15
  int getRemainingMinutes(DateTime orderCreatedAt) {
    final minutesSinceOrder = DateTime.now()
        .difference(orderCreatedAt)
        .inMinutes;
    return (15 - minutesSinceOrder).clamp(0, 15);
  }

  /// Get the remaining seconds before cancellation window expires
  ///
  /// Useful for showing countdown timers
  int getRemainingSeconds(DateTime orderCreatedAt) {
    final secondsSinceOrder = DateTime.now()
        .difference(orderCreatedAt)
        .inSeconds;
    return (900 - secondsSinceOrder).clamp(0, 900); // 900 seconds = 15 minutes
  }

  /// Format remaining time as "Xm Ys"
  String getFormattedRemainingTime(DateTime orderCreatedAt) {
    final remainingSeconds = getRemainingSeconds(orderCreatedAt);
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Get cancellation eligibility message
  ///
  /// Returns a user-friendly message explaining if/why order can't be cancelled
  String getCancellationEligibilityMessage(
    DateTime orderCreatedAt,
    String orderStatus,
  ) {
    if (!['pending', 'preparing'].contains(orderStatus)) {
      return 'Orders with status "$orderStatus" cannot be cancelled';
    }

    final minutesSinceOrder = DateTime.now()
        .difference(orderCreatedAt)
        .inMinutes;
    if (minutesSinceOrder > 15) {
      return 'Cancellation window expired (orders can only be cancelled within 15 minutes)';
    }

    final remainingMinutes = getRemainingMinutes(orderCreatedAt);
    return 'You can cancel within $remainingMinutes minute${remainingMinutes != 1 ? 's' : ''}';
  }
}
