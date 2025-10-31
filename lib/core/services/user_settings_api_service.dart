import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

/// API Service for user settings and profile management
class UserSettingsApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Get authentication headers with token
  Future<Map<String, String>> get _authHeaders async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get current user ID from storage
  Future<String?> _getCurrentUserId() async {
    return await _storage.read(key: 'user_id');
  }

  // ==================== PROFILE ====================

  /// Get current user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      debugPrint(
        '📱 UserSettingsApiService: Fetching profile for user: $userId',
      );

      final headers = await _authHeaders;
      final response = await _dio.get(
        '/api/users/$userId',
        options: Options(headers: headers),
      );

      debugPrint('✅ UserSettingsApiService: Profile fetched successfully');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      debugPrint('❌ UserSettingsApiService: DioException: ${e.message}');

      if (e.response?.statusCode == 404) {
        throw Exception('User not found');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please login again.');
      }

      throw Exception('Failed to fetch profile: ${e.message}');
    } catch (e) {
      debugPrint('❌ UserSettingsApiService: Error: $e');
      throw Exception('Failed to fetch profile: $e');
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      debugPrint(
        '📱 UserSettingsApiService: Updating profile for user: $userId',
      );

      final headers = await _authHeaders;

      // Build update data - only include non-null fields
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (phone != null) updateData['phone'] = phone;

      // Handle preferences
      if (preferences != null) {
        updateData['preferences'] = preferences;
      } else if (address != null) {
        // If address is provided separately, add to preferences
        updateData['preferences'] = {'address': address};
      }

      debugPrint('📤 UserSettingsApiService: Update data: ${updateData.keys}');

      final response = await _dio.put(
        '/api/users/$userId',
        data: updateData,
        options: Options(headers: headers),
      );

      debugPrint('✅ UserSettingsApiService: Profile updated successfully');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      debugPrint('❌ UserSettingsApiService: DioException: ${e.message}');

      if (e.response?.statusCode == 404) {
        throw Exception('User not found');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please login again.');
      } else if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Invalid data';
        throw Exception(message);
      }

      throw Exception('Failed to update profile: ${e.message}');
    } catch (e) {
      debugPrint('❌ UserSettingsApiService: Error: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  // ==================== NOTIFICATION PREFERENCES ====================

  /// Update notification preferences
  Future<Map<String, dynamic>> updateNotificationPreferences({
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
    bool? orderUpdates,
    bool? promotions,
    bool? newsletter,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      debugPrint(
        '📱 UserSettingsApiService: Updating notification preferences',
      );

      final headers = await _authHeaders;

      // Build notification preferences
      final notificationPrefs = <String, dynamic>{};
      if (emailNotifications != null)
        notificationPrefs['email'] = emailNotifications;
      if (pushNotifications != null)
        notificationPrefs['push'] = pushNotifications;
      if (smsNotifications != null) notificationPrefs['sms'] = smsNotifications;
      if (orderUpdates != null)
        notificationPrefs['orderUpdates'] = orderUpdates;
      if (promotions != null) notificationPrefs['promotions'] = promotions;
      if (newsletter != null) notificationPrefs['newsletter'] = newsletter;

      final updateData = {
        'preferences': {'notifications': notificationPrefs},
      };

      final response = await _dio.put(
        '/api/users/$userId',
        data: updateData,
        options: Options(headers: headers),
      );

      debugPrint('✅ UserSettingsApiService: Notification preferences updated');
      return response.data['data'] ?? response.data;
    } catch (e) {
      debugPrint('❌ UserSettingsApiService: Error: $e');
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  // ==================== LANGUAGE & CURRENCY ====================

  /// Update language preference
  Future<Map<String, dynamic>> updateLanguage(String language) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      debugPrint('📱 UserSettingsApiService: Updating language to: $language');

      final headers = await _authHeaders;

      final updateData = {
        'preferences': {'language': language},
      };

      final response = await _dio.put(
        '/api/users/$userId',
        data: updateData,
        options: Options(headers: headers),
      );

      debugPrint('✅ UserSettingsApiService: Language updated');
      return response.data['data'] ?? response.data;
    } catch (e) {
      debugPrint('❌ UserSettingsApiService: Error: $e');
      throw Exception('Failed to update language: $e');
    }
  }

  /// Update currency preference
  Future<Map<String, dynamic>> updateCurrency(String currency) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      debugPrint('📱 UserSettingsApiService: Updating currency to: $currency');

      final headers = await _authHeaders;

      final updateData = {
        'preferences': {'currency': currency},
      };

      final response = await _dio.put(
        '/api/users/$userId',
        data: updateData,
        options: Options(headers: headers),
      );

      debugPrint('✅ UserSettingsApiService: Currency updated');
      return response.data['data'] ?? response.data;
    } catch (e) {
      debugPrint('❌ UserSettingsApiService: Error: $e');
      throw Exception('Failed to update currency: $e');
    }
  }

  // ==================== PASSWORD ====================

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      debugPrint('📱 UserSettingsApiService: Changing password');

      final headers = await _authHeaders;

      final updateData = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };

      await _dio.put(
        '/api/users/$userId/password',
        data: updateData,
        options: Options(headers: headers),
      );

      debugPrint('✅ UserSettingsApiService: Password changed successfully');
    } on DioException catch (e) {
      debugPrint('❌ UserSettingsApiService: DioException: ${e.message}');

      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Invalid password';
        throw Exception(message);
      } else if (e.response?.statusCode == 401) {
        throw Exception('Current password is incorrect');
      }

      throw Exception('Failed to change password: ${e.message}');
    } catch (e) {
      debugPrint('❌ UserSettingsApiService: Error: $e');
      throw Exception('Failed to change password: $e');
    }
  }

  // ==================== ACCOUNT ====================

  /// Delete user account
  Future<void> deleteAccount({required String password}) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      debugPrint('📱 UserSettingsApiService: Deleting account');

      final headers = await _authHeaders;

      await _dio.delete(
        '/api/users/$userId',
        data: {'password': password},
        options: Options(headers: headers),
      );

      // Clear local storage
      await _storage.deleteAll();

      debugPrint('✅ UserSettingsApiService: Account deleted successfully');
    } on DioException catch (e) {
      debugPrint('❌ UserSettingsApiService: DioException: ${e.message}');

      if (e.response?.statusCode == 401) {
        throw Exception('Incorrect password');
      }

      throw Exception('Failed to delete account: ${e.message}');
    } catch (e) {
      debugPrint('❌ UserSettingsApiService: Error: $e');
      throw Exception('Failed to delete account: $e');
    }
  }

  // ==================== VALIDATION ====================

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number format
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  /// Get password strength message
  static String getPasswordStrengthMessage(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return 'Password is strong';
  }
}
