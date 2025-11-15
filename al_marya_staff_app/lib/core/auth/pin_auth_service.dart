import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// PIN + QR Badge Authentication Service
/// Handles staff authentication using Employee ID + PIN or QR badge scanning
class PinAuthService {
  static const String baseUrl =
      'https://almaryarostary.onrender.com/api/staff/auth';

  // Cache keys
  static const String _tokenKey = 'staff_token';
  static const String _staffDataKey = 'staff_data';
  static const String _employeeIdKey = 'employee_id';
  static const String _lastLoginKey = 'last_login';

  /// Login with 4-6 digit PIN only (no Employee ID required)
  Future<Map<String, dynamic>> loginWithPin({required String pin}) async {
    try {
      print('🔐 Attempting PIN-only login to: $baseUrl/login-pin');
      print('🔐 PIN length: ${pin.length} digits');

      final response = await http.post(
        Uri.parse('$baseUrl/login-pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin}),
      );

      print('🔐 Response status: ${response.statusCode}');
      print('🔐 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Save token and staff data
        await _saveAuthData(
          token: data['token'],
          staffData: data['staff'],
          employeeId: data['staff']['employeeId'],
        );

        print('✅ Login successful! Staff: ${data['staff']['name']}');

        return {
          'success': true,
          'token': data['token'],
          'staff': data['staff'],
          'requirePinChange': data['requirePinChange'] ?? false,
        };
      } else if (response.statusCode == 423) {
        // PIN locked
        return {
          'success': false,
          'error': data['message'] ?? 'PIN locked. Please try again later.',
          'locked': true,
          'lockedUntil': data['lockedUntil'],
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Invalid PIN. Please try again.',
          'attemptsRemaining': data['attemptsLeft'],
        };
      }
    } catch (e) {
      print('❌ Login error: $e');
      return {
        'success': false,
        'error': 'Connection error. Please check your internet connection.',
        'exception': e.toString(),
      };
    }
  }

  /// Login with QR badge scan
  Future<Map<String, dynamic>> loginWithQR({required String qrToken}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login-qr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'qrToken': qrToken}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Save token and staff data
        await _saveAuthData(
          token: data['token'],
          staffData: data['staff'],
          employeeId: data['staff']['employeeId'],
        );

        return {
          'success': true,
          'token': data['token'],
          'staff': data['staff'],
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Invalid or expired QR badge',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error. Please check your internet connection.',
        'exception': e.toString(),
      };
    }
  }

  /// Change staff PIN
  Future<Map<String, dynamic>> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/change-pin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'currentPin': currentPin, 'newPin': newPin}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'PIN changed successfully',
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to change PIN',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error. Please try again.',
        'exception': e.toString(),
      };
    }
  }

  /// Validate current session
  Future<Map<String, dynamic>> validateSession() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'error': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/session'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Update cached staff data
        await _updateStaffData(data['staff']);

        return {
          'success': true,
          'staff': data['staff'],
          'isOnShift': data['staff']['isOnShift'] ?? false,
        };
      } else {
        // Token expired or invalid
        await logout();
        return {'success': false, 'error': 'Session expired'};
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error',
        'exception': e.toString(),
      };
    }
  }

  /// Logout (clear local data)
  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        // Notify server (optional, token is deleted client-side)
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }
    } catch (e) {
      // Ignore server errors on logout
    }

    // Clear local storage
    await _clearAuthData();
  }

  /// Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get stored staff data
  Future<Map<String, dynamic>?> getStaffData() async {
    final prefs = await SharedPreferences.getInstance();
    final staffJson = prefs.getString(_staffDataKey);
    if (staffJson != null) {
      return jsonDecode(staffJson);
    }
    return null;
  }

  /// Get last used Employee ID (kept for reference, auto-saved after login)
  Future<String?> getLastEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_employeeIdKey);
  }

  /// Get staff name from cached data
  Future<String?> getStaffName() async {
    final staffData = await getStaffData();
    return staffData?['name'] as String?;
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;

    // Validate token with server
    final result = await validateSession();
    return result['success'] == true;
  }

  /// Save authentication data
  Future<void> _saveAuthData({
    required String token,
    required Map<String, dynamic> staffData,
    required String employeeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_staffDataKey, jsonEncode(staffData));
    await prefs.setString(_employeeIdKey, employeeId);
    await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
  }

  /// Update cached staff data
  Future<void> _updateStaffData(Map<String, dynamic> staffData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_staffDataKey, jsonEncode(staffData));
  }

  /// Clear all authentication data
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_staffDataKey);
    // Keep employee ID for convenience on next login
    // await prefs.remove(_employeeIdKey);
    await prefs.remove(_lastLoginKey);
  }
}
