import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

/// Service for managing subscription features
class SubscriptionsApiService {
  static final SubscriptionsApiService _instance =
      SubscriptionsApiService._internal();
  factory SubscriptionsApiService() => _instance;
  SubscriptionsApiService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get user's subscriptions
  Future<List<Map<String, dynamic>>> getUserSubscriptions(String userId) async {
    try {
      final response = await _apiClient.get(
        '/api/subscriptions?userId=$userId',
      );

      if (_apiClient.isSuccessful(response)) {
        final data = _apiClient.parseResponse(response);
        return List<Map<String, dynamic>>.from(data['subscriptions'] ?? []);
      } else {
        throw Exception('Failed to fetch user subscriptions');
      }
    } catch (e) {
      debugPrint('❌ Error fetching user subscriptions: $e');
      rethrow;
    }
  }

  /// Create a new subscription
  Future<Map<String, dynamic>> createSubscription({
    required String userId,
    required String planId,
    required String frequency,
    required Map<String, dynamic> deliveryAddress,
    String? preferences,
    Map<String, dynamic>? customization,
  }) async {
    try {
      final subscriptionData = {
        'userId': userId,
        'planId': planId,
        'frequency': frequency,
        'deliveryAddress': deliveryAddress,
        if (preferences != null) 'preferences': preferences,
        if (customization != null) 'customization': customization,
      };

      final response = await _apiClient.post(
        '/api/subscriptions',
        body: subscriptionData,
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to create subscription');
      }
    } catch (e) {
      debugPrint('❌ Error creating subscription: $e');
      rethrow;
    }
  }

