import 'package:dio/dio.dart';
import 'package:qahwat_al_emarat/domain/models/auth_models.dart';
import 'package:qahwat_al_emarat/domain/models/auth_request_models.dart';

class AuthService {
  final Dio _dio;

  AuthService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.qahwat.com',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post('/auth/login', data: request.toJson());
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> logout(String accessToken) async {
    try {
      await _dio.post(
        '/auth/logout',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Token refresh failed: $e');
    }
  }

  Future<User> getCurrentUser(String accessToken) async {
    try {
      final response = await _dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } catch (e) {
      throw Exception('Forgot password failed: $e');
    }
  }

  Future<void> resetPassword(ResetPasswordRequest request) async {
    try {
      await _dio.post('/auth/reset-password', data: request.toJson());
    } catch (e) {
      throw Exception('Reset password failed: $e');
    }
  }

  Future<void> changePassword(
    String accessToken,
    ChangePasswordRequest request,
  ) async {
    try {
      await _dio.put(
        '/auth/change-password',
        data: request.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } catch (e) {
      throw Exception('Change password failed: $e');
    }
  }
}
