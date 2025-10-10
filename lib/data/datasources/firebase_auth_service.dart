import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import '../../../domain/models/auth_models.dart' as auth_models;
import '../../../domain/models/auth_request_models.dart';

/// Firebase-based authentication service
class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Convert Firebase User to our domain User model
  auth_models.User? _convertFirebaseUser(User? firebaseUser) {
    if (firebaseUser == null) return null;

    return auth_models.User(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      phone: firebaseUser.phoneNumber,
      avatar: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime,
      updatedAt: null,
      isEmailVerified: firebaseUser.emailVerified,
      isAnonymous: firebaseUser.isAnonymous,
      roles: ['user'], // Default role
    );
  }

  /// Create AuthResponse from Firebase User
  Future<auth_models.AuthResponse> _createAuthResponse(
    User firebaseUser, {
    String message = 'Authentication successful',
  }) async {
    final token = await firebaseUser.getIdToken() ?? '';
    final refreshToken = firebaseUser.refreshToken ?? '';

    return auth_models.AuthResponse(
      accessToken: token,
      refreshToken: refreshToken,
      expiresIn: 3600, // 1 hour default
      tokenType: 'Bearer',
      user: _convertFirebaseUser(firebaseUser)!,
    );
  }

  /// Stream of authentication state changes
  Stream<auth_models.User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_convertFirebaseUser);
  }

  /// Check if user is currently logged in
  Future<bool> isLoggedIn() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    // Check if token is still valid
    try {
      await user.getIdToken(true); // Force refresh
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get current user
  Future<auth_models.User?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      // Refresh user data
      await firebaseUser.reload();
      return _convertFirebaseUser(_firebaseAuth.currentUser);
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  /// Register with email and password
  Future<auth_models.AuthResponse> register(RegisterRequest request) async {
    try {
      // Validate password match
      if (request.password != request.confirmPassword) {
        throw auth_models.AuthException('Passwords do not match');
      }

      // Create user
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: request.email,
        password: request.password,
      );

      final user = credential.user;
      if (user == null) {
        throw auth_models.AuthException('Failed to create user');
      }

      // Update display name
      await user.updateDisplayName(request.name);

      // Send email verification
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }

      // Reload user to get updated info
      await user.reload();
      final updatedUser = _firebaseAuth.currentUser;

      if (updatedUser == null) {
        throw auth_models.AuthException('Failed to get updated user info');
      }

      return await _createAuthResponse(
        updatedUser,
        message: 'Registration successful. Please verify your email.',
      );
    } on FirebaseAuthException catch (e) {
      throw auth_models.AuthException(_getErrorMessage(e.code), e.code);
    } catch (e) {
      if (e is auth_models.AuthException) rethrow;
      throw auth_models.AuthException('Registration failed: $e');
    }
  }

  /// Login with email and password
  Future<auth_models.AuthResponse> login(LoginRequest request) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: request.email,
        password: request.password,
      );

      final user = credential.user;
      if (user == null) {
        throw auth_models.AuthException('Login failed: No user returned');
      }

      return await _createAuthResponse(user);
    } on FirebaseAuthException catch (e) {
      throw auth_models.AuthException(_getErrorMessage(e.code), e.code);
    } catch (e) {
      if (e is auth_models.AuthException) rethrow;
      throw auth_models.AuthException('Login failed: $e');
    }
  }

  /// Sign in with Google
  Future<auth_models.AuthResponse> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw auth_models.AuthException('Google Sign-In was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      final user = userCredential.user;
      if (user == null) {
        throw auth_models.AuthException(
          'Google Sign-In failed: No user returned',
        );
      }

      return await _createAuthResponse(
        user,
        message: 'Google Sign-In successful',
      );
    } on FirebaseAuthException catch (e) {
      throw auth_models.AuthException(_getErrorMessage(e.code), e.code);
    } catch (e) {
      if (e is auth_models.AuthException) rethrow;
      throw auth_models.AuthException('Google Sign-In failed: $e');
    }
  }

  /// Sign in with Apple (iOS only)
  Future<auth_models.AuthResponse> signInWithApple() async {
    try {
      if (!Platform.isIOS) {
        throw auth_models.AuthException(
          'Apple Sign-In is only available on iOS',
        );
      }

      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an `OAuthCredential` from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in the user with Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );

      final user = userCredential.user;
      if (user == null) {
        throw auth_models.AuthException(
          'Apple Sign-In failed: No user returned',
        );
      }

      // Update display name if provided by Apple and not already set
      if (user.displayName == null || user.displayName!.isEmpty) {
        final fullName =
            appleCredential.givenName != null &&
                appleCredential.familyName != null
            ? '${appleCredential.givenName} ${appleCredential.familyName}'
            : null;

        if (fullName != null && fullName.isNotEmpty) {
          await user.updateDisplayName(fullName);
          await user.reload();
        }
      }

      return await _createAuthResponse(
        _firebaseAuth.currentUser!,
        message: 'Apple Sign-In successful',
      );
    } on FirebaseAuthException catch (e) {
      throw auth_models.AuthException(_getErrorMessage(e.code), e.code);
    } catch (e) {
      if (e is auth_models.AuthException) rethrow;
      throw auth_models.AuthException('Apple Sign-In failed: $e');
    }
  }

  /// Sign in as guest (anonymous)
  Future<auth_models.AuthResponse> loginAsGuest() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();

      final user = credential.user;
      if (user == null) {
        throw auth_models.AuthException(
          'Anonymous sign-in failed: No user returned',
        );
      }

      return await _createAuthResponse(user, message: 'Signed in as guest');
    } on FirebaseAuthException catch (e) {
      throw auth_models.AuthException(_getErrorMessage(e.code), e.code);
    } catch (e) {
      if (e is auth_models.AuthException) rethrow;
      throw auth_models.AuthException('Guest sign-in failed: $e');
    }
  }

  /// Send password reset email
  Future<void> forgotPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw auth_models.AuthException(_getErrorMessage(e.code), e.code);
    } catch (e) {
      throw auth_models.AuthException('Password reset failed: $e');
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw auth_models.AuthException('No authenticated user found');
      }

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw auth_models.AuthException(_getErrorMessage(e.code), e.code);
    } catch (e) {
      throw auth_models.AuthException('Failed to send email verification: $e');
    }
  }

  /// Refresh authentication token
  Future<auth_models.AuthResponse> refreshToken(String refreshToken) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw auth_models.AuthException('No authenticated user found');
      }

      // Force token refresh
      await user.getIdToken(true);

      return await _createAuthResponse(
        user,
        message: 'Token refreshed successfully',
      );
    } on FirebaseAuthException catch (e) {
      throw auth_models.AuthException(_getErrorMessage(e.code), e.code);
    } catch (e) {
      if (e is auth_models.AuthException) rethrow;
      throw auth_models.AuthException('Token refresh failed: $e');
    }
  }

  /// Update user profile
  Future<auth_models.User> updateProfile({
    String? name,
    String? photoURL,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw auth_models.AuthException('No authenticated user found');
      }

      if (name != null) {
        await user.updateDisplayName(name);
      }

      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Reload user to get updated info
      await user.reload();
      final updatedUser = _firebaseAuth.currentUser;

      if (updatedUser == null) {
        throw auth_models.AuthException('Failed to get updated user info');
      }

      final domainUser = _convertFirebaseUser(updatedUser);
      if (domainUser == null) {
        throw auth_models.AuthException('Failed to convert updated user');
      }

      return domainUser;
    } on FirebaseAuthException catch (e) {
      throw auth_models.AuthException(_getErrorMessage(e.code), e.code);
    } catch (e) {
      if (e is auth_models.AuthException) rethrow;
      throw auth_models.AuthException('Profile update failed: $e');
    }
  }

  /// Changes the current user's password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        throw auth_models.AuthException('No authenticated user found');
      }

      // Validate new password confirmation
      if (newPassword != confirmPassword) {
        throw auth_models.AuthException(
          'New password and confirmation do not match',
        );
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw auth_models.AuthException(_getErrorMessage(e.code), e.code);
    } catch (e) {
      if (e is auth_models.AuthException) rethrow;
      throw auth_models.AuthException('Failed to change password: $e');
    }
  }

  /// Sign out current user
  Future<void> logout() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Firebase
      await _firebaseAuth.signOut();
    } catch (e) {
      throw auth_models.AuthException('Logout failed: $e');
    }
  }

  /// Delete current user account
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw auth_models.AuthException('No authenticated user found');
      }

      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw auth_models.AuthException(_getErrorMessage(e.code), e.code);
    } catch (e) {
      if (e is auth_models.AuthException) rethrow;
      throw auth_models.AuthException('Failed to delete account: $e');
    }
  }

  /// Convert Firebase error codes to user-friendly messages
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not allowed.';
      case 'invalid-credential':
        return 'The supplied auth credential is malformed or has expired.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      case 'requires-recent-login':
        return 'This operation is sensitive and requires recent authentication. Log in again before retrying.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
