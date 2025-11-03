import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_logger.dart';

/// Admin provider for managing admin panel state and data
class AdminProvider extends ChangeNotifier {
  // Dashboard Metrics
  int _totalOrders = 0;
  double _totalRevenue = 0.0;
  int _totalProducts = 0;
  int _totalUsers = 0;
  bool _isLoading = false;
  String? _error;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Getters
  int get totalOrders => _totalOrders;
  double get totalRevenue => _totalRevenue;
  int get totalProducts => _totalProducts;
  int get totalUsers => _totalUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Mock data for demonstration
  final List<Map<String, dynamic>> _recentOrders = [
    {
      'id': 'ORD-001',
      'customer': 'Ahmed Al-Mansoori',
      'amount': 45.99,
      'status': 'Processing',
      'date': '2024-01-15',
    },
    {
      'id': 'ORD-002',
      'customer': 'Fatima Al-Zahra',
      'amount': 32.50,
      'status': 'Shipped',
      'date': '2024-01-14',
    },
    {
      'id': 'ORD-003',
      'customer': 'Mohammed Al-Rashid',
      'amount': 78.25,
      'status': 'Delivered',
      'date': '2024-01-13',
    },
  ];

  final List<Map<String, dynamic>> _salesData = [
    {'month': 'Jan', 'sales': 12000},
    {'month': 'Feb', 'sales': 15000},
    {'month': 'Mar', 'sales': 18000},
    {'month': 'Apr', 'sales': 22000},
    {'month': 'May', 'sales': 25000},
    {'month': 'Jun', 'sales': 28000},
  ];

  List<Map<String, dynamic>> get recentOrders => _recentOrders;
  List<Map<String, dynamic>> get salesData => _salesData;

  // Initialize and fetch real data
  AdminProvider() {
    _initializeData();
  }

  void _initializeData() {
    // Load mock data initially, then fetch real data
    _loadMockData();
    fetchDashboardData();
  }

  // Fetch real dashboard data from backend
  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get authentication token
      final token = await _getAuthToken();
      if (token == null) {
        AppLogger.error('❌ No authentication token found - showing mock data');
        _error = 'No authentication token found';
        return;
      }

      AppLogger.success('✅ Admin token found, fetching real data...');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Fetch user statistics
      await _fetchUserStats(headers);

      // Note: Add other metrics (orders, products, revenue)
      // For now, we'll focus on fixing the user count issue

      _error = null;
      AppLogger.success('✅ Admin dashboard data loaded successfully');
    } catch (e) {
      _error = e.toString();
      AppLogger.error('❌ Error fetching dashboard data: $e');
      // Keep mock data if API fails
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUserStats(Map<String, String> headers) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/api/admin/users/stats');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final overview = data['data']['overview'];
          _totalUsers = overview['totalUsers'] ?? 0;
          AppLogger.success('✅ Updated user count from API: $_totalUsers');
        }
      } else {
        throw Exception('Failed to load user stats: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('fetching user stats: $e');
      throw e;
    }
  }

  // Get authentication token - using same key as admin login page
  Future<String?> _getAuthToken() async {
    try {
      return await _storage.read(key: 'auth_token'); // Same key as admin login
    } catch (e) {
      AppLogger.error('reading auth token: $e');
      return null;
    }
  }

  void _loadMockData() {
    _totalOrders = 156;
    _totalRevenue = 45280.50;
    _totalProducts = 24;
    _totalUsers = 89;
    notifyListeners();
  }

  // Methods to update data
  void updateMetrics({
    int? orders,
    double? revenue,
    int? products,
    int? users,
  }) {
    if (orders != null) _totalOrders = orders;
    if (revenue != null) _totalRevenue = revenue;
    if (products != null) _totalProducts = products;
    if (users != null) _totalUsers = users;
    notifyListeners();
  }

  // Refresh dashboard data
  Future<void> refreshDashboard() async {
    await fetchDashboardData();
  }

  // Get order status color
  Color getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Calculate percentage change (mock implementation)
  double getRevenueChange() {
    // Mock: +12.5% increase
    return 12.5;
  }

  double getOrdersChange() {
    // Mock: +8.3% increase
    return 8.3;
  }

  double getUsersChange() {
    // Mock: +15.2% increase
    return 15.2;
  }
}
