import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/slider_model.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// Slider API Service
/// Handles all slider/banner-related API calls
class SliderApiService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final String baseUrl;

  SliderApiService({Dio? dio, FlutterSecureStorage? storage, String? baseUrl})
    : _dio = dio ?? Dio(),
      _storage = storage ?? const FlutterSecureStorage(),
      baseUrl = baseUrl ?? AppConstants.baseUrl {
    _configureDio();
  }

  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add interceptor for auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          AppLogger.error('❌ API Error: ${error.message}');
          if (error.response != null) {
            AppLogger.error('📛 Status: ${error.response?.statusCode}');
            AppLogger.error('📛 Data: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ==================== FETCH OPERATIONS ====================

  /// Fetch all sliders with optional filters
  Future<Map<String, dynamic>> fetchAllSliders({
    int page = 1,
    int limit = 50,
    String? search,
    bool? isActive,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (isActive != null) {
        queryParams['isActive'] = isActive;
      }
      if (sortBy != null) {
        queryParams['sortBy'] = sortBy;
      }
      if (sortOrder != null) {
        queryParams['sortOrder'] = sortOrder;
      }

      AppLogger.network(
        '🌐 SliderApiService: Fetching sliders with params: $queryParams',
      );

      final response = await _dio.get(
        '/api/sliders',
        queryParameters: queryParams,
      );

      AppLogger.success(
        '✅ SliderApiService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List;
        final sliders = data
            .map((json) => SliderModel.fromJson(json as Map<String, dynamic>))
            .toList();

        AppLogger.debug(
          '✅ SliderApiService: Successfully parsed ${sliders.length} sliders',
        );

        return {
          'sliders': sliders,
          'pagination':
              response.data['pagination'] ??
              {'page': page, 'pages': 1, 'total': sliders.length},
        };
      } else {
        throw Exception('Failed to fetch sliders: ${response.data['message']}');
      }
    } on DioException catch (e) {
      AppLogger.error('❌ DioException in fetchAllSliders: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      AppLogger.error('❌ Exception in fetchAllSliders: $e');
      throw Exception('Error fetching sliders: $e');
    }
  }

  /// Fetch a single slider by ID
  Future<SliderModel> fetchSlider(String id) async {
    try {
      AppLogger.network('🌐 SliderApiService: Fetching slider $id');

      final response = await _dio.get('/api/sliders/$id');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return SliderModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to fetch slider: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching slider: $e');
    }
  }

  /// Fetch active sliders only
  Future<List<SliderModel>> fetchActiveSliders({int limit = 10}) async {
    try {
      AppLogger.network('🌐 SliderApiService: Fetching active sliders');

      final response = await _dio.get(
        '/api/sliders',
        queryParameters: {'isActive': true, 'limit': limit},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List;
        return data
            .map((json) => SliderModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch active sliders');
      }
    } catch (e) {
      AppLogger.error('❌ Error fetching active sliders: $e');
      return [];
    }
  }

  // ==================== CREATE OPERATION ====================

  /// Create a new slider
  Future<SliderModel> createSlider({
    required String title,
    required String imagePath,
    String? description,
    String? mobileImagePath,
    String? buttonText,
    String? buttonLink,
    String? backgroundColor,
    String? textColor,
    String? position,
    int? displayOrder,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? targetAudience,
    List<String>? categories,
    List<String>? tags,
    String? altText,
  }) async {
    try {
      AppLogger.network('🌐 SliderApiService: Creating slider');

      // Create FormData for file upload
      final formData = FormData.fromMap({
        'title': title,
        if (description != null) 'description': description,
        'image': await MultipartFile.fromFile(imagePath),
        if (mobileImagePath != null)
          'mobileImage': await MultipartFile.fromFile(mobileImagePath),
        if (buttonText != null) 'buttonText': buttonText,
        if (buttonLink != null) 'buttonLink': buttonLink,
        if (backgroundColor != null) 'backgroundColor': backgroundColor,
        if (textColor != null) 'textColor': textColor,
        if (position != null) 'position': position,
        if (displayOrder != null) 'displayOrder': displayOrder,
        if (isActive != null) 'isActive': isActive,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (targetAudience != null && targetAudience.isNotEmpty)
          'targetAudience': targetAudience,
        if (categories != null && categories.isNotEmpty)
          'categories': categories,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (altText != null) 'altText': altText,
      });

      final response = await _dio.post('/api/sliders', data: formData);

      if (response.statusCode == 201 && response.data['success'] == true) {
        AppLogger.success('✅ SliderApiService: Slider created successfully');
        return SliderModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to create slider: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      AppLogger.error('❌ Exception in createSlider: $e');
      throw Exception('Error creating slider: $e');
    }
  }

  // ==================== UPDATE OPERATION ====================

  /// Update an existing slider
  Future<SliderModel> updateSlider({
    required String id,
    String? title,
    String? imagePath,
    String? description,
    String? mobileImagePath,
    String? buttonText,
    String? buttonLink,
    String? backgroundColor,
    String? textColor,
    String? position,
    int? displayOrder,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? targetAudience,
    List<String>? categories,
    List<String>? tags,
    String? altText,
  }) async {
    try {
      AppLogger.network('🌐 SliderApiService: Updating slider $id');

      final formData = FormData.fromMap({
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath),
        if (mobileImagePath != null)
          'mobileImage': await MultipartFile.fromFile(mobileImagePath),
        if (buttonText != null) 'buttonText': buttonText,
        if (buttonLink != null) 'buttonLink': buttonLink,
        if (backgroundColor != null) 'backgroundColor': backgroundColor,
        if (textColor != null) 'textColor': textColor,
        if (position != null) 'position': position,
        if (displayOrder != null) 'displayOrder': displayOrder,
        if (isActive != null) 'isActive': isActive,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (targetAudience != null) 'targetAudience': targetAudience,
        if (categories != null) 'categories': categories,
        if (tags != null) 'tags': tags,
        if (altText != null) 'altText': altText,
      });

      final response = await _dio.put('/api/sliders/$id', data: formData);

      if (response.statusCode == 200 && response.data['success'] == true) {
        AppLogger.success('✅ SliderApiService: Slider updated successfully');
        return SliderModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to update slider: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      AppLogger.error('❌ Exception in updateSlider: $e');
      throw Exception('Error updating slider: $e');
    }
  }

  // ==================== DELETE OPERATION ====================

  /// Delete a slider
  Future<bool> deleteSlider(String id) async {
    try {
      AppLogger.network('🌐 SliderApiService: Deleting slider $id');

      final response = await _dio.delete('/api/sliders/$id');

      if (response.statusCode == 200 && response.data['success'] == true) {
        AppLogger.success('✅ SliderApiService: Slider deleted successfully');
        return true;
      } else {
        throw Exception('Failed to delete slider: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      AppLogger.error('❌ Exception in deleteSlider: $e');
      throw Exception('Error deleting slider: $e');
    }
  }

  // ==================== TOGGLE ACTIVE STATUS ====================

  /// Toggle slider active status
  Future<bool> toggleActiveStatus(String id, bool isActive) async {
    try {
      AppLogger.network(
        '🌐 SliderApiService: Toggling slider $id to $isActive',
      );

      final response = await _dio.patch(
        '/api/sliders/$id',
        data: {'isActive': isActive},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        AppLogger.success('✅ SliderApiService: Status toggled successfully');
        return true;
      } else {
        throw Exception('Failed to toggle status: ${response.data['message']}');
      }
    } catch (e) {
      AppLogger.error('❌ Exception in toggleActiveStatus: $e');
      return false;
    }
  }

  // ==================== ANALYTICS ====================

  /// Track slider click
  Future<bool> trackClick(String id) async {
    try {
      await _dio.post('/api/sliders/$id/click');
      return true;
    } catch (e) {
      AppLogger.error('❌ Exception in trackClick: $e');
      return false;
    }
  }

  /// Track slider view
  Future<bool> trackView(String id) async {
    try {
      await _dio.post('/api/sliders/$id/view');
      return true;
    } catch (e) {
      AppLogger.error('❌ Exception in trackView: $e');
      return false;
    }
  }

  // ==================== STATISTICS ====================

  /// Get slider statistics
  Future<Map<String, dynamic>> getSliderStats() async {
    try {
      AppLogger.network('🌐 SliderApiService: Fetching slider statistics');

      final response = await _dio.get('/api/sliders/stats');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch stats');
      }
    } catch (e) {
      AppLogger.error('❌ Exception in getSliderStats: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
        'scheduled': 0,
        'expired': 0,
      };
    }
  }

  // ==================== UPDATE DISPLAY ORDER ====================

  /// Update display order of multiple sliders
  Future<bool> updateDisplayOrder(List<Map<String, dynamic>> updates) async {
    try {
      AppLogger.debug(
        '🌐 SliderApiService: Updating display order for ${updates.length} sliders',
      );

      final response = await _dio.patch(
        '/api/sliders/reorder',
        data: {'updates': updates},
      );

      if (response.statusCode == 200) {
        AppLogger.success(
          '✅ SliderApiService: Display order updated successfully',
        );
        return true;
      } else {
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Exception in updateDisplayOrder: $e');
      return false;
    }
  }
}
