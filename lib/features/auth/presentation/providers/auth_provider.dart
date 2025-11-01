import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:qahwat_al_emarat/domain/repositories/auth_repository.dart';
import 'package:qahwat_al_emarat/domain/models/auth_models.dart';
import 'package:qahwat_al_emarat/core/services/user_api_service.dart';
import 'package:qahwat_al_emarat/core/utils/app_logger.dart';
import '../../../../services/reward_service.dart';

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
  bool get isGuest => _isGuestMode;
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

  bool _isGuestMode = false;

  Future<void> loginAsGuest() async {
    try {
      _setState(AuthState.loading);
      _clearError();

      // Set guest mode flag - no account creation
      _isGuestMode = true;
      _user = null;
      _setState(AuthState.unauthenticated);
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

      // Ensure user has QR code (background task)
      _ensureUserQRCode();

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

      // Initialize QR code for new user (background task)
      _initializeNewUserQRCode();

      _setState(AuthState.authenticated);
    } catch (e) {
      _handleAuthError(e);
    }
  }

  Future<void> logout() async {
    try {
      // First set loading state
      _setState(AuthState.loading);

      // Cancel any active timers
      _sessionTimer?.cancel();
      _sessionTimer = null;

      // Clear local state first
      _user = null;
      _refreshToken = null;
      _isGuestMode = false;
      _lastAuthTime = null;
      _errorMessage = null;

      // Then call repository logout (this might fail but we continue anyway)
      try {
        await _authRepository.logout();
      } catch (e) {
        debugPrint('Repository logout error (continuing anyway): $e');
      }

      // Finally set unauthenticated state
      _setState(AuthState.unauthenticated);
    } catch (e) {
      // Even if there's an error, clear the auth state
      _user = null;
      _refreshToken = null;
      _isGuestMode = false;
      _lastAuthTime = null;
      _sessionTimer?.cancel();
      _sessionTimer = null;
      _setState(AuthState.unauthenticated);
      debugPrint('Logout error: $e');
    }
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
    File? avatarFile,
  }) async {
    if (_user == null) {
      throw AuthException('No authenticated user');
    }

    try {
      _setState(AuthState.loading);
      _clearError();

      // Enhanced Firebase authentication for profile updates
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw AuthException(
          'You must be signed in to update your profile. Please sign in and try again.',
        );
      }

      // Verify user is properly authenticated (not anonymous)
      if (firebaseUser.isAnonymous) {
        throw AuthException(
          'Anonymous users cannot update profiles. Please create an account first.',
        );
      }

      // Get fresh Firebase ID token (force refresh to ensure validity)
      final token = await firebaseUser.getIdToken(true);
      if (token == null || token.isEmpty) {
        throw AuthException(
          'Failed to get authentication token. Please sign out and sign in again.',
        );
      }

      AppLogger.info(
        'Profile update: Getting fresh Firebase token for ${firebaseUser.email}',
        tag: 'AuthProvider',
      );
      AppLogger.info(
        'Profile update: Token length: ${token.length}',
        tag: 'AuthProvider',
      );

      // Use backend API for profile updates (handles Cloudinary upload)
      final userApiService = UserApiService();
      try {
        final updatedUser = await userApiService.updateMyProfile(
          name: name,
          phone: phone,
          avatarPath: avatarFile?.path,
          firebaseToken: token,
        );

        // Update local user state
        _user = User(
          id: updatedUser.id,
          name: updatedUser.name,
          email: updatedUser.email,
          phone: updatedUser.phone,
          avatar: updatedUser.avatar ?? _user!.avatar,
          isEmailVerified: updatedUser.isEmailVerified,
          isAnonymous: _user!.isAnonymous,
          roles: updatedUser.roles,
          createdAt: updatedUser.createdAt ?? _user!.createdAt,
          updatedAt: DateTime.now(),
        );

        _setState(AuthState.authenticated);
        AppLogger.success('Profile updated successfully', tag: 'AuthProvider');
      } catch (apiError) {
        AppLogger.error(
          'Profile update API failed',
          tag: 'AuthProvider',
          error: apiError,
        );

        // Handle specific API errors
        final errorMessage = apiError.toString();
        if (errorMessage.contains('Invalid token format') ||
            errorMessage.contains('Session expired')) {
          throw AuthException(
            'Your session has expired. Please sign out and sign in again to update your profile.',
          );
        } else if (errorMessage.contains('401') ||
            errorMessage.contains('Unauthorized')) {
          throw AuthException(
            'Authentication failed. Please sign out and sign in again.',
          );
        } else {
          throw AuthException('Failed to update profile: ${errorMessage}');
        }
      }
    } catch (e) {
      _handleAuthError(e);
      rethrow; // Re-throw so the UI can show the error
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

  // Additional convenience methods
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
  }) async {
    await register(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      phone: phone,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await forgotPassword(email);
  }

  Future<void> resetPassword(
    String token,
    String password,
    String confirmPassword,
  ) async {
    try {
      if (!_isValidPassword(password)) {
        throw AuthException('Password must be at least 6 characters');
      }
      if (password != confirmPassword) {
        throw AuthException('Passwords do not match');
      }

      _setState(AuthState.loading);
      _clearError();

      await _authRepository.resetPassword(token, password, confirmPassword);

      // After successful password reset, user needs to log in again
      _setState(AuthState.unauthenticated);
    } catch (e) {
      _handleAuthError(e);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      debugPrint('AuthProvider: Starting Google Sign-In...');
      _setState(AuthState.loading);
      _clearError();

      debugPrint('AuthProvider: Calling repository signInWithGoogle...');
      final response = await _authRepository.signInWithGoogle();

      debugPrint('AuthProvider: Google Sign-In response received');
      _user = response.user;
      _refreshToken = response.refreshToken;
      _startSessionTimer();

      // Ensure user has QR code (background task)
      _ensureUserQRCode();

      debugPrint('AuthProvider: Setting authenticated state');
      _setState(AuthState.authenticated);
    } catch (e) {
      debugPrint('AuthProvider: Google Sign-In error: $e');
      _handleAuthError(e);
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      _setState(AuthState.loading);
      _clearError();

      await _authRepository.sendEmailVerification();

      // Don't change the auth state after sending verification
      _setState(AuthState.authenticated);
    } catch (e) {
      _handleAuthError(e);
    }
  }

  Future<void> verifyEmail(String verificationToken) async {
    try {
      _setState(AuthState.loading);
      _clearError();

      await _authRepository.verifyEmail(verificationToken);

      // Update user verification status
      if (_user != null) {
        _user = User(
          id: _user!.id,
          name: _user!.name,
          email: _user!.email,
          phone: _user!.phone,
          avatar: _user!.avatar,
          isEmailVerified: true, // Mark as verified
          isAnonymous: _user!.isAnonymous,
          roles: _user!.roles,
          createdAt: _user!.createdAt,
          updatedAt: DateTime.now(),
        );
      }

      _setState(AuthState.authenticated);
    } catch (e) {
      _handleAuthError(e);
    }
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

  // QR Code management methods
  void _ensureUserQRCode() {
    // Run in background, don't block authentication
    Future.microtask(() async {
      try {
        await RewardService.ensureUserHasQRCode();
      } catch (e) {
        // Log error but don't affect auth flow
        debugPrint('Failed to ensure QR code: $e');
      }
    });
  }

  void _initializeNewUserQRCode() {
    // Run in background for new users
    Future.microtask(() async {
      try {
        if (_user?.id != null) {
          await RewardService.initializeUserQRCode(_user!.id);
        }
      } catch (e) {
        // Log error but don't affect auth flow
        debugPrint('Failed to initialize QR code for new user: $e');
      }
    });
  }
}
