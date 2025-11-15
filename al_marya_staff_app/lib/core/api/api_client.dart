import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  String? _authToken;

  /// Set authentication token for all requests
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Get headers with optional authentication
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// Generic GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse(endpoint);
      final response = await _client
          .get(uri, headers: _getHeaders(includeAuth: requiresAuth))
          .timeout(AppConstants.connectionTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on HttpException {
      throw ApiException('Server error occurred');
    } catch (e) {
      throw ApiException('Request failed: $e');
    }
  }

  /// Generic POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse(endpoint);
      final response = await _client
          .post(
            uri,
            headers: _getHeaders(includeAuth: requiresAuth),
            body: jsonEncode(body),
          )
          .timeout(AppConstants.connectionTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on HttpException {
      throw ApiException('Server error occurred');
    } catch (e) {
      throw ApiException('Request failed: $e');
    }
  }

  /// Generic PUT request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse(endpoint);
      final response = await _client
          .put(
            uri,
            headers: _getHeaders(includeAuth: requiresAuth),
            body: jsonEncode(body),
          )
          .timeout(AppConstants.connectionTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on HttpException {
      throw ApiException('Server error occurred');
    } catch (e) {
      throw ApiException('Request failed: $e');
    }
  }

  /// Generic PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse(endpoint);
      final response = await _client
          .patch(
            uri,
            headers: _getHeaders(includeAuth: requiresAuth),
            body: jsonEncode(body),
          )
          .timeout(AppConstants.connectionTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on HttpException {
      throw ApiException('Server error occurred');
    } catch (e) {
      throw ApiException('Request failed: $e');
    }
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      try {
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic> ? data : {'data': data};
      } catch (e) {
        throw ApiException('Invalid response format');
      }
    }

    // Handle error responses
    String message = 'Request failed with status: $statusCode';
    try {
      final errorData = jsonDecode(response.body);
      if (errorData is Map && errorData.containsKey('message')) {
        message = errorData['message'];
      } else if (errorData is Map && errorData.containsKey('error')) {
        message = errorData['error'];
      }
    } catch (_) {
      // Use default message if parsing fails
    }

    switch (statusCode) {
      case 400:
        throw ApiException('Bad request: $message');
      case 401:
        throw UnauthorizedException('Unauthorized: $message');
      case 403:
        throw ApiException('Forbidden: $message');
      case 404:
        throw ApiException('Not found: $message');
      case 500:
        throw ApiException('Server error: $message');
      default:
        throw ApiException(message);
    }
  }

  /// Health check
  Future<bool> healthCheck() async {
    try {
      final response = await get(ApiEndpoints.health, requiresAuth: false);
      return response['status'] == 'healthy';
    } catch (_) {
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

/// Base API exception
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Unauthorized exception (401)
class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}
