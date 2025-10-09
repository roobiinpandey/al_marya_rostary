import '../models/auth_models.dart';

/// Repository interface for authentication operations
abstract class AuthRepository {
  /// Performs user login with email and password
  ///
  /// Returns [AuthResponse] containing user info and tokens on success
  /// Throws [AuthException] if login fails
  Future<AuthResponse> login(String email, String password);

  /// Registers a new user with the provided details
  ///
  /// Returns [AuthResponse] containing user info and tokens on success
  /// Throws [AuthException] if registration fails
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
  });

  /// Logs out the current user
  ///
  /// Throws [AuthException] if logout fails
  Future<void> logout();

  /// Initiates password reset for the given email
  ///
  /// Throws [AuthException] if the request fails
  Future<void> forgotPassword(String email);

  /// Refreshes the authentication token using the refresh token
  ///
  /// Returns [AuthResponse] with new tokens on success
  /// Throws [AuthException] if refresh fails
  Future<AuthResponse> refreshToken(String refreshToken);

  /// Gets the currently authenticated user
  ///
  /// Returns [User] if authenticated, null otherwise
  Future<User?> getCurrentUser();

  /// Updates the user's profile information
  ///
  /// Returns [AuthResponse] containing updated user info and possibly new tokens
  /// Throws [AuthException] if update fails
  Future<AuthResponse> updateProfile(User updatedUser);

  /// Updates the user's profile information with file upload support
  ///
  /// Returns [AuthResponse] containing updated user info and possibly new tokens
  /// Throws [AuthException] if update fails
  Future<AuthResponse> updateProfileWithFile(
    String? name,
    String? phone, 
    dynamic avatarFile, // Using dynamic to avoid dart:io import in interface
  );

  /// Checks if the current session is valid and user is logged in
  ///
  /// Returns true if the user is logged in and session is valid
  Future<bool> isLoggedIn();

  /// Changes the user's password
  ///
  /// Throws [AuthException] if password change fails
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  );
}
