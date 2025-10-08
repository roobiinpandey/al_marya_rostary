import 'package:flutter/foundation.dart';
import '../../../domain/models/auth_models.dart';
import '../../../domain/models/auth_request_models.dart';

/// MockAuthApiService provides a mock implementation of authentication APIs for
/// development, testing, and offline functionality. It simulates network delays
/// and common authentication scenarios.
class MockAuthApiService {
  static const _mockNetworkDelays = {
    'login': Duration(seconds: 1),
    'register': Duration(seconds: 1),
    'logout': Duration(milliseconds: 500),
    'refresh': Duration(milliseconds: 500),
    'profile': Duration(milliseconds: 300),
    'password': Duration(seconds: 1),
  };
  static const _tokenDuration = Duration(hours: 1);
  static const _tokenType = 'Bearer';

  // Mock user database
  final Map<String, Map<String, dynamic>> _mockUsers = {
    'test@example.com': {
      'password': 'password',
      'user': <String, dynamic>{
        'id': '1',
        'name': 'Test User',
        'email': 'test@example.com',
        'phone': '+971501234567',
        'avatar': null,
        'createdAt': DateTime(2024).toIso8601String(),
        'updatedAt': DateTime(2024).toIso8601String(),
        'isEmailVerified': true,
        'isAnonymous': false,
        'roles': ['customer'],
      },
    },
    'admin@demo.com': {
      'password': 'admin123',
      'user': <String, dynamic>{
        'id': '2',
        'name': 'Admin User',
        'email': 'admin@demo.com',
        'phone': '+971509876543',
        'avatar': null,
        'createdAt': DateTime(2024).toIso8601String(),
        'updatedAt': DateTime(2024).toIso8601String(),
        'isEmailVerified': true,
        'isAnonymous': false,
        'roles': ['admin', 'customer'],
      },
    },
  };

  // Mock registered users for registration validation
  final Set<String> _registeredEmails = {'test@example.com', 'admin@demo.com'};

