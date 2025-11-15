import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_endpoints.dart';

/// Service for Staff Admin Authentication (Product Management Access)
/// Separate from regular staff PIN authentication
class StaffAdminAuthService {
  static final StaffAdminAuthService _instance =
      StaffAdminAuthService._internal();
  factory StaffAdminAuthService() => _instance;
  StaffAdminAuthService._internal();

  // SharedPreferences keys
  static const String _adminTokenKey = 'staff_admin_token';
  static const String _hasAdminAccessKey = 'has_admin_access';
  static const String _adminUsernameKey = 'admin_username';
  static const String _staffIdKey = 'staff_id';
  static const String _staffNameKey = 'staff_name';
  static const String _staffRoleKey = 'staff_role';

  String? _adminToken;
  bool _hasAdminAccess = false;

  /// Initialize and load saved admin session
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _adminToken = prefs.getString(_adminTokenKey);
    _hasAdminAccess = prefs.getBool(_hasAdminAccessKey) ?? false;
  }

  /// Login with staff admin credentials
  /// Returns success status and message
  Future<Map<String, dynamic>> adminLogin({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/api/staff/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        // Save admin token and session
        final token = data['token'] as String;
        final staff = data['staff'] as Map<String, dynamic>;

        await _saveAdminSession(
          token: token,
          staffId: staff['id'] as String,
          staffName: staff['name'] as String,
          staffRole: staff['role'] as String,
          adminUsername: username,
        );

        return {'success': true, 'message': 'Login successful', 'staff': staff};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Save admin session to SharedPreferences
  Future<void> _saveAdminSession({
    required String token,
    required String staffId,
    required String staffName,
    required String staffRole,
    required String adminUsername,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_adminTokenKey, token);
    await prefs.setBool(_hasAdminAccessKey, true);
    await prefs.setString(_adminUsernameKey, adminUsername);
    await prefs.setString(_staffIdKey, staffId);
    await prefs.setString(_staffNameKey, staffName);
    await prefs.setString(_staffRoleKey, staffRole);

    _adminToken = token;
    _hasAdminAccess = true;
  }

  /// Check if user has admin access
  Future<bool> hasAdminAccess() async {
    if (_hasAdminAccess && _adminToken != null) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    _hasAdminAccess = prefs.getBool(_hasAdminAccessKey) ?? false;
    _adminToken = prefs.getString(_adminTokenKey);

    return _hasAdminAccess && _adminToken != null;
  }

  /// Get saved admin token
  Future<String?> getAdminToken() async {
    if (_adminToken != null) {
      return _adminToken;
    }

    final prefs = await SharedPreferences.getInstance();
    _adminToken = prefs.getString(_adminTokenKey);
    return _adminToken;
  }

  /// Get admin username
  Future<String?> getAdminUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminUsernameKey);
  }

  /// Get staff info
  Future<Map<String, String?>> getStaffInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_staffIdKey),
      'name': prefs.getString(_staffNameKey),
      'role': prefs.getString(_staffRoleKey),
      'username': prefs.getString(_adminUsernameKey),
    };
  }

  /// Logout admin session
  Future<void> logoutAdmin() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_adminTokenKey);
    await prefs.setBool(_hasAdminAccessKey, false);
    await prefs.remove(_adminUsernameKey);
    await prefs.remove(_staffIdKey);
    await prefs.remove(_staffNameKey);
    await prefs.remove(_staffRoleKey);

    _adminToken = null;
    _hasAdminAccess = false;
  }

  /// Verify token is still valid
  Future<bool> verifyToken() async {
    if (_adminToken == null) {
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/staff/products'),
        headers: {'Authorization': 'Bearer $_adminToken'},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
