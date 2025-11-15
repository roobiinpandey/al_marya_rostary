import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

/// Service for managing loyalty program features
class LoyaltyApiService {
  static final LoyaltyApiService _instance = LoyaltyApiService._internal();
  factory LoyaltyApiService() => _instance;
  LoyaltyApiService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get user's loyalty account
  Future<Map<String, dynamic>> getLoyaltyAccount(String userId) async {
    try {
      final response = await _apiClient.get('/api/loyalty/account/$userId');

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to fetch loyalty account');
      }
    } catch (e) {
      debugPrint('❌ Error fetching loyalty account: $e');
      rethrow;
    }
  }

  /// Get user's loyalty points history
  Future<List<Map<String, dynamic>>> getPointsHistory(String userId) async {
    try {
      final response = await _apiClient.get('/api/loyalty/points/$userId');

      if (_apiClient.isSuccessful(response)) {
        final data = _apiClient.parseResponse(response);
        return List<Map<String, dynamic>>.from(data['points'] ?? []);
      } else {
        throw Exception('Failed to fetch points history');
      }
    } catch (e) {
      debugPrint('❌ Error fetching points history: $e');
      rethrow;
    }
  }

  /// Award points to user (admin function)
  Future<Map<String, dynamic>> awardPoints({
    required String userId,
    required int points,
    required String reason,
    String? orderId,
  }) async {
    try {
      final pointData = {
        'userId': userId,
        'points': points,
        'reason': reason,
        if (orderId != null) 'orderId': orderId,
      };

      final response = await _apiClient.post(
        '/api/loyalty/points/award',
        body: pointData,
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to award points');
      }
    } catch (e) {
      debugPrint('❌ Error awarding points: $e');
      rethrow;
    }
  }

  /// Get all loyalty tiers
  Future<List<Map<String, dynamic>>> getLoyaltyTiers() async {
    try {
      final response = await _apiClient.get('/api/loyalty/tiers');

      if (_apiClient.isSuccessful(response)) {
        final data = _apiClient.parseResponse(response);
        return List<Map<String, dynamic>>.from(data['tiers'] ?? []);
      } else {
        throw Exception('Failed to fetch loyalty tiers');
      }
    } catch (e) {
      debugPrint('❌ Error fetching loyalty tiers: $e');
      rethrow;
    }
  }

  /// Get available rewards for user
  Future<List<Map<String, dynamic>>> getAvailableRewards(String userId) async {
    try {
      final response = await _apiClient.get(
        '/api/loyalty/rewards?userId=$userId',
      );

      if (_apiClient.isSuccessful(response)) {
        final data = _apiClient.parseResponse(response);
        return List<Map<String, dynamic>>.from(data['rewards'] ?? []);
      } else {
        throw Exception('Failed to fetch available rewards');
      }
    } catch (e) {
      debugPrint('❌ Error fetching available rewards: $e');
      rethrow;
    }
  }

  /// Redeem a reward
  Future<Map<String, dynamic>> redeemReward({
    required String userId,
    required String rewardId,
    required int pointsRequired,
  }) async {
    try {
      final redeemData = {
        'userId': userId,
        'rewardId': rewardId,
        'pointsRequired': pointsRequired,
      };

      final response = await _apiClient.post(
        '/api/loyalty/redeem',
        body: redeemData,
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to redeem reward');
      }
    } catch (e) {
      debugPrint('❌ Error redeeming reward: $e');
      rethrow;
    }
  }

  /// Get user's redemption history
  Future<List<Map<String, dynamic>>> getRedemptionHistory(String userId) async {
    try {
      final response = await _apiClient.get('/api/loyalty/redemptions/$userId');

      if (_apiClient.isSuccessful(response)) {
        final data = _apiClient.parseResponse(response);
        return List<Map<String, dynamic>>.from(data['redemptions'] ?? []);
      } else {
        throw Exception('Failed to fetch redemption history');
      }
    } catch (e) {
      debugPrint('❌ Error fetching redemption history: $e');
      rethrow;
    }
  }

  /// Get loyalty program overview
  Future<Map<String, dynamic>> getLoyaltyProgram() async {
    try {
      final response = await _apiClient.get('/api/loyalty/program');

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to fetch loyalty program info');
      }
    } catch (e) {
      debugPrint('❌ Error fetching loyalty program: $e');
      rethrow;
    }
  }

  /// Admin: Get loyalty statistics
  Future<Map<String, dynamic>> getAdminLoyaltyStats() async {
    try {
      final response = await _apiClient.get('/api/loyalty/admin/stats');

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to fetch admin loyalty stats');
      }
    } catch (e) {
      debugPrint('❌ Error fetching admin loyalty stats: $e');
      rethrow;
    }
  }

  /// Admin: Get all loyalty members
  Future<List<Map<String, dynamic>>> getAllLoyaltyMembers({
    int page = 1,
    int limit = 20,
    String? tier,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (tier != null) 'tier': tier,
      };

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');

      final response = await _apiClient.get(
        '/api/loyalty/admin/members?$queryString',
      );

      if (_apiClient.isSuccessful(response)) {
        final data = _apiClient.parseResponse(response);
        return List<Map<String, dynamic>>.from(data['members'] ?? []);
      } else {
        throw Exception('Failed to fetch loyalty members');
      }
    } catch (e) {
      debugPrint('❌ Error fetching loyalty members: $e');
      rethrow;
    }
  }

  /// Admin: Create or update loyalty tier
  Future<Map<String, dynamic>> saveLoyaltyTier(
    Map<String, dynamic> tierData,
  ) async {
    try {
      final response = await _apiClient.post(
        '/api/loyalty/admin/tiers',
        body: tierData,
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to save loyalty tier');
      }
    } catch (e) {
      debugPrint('❌ Error saving loyalty tier: $e');
      rethrow;
    }
  }

  /// Admin: Delete loyalty tier
  Future<bool> deleteLoyaltyTier(String tierId) async {
    try {
      final response = await _apiClient.delete(
        '/api/loyalty/admin/tiers/$tierId',
      );

      return _apiClient.isSuccessful(response);
    } catch (e) {
      debugPrint('❌ Error deleting loyalty tier: $e');
      rethrow;
    }
  }
}
