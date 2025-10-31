import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/gift_set_model.dart';
import '../constants/app_constants.dart';

/// GiftSetApiService handles all gift set related operations
///
/// Provides comprehensive gift set management:
/// - Fetch all gift sets with filtering and pagination
/// - Get featured and popular gift sets
/// - Get gift sets by occasion, audience, price range
/// - Manage gift set reviews and analytics
/// - Search gift sets functionality
class GiftSetApiService {
  final Dio _dio;

  GiftSetApiService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    _dio.options.validateStatus = (status) => status! < 500;
  }

  /// Get all gift sets with filtering and pagination
  Future<Map<String, dynamic>> getGiftSets({
    int page = 1,
    int limit = 20,
    String? occasion,
    String? targetAudience,
    double? minPrice,
    double? maxPrice,
    bool? featured,
    bool? popular,
    bool? available,
    String? search,
    String sortBy = 'displayOrder',
    String sortOrder = 'asc',
  }) async {
    try {
      debugPrint('🎁 GiftSetApiService: Fetching gift sets');

      // Build query parameters
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (occasion != null) queryParams['occasion'] = occasion;
      if (targetAudience != null)
        queryParams['targetAudience'] = targetAudience;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (featured != null) queryParams['featured'] = featured;
      if (popular != null) queryParams['popular'] = popular;
      if (available != null) queryParams['available'] = available;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      debugPrint('🌐 API Request: GET ${AppConstants.baseUrl}/api/gift-sets');
      debugPrint('📤 Query params: $queryParams');

      final response = await _dio.get(
        '/api/gift-sets',
        queryParameters: queryParams,
        options: Options(headers: _getHeaders()),
      );

      debugPrint('✅ API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true) {
          debugPrint('✅ GiftSetApiService: Successfully parsed response');
          debugPrint(
            '📊 Gift sets count: ${(data['data'] as List?)?.length ?? 0}',
          );

          return {
            'giftSets': (data['data'] as List<dynamic>? ?? [])
                .map((json) => GiftSetModel.fromJson(json))
                .toList(),
            'pagination': data['pagination'] ?? {},
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch gift sets');
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: Failed to fetch gift sets',
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ GiftSetApiService: Dio error fetching gift sets: ${e.message}',
      );
      debugPrint('📛 Status: ${e.response?.statusCode}');
      debugPrint('📛 Data: ${e.response?.data}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ GiftSetApiService: Error fetching gift sets: $e');
      throw Exception('Error fetching gift sets: $e');
    }
  }

  /// Get gift set by ID
  Future<GiftSetModel> getGiftSetById(String id) async {
    try {
      debugPrint('🎁 GiftSetApiService: Fetching gift set by ID: $id');

      final response = await _dio.get(
        '/api/gift-sets/$id',
        options: Options(headers: _getHeaders()),
      );

      debugPrint('✅ API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true) {
          return GiftSetModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch gift set');
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: Failed to fetch gift set',
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ GiftSetApiService: Dio error fetching gift set: ${e.message}',
      );
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ GiftSetApiService: Error fetching gift set: $e');
      throw Exception('Error fetching gift set: $e');
    }
  }

  /// Get featured gift sets
  Future<List<GiftSetModel>> getFeaturedGiftSets({int limit = 10}) async {
    try {
      debugPrint('🎁 GiftSetApiService: Fetching featured gift sets');

      final response = await _dio.get(
        '/api/gift-sets/featured',
        queryParameters: {'limit': limit},
        options: Options(headers: _getHeaders()),
      );

      debugPrint('✅ API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true) {
          return (data['data'] as List<dynamic>)
              .map((json) => GiftSetModel.fromJson(json))
              .toList();
        } else {
          throw Exception(
            data['message'] ?? 'Failed to fetch featured gift sets',
          );
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: Failed to fetch featured gift sets',
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ GiftSetApiService: Dio error fetching featured gift sets: ${e.message}',
      );
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ GiftSetApiService: Error fetching featured gift sets: $e');
      throw Exception('Error fetching featured gift sets: $e');
    }
  }

  /// Get popular gift sets
  Future<List<GiftSetModel>> getPopularGiftSets({int limit = 10}) async {
    try {
      debugPrint('🎁 GiftSetApiService: Fetching popular gift sets');

      final response = await _dio.get(
        '/api/gift-sets/popular',
        queryParameters: {'limit': limit},
        options: Options(headers: _getHeaders()),
      );

      debugPrint('✅ API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true) {
          return (data['data'] as List<dynamic>)
              .map((json) => GiftSetModel.fromJson(json))
              .toList();
        } else {
          throw Exception(
            data['message'] ?? 'Failed to fetch popular gift sets',
          );
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: Failed to fetch popular gift sets',
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ GiftSetApiService: Dio error fetching popular gift sets: ${e.message}',
      );
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ GiftSetApiService: Error fetching popular gift sets: $e');
      throw Exception('Error fetching popular gift sets: $e');
    }
  }

  /// Get gift sets by occasion
  Future<List<GiftSetModel>> getGiftSetsByOccasion(
    String occasion, {
    int limit = 20,
  }) async {
    try {
      debugPrint(
        '🎁 GiftSetApiService: Fetching gift sets by occasion: $occasion',
      );

      final response = await _dio.get(
        '/api/gift-sets/occasion/$occasion',
        queryParameters: {'limit': limit},
        options: Options(headers: _getHeaders()),
      );

      debugPrint('✅ API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true) {
          return (data['data'] as List<dynamic>)
              .map((json) => GiftSetModel.fromJson(json))
              .toList();
        } else {
          throw Exception(
            data['message'] ?? 'Failed to fetch gift sets by occasion',
          );
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: Failed to fetch gift sets by occasion',
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ GiftSetApiService: Dio error fetching gift sets by occasion: ${e.message}',
      );
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint(
        '❌ GiftSetApiService: Error fetching gift sets by occasion: $e',
      );
      throw Exception('Error fetching gift sets by occasion: $e');
    }
  }

  /// Get gift sets by target audience
  Future<List<GiftSetModel>> getGiftSetsByAudience(
    String audience, {
    int limit = 20,
  }) async {
    try {
      debugPrint(
        '🎁 GiftSetApiService: Fetching gift sets by audience: $audience',
      );

      final response = await _dio.get(
        '/api/gift-sets/audience/$audience',
        queryParameters: {'limit': limit},
        options: Options(headers: _getHeaders()),
      );

      debugPrint('✅ API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true) {
          return (data['data'] as List<dynamic>)
              .map((json) => GiftSetModel.fromJson(json))
              .toList();
        } else {
          throw Exception(
            data['message'] ?? 'Failed to fetch gift sets by audience',
          );
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: Failed to fetch gift sets by audience',
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ GiftSetApiService: Dio error fetching gift sets by audience: ${e.message}',
      );
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint(
        '❌ GiftSetApiService: Error fetching gift sets by audience: $e',
      );
      throw Exception('Error fetching gift sets by audience: $e');
    }
  }

  /// Get gift sets by price range
  Future<List<GiftSetModel>> getGiftSetsByPriceRange(
    double minPrice,
    double maxPrice,
  ) async {
    try {
      debugPrint(
        '🎁 GiftSetApiService: Fetching gift sets by price range: $minPrice - $maxPrice',
      );

      final response = await _dio.get(
        '/api/gift-sets',
        queryParameters: {
          'minPrice': minPrice,
          'maxPrice': maxPrice,
          'available': true,
        },
        options: Options(headers: _getHeaders()),
      );

      debugPrint('✅ API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true) {
          return (data['data'] as List<dynamic>)
              .map((json) => GiftSetModel.fromJson(json))
              .toList();
        } else {
          throw Exception(
            data['message'] ?? 'Failed to fetch gift sets by price range',
          );
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: Failed to fetch gift sets by price range',
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ GiftSetApiService: Dio error fetching gift sets by price range: ${e.message}',
      );
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint(
        '❌ GiftSetApiService: Error fetching gift sets by price range: $e',
      );
      throw Exception('Error fetching gift sets by price range: $e');
    }
  }

  /// Add review to gift set
  Future<void> addReview(
    String giftSetId, {
    required int rating,
    String? comment,
    String? occasion,
    String? recipientType,
    bool wouldRecommend = true,
  }) async {
    try {
      debugPrint('🎁 GiftSetApiService: Adding review to gift set: $giftSetId');

      final reviewData = {
        'rating': rating,
        'comment': comment,
        'occasion': occasion,
        'recipientType': recipientType,
        'wouldRecommend': wouldRecommend,
      };

      final response = await _dio.post(
        '/api/gift-sets/$giftSetId/review',
        data: reviewData,
        options: Options(headers: _getHeaders()),
      );

      debugPrint('✅ API Response: ${response.statusCode}');

      if (response.statusCode != 200) {
        final data = response.data as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Failed to add review');
      }
    } on DioException catch (e) {
      debugPrint('❌ GiftSetApiService: Dio error adding review: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ GiftSetApiService: Error adding review: $e');
      throw Exception('Error adding review: $e');
    }
  }

  /// Increment view count for analytics
  Future<void> incrementViews(String giftSetId) async {
    try {
      // This will be handled automatically by the backend when fetching by ID
      await getGiftSetById(giftSetId);
    } catch (e) {
      // Silently fail for analytics
      debugPrint('❌ GiftSetApiService: Error incrementing views: $e');
    }
  }

  /// Get standard headers for API requests
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'QahwatAlEmarat/1.0.0 Flutter Mobile App',
      'Cache-Control': 'no-cache',
    };
  }
}
