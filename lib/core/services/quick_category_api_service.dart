import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/quick_category_model.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// Quick Category API Service
/// Handles all quick category-related API calls
class QuickCategoryApiService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final String baseUrl;

  QuickCategoryApiService({
    Dio? dio,
    FlutterSecureStorage? storage,
    String? baseUrl,
  }) : _dio = dio ?? Dio(),
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
          AppLogger.error('❌ QuickCategory API Error: ${error.message}');
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

  /// Fetch all quick categories (Admin)
  Future<Map<String, dynamic>> fetchAllQuickCategories({
    int page = 1,
    int limit = 50,
    String? search,
    bool? isActive,
    String? tag,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (isActive != null) {
        queryParams['active'] = isActive;
      }
      if (tag != null && tag.isNotEmpty) {
        queryParams['tag'] = tag;
      }

      AppLogger.debug(
        '🌐 QuickCategoryApiService: Fetching quick categories with params: $queryParams',
      );

      final response = await _dio.get(
        '/api/quick-categories',
        queryParameters: queryParams,
      );

      AppLogger.debug(
        '✅ QuickCategoryApiService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Handle null data field
        final data = response.data['data'];
        if (data == null) {
          AppLogger.debug(
            '⚠️ QuickCategoryApiService: Data field is null, returning empty list',
          );
          return {
            'quickCategories': <QuickCategoryModel>[],
            'pagination': response.data['pagination'] ?? {},
          };
        }

        final dataList = data as List;
        final quickCategories = dataList
            .map(
              (json) =>
                  QuickCategoryModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        AppLogger.debug(
          '✅ QuickCategoryApiService: Successfully parsed ${quickCategories.length} quick categories',
        );

        return {
          'quickCategories': quickCategories,
          'pagination': response.data['pagination'] ?? {},
        };
      } else {
        throw Exception(
          'Failed to fetch quick categories: ${response.data['message']}',
        );
      }
    } catch (e) {
      AppLogger.error('❌ QuickCategoryApiService: Error fetching quick categories: $e');
      rethrow;
    }
  }

  /// Fetch active quick categories (Public)
  Future<List<QuickCategoryModel>> fetchActiveQuickCategories({
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};

      AppLogger.network('🌐 QuickCategoryApiService: Fetching active quick categories');

      final response = await _dio.get(
        '/api/quick-categories/active',
        queryParameters: queryParams,
      );

      AppLogger.debug(
        '✅ QuickCategoryApiService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Handle null data field
        final data = response.data['data'];
        if (data == null) {
          AppLogger.debug(
            '⚠️ QuickCategoryApiService: Data field is null, returning empty list',
          );
          return [];
        }

        final dataList = data as List;
        final quickCategories = dataList
            .map(
              (json) =>
                  QuickCategoryModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        AppLogger.debug(
          '✅ QuickCategoryApiService: Successfully parsed ${quickCategories.length} active quick categories',
        );

        return quickCategories;
      } else {
        throw Exception(
          'Failed to fetch active quick categories: ${response.data['message']}',
        );
      }
    } catch (e) {
      AppLogger.debug(
        '❌ QuickCategoryApiService: Error fetching active quick categories: $e',
      );
      rethrow;
    }
  }

  /// Fetch single quick category
  Future<QuickCategoryModel> fetchQuickCategory(String id) async {
    try {
      AppLogger.network('🌐 QuickCategoryApiService: Fetching quick category: $id');

      final response = await _dio.get('/api/quick-categories/$id');

      AppLogger.debug(
        '✅ QuickCategoryApiService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final quickCategory = QuickCategoryModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );

        AppLogger.debug(
          '✅ QuickCategoryApiService: Successfully parsed quick category: ${quickCategory.title}',
        );

        return quickCategory;
      } else {
        throw Exception(
          'Failed to fetch quick category: ${response.data['message']}',
        );
      }
    } catch (e) {
      AppLogger.error('❌ QuickCategoryApiService: Error fetching quick category: $e');
      rethrow;
    }
  }

  // ==================== CRUD OPERATIONS ====================

  /// Create new quick category
  Future<QuickCategoryModel> createQuickCategory({
    required String title,
    required String subtitle,
    required String color,
    String? imageUrl,
    String? imageFilePath,
    int? displayOrder,
    bool isActive = true,
    String linkTo = 'none',
    String linkValue = '',
    String description = '',
    List<String> tags = const [],
  }) async {
    try {
      AppLogger.network('🌐 QuickCategoryApiService: Creating quick category: $title');

      FormData formData = FormData.fromMap({
        'title': title,
        'subtitle': subtitle,
        'color': color,
        'isActive': isActive,
        'linkTo': linkTo,
        'linkValue': linkValue,
        'description': description,
        'tags': tags,
      });

      if (displayOrder != null) {
        formData.fields.add(MapEntry('displayOrder', displayOrder.toString()));
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        formData.fields.add(MapEntry('imageUrl', imageUrl));
      }

      if (imageFilePath != null && imageFilePath.isNotEmpty) {
        formData.files.add(
          MapEntry('image', await MultipartFile.fromFile(imageFilePath)),
        );
      }

      final response = await _dio.post('/api/quick-categories', data: formData);

      AppLogger.debug(
        '✅ QuickCategoryApiService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        final quickCategory = QuickCategoryModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );

        AppLogger.debug(
          '✅ QuickCategoryApiService: Successfully created quick category: ${quickCategory.title}',
        );

        return quickCategory;
      } else {
        throw Exception(
          'Failed to create quick category: ${response.data['message']}',
        );
      }
    } catch (e) {
      AppLogger.error('❌ QuickCategoryApiService: Error creating quick category: $e');
      rethrow;
    }
  }

  /// Update quick category
  Future<QuickCategoryModel> updateQuickCategory({
    required String id,
    String? title,
    String? subtitle,
    String? color,
    String? imageUrl,
    String? imageFilePath,
    int? displayOrder,
    bool? isActive,
    String? linkTo,
    String? linkValue,
    String? description,
    List<String>? tags,
  }) async {
    try {
      AppLogger.network('🌐 QuickCategoryApiService: Updating quick category: $id');

      FormData formData = FormData();

      if (title != null) formData.fields.add(MapEntry('title', title));
      if (subtitle != null) formData.fields.add(MapEntry('subtitle', subtitle));
      if (color != null) formData.fields.add(MapEntry('color', color));
      if (displayOrder != null)
        formData.fields.add(MapEntry('displayOrder', displayOrder.toString()));
      if (isActive != null)
        formData.fields.add(MapEntry('isActive', isActive.toString()));
      if (linkTo != null) formData.fields.add(MapEntry('linkTo', linkTo));
      if (linkValue != null)
        formData.fields.add(MapEntry('linkValue', linkValue));
      if (description != null)
        formData.fields.add(MapEntry('description', description));
      if (tags != null) {
        for (String tag in tags) {
          formData.fields.add(MapEntry('tags', tag));
        }
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        formData.fields.add(MapEntry('imageUrl', imageUrl));
      }

      if (imageFilePath != null && imageFilePath.isNotEmpty) {
        formData.files.add(
          MapEntry('image', await MultipartFile.fromFile(imageFilePath)),
        );
      }

      final response = await _dio.put(
        '/api/quick-categories/$id',
        data: formData,
      );

      AppLogger.debug(
        '✅ QuickCategoryApiService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final quickCategory = QuickCategoryModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );

        AppLogger.debug(
          '✅ QuickCategoryApiService: Successfully updated quick category: ${quickCategory.title}',
        );

        return quickCategory;
      } else {
        throw Exception(
          'Failed to update quick category: ${response.data['message']}',
        );
      }
    } catch (e) {
      AppLogger.error('❌ QuickCategoryApiService: Error updating quick category: $e');
      rethrow;
    }
  }

  /// Delete quick category
  Future<void> deleteQuickCategory(String id) async {
    try {
      AppLogger.network('🌐 QuickCategoryApiService: Deleting quick category: $id');

      final response = await _dio.delete('/api/quick-categories/$id');

      AppLogger.debug(
        '✅ QuickCategoryApiService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        AppLogger.success('✅ QuickCategoryApiService: Successfully deleted quick category');
      } else {
        throw Exception(
          'Failed to delete quick category: ${response.data['message']}',
        );
      }
    } catch (e) {
      AppLogger.error('❌ QuickCategoryApiService: Error deleting quick category: $e');
      rethrow;
    }
  }

  // ==================== SPECIAL OPERATIONS ====================

  /// Toggle quick category status
  Future<QuickCategoryModel> toggleQuickCategoryStatus(String id) async {
    try {
      AppLogger.debug(
        '🌐 QuickCategoryApiService: Toggling status for quick category: $id',
      );

      final response = await _dio.put(
        '/api/quick-categories/$id/toggle-status',
      );

      AppLogger.debug(
        '✅ QuickCategoryApiService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final quickCategory = QuickCategoryModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );

        AppLogger.debug(
          '✅ QuickCategoryApiService: Successfully toggled status: ${quickCategory.isActive}',
        );

        return quickCategory;
      } else {
        throw Exception(
          'Failed to toggle quick category status: ${response.data['message']}',
        );
      }
    } catch (e) {
      AppLogger.debug(
        '❌ QuickCategoryApiService: Error toggling quick category status: $e',
      );
      rethrow;
    }
  }

  /// Reorder quick categories
  Future<void> reorderQuickCategories(List<String> orderedIds) async {
    try {
      AppLogger.network('🌐 QuickCategoryApiService: Reordering quick categories');

      final response = await _dio.put(
        '/api/quick-categories/reorder',
        data: {'orderedIds': orderedIds},
      );

      AppLogger.debug(
        '✅ QuickCategoryApiService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        AppLogger.debug(
          '✅ QuickCategoryApiService: Successfully reordered quick categories',
        );
      } else {
        throw Exception(
          'Failed to reorder quick categories: ${response.data['message']}',
        );
      }
    } catch (e) {
      AppLogger.error('❌ QuickCategoryApiService: Error reordering quick categories: $e');
      rethrow;
    }
  }

  // ==================== ANALYTICS ====================

  /// Get quick category statistics
  Future<Map<String, dynamic>> getQuickCategoryStats() async {
    try {
      AppLogger.network('🌐 QuickCategoryApiService: Fetching quick category stats');

      final response = await _dio.get('/api/quick-categories/stats');

      AppLogger.debug(
        '✅ QuickCategoryApiService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final stats = response.data['data'] as Map<String, dynamic>;

        AppLogger.success('✅ QuickCategoryApiService: Successfully fetched stats');

        return stats;
      } else {
        throw Exception(
          'Failed to fetch quick category stats: ${response.data['message']}',
        );
      }
    } catch (e) {
      AppLogger.debug(
        '❌ QuickCategoryApiService: Error fetching quick category stats: $e',
      );
      rethrow;
    }
  }

  /// Track quick category click
  Future<void> trackQuickCategoryClick(String id) async {
    try {
      AppLogger.debug(
        '🌐 QuickCategoryApiService: Tracking click for quick category: $id',
      );

      final response = await _dio.post('/api/quick-categories/$id/click');

      if (response.statusCode == 200 && response.data['success'] == true) {
        AppLogger.success('✅ QuickCategoryApiService: Successfully tracked click');
      }
    } catch (e) {
      AppLogger.error('❌ QuickCategoryApiService: Error tracking click: $e');
      // Don't rethrow for analytics - should not break user experience
    }
  }

  /// Track quick category view
  Future<void> trackQuickCategoryView(String id) async {
    try {
      AppLogger.debug(
        '🌐 QuickCategoryApiService: Tracking view for quick category: $id',
      );

      final response = await _dio.post('/api/quick-categories/$id/view');

      if (response.statusCode == 200 && response.data['success'] == true) {
        AppLogger.success('✅ QuickCategoryApiService: Successfully tracked view');
      }
    } catch (e) {
      AppLogger.error('❌ QuickCategoryApiService: Error tracking view: $e');
      // Don't rethrow for analytics - should not break user experience
    }
  }
}