  /// Update an existing subscription
  Future<Map<String, dynamic>> updateSubscription(
    String subscriptionId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _apiClient.put(
        '/api/subscriptions/$subscriptionId',
        body: updateData,
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to update subscription');
      }
    } catch (e) {
      debugPrint('❌ Error updating subscription: $e');
      rethrow;
    }
  }

  /// Pause a subscription
  Future<Map<String, dynamic>> pauseSubscription(String subscriptionId) async {
    try {
      final response = await _apiClient.post(
        '/api/subscriptions/$subscriptionId/pause',
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to pause subscription');
      }
    } catch (e) {
      debugPrint('❌ Error pausing subscription: $e');
      rethrow;
    }
  }

  /// Resume a paused subscription
  Future<Map<String, dynamic>> resumeSubscription(String subscriptionId) async {
    try {
      final response = await _apiClient.post(
        '/api/subscriptions/$subscriptionId/resume',
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to resume subscription');
      }
    } catch (e) {
      debugPrint('❌ Error resuming subscription: $e');
      rethrow;
    }
  }

  /// Cancel a subscription
  Future<Map<String, dynamic>> cancelSubscription(
    String subscriptionId, {
    String? reason,
    bool immediate = false,
  }) async {
    try {
      final cancelData = {
        if (reason != null) 'reason': reason,
        'immediate': immediate,
      };

      final response = await _apiClient.post(
        '/api/subscriptions/$subscriptionId/cancel',
        body: cancelData,
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to cancel subscription');
      }
    } catch (e) {
      debugPrint('❌ Error canceling subscription: $e');
      rethrow;
    }
  }

  /// Get subscription details
  Future<Map<String, dynamic>> getSubscriptionDetails(
    String subscriptionId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/api/subscriptions/$subscriptionId',
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to fetch subscription details');
      }
    } catch (e) {
      debugPrint('❌ Error fetching subscription details: $e');
      rethrow;
    }
  }

  /// Get subscription delivery history
  Future<List<Map<String, dynamic>>> getSubscriptionDeliveries(
    String subscriptionId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/api/subscriptions/$subscriptionId/deliveries',
      );

      if (_apiClient.isSuccessful(response)) {
        final data = _apiClient.parseResponse(response);
        return List<Map<String, dynamic>>.from(data['deliveries'] ?? []);
      } else {
        throw Exception('Failed to fetch subscription deliveries');
      }
    } catch (e) {
      debugPrint('❌ Error fetching subscription deliveries: $e');
      rethrow;
    }
  }

  /// Get available subscription plans
  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    try {
      debugPrint('📡 Calling GET /api/subscriptions/plans');
      final response = await _apiClient.get('/api/subscriptions/plans');
      debugPrint('📥 Response status: ${response.statusCode}');

      if (_apiClient.isSuccessful(response)) {
        final data = _apiClient.parseResponse(response);
        debugPrint('📦 Parsed data keys: ${data.keys}');

        // The response structure is: {success: true, data: {plans: [...]}}
        // So we need to access data['data']['plans']
        final dataObject = data['data'] as Map<String, dynamic>?;
        debugPrint('📦 Data object keys: ${dataObject?.keys}');
        debugPrint('📦 Plans in data: ${dataObject?['plans']}');

        final plans = List<Map<String, dynamic>>.from(
          dataObject?['plans'] ?? [],
        );
        debugPrint('✅ Returning ${plans.length} plans');
        return plans;
      } else {
        debugPrint('❌ Response not successful: ${response.statusCode}');
        throw Exception('Failed to fetch subscription plans');
      }
    } catch (e) {
      debugPrint('❌ Error fetching subscription plans: $e');
      rethrow;
    }
  }

  /// Skip next delivery
  Future<Map<String, dynamic>> skipNextDelivery(
    String subscriptionId, {
    String? reason,
  }) async {
    try {
      final skipData = {if (reason != null) 'reason': reason};

      final response = await _apiClient.post(
        '/api/subscriptions/$subscriptionId/skip',
        body: skipData,
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to skip delivery');
      }
    } catch (e) {
      debugPrint('❌ Error skipping delivery: $e');
      rethrow;
    }
  }

  /// Admin: Get all subscriptions
  Future<List<Map<String, dynamic>>> getAllSubscriptions({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
      };

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');

      final response = await _apiClient.get(
        '/api/subscriptions/admin/all?$queryString',
      );

      if (_apiClient.isSuccessful(response)) {
        final data = _apiClient.parseResponse(response);
        return List<Map<String, dynamic>>.from(data['subscriptions'] ?? []);
      } else {
        throw Exception('Failed to fetch all subscriptions');
      }
    } catch (e) {
      debugPrint('❌ Error fetching all subscriptions: $e');
      rethrow;
    }
  }

  /// Admin: Get subscription statistics
  Future<Map<String, dynamic>> getAdminSubscriptionStats() async {
    try {
      final response = await _apiClient.get('/api/subscriptions/admin/stats');

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to fetch admin subscription stats');
      }
    } catch (e) {
      debugPrint('❌ Error fetching admin subscription stats: $e');
      rethrow;
    }
  }

  /// Admin: Update subscription status
  Future<Map<String, dynamic>> updateSubscriptionStatus(
    String subscriptionId,
    String status,
  ) async {
    try {
      final response = await _apiClient.put(
        '/api/subscriptions/admin/$subscriptionId/status',
        body: {'status': status},
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to update subscription status');
      }
    } catch (e) {
      debugPrint('❌ Error updating subscription status: $e');
      rethrow;
    }
  }

  /// Admin: Create subscription plan
  Future<Map<String, dynamic>> createSubscriptionPlan(
    Map<String, dynamic> planData,
  ) async {
    try {
      final response = await _apiClient.post(
        '/api/subscriptions/admin/plans',
        body: planData,
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to create subscription plan');
      }
    } catch (e) {
      debugPrint('❌ Error creating subscription plan: $e');
      rethrow;
    }
  }

  /// Admin: Update subscription plan
  Future<Map<String, dynamic>> updateSubscriptionPlan(
    String planId,
    Map<String, dynamic> planData,
  ) async {
    try {
      final response = await _apiClient.put(
        '/api/subscriptions/admin/plans/$planId',
        body: planData,
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to update subscription plan');
      }
    } catch (e) {
      debugPrint('❌ Error updating subscription plan: $e');
      rethrow;
    }
  }

  /// Admin: Delete subscription plan
  Future<bool> deleteSubscriptionPlan(String planId) async {
    try {
      final response = await _apiClient.delete(
        '/api/subscriptions/admin/plans/$planId',
      );

      return _apiClient.isSuccessful(response);
    } catch (e) {
      debugPrint('❌ Error deleting subscription plan: $e');
      rethrow;
    }
  }
}
