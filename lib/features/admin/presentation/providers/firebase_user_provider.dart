import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/firebase_user_model.dart';
import '../../../../core/constants/app_constants.dart';

/// Provider for Firebase User Management
/// Single source of truth - all users stored in Firebase only
class FirebaseUserProvider with ChangeNotifier {
  List<FirebaseUserModel> _firebaseUsers = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalUsers = 0;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _cachedAuthToken;

  // Getters
  List<FirebaseUserModel> get firebaseUsers => _firebaseUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalUsers => _totalUsers;

  String get baseUrl => '${AppConstants.baseUrl}/api/admin';

  // Load auth token from secure storage
  Future<void> loadAuthToken() async {
    try {
      _cachedAuthToken = await _storage.read(key: 'auth_token');
      debugPrint(
        '🔑 Firebase Provider - Auth token loaded: ${_cachedAuthToken != null ? "YES" : "NO"}',
      );
    } catch (e) {
      debugPrint('❌ Error loading auth token: $e');
      _cachedAuthToken = null;
    }
  }

  // Get headers with auth token
  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_cachedAuthToken != null) {
      headers['Authorization'] = 'Bearer $_cachedAuthToken';
    }
    return headers;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Fetch Firebase users - SINGLE SOURCE OF TRUTH
  Future<void> fetchFirebaseUsers({int page = 1, int limit = 20}) async {
    _setLoading(true);
    _setError(null);

    try {
      // Load auth token if not already loaded
      if (_cachedAuthToken == null) {
        await loadAuthToken();
      }

      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/firebase-users',
      ).replace(queryParameters: queryParams);

      debugPrint('🔥 Fetching Firebase users from: $uri');
      final response = await http.get(uri, headers: _getHeaders());

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // ✅ FIX: Backend returns data in nested 'data' object
          final responseData = data['data'] ?? data;
          final usersList = responseData['users'] as List? ?? [];

          _firebaseUsers = usersList
              .map((userJson) => FirebaseUserModel.fromJson(userJson))
              .toList();

          // Handle pagination
          final pagination = responseData['pagination'];
          if (pagination != null) {
            _totalUsers = pagination['total'] ?? usersList.length;
            _totalPages = (_totalUsers / limit).ceil();
            _currentPage = page;
          } else {
            // Fallback if no pagination object
            _totalUsers = usersList.length;
            _totalPages = 1;
            _currentPage = 1;
          }

          debugPrint('✅ Loaded ${_firebaseUsers.length} Firebase users');
          debugPrint(
            '📊 Total: $_totalUsers, Pages: $_totalPages, Current: $_currentPage',
          );
        } else {
          _setError(data['message'] ?? 'Failed to fetch Firebase users');
        }
      } else if (response.statusCode == 401) {
        _setError('Unauthorized - Please login again');
      } else {
        _setError('Failed to fetch Firebase users: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching Firebase users: $e');
      _setError('Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle Firebase user enabled/disabled status
  Future<bool> toggleFirebaseUserStatus(String uid) async {
    _setLoading(true);
    _setError(null);

    try {
      if (_cachedAuthToken == null) {
        await loadAuthToken();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/firebase-users/$uid/toggle-active'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        // Refresh the list
        await fetchFirebaseUsers(page: _currentPage);
        return true;
      } else {
        _setError('Failed to toggle user status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _setError('Error toggling user status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete Firebase user
  Future<bool> deleteFirebaseUser(String uid) async {
    _setLoading(true);
    _setError(null);

    try {
      if (_cachedAuthToken == null) {
        await loadAuthToken();
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/firebase-users/$uid'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        // Remove from local list
        _firebaseUsers.removeWhere((user) => user.uid == uid);
        _totalUsers--;
        notifyListeners();
        return true;
      } else {
        _setError('Failed to delete user: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _setError('Error deleting user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Go to next page
  void nextPage() {
    if (_currentPage < _totalPages) {
      _currentPage++;
      fetchFirebaseUsers(page: _currentPage);
    }
  }

  /// Go to previous page
  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      fetchFirebaseUsers(page: _currentPage);
    }
  }

  /// Refresh current page
  Future<void> refresh() async {
    await fetchFirebaseUsers(page: _currentPage);
  }
}