  // Token generation helpers
  String _generateAccessToken(String userId) {
    debugPrint('🔑 Generating mock access token for user $userId');
    return 'mock_access_token_${userId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateRefreshToken(String userId) {
    debugPrint('🔄 Generating mock refresh token for user $userId');
    return 'mock_refresh_token_${userId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  AuthResponse _generateAuthResponse(User user) {
    final accessToken = _generateAccessToken(user.id);
    final refreshToken = _generateRefreshToken(user.id);
    debugPrint(
      '👤 Generated auth response for user ${user.id} (${user.email})',
    );
    return AuthResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: _tokenDuration.inSeconds,
      tokenType: _tokenType,
      user: user,
    );
  }

  // Token validation helpers
  String _extractUserIdFromToken(String token, String type) {
    final parts = token.split('_');
    if (parts.length < 4 ||
        parts[0] != 'mock' ||
        parts[1] != type ||
        parts[2] != 'token') {
      throw AuthException('Invalid $type token format', 'INVALID_TOKEN');
    }
    return parts[3].split('_')[0]; // Get the user ID part
  }

  String _validateAccessToken(String token) {
    try {
      return _extractUserIdFromToken(token, 'access');
    } catch (e) {
      throw AuthException('Invalid access token', 'INVALID_TOKEN');
    }
  }

  String _validateRefreshToken(String token) {
    try {
      return _extractUserIdFromToken(token, 'refresh');
    } catch (e) {
      throw AuthException('Invalid refresh token', 'INVALID_TOKEN');
    }
  }

  // API Methods
  Future<AuthResponse> login(LoginRequest request) async {
    await Future.delayed(_mockNetworkDelays['login']!);
    final userData = _mockUsers[request.email];
    if (userData == null || userData['password'] != request.password) {
      throw AuthException(
        'Invalid email or password. Try: test@example.com / password or admin@demo.com / admin123',
        'INVALID_CREDENTIALS',
      );
    }
    final user = User.fromJson(userData['user']);
    return _generateAuthResponse(user);
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    await Future.delayed(_mockNetworkDelays['register']!);
    if (_registeredEmails.contains(request.email)) {
      throw AuthException('Email already exists', 'EMAIL_EXISTS');
    }
    if (request.password != request.confirmPassword) {
      throw AuthException('Passwords do not match', 'PASSWORD_MISMATCH');
    }
    final userId = (_mockUsers.length + 1).toString();
    final now = DateTime.now();
    final newUser = <String, dynamic>{
      'id': userId,
      'name': request.name,
      'email': request.email,
      'phone': request.phone,
      'avatar': null,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'isEmailVerified': false,
      'isAnonymous': false,
      'roles': ['customer'],
    };
    _mockUsers[request.email] = {'password': request.password, 'user': newUser};
    _registeredEmails.add(request.email);
    return _generateAuthResponse(User.fromJson(newUser));
  }

  Future<void> logout(String token) async {
    await Future.delayed(_mockNetworkDelays['logout']!);
    _validateAccessToken(token);
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    await Future.delayed(_mockNetworkDelays['refresh']!);
    final userId = _validateRefreshToken(refreshToken);
    final user = _mockUsers.values.firstWhere(
      (userData) => userData['user']['id'] == userId,
      orElse: () => throw AuthException('User not found', 'USER_NOT_FOUND'),
    )['user'];
    return _generateAuthResponse(User.fromJson(user));
  }

  Future<User> getCurrentUser(String token) async {
    await Future.delayed(_mockNetworkDelays['profile']!);
    final userId = _validateAccessToken(token);
    final user = _mockUsers.values.firstWhere(
      (userData) => userData['user']['id'] == userId,
      orElse: () => throw AuthException('User not found', 'USER_NOT_FOUND'),
    )['user'];
    return User.fromJson(user);
  }

  Future<void> forgotPassword(String email) async {
    await Future.delayed(_mockNetworkDelays['password']!);
    if (!_mockUsers.containsKey(email)) {
      throw AuthException('Email not found', 'EMAIL_NOT_FOUND');
    }
    debugPrint('📧 Password reset email would be sent to: $email');
  }

  Future<void> resetPassword(ResetPasswordRequest request) async {
    await Future.delayed(_mockNetworkDelays['password']!);
    if (request.password != request.confirmPassword) {
      throw AuthException('Passwords do not match', 'PASSWORD_MISMATCH');
    }
    debugPrint('🔐 Password would be reset (validation would be performed)');
  }

  Future<void> changePassword(
    String token,
    ChangePasswordRequest request,
  ) async {
    await Future.delayed(_mockNetworkDelays['password']!);
    final userId = _validateAccessToken(token);
    final userEntry = _mockUsers.entries.firstWhere(
      (entry) => entry.value['user']['id'] == userId,
      orElse: () => throw AuthException('User not found', 'USER_NOT_FOUND'),
    );
    if (userEntry.value['password'] != request.currentPassword) {
      throw AuthException('Current password is incorrect', 'INVALID_PASSWORD');
    }
    if (request.newPassword != request.confirmNewPassword) {
      throw AuthException('New passwords do not match', 'PASSWORD_MISMATCH');
    }
    userEntry.value['password'] = request.newPassword;
    debugPrint('🔐 Password changed for user: $userId');
  }

  Future<AuthResponse> updateProfile(String token, User updatedUser) async {
    await Future.delayed(_mockNetworkDelays['profile']!);
    final userId = _validateAccessToken(token);
    final userEntry = _mockUsers.entries.firstWhere(
      (entry) => entry.value['user']['id'] == userId,
      orElse: () => throw AuthException('User not found', 'USER_NOT_FOUND'),
    );
    final userData = userEntry.value['user'] as Map<String, dynamic>;
    userData['name'] = updatedUser.name;
    userData['phone'] = updatedUser.phone;
    userData['avatar'] = updatedUser.avatar;
    userData['updatedAt'] = DateTime.now().toIso8601String();
    debugPrint('👤 Profile updated for user: $userId');
    return _generateAuthResponse(User.fromJson(userData));
  }
}
