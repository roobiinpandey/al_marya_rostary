import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/app_constants.dart';

/// OAuth Authentication Service
/// Handles Google, Facebook, and Apple Sign In
class OAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Sign in with Google
  /// Returns: Map with success status, user data, and token
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      print('🔵 Starting Google Sign In...');
      
      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return {
          'success': false,
          'message': 'Google sign in cancelled by user',
        };
      }

      print('✅ Google account selected: ${googleUser.email}');

      // Get auth details
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);

      print('✅ Firebase authentication successful');

      // Get ID token for backend
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw Exception('Failed to get ID token from Firebase');
      }

      print('📡 Sending token to backend...');

      // Send to backend
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/google'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'idToken': idToken,
        }),
      );

      print('📡 Backend response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          // Save token
          await _secureStorage.write(
            key: 'auth_token',
            value: data['token'],
          );

          print('✅ Google login successful: ${data['user']['email']}');
          print('👤 User ID: ${data['user']['id']}');

          return {
            'success': true,
            'user': data['user'],
            'token': data['token'],
            'message': data['message'] ?? 'Login successful',
          };
        }
      }

      // Parse error message
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Backend authentication failed');

    } on FirebaseAuthException catch (e) {
      print('❌ Firebase auth error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': _getFirebaseErrorMessage(e.code),
      };
    } catch (e) {
      print('❌ Google sign in error: $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  /// Sign in with Facebook
  /// Note: Requires flutter_facebook_auth package
  /// Returns: Map with success status, user data, and token
  Future<Map<String, dynamic>> signInWithFacebook() async {
    try {
      print('📘 Facebook Sign In not yet implemented');
      
      // Placeholder for Facebook authentication
      // You need to add flutter_facebook_auth package to use this
      
      return {
        'success': false,
        'message': 'Facebook login is not yet configured. Please use Google or email login.',
      };
      
      // Uncomment when flutter_facebook_auth is added:
      /*
      print('📘 Starting Facebook Sign In...');
      
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        return {
          'success': false,
          'message': 'Facebook login cancelled or failed',
        };
      }

      print('✅ Facebook login successful');

      final AccessToken? accessToken = result.accessToken;
      
      if (accessToken == null) {
        throw Exception('Failed to get Facebook access token');
      }

      print('📡 Sending token to backend...');

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/facebook'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'accessToken': accessToken.tokenString,
        }),
      );

      print('📡 Backend response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          await _secureStorage.write(
            key: 'auth_token',
            value: data['token'],
          );

          print('✅ Facebook authentication successful: ${data['user']['email']}');

          return {
            'success': true,
            'user': data['user'],
            'token': data['token'],
            'message': data['message'] ?? 'Login successful',
          };
        }
      }

      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Backend authentication failed');
      */
      
    } catch (e) {
      print('❌ Facebook sign in error: $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  /// Sign in with Apple
  /// Returns: Map with success status, user data, and token
  Future<Map<String, dynamic>> signInWithApple() async {
    try {
      print('🍎 Apple Sign In not yet implemented');
      
      return {
        'success': false,
        'message': 'Apple login is not yet configured. Please use Google or email login.',
      };
      
    } catch (e) {
      print('❌ Apple sign in error: $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
        _secureStorage.delete(key: 'auth_token'),
      ]);
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Sign out error: $e');
      rethrow;
    }
  }

  /// Get current Firebase user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  /// Check if user is signed in
  bool isSignedIn() {
    return _firebaseAuth.currentUser != null;
  }

  /// Get auth token from storage
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  /// Helper method to get user-friendly error messages
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in method.';
      case 'invalid-credential':
        return 'The credential is invalid or has expired.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this credential.';
      case 'wrong-password':
        return 'Invalid password.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
