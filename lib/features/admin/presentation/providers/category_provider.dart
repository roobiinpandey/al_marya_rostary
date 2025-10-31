import 'package:flutter/foundation.dart';
import '../../../../core/services/category_api_service.dart';
import '../../../../data/models/category_model.dart';
import '../../../../core/utils/app_logger.dart';

/// Provider for managing category state and operations
/// Handles all category-related business logic and state management
class CategoryProvider with ChangeNotifier {
  final CategoryApiService _categoryApiService;

  CategoryProvider({required CategoryApiService categoryApiService})
    : _categoryApiService = categoryApiService;

  // State variables
  List<CategoryModel> _categories = [];
  List<CategoryModel> _filteredCategories = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  Map<String, dynamic> _statistics = {};

  // Search and filter state
  String _searchQuery = '';
  bool? _activeFilter;
  String _sortBy = 'displayOrder';
  String _sortOrder = 'asc';

  // Getters
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<CategoryModel> get filteredCategories =>
      List.unmodifiable(_filteredCategories);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMore => _hasMore;
  Map<String, dynamic> get statistics => Map.unmodifiable(_statistics);
  String get searchQuery => _searchQuery;
  bool? get activeFilter => _activeFilter;

  // ==================== FETCH OPERATIONS ====================

  /// Fetch categories from API
  Future<void> fetchCategories({bool refresh = false, int? page}) async {
    if (_isLoading) return;

    // Reset if refreshing
    if (refresh) {
      _currentPage = 1;
      _categories = [];
      _hasMore = true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _categoryApiService.fetchAllCategories(
        page: page ?? _currentPage,
        limit: 50,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        isActive: _activeFilter,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      final newCategories =
          response['categories'] as List<CategoryModel>? ?? [];
      final pagination = response['pagination'] as Map<String, dynamic>? ?? {};

      if (refresh) {
        _categories = newCategories;
      } else {
        // Append new categories, avoid duplicates
        for (var category in newCategories) {
          if (!_categories.any((c) => c.id == category.id)) {
            _categories.add(category);
          }
        }
      }

      _filteredCategories = List.from(_categories);
      _currentPage = pagination['page'] as int? ?? 1;
      _totalPages = pagination['pages'] as int? ?? 1;
      _hasMore = _currentPage < _totalPages;

      _errorMessage = null;

      // Fetch statistics
      await _fetchStatistics();
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('fetching categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more categories (pagination)
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;

    _currentPage++;
    await fetchCategories(page: _currentPage);
  }

  /// Fetch statistics
  Future<void> _fetchStatistics() async {
    try {
      _statistics = await _categoryApiService.getCategoryStats();
    } catch (e) {
      AppLogger.error('fetching statistics: $e');
      _statistics = {
        'total': _categories.length,
        'active': _categories.where((c) => c.isActive).length,
        'inactive': _categories.where((c) => !c.isActive).length,
      };
    }
  }

  // ==================== CREATE OPERATION ====================

  /// Create a new category
  Future<bool> createCategory({
    required String nameEn,
    required String nameAr,
    required String descriptionEn,
    required String descriptionAr,
    String? parentId,
    String? color,
    int? displayOrder,
    bool? isActive,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newCategory = await _categoryApiService.createCategory(
        nameEn: nameEn,
        nameAr: nameAr,
        descriptionEn: descriptionEn,
        descriptionAr: descriptionAr,
        parentId: parentId,
        color: color ?? '#8B4513',
        displayOrder: displayOrder ?? (_categories.length + 1),
        isActive: isActive ?? true,
      );

      // Add to local list
      _categories.insert(0, newCategory);
      _filteredCategories = List.from(_categories);

      // Update statistics
      await _fetchStatistics();

      _errorMessage = null;
      _isSubmitting = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('creating category: $e');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== UPDATE OPERATION ====================

  /// Update an existing category
  Future<bool> updateCategory({
    required String categoryId,
    String? nameEn,
    String? nameAr,
    String? descriptionEn,
    String? descriptionAr,
    String? parentId,
    String? color,
    int? displayOrder,
    bool? isActive,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedCategory = await _categoryApiService.updateCategory(
        categoryId: categoryId,
        nameEn: nameEn,
        nameAr: nameAr,
        descriptionEn: descriptionEn,
        descriptionAr: descriptionAr,
        parentId: parentId,
        color: color,
        displayOrder: displayOrder,
        isActive: isActive,
      );

      // Update in local list
      final index = _categories.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        _categories[index] = updatedCategory;
        _filteredCategories = List.from(_categories);
      }

      // Update statistics
      await _fetchStatistics();

      _errorMessage = null;
      _isSubmitting = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('updating category: $e');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== DELETE OPERATION ====================

  /// Delete a category
  Future<bool> deleteCategory(String categoryId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _categoryApiService.deleteCategory(categoryId);

      // Remove from local list
      _categories.removeWhere((c) => c.id == categoryId);
      _filteredCategories = List.from(_categories);

      // Update statistics
      await _fetchStatistics();

      _errorMessage = null;
      _isSubmitting = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('deleting category: $e');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== TOGGLE OPERATIONS ====================

  /// Toggle category active status
  Future<bool> toggleActiveStatus(String categoryId, bool isActive) async {
    try {
      await _categoryApiService.toggleActiveStatus(categoryId, isActive);

      // Update locally
      final index = _categories.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        _categories[index] = _categories[index].copyWith(isActive: isActive);
        _filteredCategories = List.from(_categories);
      }

      // Update statistics
      await _fetchStatistics();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('toggling active status: $e');
      notifyListeners();
      return false;
    }
  }

  // ==================== DISPLAY ORDER ====================

  /// Update display order
  Future<bool> updateDisplayOrder(String categoryId, int displayOrder) async {
    try {
      await _categoryApiService.updateDisplayOrder(categoryId, displayOrder);

      // Update locally
      final index = _categories.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        _categories[index] = _categories[index].copyWith(
          displayOrder: displayOrder,
        );
        _filteredCategories = List.from(_categories);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('updating display order: $e');
      notifyListeners();
      return false;
    }
  }

  // ==================== SEARCH AND FILTER ====================

  /// Set search query and filter categories
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Set active filter
  void setActiveFilter(bool? isActive) {
    _activeFilter = isActive;
    fetchCategories(refresh: true);
  }

  /// Set sort options
  void setSortOptions(String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    fetchCategories(refresh: true);
  }

  /// Apply local filters (for instant filtering without API call)
  void _applyFilters() {
    if (_searchQuery.isEmpty && _activeFilter == null) {
      _filteredCategories = List.from(_categories);
      return;
    }

    _filteredCategories = _categories.where((category) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameEn = category.name['en']?.toLowerCase() ?? '';
        final nameAr = category.name['ar']?.toLowerCase() ?? '';
        final descEn = category.description['en']?.toLowerCase() ?? '';
        final descAr = category.description['ar']?.toLowerCase() ?? '';

        if (!nameEn.contains(query) &&
            !nameAr.contains(query) &&
            !descEn.contains(query) &&
            !descAr.contains(query)) {
          return false;
        }
      }

      // Active filter
      if (_activeFilter != null && category.isActive != _activeFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _activeFilter = null;
    _sortBy = 'displayOrder';
    _sortOrder = 'asc';
    fetchCategories(refresh: true);
  }

  // ==================== UTILITY METHODS ====================

  /// Get category by ID
  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all active categories
  List<CategoryModel> getActiveCategories() {
    return _categories.where((c) => c.isActive).toList();
  }

  /// Get top-level categories (no parent)
  List<CategoryModel> getTopLevelCategories() {
    return _categories.where((c) => c.parentId == null).toList();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _categories = [];
    _filteredCategories = [];
    _isLoading = false;
    _isSubmitting = false;
    _errorMessage = null;
    _currentPage = 1;
    _totalPages = 1;
    _hasMore = true;
    _statistics = {};
    _searchQuery = '';
    _activeFilter = null;
    _sortBy = 'displayOrder';
    _sortOrder = 'asc';
    notifyListeners();
  }
}
