import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

/// Service for managing referral program features
class ReferralsApiService {
  static final ReferralsApiService _instance = ReferralsApiService._internal();
  factory ReferralsApiService() => _instance;
  ReferralsApiService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get user's referrals
  Future<List<Map<String, dynamic>>> getUserReferrals(String userId) async {
    try {
      final response = await _apiClient.get('/api/referrals/user/$userId');

      if (_apiClient.isSuccessful(response)) {
        final data = _apiClient.parseResponse(response);
        return List<Map<String, dynamic>>.from(data['referrals'] ?? []);
      } else {
        throw Exception('Failed to fetch user referrals');
      }
    } catch (e) {
      debugPrint('❌ Error fetching user referrals: $e');
      rethrow;
    }
  }

  /// Create a new referral
  Future<Map<String, dynamic>> createReferral({
    required String referrerId,
    String? refereeEmail,
    String? refereePhone,
  }) async {
    try {
      final referralData = {
        'referrerId': referrerId,
        if (refereeEmail != null) 'refereeEmail': refereeEmail,
        if (refereePhone != null) 'refereePhone': refereePhone,
      };

      final response = await _apiClient.post(
        '/api/referrals/create',
        body: referralData,
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to create referral');
      }
    } catch (e) {
      debugPrint('❌ Error creating referral: $e');
      rethrow;
    }
  }

  /// Track referral click/use
  Future<Map<String, dynamic>> trackReferralClick(String referralCode) async {
    try {
      final response = await _apiClient.post(
        '/api/referrals/click/$referralCode',
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to track referral click');
      }
    } catch (e) {
      debugPrint('❌ Error tracking referral click: $e');
      rethrow;
    }
  }

  /// Get referral program information
  Future<Map<String, dynamic>> getReferralProgram() async {
    try {
      final response = await _apiClient.get('/api/referrals/program');

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to fetch referral program info');
      }
    } catch (e) {
      debugPrint('❌ Error fetching referral program: $e');
      rethrow;
    }
  }

  /// Get referral by code
  Future<Map<String, dynamic>?> getReferralByCode(String code) async {
    try {
      final response = await _apiClient.get('/api/referrals/code/$code');

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else if (response.statusCode == 404) {
        return null; // Referral code not found
      } else {
        throw Exception('Failed to fetch referral by code');
      }
    } catch (e) {
      debugPrint('❌ Error fetching referral by code: $e');
      rethrow;
    }
  }

  /// Complete referral (when referee signs up/purchases)
  Future<Map<String, dynamic>> completeReferral({
    required String referralCode,
    required String refereeId,
    String? orderId,
  }) async {
    try {
      final completionData = {
        'referralCode': referralCode,
        'refereeId': refereeId,
        if (orderId != null) 'orderId': orderId,
      };

      final response = await _apiClient.post(
        '/api/referrals/complete',
        body: completionData,
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to complete referral');
      }
    } catch (e) {
      debugPrint('❌ Error completing referral: $e');
      rethrow;
    }
  }

  /// Get referral statistics for user
  Future<Map<String, dynamic>> getUserReferralStats(String userId) async {
    try {
      final response = await _apiClient.get(
        '/api/referrals/user/$userId/stats',
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to fetch user referral stats');
      }
    } catch (e) {
      debugPrint('❌ Error fetching user referral stats: $e');
      rethrow;
    }
  }

  /// Get user's referral earnings
  Future<List<Map<String, dynamic>>> getUserReferralEarnings(
    String userId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/api/referrals/user/$userId/earnings',
      );

      if (_apiClient.isSuccessful(response)) {
        final data = _apiClient.parseResponse(response);
        return List<Map<String, dynamic>>.from(data['earnings'] ?? []);
      } else {
        throw Exception('Failed to fetch user referral earnings');
      }
    } catch (e) {
      debugPrint('❌ Error fetching user referral earnings: $e');
      rethrow;
    }
  }

  /// Admin: Get all referrals
  Future<List<Map<String, dynamic>>> getAllReferrals({
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
        '/api/referrals/admin/all?$queryString',
      );

      if (_apiClient.isSuccessful(response)) {
        final data = _apiClient.parseResponse(response);
        return List<Map<String, dynamic>>.from(data['referrals'] ?? []);
      } else {
        throw Exception('Failed to fetch all referrals');
      }
    } catch (e) {
      debugPrint('❌ Error fetching all referrals: $e');
      rethrow;
    }
  }

  /// Admin: Get referral statistics
  Future<Map<String, dynamic>> getAdminReferralStats() async {
    try {
      final response = await _apiClient.get('/api/referrals/admin/stats');

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to fetch admin referral stats');
      }
    } catch (e) {
      debugPrint('❌ Error fetching admin referral stats: $e');
      rethrow;
    }
  }

  /// Admin: Update referral status
  Future<Map<String, dynamic>> updateReferralStatus(
    String referralId,
    String status,
  ) async {
    try {
      final response = await _apiClient.put(
        '/api/referrals/admin/$referralId/status',
        body: {'status': status},
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to update referral status');
      }
    } catch (e) {
      debugPrint('❌ Error updating referral status: $e');
      rethrow;
    }
  }

  /// Admin: Delete referral
  Future<bool> deleteReferral(String referralId) async {
    try {
      final response = await _apiClient.delete(
        '/api/referrals/admin/$referralId',
      );

      return _apiClient.isSuccessful(response);
    } catch (e) {
      debugPrint('❌ Error deleting referral: $e');
      rethrow;
    }
  }
}
