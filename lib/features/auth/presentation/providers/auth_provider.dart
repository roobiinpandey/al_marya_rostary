import 'package:flutter/material.dart';
import 'dart:async';
import 'package:qahwat_al_emarat/domain/repositories/auth_repository.dart';
import 'package:qahwat_al_emarat/domain/models/auth_models.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  bool _isInitialized = false;
  final Duration _sessionTimeout = const Duration(hours: 1);
  DateTime? _lastAuthTime;

  AuthProvider(this._authRepository, {bool skipInitialization = false}) {
    if (!skipInitialization) {
      _initializeAuthState();
    }
  }

  AuthState _state = AuthState.initial;
  User? _user;
  String? _errorMessage;
  Timer? _sessionTimer;

  // Public getters
  AuthState get state => _state;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == AuthState.loading;
  bool get isAuthenticated =>
      _state == AuthState.authenticated && _user != null;
  bool get hasError => _state == AuthState.error;
  bool get isGuest => _user?.isAnonymous ?? false;
  bool get isInitialized => _isInitialized;

  Future<void> _initializeAuthState() async {
    try {
      _setState(AuthState.loading);
      final isLoggedIn = await _authRepository.isLoggedIn();

      if (isLoggedIn) {
        final currentUser = await _authRepository.getCurrentUser();
        if (currentUser != null) {
          _user = currentUser;
          _startSessionTimer();
          _setState(AuthState.authenticated);
        } else {
          _setState(AuthState.unauthenticated);
        }
      } else {
        _setState(AuthState.unauthenticated);
      }
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
      _isInitialized = true;
    }
  } // Helper methods

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  Future<void> loginAsGuest() async {
    try {
      _setState(AuthState.loading);
      _clearError();

      // Generate a random guest email to ensure uniqueness
      final guestId = DateTime.now().millisecondsSinceEpoch.toString();
      final email = 'guest_$guestId@temp.com';
      const password = 'GuestPass123!';

      final response = await _authRepository.register(
        name: 'Guest User',
        email: email,
        password: password,
        confirmPassword: password,
      );

      _user = response.user;
      _refreshToken = response.refreshToken;
      _startSessionTimer();
      _setState(AuthState.authenticated);
    } catch (e) {
      _handleAuthError(e);
    }
  }

  Future<void> login(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw AuthException('Email and password are required');
      }
      if (!_isValidEmail(email)) {
        throw AuthException('Please enter a valid email address');
      }
      if (!_isValidPassword(password)) {
        throw AuthException('Password must be at least 6 characters');
      }

      _setState(AuthState.loading);
      _clearError();

      final response = await _authRepository.login(email, password);
      _user = response.user;
      _refreshToken = response.refreshToken;
      _startSessionTimer();
      _setState(AuthState.authenticated);
    } catch (e) {
      _handleAuthError(e);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
  }) async {
    try {
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        throw AuthException('All fields are required');
      }
      if (!_isValidEmail(email)) {
        throw AuthException('Please enter a valid email address');
      }
      if (!_isValidPassword(password)) {
        throw AuthException('Password must be at least 6 characters');
      }
      if (password != confirmPassword) {
        throw AuthException('Passwords do not match');
      }

      _setState(AuthState.loading);
      _clearError();

      final response = await _authRepository.register(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        phone: phone,
      );

      _user = response.user;
      _refreshToken = response.refreshToken;
      _startSessionTimer();
      _setState(AuthState.authenticated);
    } catch (e) {
      _handleAuthError(e);
    }
  }

  Future<void> logout() async {
    try {
      _setState(AuthState.loading);
      await _authRepository.logout();
      _clearAuthState();
    } catch (e) {
      _clearAuthState();
      debugPrint('Logout error: $e');
    }
  }

  void _clearAuthState() {
    _user = null;
    _refreshToken = null;
    _setState(AuthState.unauthenticated);
  }

  Future<void> forgotPassword(String email) async {
    try {
      if (email.isEmpty) {
        throw AuthException('Email is required');
      }
      if (!_isValidEmail(email)) {
        throw AuthException('Please enter a valid email address');
      }

      _setState(AuthState.loading);
      _clearError();

      await _authRepository.forgotPassword(email);
      _setState(
        _user != null ? AuthState.authenticated : AuthState.unauthenticated,
      );
    } catch (e) {
      _handleAuthError(e);
    }
  }

  String? _refreshToken;

  Future<void> refreshToken() async {
    try {
      if (_refreshToken == null) {
        throw AuthException('No refresh token available');
      }
      final response = await _authRepository.refreshToken(_refreshToken!);
      _user = response.user;
      _refreshToken = response.refreshToken;
      _setState(AuthState.authenticated);
    } catch (e) {
      await logout();
      _handleAuthError(AuthException('Session expired. Please login again.'));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      if (!_isValidPassword(newPassword)) {
        throw AuthException('New password must be at least 6 characters');
      }
      if (newPassword != confirmPassword) {
        throw AuthException('New passwords do not match');
      }

      _setState(AuthState.loading);
      _clearError();

      await _authRepository.changePassword(
        currentPassword,
        newPassword,
        confirmPassword,
      );

      _setState(AuthState.authenticated);
    } catch (e) {
      _handleAuthError(e);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? avatar,
  }) async {
    if (_user == null) {
      throw AuthException('No authenticated user');
    }

    try {
      _setState(AuthState.loading);
      _clearError();

      final updatedUser = User(
        id: _user!.id,
        name: name ?? _user!.name,
        email: _user!.email,
        phone: phone ?? _user!.phone,
        avatar: avatar ?? _user!.avatar,
        isEmailVerified: _user!.isEmailVerified,
        isAnonymous: _user!.isAnonymous,
        roles: _user!.roles,
        createdAt: _user!.createdAt,
        updatedAt: DateTime.now(),
      );

      final response = await _authRepository.updateProfile(updatedUser);
      _user = response.user;
      if (response.refreshToken.isNotEmpty) {
        _refreshToken = response.refreshToken;
      }
      _setState(AuthState.authenticated);
    } catch (e) {
      _handleAuthError(e);
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _lastAuthTime = DateTime.now();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_lastAuthTime != null &&
          DateTime.now().difference(_lastAuthTime!) > _sessionTimeout) {
        timer.cancel();
        logout();
      }
    });
  }

  void _updateSessionTimer() {
    _lastAuthTime = DateTime.now();
  }

  // repository interface. It should be added to the interface first.
  /*
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? avatar,
  }) async {
    if (_user == null) {
      throw AuthException('No authenticated user');
    }

    try {
      _setState(AuthState.loading);
      _clearError();

      final updatedUser = User(
        id: _user!.id,
        name: name ?? _user!.name,
        email: _user!.email,
        phone: phone ?? _user!.phone,
        avatar: avatar ?? _user!.avatar,
        isEmailVerified: _user!.isEmailVerified,
        isAnonymous: _user!.isAnonymous,
        roles: _user!.roles,
        createdAt: _user!.createdAt,
        updatedAt: DateTime.now(),
      );

      final response = await _authRepository.updateProfile(updatedUser);
      _user = response.user;
      if (response.refreshToken.isNotEmpty) {
        _refreshToken = response.refreshToken;
      }
      _setState(AuthState.authenticated);
    } catch (e) {
      _handleAuthError(e);
    }
  }
  */

  // Error handling
  void _handleAuthError(dynamic error) {
    String message;

    if (error is AuthException) {
      message = error.message;
    } else if (error is Exception) {
      message = error.toString().replaceAll('Exception: ', '');
    } else {
      message = error.toString();
    }

    _setError(message);
  }

  // State management
  void _setState(AuthState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _state = AuthState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    _setState(
      _user != null ? AuthState.authenticated : AuthState.unauthenticated,
    );
  }

  // Role and state checks
  bool hasRole(String role) => _user?.roles.contains(role) ?? false;
  bool get isAdmin => hasRole('admin');
  bool get isCustomer => hasRole('customer');
  bool get isEmailVerified => _user?.isEmailVerified ?? false;
  bool get canChangePassword => _user != null && !_user!.isAnonymous;
  bool get canUpdateProfile => _user != null;
  bool get needsEmailVerification =>
      _user != null && !_user!.isEmailVerified && !_user!.isAnonymous;
}
