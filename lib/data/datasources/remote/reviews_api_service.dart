import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

/// Service for managing product reviews
class ReviewsApiService {
  static final ReviewsApiService _instance = ReviewsApiService._internal();
  factory ReviewsApiService() => _instance;
  ReviewsApiService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get reviews for a specific product
  Future<List<Map<String, dynamic>>> getProductReviews(String productId) async {
    try {
      final response = await _apiClient.get('/api/reviews/product/$productId');

      if (_apiClient.isSuccessful(response)) {
        final data = _apiClient.parseResponse(response);
        return List<Map<String, dynamic>>.from(data['reviews'] ?? []);
      } else {
        throw Exception('Failed to fetch product reviews');
      }
    } catch (e) {
      debugPrint('❌ Error fetching product reviews: $e');
      rethrow;
    }
  }

  /// Submit a new review for a product
  Future<Map<String, dynamic>> submitReview({
    required String productId,
    required String productName,
    required int rating,
    required String comment,
    String? userId,
    String? userName,
    String? userEmail,
  }) async {
    try {
      final reviewData = {
        'productId': productId,
        'productName': productName,
        'rating': rating,
        'comment': comment,
        if (userId != null) 'userId': userId,
        if (userName != null) 'userName': userName,
        if (userEmail != null) 'userEmail': userEmail,
      };

      final response = await _apiClient.post('/api/reviews', body: reviewData);

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to submit review');
      }
    } catch (e) {
      debugPrint('❌ Error submitting review: $e');
      rethrow;
    }
  }

  /// Mark a review as helpful
  Future<Map<String, dynamic>> markReviewHelpful(String reviewId) async {
    try {
      final response = await _apiClient.post('/api/reviews/$reviewId/helpful');

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to mark review as helpful');
      }
    } catch (e) {
      debugPrint('❌ Error marking review as helpful: $e');
      rethrow;
    }
  }

  /// Get reviews by a specific user
  Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    try {
      final response = await _apiClient.get('/api/reviews/user/$userId');

      if (_apiClient.isSuccessful(response)) {
        final data = _apiClient.parseResponse(response);
        return List<Map<String, dynamic>>.from(data['reviews'] ?? []);
      } else {
        throw Exception('Failed to fetch user reviews');
      }
    } catch (e) {
      debugPrint('❌ Error fetching user reviews: $e');
      rethrow;
    }
  }

  /// Get review statistics for a product
  Future<Map<String, dynamic>> getReviewStats(String productId) async {
    try {
      final response = await _apiClient.get(
        '/api/reviews/product/$productId/stats',
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to fetch review statistics');
      }
    } catch (e) {
      debugPrint('❌ Error fetching review stats: $e');
      rethrow;
    }
  }

  /// Admin: Get all reviews (with moderation status)
  Future<List<Map<String, dynamic>>> getAllReviews({
    String? status,
    int page = 1,
    int limit = 20,
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
        '/api/reviews/admin/all?$queryString',
      );

      if (_apiClient.isSuccessful(response)) {
        final data = _apiClient.parseResponse(response);
        return List<Map<String, dynamic>>.from(data['reviews'] ?? []);
      } else {
        throw Exception('Failed to fetch all reviews');
      }
    } catch (e) {
      debugPrint('❌ Error fetching all reviews: $e');
      rethrow;
    }
  }

  /// Admin: Moderate a review (approve/reject)
  Future<Map<String, dynamic>> moderateReview(
    String reviewId,
    String action, // 'approve' or 'reject'
  ) async {
    try {
      final response = await _apiClient.post(
        '/api/reviews/admin/$reviewId/moderate',
        body: {'action': action},
      );

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to moderate review');
      }
    } catch (e) {
      debugPrint('❌ Error moderating review: $e');
      rethrow;
    }
  }

  /// Admin: Delete a review
  Future<bool> deleteReview(String reviewId) async {
    try {
      final response = await _apiClient.delete('/api/reviews/admin/$reviewId');

      return _apiClient.isSuccessful(response);
    } catch (e) {
      debugPrint('❌ Error deleting review: $e');
      rethrow;
    }
  }

  /// Admin: Get review statistics for dashboard
  Future<Map<String, dynamic>> getAdminReviewStats() async {
    try {
      final response = await _apiClient.get('/api/reviews/admin/stats');

      if (_apiClient.isSuccessful(response)) {
        return _apiClient.parseResponse(response);
      } else {
        throw Exception('Failed to fetch admin review stats');
      }
    } catch (e) {
      debugPrint('❌ Error fetching admin review stats: $e');
      rethrow;
    }
  }
}
