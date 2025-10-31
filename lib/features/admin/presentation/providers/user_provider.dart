import 'package:flutter/material.dart';
import '../../../../core/services/user_api_service.dart';
import '../../../../data/models/user_model.dart';

/// User Provider
/// Manages state for user/customer management
class UserProvider with ChangeNotifier {
  final UserApiService _userApiService;

  UserProvider({required UserApiService userApiService})
    : _userApiService = userApiService;

  // ==================== STATE VARIABLES ====================

  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _roleFilter;
  bool? _activeFilter;
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;

  // Statistics
  Map<String, dynamic> _statistics = {
    'total': 0,
    'active': 0,
    'inactive': 0,
    'verified': 0,
    'unverified': 0,
    'admins': 0,
    'customers': 0,
  };

  // Selected user for detail view
  UserModel? _selectedUser;

  // ==================== GETTERS ====================

  List<UserModel> get users => _users;
  List<UserModel> get filteredUsers => _filteredUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get roleFilter => _roleFilter;
  bool? get activeFilter => _activeFilter;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMore => _hasMore;
  Map<String, dynamic> get statistics => _statistics;
  UserModel? get selectedUser => _selectedUser;

  // ==================== FETCH OPERATIONS ====================

  /// Fetch users with optional pagination and filters
  Future<void> fetchUsers({int? page, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _users.clear();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _userApiService.fetchAllUsers(
        page: page ?? _currentPage,
        limit: 50,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        role: _roleFilter,
        isActive: _activeFilter,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      final newUsers = response['users'] as List<UserModel>? ?? [];
      final pagination = response['pagination'] as Map<String, dynamic>? ?? {};

      if (refresh) {
        _users = newUsers;
      } else {
        // Append new users, avoid duplicates
        for (var user in newUsers) {
          if (!_users.any((u) => u.id == user.id)) {
            _users.add(user);
          }
        }
      }

      _filteredUsers = List.from(_users);
      _currentPage = pagination['page'] as int? ?? 1;
      _totalPages = pagination['pages'] as int? ?? 1;
      _hasMore = _currentPage < _totalPages;

      _errorMessage = null;

      // Update statistics
      _updateStatistics();
    } catch (e) {
      _errorMessage = e.toString();
      print('Error fetching users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more users (pagination)
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;

    _currentPage++;
    await fetchUsers(page: _currentPage);
  }

  /// Fetch single user details
  Future<void> fetchUserDetails(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedUser = await _userApiService.fetchUser(id);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error fetching user details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update statistics from current user list
  void _updateStatistics() {
    _statistics = {
      'total': _users.length,
      'active': _users.where((u) => u.isActive).length,
      'inactive': _users.where((u) => !u.isActive).length,
      'verified': _users.where((u) => u.isEmailVerified).length,
      'unverified': _users.where((u) => !u.isEmailVerified).length,
      'admins': _users.where((u) => u.isAdmin).length,
      'customers': _users.where((u) => u.isCustomer).length,
    };
  }

  // ==================== UPDATE OPERATIONS ====================

  /// Update user information
  Future<bool> updateUser({
    required String id,
    String? name,
    String? email,
    String? phone,
    List<String>? roles,
    bool? isActive,
    bool? isEmailVerified,
    Map<String, dynamic>? preferences,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _userApiService.updateUser(
        id: id,
        name: name,
        email: email,
        phone: phone,
        roles: roles,
        isActive: isActive,
        isEmailVerified: isEmailVerified,
        preferences: preferences,
      );

      final index = _users.indexWhere((u) => u.id == id);
      if (index != -1) {
        _users[index] = updatedUser;
        _applyFilters();
        _updateStatistics();
      }

      if (_selectedUser?.id == id) {
        _selectedUser = updatedUser;
      }

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      print('Error updating user: $e');
      return false;
    }
  }

  /// Toggle user active status
  Future<bool> toggleActiveStatus(String id, bool isActive) async {
    try {
      final success = await _userApiService.toggleActiveStatus(id, isActive);

      if (success) {
        final index = _users.indexWhere((u) => u.id == id);
        if (index != -1) {
          _users[index] = _users[index].copyWith(isActive: isActive);
          _applyFilters();
          _updateStatistics();
          notifyListeners();
        }

        if (_selectedUser?.id == id) {
          _selectedUser = _selectedUser!.copyWith(isActive: isActive);
        }
      }

      return success;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error toggling status: $e');
      return false;
    }
  }

  /// Update user roles
  Future<bool> updateUserRoles(String id, List<String> roles) async {
    try {
      final updatedUser = await _userApiService.updateUserRoles(id, roles);

      final index = _users.indexWhere((u) => u.id == id);
      if (index != -1) {
        _users[index] = updatedUser;
        _applyFilters();
        _updateStatistics();
        notifyListeners();
      }

      if (_selectedUser?.id == id) {
        _selectedUser = updatedUser;
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error updating roles: $e');
      return false;
    }
  }

  /// Update loyalty points
  Future<bool> updateLoyaltyPoints({
    required String id,
    required int points,
    String? reason,
  }) async {
    try {
      final updatedUser = await _userApiService.updateLoyaltyPoints(
        id: id,
        points: points,
        reason: reason,
      );

      final index = _users.indexWhere((u) => u.id == id);
      if (index != -1) {
        _users[index] = updatedUser;
        notifyListeners();
      }

      if (_selectedUser?.id == id) {
        _selectedUser = updatedUser;
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error updating loyalty points: $e');
      return false;
    }
  }

  // ==================== DELETE OPERATION ====================

  /// Delete user
  Future<bool> deleteUser(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _userApiService.deleteUser(id);

      if (success) {
        _users.removeWhere((u) => u.id == id);
        _applyFilters();
        _updateStatistics();
      }

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      print('Error deleting user: $e');
      return false;
    }
  }

  // ==================== SEARCH & FILTER ====================

  /// Set search query and apply filters
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Set role filter
  void setRoleFilter(String? role) {
    _roleFilter = role;
    fetchUsers(refresh: true);
  }

  /// Set active filter
  void setActiveFilter(bool? isActive) {
    _activeFilter = isActive;
    fetchUsers(refresh: true);
  }

  /// Apply filters to user list
  void _applyFilters() {
    _filteredUsers = _users.where((user) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = user.name.toLowerCase().contains(query);
        final emailMatch = user.email.toLowerCase().contains(query);
        final phoneMatch = user.phone?.toLowerCase().contains(query) ?? false;
        if (!nameMatch && !emailMatch && !phoneMatch) return false;
      }

      return true;
    }).toList();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _roleFilter = null;
    _activeFilter = null;
    fetchUsers(refresh: true);
  }

  // ==================== USER ORDERS ====================

  /// Fetch user's orders
  Future<List<Map<String, dynamic>>> fetchUserOrders(String userId) async {
    try {
      return await _userApiService.fetchUserOrders(userId);
    } catch (e) {
      _errorMessage = e.toString();
      print('Error fetching user orders: $e');
      return [];
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Get user by ID
  UserModel? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get active users only
  List<UserModel> getActiveUsers() {
    return _users.where((u) => u.isActive).toList();
  }

  /// Get users by role
  List<UserModel> getUsersByRole(String role) {
    return _users.where((u) => u.roles.contains(role)).toList();
  }

  /// Set selected user
  void setSelectedUser(UserModel? user) {
    _selectedUser = user;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await fetchUsers(refresh: true);
  }

  /// Search users by query
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      return await _userApiService.searchUsers(query);
    } catch (e) {
      _errorMessage = e.toString();
      print('Error searching users: $e');
      return [];
    }
  }
}
