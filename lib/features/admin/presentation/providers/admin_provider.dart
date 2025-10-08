import 'package:flutter/material.dart';

/// Admin provider for managing admin panel state and data
class AdminProvider extends ChangeNotifier {
  // Dashboard Metrics
  int _totalOrders = 0;
  double _totalRevenue = 0.0;
  int _totalProducts = 0;
  int _totalUsers = 0;

  // Getters
  int get totalOrders => _totalOrders;
  double get totalRevenue => _totalRevenue;
  int get totalProducts => _totalProducts;
  int get totalUsers => _totalUsers;

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

  // Initialize with mock data
  AdminProvider() {
    _loadMockData();
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
    // TODO: Implement actual data fetching from API
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    _loadMockData(); // Reload mock data
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
