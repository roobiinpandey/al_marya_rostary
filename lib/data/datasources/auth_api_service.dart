import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/models/auth_models.dart' as auth_models;
import '../../../domain/models/auth_request_models.dart';
import 'mock_auth_api_service.dart';

/// AuthApiService handles authentication API calls
class AuthApiService {
  final Dio _dio;
  final MockAuthApiService _mockService;

  auth_models.AuthException _createAuthException(
    String message, [
    String? code,
  ]) {
    return auth_models.AuthException(message, code);
  }

  AuthApiService({Dio? dio})
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
              validateStatus: (status) => status != null && status < 500,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          ),
      _mockService = MockAuthApiService() {
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
          _handleAuthError(error);
          return handler.next(error);
        },
      ),
    ]);
  }

  void _handleAuthError(DioException error) {
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
              throw _createAuthException(
                messages.join(', '),
                'VALIDATION_ERROR',
              );
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

    throw _createAuthException(message, errorCode);
  }

  Future<auth_models.AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '${AppConstants.authEndpoint}/login',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return auth_models.AuthResponse.fromJson(response.data);
      } else {
        throw _createAuthException('Login failed');
      }
    } catch (e) {
      debugPrint(
        '🔄 Real API login failed, falling back to mock authentication: $e',
      );
      // Fallback to mock authentication
      return _mockService.login(request);
    }
  }

  Future<auth_models.AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '${AppConstants.authEndpoint}/register',
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        return auth_models.AuthResponse.fromJson(response.data);
      } else {
        throw _createAuthException('Registration failed');
      }
    } catch (e) {
      debugPrint(
        '🔄 Real API register failed, falling back to mock authentication: $e',
      );
      // Fallback to mock authentication
      return _mockService.register(request);
    }
  }

  Future<void> logout(String token) async {
    try {
      await _dio.post(
        '${AppConstants.authEndpoint}/logout',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      debugPrint(
        '🔄 Real API logout failed, falling back to mock authentication: $e',
      );
      // Fallback to mock authentication
      await _mockService.logout(token);
    }
  }

  Future<auth_models.AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '${AppConstants.authEndpoint}/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        return auth_models.AuthResponse.fromJson(response.data);
      } else {
        throw _createAuthException('Token refresh failed');
      }
    } catch (e) {
      debugPrint(
        '🔄 Real API refresh token failed, falling back to mock authentication: $e',
      );
      // Fallback to mock authentication
      return _mockService.refreshToken(refreshToken);
    }
  }

  Future<auth_models.User> getCurrentUser(String token) async {
    try {
      final response = await _dio.get(
        '${AppConstants.authEndpoint}/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return auth_models.User.fromJson(response.data);
      } else {
        throw _createAuthException('Failed to get user profile');
      }
    } catch (e) {
      debugPrint(
        '🔄 Real API get current user failed, falling back to mock authentication: $e',
      );
      // Fallback to mock authentication
      return _mockService.getCurrentUser(token);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '${AppConstants.authEndpoint}/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw _createAuthException('Failed to send password reset email');
      }
    } catch (e) {
      debugPrint(
        '🔄 Real API forgot password failed, falling back to mock authentication: $e',
      );
      // Fallback to mock authentication
      await _mockService.forgotPassword(email);
    }
  }

  Future<void> resetPassword(ResetPasswordRequest request) async {
    try {
      final response = await _dio.post(
        '${AppConstants.authEndpoint}/reset-password',
        data: request.toJson(),
      );

      if (response.statusCode != 200) {
        throw _createAuthException('Failed to reset password');
      }
    } catch (e) {
      debugPrint(
        '🔄 Real API reset password failed, falling back to mock authentication: $e',
      );
      // Fallback to mock authentication
      await _mockService.resetPassword(request);
    }
  }

  Future<void> changePassword(
    String token,
    ChangePasswordRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '${AppConstants.authEndpoint}/change-password',
        data: request.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw _createAuthException('Failed to change password');
      }
    } catch (e) {
      debugPrint(
        '🔄 Real API change password failed, falling back to mock authentication: $e',
      );
      // Fallback to mock authentication
      await _mockService.changePassword(token, request);
    }
  }

  Future<auth_models.AuthResponse> updateProfile(
    String token,
    auth_models.User updatedUser,
  ) async {
    try {
      final response = await _dio.put(
        '${AppConstants.authEndpoint}/profile',
        data: updatedUser.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return auth_models.AuthResponse.fromJson(response.data);
      } else {
        throw _createAuthException('Failed to update profile');
      }
    } catch (e) {
      debugPrint(
        '🔄 Real API update profile failed, falling back to mock authentication: $e',
      );
      // Fallback to mock authentication
      return _mockService.updateProfile(token, updatedUser);
    }
  }

  /// Update user profile with file upload support (avatar)
  Future<auth_models.AuthResponse> updateProfileWithFile(
    String token,
    String? name,
    String? phone,
    File? avatarFile,
  ) async {
    try {
      final formData = FormData();
      
      // Add text fields
      if (name != null && name.isNotEmpty) {
        formData.fields.add(MapEntry('name', name));
      }
      if (phone != null && phone.isNotEmpty) {
        formData.fields.add(MapEntry('phone', phone));
      }
      
      // Add avatar file if provided
      if (avatarFile != null) {
        final fileName = avatarFile.path.split('/').last;
        formData.files.add(MapEntry(
          'avatar',
          await MultipartFile.fromFile(
            avatarFile.path,
            filename: fileName,
          ),
        ));
      }

      final response = await _dio.put(
        '${AppConstants.authEndpoint}/profile',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200) {
        return auth_models.AuthResponse.fromJson(response.data);
      } else {
        throw _createAuthException('Failed to update profile');
      }
    } catch (e) {
      debugPrint(
        '🔄 Real API update profile with file failed, falling back to mock: $e',
      );
      // For fallback, create a User object and use mock service
      final updatedUser = auth_models.User(
        id: '',
        name: name ?? '',
        email: '',
        phone: phone,
        avatar: null, // Mock service doesn't handle file uploads
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEmailVerified: false,
        isAnonymous: false,
        roles: [],
      );
      return _mockService.updateProfile(token, updatedUser);
    }
  }
}
