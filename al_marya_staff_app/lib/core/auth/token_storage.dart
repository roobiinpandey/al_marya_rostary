import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/staff.dart';
import '../constants/app_constants.dart';

/// Service for storing and retrieving authentication tokens and staff data
class TokenStorage {
  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure SharedPreferences is initialized
  static Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // ===== Token Management =====

  /// Save authentication token
  static Future<bool> saveToken(String token) async {
    final prefs = await _getPrefs();
    return await prefs.setString(AppConstants.tokenKey, token);
  }

  /// Get authentication token
  static Future<String?> getToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.tokenKey);
  }

  /// Delete authentication token
  static Future<bool> deleteToken() async {
    final prefs = await _getPrefs();
    return await prefs.remove(AppConstants.tokenKey);
  }

  /// Check if token exists
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ===== Staff Data Management =====

  /// Save complete staff data
  static Future<bool> saveStaffData(Staff staff) async {
    final prefs = await _getPrefs();

    // Save as JSON string
    final staffJson = jsonEncode(staff.toJson());
    final result = await prefs.setString('staff_data', staffJson);

    // Also save individual fields for quick access
    await prefs.setString(AppConstants.staffIdKey, staff.id);
    await prefs.setString(AppConstants.staffEmailKey, staff.email);
    await prefs.setString(AppConstants.staffNameKey, staff.name);
    await prefs.setString(AppConstants.staffRoleKey, staff.role);

    return result;
  }

  /// Get complete staff data
  static Future<Staff?> getStaffData() async {
    final prefs = await _getPrefs();
    final staffJson = prefs.getString('staff_data');

    if (staffJson == null || staffJson.isEmpty) {
      return null;
    }

    try {
      final staffMap = jsonDecode(staffJson) as Map<String, dynamic>;
      return Staff.fromJson(staffMap);
    } catch (e) {
      // If parsing fails, return null
      return null;
    }
  }

  /// Get staff ID (quick access)
  static Future<String?> getStaffId() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.staffIdKey);
  }

  /// Get staff email (quick access)
  static Future<String?> getStaffEmail() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.staffEmailKey);
  }

  /// Get staff name (quick access)
  static Future<String?> getStaffName() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.staffNameKey);
  }

  /// Get staff role (quick access)
  static Future<String?> getStaffRole() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.staffRoleKey);
  }

  // ===== FCM Token Management =====

  /// Save FCM token
  static Future<bool> saveFcmToken(String token) async {
    final prefs = await _getPrefs();
    return await prefs.setString(AppConstants.fcmTokenKey, token);
  }

  /// Get FCM token
  static Future<String?> getFcmToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.fcmTokenKey);
  }

  /// Delete FCM token
  static Future<bool> deleteFcmToken() async {
    final prefs = await _getPrefs();
    return await prefs.remove(AppConstants.fcmTokenKey);
  }

  // ===== Clear All Data =====

  /// Clear all authentication and staff data (logout)
  static Future<bool> clearAll() async {
    final prefs = await _getPrefs();

    // Remove all app-related keys
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove('staff_data');
    await prefs.remove(AppConstants.staffIdKey);
    await prefs.remove(AppConstants.staffEmailKey);
    await prefs.remove(AppConstants.staffNameKey);
    await prefs.remove(AppConstants.staffRoleKey);
    await prefs.remove(AppConstants.fcmTokenKey);

    return true;
  }

  // ===== Utility Methods =====

  /// Check if user is logged in (has both token and staff data)
  static Future<bool> isLoggedIn() async {
    final hasToken = await TokenStorage.hasToken();
    final staffData = await getStaffData();
    return hasToken && staffData != null;
  }

  /// Get all stored keys (for debugging)
  static Future<Set<String>> getAllKeys() async {
    final prefs = await _getPrefs();
    return prefs.getKeys();
  }

  /// Print all stored data (for debugging)
  static Future<void> printAllData() async {
    final prefs = await _getPrefs();
    final keys = prefs.getKeys();

    print('=== Token Storage Data ===');
    for (final key in keys) {
      final value = prefs.get(key);
      print('$key: $value');
    }
    print('=========================');
  }
}
