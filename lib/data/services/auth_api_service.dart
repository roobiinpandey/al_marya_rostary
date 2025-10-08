import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/models/auth_models.dart';
import '../../../domain/models/auth_request_models.dart';

/// AuthApiService handles authentication API calls
class AuthApiService {
  final Dio _dio;

  AuthApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: AppConstants.defaultTimeout),
          receiveTimeout: const Duration(seconds: AppConstants.defaultTimeout),
          sendTimeout: const Duration(seconds: AppConstants.defaultTimeout),
          validateStatus: (status) => status != null && status < 500,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    _setupInterceptors();
    _setupRetryOptions();
  }

  void _setupRetryOptions() {
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        logPrint: debugPrint,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
        retryableExtraStatuses: {401, 403},
      ),
    );
  }

  void _setupInterceptors() {
    _dio.interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('🔐 Auth API Request: ${options.method} ${options.uri}');
          if (options.headers.containsKey('Authorization')) {
            debugPrint('With auth token: ${options.headers['Authorization']}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            '✅ Auth API Response: ${response.statusCode} ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          debugPrint('❌ Auth API Error: ${error.type} - ${error.message}');
          return handler.next(error);
        },
      ),
    ]);
  }

  AuthException _handleAuthError(DioException error) {
    final String errorCode;
    String message;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorCode = 'TIMEOUT';
        message = 'Network timeout. Please check your connection.';
        break;
      case DioExceptionType.connectionError:
        errorCode = 'CONNECTION_ERROR';
        message = 'Network error. Please check your connection.';
        break;
      default:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (data != null && data['message'] is String) {
          message = data['message'];
          errorCode = (data['code'] as String?) ?? 'SERVER_ERROR';
          break;
        }

        switch (statusCode) {
          case 400:
            errorCode = 'INVALID_REQUEST';
            message = 'Invalid credentials or request';
            break;
          case 401:
            errorCode = 'INVALID_CREDENTIALS';
            message = 'Invalid email or password';
            break;
          case 403:
            errorCode = 'ACCOUNT_DISABLED';
            message = 'Account is disabled';
            break;
          case 409:
            errorCode = 'EMAIL_EXISTS';
            message = 'Email already exists';
            break;
          case 422:
            final errors = data?['errors'] as Map<String, dynamic>?;
            if (errors != null) {
              final messages = errors.values
                  .expand((e) => e)
                  .cast<String>()
                  .toList();
              return AuthException(messages.join(', '), 'VALIDATION_ERROR');
            }
            errorCode = 'VALIDATION_ERROR';
            message = 'Validation failed';
            break;
          case 429:
            errorCode = 'RATE_LIMITED';
            message = 'Too many attempts. Please try again later.';
            break;
          case 500:
          case 502:
          case 503:
          case 504:
            errorCode = 'SERVER_ERROR';
            message = 'Server error. Please try again later.';
            break;
          default:
            errorCode = 'AUTH_ERROR_${statusCode ?? "UNKNOWN"}';
            message = 'Authentication failed. Please try again.';
        }
    }

    return AuthException(message, errorCode);
  }

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '${AppConstants.authEndpoint}/login',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '${AppConstants.authEndpoint}/register',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> logout(String token) async {
    try {
      await _dio.post(
        '${AppConstants.authEndpoint}/logout',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(
        '${AppConstants.authEndpoint}/forgot-password',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '${AppConstants.authEndpoint}/refresh',
        data: {'refreshToken': refreshToken},
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<User> getCurrentUser(String token) async {
    try {
      final response = await _dio.get(
        '${AppConstants.authEndpoint}/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> changePassword(
    String token,
    ChangePasswordRequest request,
  ) async {
    try {
      await _dio.post(
        '${AppConstants.authEndpoint}/change-password',
        data: request.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<AuthResponse> updateProfile(String token, User updatedUser) async {
    try {
      final response = await _dio.put(
        '${AppConstants.authEndpoint}/profile',
        data: updatedUser.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }
}
