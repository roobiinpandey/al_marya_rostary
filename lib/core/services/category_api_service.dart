import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/category_model.dart';

/// API Service for Category Management
/// Handles all category-related API calls to the backend
class CategoryApiService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  // Base URL for the API (update with production URL)
  static const String baseUrl = 'http://localhost:5001';

  CategoryApiService({Dio? dio, FlutterSecureStorage? secureStorage})
    : _dio = dio ?? Dio(),
      _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _configureDio();
  }

  /// Configure Dio with interceptors and options
  void _configureDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add logging interceptor for debugging
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  /// Get authentication token from secure storage
  Future<String?> _getAuthToken() async {
    try {
      return await _secureStorage.read(key: 'auth_token');
    } catch (e) {
      print('Error reading auth token: $e');
      return null;
    }
  }

  /// Create headers with authentication token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== CATEGORY CRUD OPERATIONS ====================

  /// Fetch all categories from the backend
  /// Supports pagination, search, and filtering
  Future<Map<String, dynamic>> fetchAllCategories({
    int page = 1,
    int limit = 50,
    String? search,
    bool? isActive,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParameters = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (isActive != null) 'isActive': isActive.toString(),
        if (sortBy != null) 'sortBy': sortBy,
        if (sortOrder != null) 'sortOrder': sortOrder,
      };

      final response = await _dio.get(
        '/api/categories',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List;
        final categories = data
            .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return {
          'categories': categories,
          'pagination': response.data['pagination'] ?? {},
          'success': true,
        };
      } else {
        throw Exception(
          'Failed to fetch categories: ${response.data['message']}',
        );
      }
    } on DioException catch (e) {
      print('DioException in fetchAllCategories: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Error in fetchAllCategories: $e');
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Create a new category
  /// Requires admin authentication
  Future<CategoryModel> createCategory({
    required String nameEn,
    required String nameAr,
    required String descriptionEn,
    required String descriptionAr,
    String? parentId,
    String? color,
    int? displayOrder,
    bool? isActive,
  }) async {
    try {
      final headers = await _getHeaders();

      final categoryData = {
        'nameEn': nameEn,
        'nameAr': nameAr,
        'descriptionEn': descriptionEn,
        'descriptionAr': descriptionAr,
        if (parentId != null) 'parentId': parentId,
        if (color != null) 'color': color,
        if (displayOrder != null) 'displayOrder': displayOrder,
        if (isActive != null) 'isActive': isActive,
      };

      final response = await _dio.post(
        '/api/categories',
        data: categoryData,
        options: Options(headers: headers),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final categoryJson = response.data['data'] ?? response.data;
        return CategoryModel.fromJson(categoryJson as Map<String, dynamic>);
      } else {
        throw Exception(
          'Failed to create category: ${response.data['message']}',
        );
      }
    } on DioException catch (e) {
      print('DioException in createCategory: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
        throw Exception(
          e.response?.data['message'] ?? 'Failed to create category',
        );
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Error in createCategory: $e');
      throw Exception('Failed to create category: $e');
    }
  }

  /// Update an existing category
  /// Requires admin authentication
  Future<CategoryModel> updateCategory({
    required String categoryId,
    String? nameEn,
    String? nameAr,
    String? descriptionEn,
    String? descriptionAr,
    String? parentId,
    String? color,
    int? displayOrder,
    bool? isActive,
  }) async {
    try {
      final headers = await _getHeaders();

      final updateData = {
        if (nameEn != null) 'nameEn': nameEn,
        if (nameAr != null) 'nameAr': nameAr,
        if (descriptionEn != null) 'descriptionEn': descriptionEn,
        if (descriptionAr != null) 'descriptionAr': descriptionAr,
        if (parentId != null) 'parentId': parentId,
        if (color != null) 'color': color,
        if (displayOrder != null) 'displayOrder': displayOrder,
        if (isActive != null) 'isActive': isActive,
      };

      final response = await _dio.put(
        '/api/categories/$categoryId',
        data: updateData,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final categoryJson = response.data['data'] ?? response.data;
        return CategoryModel.fromJson(categoryJson as Map<String, dynamic>);
      } else {
        throw Exception(
          'Failed to update category: ${response.data['message']}',
        );
      }
    } on DioException catch (e) {
      print('DioException in updateCategory: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
        throw Exception(
          e.response?.data['message'] ?? 'Failed to update category',
        );
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Error in updateCategory: $e');
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete a category
  /// Requires admin authentication
  /// Note: Backend may prevent deletion if category has products
  Future<void> deleteCategory(String categoryId) async {
    try {
      final headers = await _getHeaders();

      final response = await _dio.delete(
        '/api/categories/$categoryId',
        options: Options(headers: headers),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete category: ${response.data['message']}',
        );
      }
    } on DioException catch (e) {
      print('DioException in deleteCategory: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
        throw Exception(
          e.response?.data['message'] ?? 'Failed to delete category',
        );
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Error in deleteCategory: $e');
      throw Exception('Failed to delete category: $e');
    }
  }

  /// Get a single category by ID
  Future<CategoryModel> getCategoryById(String categoryId) async {
    try {
      final response = await _dio.get('/api/categories/$categoryId');

      if (response.statusCode == 200) {
        final categoryJson = response.data['data'] ?? response.data;
        return CategoryModel.fromJson(categoryJson as Map<String, dynamic>);
      } else {
        throw Exception(
          'Failed to fetch category: ${response.data['message']}',
        );
      }
    } on DioException catch (e) {
      print('DioException in getCategoryById: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Error in getCategoryById: $e');
      throw Exception('Failed to fetch category: $e');
    }
  }

  /// Toggle category active status
  /// Convenience method for enabling/disabling categories
  Future<void> toggleActiveStatus(String categoryId, bool isActive) async {
    try {
      await updateCategory(categoryId: categoryId, isActive: isActive);
    } catch (e) {
      print('Error toggling category status: $e');
      rethrow;
    }
  }

  /// Update category display order
  /// Used for drag-and-drop reordering
  Future<void> updateDisplayOrder(String categoryId, int displayOrder) async {
    try {
      await updateCategory(categoryId: categoryId, displayOrder: displayOrder);
    } catch (e) {
      print('Error updating display order: $e');
      rethrow;
    }
  }

  /// Get category statistics
  /// Returns counts and other useful metrics
  Future<Map<String, dynamic>> getCategoryStats() async {
    try {
      final categoriesResponse = await fetchAllCategories(limit: 100);
      final categories =
          categoriesResponse['categories'] as List<CategoryModel>;

      final stats = {
        'total': categories.length,
        'active': categories.where((c) => c.isActive).length,
        'inactive': categories.where((c) => !c.isActive).length,
        'withParent': categories.where((c) => c.parentId != null).length,
        'topLevel': categories.where((c) => c.parentId == null).length,
      };

      return stats;
    } catch (e) {
      print('Error getting category stats: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
        'withParent': 0,
        'topLevel': 0,
      };
    }
  }

  /// Get categories organized in a tree structure (hierarchical)
  /// Useful for displaying parent-child relationships
  Future<List<CategoryModel>> getCategoriesTree() async {
    try {
      final response = await fetchAllCategories(limit: 100);
      final allCategories = response['categories'] as List<CategoryModel>;

      // Separate root categories (no parent)
      final rootCategories = allCategories
          .where((c) => c.parentId == null)
          .toList();

      // Organize into tree (if parent/child relationships exist)
      // For now, just return sorted by displayOrder
      // TODO: Implement full tree structure with children if needed
      rootCategories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      return rootCategories;
    } catch (e) {
      print('Error getting categories tree: $e');
      rethrow;
    }
  }
}
