import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

/// API service for authentication operations
class AuthApiService {
  static const String _baseUrl = AppConstants.baseUrl;
  static const String _authEndpoint = '/api/auth';

  /// Register a new user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$_authEndpoint/register');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'user': responseData['data']['user'],
          'token': responseData['data']['token'],
          'refreshToken': responseData['data']['refreshToken'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$_authEndpoint/login');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': responseData['data']['user'],
          'token': responseData['data']['token'],
          'refreshToken': responseData['data']['refreshToken'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get current user info
  static Future<Map<String, dynamic>> getMe(String token) async {
    try {
      final url = Uri.parse('$_baseUrl$_authEndpoint/me');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'user': responseData['data']['user']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get user info',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Refresh token
  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final url = Uri.parse('$_baseUrl$_authEndpoint/refresh');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'refreshToken': refreshToken}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'token': responseData['data']['token'],
          'refreshToken': responseData['data']['refreshToken'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Token refresh failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
