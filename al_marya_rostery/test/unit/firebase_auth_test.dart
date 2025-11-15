import 'package:flutter_test/flutter_test.dart';
import 'package:qahwat_al_emarat/domain/models/auth_request_models.dart';
import 'package:qahwat_al_emarat/domain/models/auth_models.dart';

void main() {
  group('Firebase Auth Models', () {
    test('should handle login request structure', () {
      final loginRequest = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(loginRequest.email, equals('test@example.com'));
      expect(loginRequest.password, equals('password123'));
    });

    test('should handle register request structure', () {
      final registerRequest = RegisterRequest(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        confirmPassword: 'password123',
        phone: '+971501234567',
      );

      expect(registerRequest.name, equals('Test User'));
      expect(registerRequest.email, equals('test@example.com'));
      expect(registerRequest.password, equals('password123'));
      expect(registerRequest.confirmPassword, equals('password123'));
      expect(registerRequest.phone, equals('+971501234567'));
    });

    test('should create User model with required fields', () {
      final user = User(
        id: 'user123',
        name: 'Test User',
        email: 'test@example.com',
        isEmailVerified: true,
        roles: ['user'],
      );

      expect(user.id, equals('user123'));
      expect(user.name, equals('Test User'));
      expect(user.email, equals('test@example.com'));
      expect(user.isEmailVerified, isTrue);
      expect(user.roles, contains('user'));
      expect(user.isAnonymous, isFalse); // Default value
    });

    test('should create AuthResponse model with required fields', () {
      final user = User(
        id: 'user123',
        name: 'Test User',
        email: 'test@example.com',
        isEmailVerified: true,
        roles: ['user'],
      );

      final authResponse = AuthResponse(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_123',
        expiresIn: 3600,
        tokenType: 'Bearer',
        user: user,
      );

      expect(authResponse.accessToken, equals('access_token_123'));
      expect(authResponse.refreshToken, equals('refresh_token_123'));
      expect(authResponse.expiresIn, equals(3600));
      expect(authResponse.tokenType, equals('Bearer'));
      expect(authResponse.user.id, equals('user123'));
    });

    test('should create AuthException with message and code', () {
      final exception = AuthException(
        'Authentication failed',
        'auth/invalid-credentials',
      );

      expect(exception.message, equals('Authentication failed'));
      expect(exception.code, equals('auth/invalid-credentials'));
      expect(exception.toString(), contains('Authentication failed'));
      expect(exception.toString(), contains('auth/invalid-credentials'));
    });

    test('should create AuthException with message only', () {
      final exception = AuthException('Authentication failed');

      expect(exception.message, equals('Authentication failed'));
      expect(exception.code, isNull);
      expect(exception.toString(), contains('Authentication failed'));
    });
  });
}
