import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../models/driver_model.dart';
import 'notification_service.dart';

class PinAuthService {
  // Singleton pattern
  static final PinAuthService _instance = PinAuthService._internal();
  factory PinAuthService() => _instance;
  PinAuthService._internal();

  final _notificationService = NotificationService();

  String? _authToken;
  Driver? _currentDriver;

  String? get authToken => _authToken;
  Driver? get currentDriver => _currentDriver;
  bool get isAuthenticated => _authToken != null && _currentDriver != null;

  // Initialize - Check if user has saved session
  Future<bool> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(AppConstants.authTokenKey);
      final savedDriverData = prefs.getString(AppConstants.driverDataKey);

      if (savedToken != null && savedDriverData != null) {
        _authToken = savedToken;
        _currentDriver = Driver.fromJson(jsonDecode(savedDriverData));

        // Validate token with backend
        final isValid = await validateToken();
        if (isValid) {
          return true;
        } else {
          await logout();
          return false;
        }
      }
      return false;
    } catch (e) {
      print('Error initializing auth: $e');
      return false;
    }
  }

  // PIN Login
  Future<Map<String, dynamic>> loginWithPin(String pin, bool rememberMe) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.pinLoginEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'pin': pin}),
          )
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _authToken = data['token'];
        _currentDriver = Driver.fromJson(data['driver']);

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.authTokenKey, _authToken!);
        await prefs.setString(
          AppConstants.driverDataKey,
          jsonEncode(_currentDriver!.toJson()),
        );
        await prefs.setBool(AppConstants.rememberMeKey, rememberMe);

        if (rememberMe) {
          await prefs.setString(AppConstants.pinKey, pin);
        } else {
          await prefs.remove(AppConstants.pinKey);
        }

        // Enable notifications after login (don't block login if this fails)
        try {
          await _notificationService.setNotificationsEnabled(true);
          print('✅ Notifications enabled after login');
        } catch (e) {
          print('⚠️ Could not enable notifications: $e');
        }

        return {
          'success': true,
          'message': 'Login successful',
          'driver': _currentDriver,
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Connection error. Please check your internet.',
      };
    }
  }

  // QR Login
  Future<Map<String, dynamic>> loginWithQR(String qrCode) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.qrLoginEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'qrCode': qrCode}),
          )
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _authToken = data['token'];
        _currentDriver = Driver.fromJson(data['driver']);

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.authTokenKey, _authToken!);
        await prefs.setString(
          AppConstants.driverDataKey,
          jsonEncode(_currentDriver!.toJson()),
        );

        // Enable notifications after login (don't block login if this fails)
        try {
          await _notificationService.setNotificationsEnabled(true);
          print('✅ Notifications enabled after login');
        } catch (e) {
          print('⚠️ Could not enable notifications: $e');
        }

        return {
          'success': true,
          'message': 'Login successful',
          'driver': _currentDriver,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid QR code',
        };
      }
    } catch (e) {
      print('QR Login error: $e');
      return {
        'success': false,
        'message': 'Connection error. Please check your internet.',
      };
    }
  }

  // Validate Token
  Future<bool> validateToken() async {
    if (_authToken == null) return false;

    try {
      final response = await http
          .get(
            Uri.parse(AppConstants.validateTokenEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_authToken',
            },
          )
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      return response.statusCode == 200;
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }

  // Change PIN
  Future<Map<String, dynamic>> changePin(
    String currentPin,
    String newPin,
  ) async {
    if (_authToken == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.changePinEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_authToken',
            },
            body: jsonEncode({'currentPin': currentPin, 'newPin': newPin}),
          )
          .timeout(Duration(seconds: AppConstants.apiTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update saved PIN if remember me is enabled
        final prefs = await SharedPreferences.getInstance();
        final rememberMe = prefs.getBool(AppConstants.rememberMeKey) ?? false;
        if (rememberMe) {
          await prefs.setString(AppConstants.pinKey, newPin);
        }

        return {
          'success': true,
          'message': data['message'] ?? 'PIN changed successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to change PIN',
        };
      }
    } catch (e) {
      print('Change PIN error: $e');
      return {
        'success': false,
        'message': 'Connection error. Please check your internet.',
      };
    }
  }

  // Get Saved PIN (if remember me enabled)
  Future<String?> getSavedPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(AppConstants.rememberMeKey) ?? false;
      if (rememberMe) {
        return prefs.getString(AppConstants.pinKey);
      }
      return null;
    } catch (e) {
      print('Error getting saved PIN: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Disable notifications immediately on logout (don't block logout if this fails)
      try {
        await _notificationService.setNotificationsEnabled(false);
        print('🔕 Notifications disabled after logout');
      } catch (e) {
        print('⚠️ Could not disable notifications: $e');
      }

      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(AppConstants.rememberMeKey) ?? false;
      final savedPin = prefs.getString(AppConstants.pinKey);

      await prefs.clear();

      // Restore remember me settings if enabled
      if (rememberMe && savedPin != null) {
        await prefs.setBool(AppConstants.rememberMeKey, true);
        await prefs.setString(AppConstants.pinKey, savedPin);
      }

      _authToken = null;
      _currentDriver = null;
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // Get Authorization Header
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_authToken ?? ''}',
    };
  }
}
