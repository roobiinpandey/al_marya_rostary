import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_constants.dart';
import '../models/coffee_product_model.dart';

/// CoffeeApiService handles API calls for coffee products
class CoffeeApiService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  String? _cachedAuthToken;

  CoffeeApiService({Dio? dio, FlutterSecureStorage? secureStorage})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConstants.baseUrl,
              connectTimeout: const Duration(
                seconds: AppConstants.defaultTimeout,
              ),
              receiveTimeout: const Duration(
                seconds: AppConstants.defaultTimeout,
              ),
              sendTimeout: const Duration(seconds: AppConstants.defaultTimeout),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'User-Agent': 'QahwatAlEmarat/1.0.0 Flutter Mobile App',
                'Cache-Control': 'no-cache',
              },
              validateStatus: (status) => status! < 500,
            ),
          ),
      _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _setupInterceptors();
  }

  Future<void> init() async {
    await loadAuthToken();
  }

  void _setupInterceptors() {
    _dio.interceptors.addAll([
      // Request interceptor for logging and auth headers
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available
          final token = _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Log request
          debugPrint('🌐 API Request: ${options.method} ${options.uri}');
          debugPrint('📤 Headers: ${options.headers}');
          if (options.data != null) {
            debugPrint('📤 Data: ${options.data}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log successful response
          debugPrint(
            '✅ API Response: ${response.statusCode} ${response.requestOptions.uri}',
          );
          debugPrint('📥 Data: ${response.data}');

          return handler.next(response);
        },
        onError: (DioException error, handler) {
          // Log error
          debugPrint('❌ API Error: ${error.type} - ${error.message}');
          if (error.response != null) {
            debugPrint(
              '📥 Error Response: ${error.response?.statusCode} ${error.response?.data}',
            );
          }

          // Handle specific error types
          switch (error.type) {
            case DioExceptionType.connectionTimeout:
            case DioExceptionType.sendTimeout:
            case DioExceptionType.receiveTimeout:
              throw ApiException(
                'Connection timeout. Please check your internet connection.',
              );
            case DioExceptionType.badResponse:
              _handleBadResponse(error);
              break;
            case DioExceptionType.cancel:
              throw ApiException('Request cancelled');
            case DioExceptionType.unknown:
              throw ApiException('Network error. Please try again.');
            default:
              throw ApiException('An unexpected error occurred');
          }

          return handler.next(error);
        },
      ),
    ]);
  }

  String? _getAuthToken() {
    return _cachedAuthToken;
  }

  Future<void> loadAuthToken() async {
    try {
      _cachedAuthToken = await _secureStorage.read(key: 'auth_token');
    } catch (e) {
      debugPrint('Error loading auth token: $e');
      _cachedAuthToken = null;
    }
  }

  void _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    switch (statusCode) {
      case 400:
        throw ApiException(
          'Bad request: ${data?['message'] ?? 'Invalid request'}',
        );
      case 401:
        throw UnauthorizedException('Unauthorized access');
      case 403:
        throw ApiException('Access forbidden');
      case 404:
        throw NotFoundException('Resource not found');
      case 409:
        throw ApiException(
          'Conflict: ${data?['message'] ?? 'Resource conflict'}',
        );
      case 422:
        throw ValidationException(
          'Validation failed: ${data?['message'] ?? 'Invalid data'}',
        );
      case 500:
        throw ApiException('Server error. Please try again later.');
      default:
        throw ApiException(
          'HTTP $statusCode: ${data?['message'] ?? 'Unknown error'}',
        );
    }
  }

  Future<List<CoffeeProductModel>> fetchCoffeeProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
  }) async {
    try {
      debugPrint(
        '🌐 CoffeeApiService: Fetching coffees from ${AppConstants.baseUrl}${AppConstants.coffeeEndpoint}',
      );

      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;

      debugPrint('📤 CoffeeApiService: Query params: $queryParams');

      final response = await _dio.get(
        AppConstants.coffeeEndpoint,
        queryParameters: queryParams,
      );

      debugPrint('✅ CoffeeApiService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint(
          '📥 CoffeeApiService: Response data type: ${data.runtimeType}',
        );

        if (data is Map<String, dynamic> && data['data'] is List) {
          final coffeeList = (data['data'] as List)
              .map((json) => CoffeeProductModel.fromJson(json))
              .toList();
          debugPrint(
            '✅ CoffeeApiService: Successfully parsed ${coffeeList.length} coffees',
          );
          return coffeeList;
        } else if (data is List) {
          final coffeeList = data
              .map((json) => CoffeeProductModel.fromJson(json))
              .toList();
          debugPrint(
            '✅ CoffeeApiService: Successfully parsed ${coffeeList.length} coffees (direct list)',
          );
          return coffeeList;
        } else {
          debugPrint(
            '❌ CoffeeApiService: Invalid response format - data is not List or Map with data',
          );
          throw ApiException('Invalid response format');
        }
      } else {
        debugPrint('❌ CoffeeApiService: HTTP ${response.statusCode} error');
        throw ApiException('Failed to load coffee products');
      }
    } catch (e) {
      debugPrint('❌ CoffeeApiService: Exception occurred: $e');

      if (e is DioException) {
        debugPrint('❌ DioException Type: ${e.type}');
        debugPrint('❌ DioException Message: ${e.message}');
        debugPrint('❌ DioException Response: ${e.response}');
        debugPrint('❌ DioException Request URL: ${e.requestOptions.uri}');

        switch (e.type) {
          case DioExceptionType.connectionTimeout:
            throw ApiException(
              'Connection timeout. Please check your internet connection.',
            );
          case DioExceptionType.sendTimeout:
            throw ApiException('Request timeout. Please try again.');
          case DioExceptionType.receiveTimeout:
            throw ApiException('Server response timeout. Please try again.');
          case DioExceptionType.connectionError:
            throw ApiException(
              'Connection error. Please check your internet connection.',
            );
          case DioExceptionType.badResponse:
            _handleBadResponse(e);
            break;
          case DioExceptionType.cancel:
            throw ApiException('Request was cancelled.');
          case DioExceptionType.unknown:
            throw ApiException(
              'Network error: ${e.message ?? 'Unknown error'}',
            );
          default:
            throw ApiException('Network error occurred.');
        }
      }

      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch coffee products: $e');
    }
  }

  Future<CoffeeProductModel> fetchCoffeeProduct(String id) async {
    try {
      final response = await _dio.get('${AppConstants.coffeeEndpoint}/$id');

      if (response.statusCode == 200) {
        return CoffeeProductModel.fromJson(response.data);
      } else {
        throw ApiException('Failed to load coffee product');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch coffee product: $e');
    }
  }

  Future<List<String>> fetchCategories() async {
    try {
      debugPrint(
        '🌐 CoffeeApiService: Fetching categories from ${AppConstants.baseUrl}${AppConstants.categoriesEndpoint}',
      );

      final response = await _dio.get(AppConstants.categoriesEndpoint);

      debugPrint(
        '✅ CoffeeApiService: Categories response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint(
          '📥 CoffeeApiService: Categories response data type: ${data.runtimeType}',
        );

        if (data is Map<String, dynamic> && data['data'] is List) {
          // Handle response format: { success: true, data: [...] }
          final categories = (data['data'] as List)
              .map(
                (item) => item is Map
                    ? (item['name']?.toString() ?? item.toString())
                    : item.toString(),
              )
              .cast<String>()
              .toList();
          debugPrint(
            '✅ CoffeeApiService: Successfully parsed ${categories.length} categories',
          );
          return categories;
        } else if (data is List) {
          // Handle direct array response
          final categories = data
              .map(
                (item) => item is Map
                    ? (item['name']?.toString() ?? item.toString())
                    : item.toString(),
              )
              .cast<String>()
              .toList();
          debugPrint(
            '✅ CoffeeApiService: Successfully parsed ${categories.length} categories (direct list)',
          );
          return categories;
        } else {
          debugPrint('❌ CoffeeApiService: Invalid categories response format');
          return [];
        }
      } else {
        debugPrint(
          '❌ CoffeeApiService: HTTP ${response.statusCode} error for categories',
        );
        throw ApiException('Failed to load categories');
      }
    } catch (e) {
      debugPrint(
        '❌ CoffeeApiService: Exception occurred while fetching categories: $e',
      );
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch categories: $e');
    }
  }

  // Method to update auth token (called after login)
  Future<void> updateAuthToken(String token) async {
    try {
      await _secureStorage.write(key: 'auth_token', value: token);
      _cachedAuthToken = token;
      debugPrint('🔑 Auth token updated and cached');
    } catch (e) {
      debugPrint('Error storing auth token: $e');
    }
  }

  // Method to clear auth token (called on logout)
  Future<void> clearAuthToken() async {
    try {
      await _secureStorage.delete(key: 'auth_token');
      _cachedAuthToken = null;
      debugPrint('🔑 Auth token cleared');
    } catch (e) {
      debugPrint('Error clearing auth token: $e');
    }
  }
}

/// Custom exception classes for better error handling
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

class ValidationException extends ApiException {
  ValidationException(super.message);
}
