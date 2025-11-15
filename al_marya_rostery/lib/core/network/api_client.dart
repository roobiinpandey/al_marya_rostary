import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

/// Centralized HTTP client for API communication
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  String? _authToken;

  /// Set authentication token for API requests
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Get default headers for API requests
  Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  /// GET request with error handling
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      debugPrint('🌐 GET: $url');

      final response = await _client
          .get(url, headers: {..._defaultHeaders, ...?headers})
          .timeout(Duration(seconds: AppConstants.defaultTimeout));

      _logResponse('GET', endpoint, response);
      return response;
    } catch (e) {
      debugPrint('❌ GET Error ($endpoint): $e');
      rethrow;
    }
  }

  /// POST request with error handling
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      debugPrint('🌐 POST: $url');
      if (body != null) debugPrint('📤 Body: $body');

      final response = await _client
          .post(
            url,
            headers: {..._defaultHeaders, ...?headers},
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: AppConstants.defaultTimeout));

      _logResponse('POST', endpoint, response);
      return response;
    } catch (e) {
      debugPrint('❌ POST Error ($endpoint): $e');
      rethrow;
    }
  }

  /// PUT request with error handling
  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      debugPrint('🌐 PUT: $url');
      if (body != null) debugPrint('📤 Body: $body');

      final response = await _client
          .put(
            url,
            headers: {..._defaultHeaders, ...?headers},
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: AppConstants.defaultTimeout));

      _logResponse('PUT', endpoint, response);
      return response;
    } catch (e) {
      debugPrint('❌ PUT Error ($endpoint): $e');
      rethrow;
    }
  }

  /// DELETE request with error handling
  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      debugPrint('🌐 DELETE: $url');

      final response = await _client
          .delete(url, headers: {..._defaultHeaders, ...?headers})
          .timeout(Duration(seconds: AppConstants.defaultTimeout));

      _logResponse('DELETE', endpoint, response);
      return response;
    } catch (e) {
      debugPrint('❌ DELETE Error ($endpoint): $e');
      rethrow;
    }
  }

  /// Log API response for debugging
  void _logResponse(String method, String endpoint, http.Response response) {
    final statusEmoji = response.statusCode >= 200 && response.statusCode < 300
        ? '✅'
        : response.statusCode >= 400 && response.statusCode < 500
        ? '⚠️'
        : '❌';

    debugPrint('$statusEmoji $method $endpoint: ${response.statusCode}');

    if (kDebugMode && response.body.isNotEmpty) {
      try {
        final jsonBody = jsonDecode(response.body);
        debugPrint('📥 Response: $jsonBody');
      } catch (e) {
        debugPrint('📥 Response (raw): ${response.body}');
      }
    }
  }

  /// Check if response is successful
  bool isSuccessful(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// Parse JSON response with error handling
  Map<String, dynamic> parseResponse(http.Response response) {
    if (!isSuccessful(response)) {
      throw HttpException(
        'API Error: ${response.statusCode} - ${response.reasonPhrase}',
      );
    }

    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw const FormatException('Invalid JSON response');
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

/// API Exception classes
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
