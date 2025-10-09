// import 'dart:convert';  // Temporarily disabled
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';  // Temporarily disabled
import '../../domain/repositories/auth_repository.dart';
import '../../domain/models/auth_models.dart';
import '../../domain/models/auth_request_models.dart';
import '../datasources/auth_api_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService _authApiService;
  // final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();  // Temporarily disabled

  AuthRepositoryImpl(this._authApiService);

  @override
  Future<AuthResponse> login(String email, String password) async {
    final response = await _authApiService.login(
      LoginRequest(email: email, password: password),
    );
    await _saveAuthState(response);
    return response;
  }

  @override
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
  }) async {
    final response = await _authApiService.register(
      RegisterRequest(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        phone: phone,
      ),
    );
    await _saveAuthState(response);
    return response;
  }

  @override
  Future<void> logout() async {
    final authState = await _getSavedAuthState();
    if (authState != null) {
      await _authApiService.logout(authState.accessToken);
    }
    await _clearAuthState();
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _authApiService.forgotPassword(email);
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmNewPassword,
  ) async {
    final authState = await _getSavedAuthState();
    if (authState == null) throw AuthException('No authentication state found');

    await _authApiService.changePassword(
      authState.accessToken,
      ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      ),
    );
  }

  @override
  Future<AuthResponse> refreshToken(String refreshToken) async {
    final response = await _authApiService.refreshToken(refreshToken);
    await _saveAuthState(response);
    return response;
  }

  @override
  Future<User?> getCurrentUser() async {
    final authState = await _getSavedAuthState();
    if (authState == null) {
      return null;
    }
    try {
      return await _authApiService.getCurrentUser(authState.accessToken);
    } catch (e) {
      await _clearAuthState();
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final authState = await _getSavedAuthState();
    return authState != null;
  }

  Future<AuthResponse?> _getSavedAuthState() async {
    // Temporarily disabled - secure storage not available
    return null;
    /*
    final tokensJson = await _secureStorage.read(key: 'auth_state');
    if (tokensJson == null) {
      return null;
    }

    try {
      return AuthResponse.fromJson(jsonDecode(tokensJson));
    } catch (e) {
      await _clearAuthState();
      return null;
    }
    */
  }

  Future<void> _saveAuthState(AuthResponse authResponse) async {
    // Temporarily disabled - secure storage not available
    /*
    await _secureStorage.write(
      key: 'auth_state',
      value: jsonEncode(authResponse.toJson()),
    );
    */
  }

  Future<void> _clearAuthState() async {
    // Temporarily disabled - secure storage not available
    /*
    await _secureStorage.delete(key: 'auth_state');
    */
  }

  @override
  Future<AuthResponse> updateProfile(User updatedUser) async {
    final authState = await _getSavedAuthState();
    if (authState == null) {
      throw AuthException('No authentication state found');
    }

    final response = await _authApiService.updateProfile(
      authState.accessToken,
      updatedUser,
    );

    await _saveAuthState(response);
    return response;
  }

  @override
  Future<AuthResponse> updateProfileWithFile(
    String? name,
    String? phone,
    dynamic avatarFile,
  ) async {
    final authState = await _getSavedAuthState();
    if (authState == null) {
      throw AuthException('No authentication state found');
    }

    final response = await _authApiService.updateProfileWithFile(
      authState.accessToken,
      name,
      phone,
      avatarFile,
    );

    await _saveAuthState(response);
    return response;
  }
}
