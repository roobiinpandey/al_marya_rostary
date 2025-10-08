import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../../../data/datasources/auth_api_service.dart';
import '../../../domain/models/auth_request_models.dart';
import '../../../domain/models/auth_models.dart' as auth_models;

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _errorMessage;
  bool _isLoading = false;
  late final AuthApiService _authService;

  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get hasError => _errorMessage != null;

  AuthProvider() {
    _authService = AuthApiService();
    _loadUserFromStorage();
  }

  // Load user from local storage
  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      if (userJson != null) {
        final userMap = json.decode(userJson);
        _user = UserModel.fromFirebase(userMap, userMap['id']);
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently - user just won't be auto-logged in
    }
  }

  // Save user to local storage
  Future<void> _saveUserToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_user != null) {
        final userMap = _user!.toMap();
        userMap['id'] = _user!.id;
        await prefs.setString('current_user', json.encode(userMap));
      } else {
        await prefs.remove('current_user');
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Save authentication tokens
  Future<void> _saveTokens(String token, String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('refresh_token', refreshToken);
    } catch (e) {
      // Handle error silently
    }
  }

  // Get stored authentication token
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      return null;
    }
  }

  // Clear all stored authentication data
  Future<void> _clearStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> logout() async {
    try {
      _setLoading(true);
      _user = null;
      await _clearStoredAuth();
      _setLoading(false);
      notifyListeners();
    } catch (error) {
      _setLoading(false);
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> loginAsGuest() async {
    try {
      _setLoading(true);
      _user = UserModel(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Guest User',
        email: null,
        isEmailVerified: false,
      );
      await _saveUserToStorage();
      _setLoading(false);
      notifyListeners();
    } catch (error) {
      _setLoading(false);
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      _setLoading(true);

      // Simple validation
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      if (!email.contains('@')) {
        throw Exception('Please enter a valid email address');
      }

      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      // Call backend API
      final result = await _authService.login(
        LoginRequest(email: email, password: password),
      );

      // Convert from domain model to local model
      _user = UserModel(
        id: result.user.id,
        name: result.user.name,
        email: result.user.email,
        phone: result.user.phone,
        avatar: result.user.avatar,
        isEmailVerified: result.user.isEmailVerified,
      );

      // Save tokens and user data
      await _saveUserToStorage();
      await _saveTokens(result.accessToken, result.refreshToken);

      _setLoading(false);
      notifyListeners();
    } catch (error) {
      _setLoading(false);
      _errorMessage = _getErrorMessage(error);
      notifyListeners();
    }
  }

  Future<void> signUp(
    String email,
    String password, {
    String? name,
    String? phone,
  }) async {
    try {
      _setLoading(true);

      // Simple validation
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      if (!email.contains('@')) {
        throw Exception('Please enter a valid email address');
      }

      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      // Call backend API
      final result = await _authService.register(
        RegisterRequest(
          name: name ?? email.split('@')[0],
          email: email,
          password: password,
          confirmPassword: password,
          phone: phone,
        ),
      );

      // Convert from domain model to local model
      _user = UserModel(
        id: result.user.id,
        name: result.user.name,
        email: result.user.email,
        phone: result.user.phone,
        avatar: result.user.avatar,
        isEmailVerified: result.user.isEmailVerified,
      );

      // Save tokens and user data
      await _saveUserToStorage();
      await _saveTokens(result.accessToken, result.refreshToken);

      _setLoading(false);
      notifyListeners();
    } catch (error) {
      _setLoading(false);
      _errorMessage = _getErrorMessage(error);
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    try {
      _setLoading(true);

      // Simulate Google Sign-In - in a real app you'd integrate with Google
      _user = UserModel(
        id: 'google_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Google User',
        email: 'user@gmail.com',
        avatar: null,
        isEmailVerified: true,
      );

      await _saveUserToStorage();
      _setLoading(false);
      notifyListeners();
    } catch (error) {
      _setLoading(false);
      _errorMessage = _getErrorMessage(error);
      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);

      // Simple validation
      if (email.isEmpty || !email.contains('@')) {
        throw Exception('Please enter a valid email address');
      }

      // In a real app, this would send an email via your backend
      // For now, we'll just simulate success
      await Future.delayed(const Duration(seconds: 1));

      _setLoading(false);
      notifyListeners();
    } catch (error) {
      _setLoading(false);
      _errorMessage = _getErrorMessage(error);
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }
}
