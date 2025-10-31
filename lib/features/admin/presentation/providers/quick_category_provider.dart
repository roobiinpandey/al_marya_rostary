import 'package:flutter/material.dart';
import '../../../../data/models/quick_category_model.dart';
import '../../../../core/services/quick_category_api_service.dart';

class QuickCategoryProvider extends ChangeNotifier {
  final QuickCategoryApiService _apiService = QuickCategoryApiService();

  // State
  List<QuickCategoryModel> _quickCategories = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  // Filters
  String _searchQuery = '';
  bool? _statusFilter;
  String _sortBy = 'displayOrder';

  // Pagination
  int _page = 1;
  static const int _pageSize = 12;

  // Getters
  List<QuickCategoryModel> get quickCategories => _filteredCategories;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool? get statusFilter => _statusFilter;
  String get sortBy => _sortBy;

  List<QuickCategoryModel> get _filteredCategories {
    var filtered = _quickCategories.where((category) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!category.title.toLowerCase().contains(query) &&
            !category.subtitle.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Status filter
      if (_statusFilter != null) {
        if (category.isActive != _statusFilter) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'createdAt':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'clickCount':
        filtered.sort((a, b) => b.clickCount.compareTo(a.clickCount));
        break;
      case 'displayOrder':
      default:
        filtered.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        break;
    }

    return filtered;
  }

  // ==================== FETCH OPERATIONS ====================

  Future<void> fetchQuickCategories({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _quickCategories.clear();
    }

    if (_isLoading || !_hasMore) return;

    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.fetchAllQuickCategories(
        page: _page,
        limit: _pageSize,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        isActive: _statusFilter,
      );

      final categories =
          response['quickCategories'] as List<QuickCategoryModel>;

      if (refresh) {
        _quickCategories = categories;
      } else {
        _quickCategories.addAll(categories);
      }

      _hasMore = categories.length == _pageSize;
      _page++;

      await _fetchStatistics();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchStatistics() async {
    try {
      _statistics = await _apiService.getQuickCategoryStats();
    } catch (e) {
      // Don't fail the whole operation for statistics
      debugPrint('Failed to fetch statistics: $e');
    }
  }

  Future<void> refresh() async {
    await fetchQuickCategories(refresh: true);
  }

  Future<void> loadMore() async {
    await fetchQuickCategories();
  }

  // ==================== CRUD OPERATIONS ====================

  Future<bool> createQuickCategory({
    required String title,
    required String subtitle,
    required String imageUrl,
    required String color,
    int? displayOrder,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final newCategory = await _apiService.createQuickCategory(
        title: title,
        subtitle: subtitle,
        imageUrl: imageUrl,
        color: color,
        displayOrder: displayOrder,
      );

      _quickCategories.insert(0, newCategory);
      await _fetchStatistics();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateQuickCategory({
    required String id,
    required String title,
    required String subtitle,
    required String imageUrl,
    required String color,
    int? displayOrder,
    bool? isActive,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final updatedCategory = await _apiService.updateQuickCategory(
        id: id,
        title: title,
        subtitle: subtitle,
        imageUrl: imageUrl,
        color: color,
        displayOrder: displayOrder,
        isActive: isActive,
      );

      final index = _quickCategories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _quickCategories[index] = updatedCategory;
      }

      await _fetchStatistics();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteQuickCategory(String id) async {
    _setLoading(true);
    _setError(null);

    try {
      await _apiService.deleteQuickCategory(id);
      _quickCategories.removeWhere((c) => c.id == id);
      await _fetchStatistics();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleQuickCategoryStatus(String id) async {
    try {
      await _apiService.toggleQuickCategoryStatus(id);

      final index = _quickCategories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _quickCategories[index] = _quickCategories[index].copyWith(
          isActive: !_quickCategories[index].isActive,
        );
      }

      await _fetchStatistics();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> reorderQuickCategories(List<String> orderedIds) async {
    _setLoading(true);
    _setError(null);

    try {
      await _apiService.reorderQuickCategories(orderedIds);

      // Reorder local list
      final reorderedCategories = <QuickCategoryModel>[];
      for (int i = 0; i < orderedIds.length; i++) {
        final id = orderedIds[i];
        final category = _quickCategories.firstWhere((c) => c.id == id);
        reorderedCategories.add(category.copyWith(displayOrder: i + 1));
      }

      _quickCategories = reorderedCategories;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== FILTER OPERATIONS ====================

  void updateSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void updateStatusFilter(bool? status) {
    if (_statusFilter != status) {
      _statusFilter = status;
      notifyListeners();
    }
  }

  void updateSortBy(String sortBy) {
    if (_sortBy != sortBy) {
      _sortBy = sortBy;
      notifyListeners();
    }
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _sortBy = 'displayOrder';
    notifyListeners();
  }

  // ==================== ANALYTICS OPERATIONS ====================

  Future<void> trackQuickCategoryClick(String id) async {
    try {
      await _apiService.trackQuickCategoryClick(id);

      // Update local click count
      final index = _quickCategories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _quickCategories[index] = _quickCategories[index].copyWith(
          clickCount: _quickCategories[index].clickCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      // Don't fail for analytics
      debugPrint('Failed to track click: $e');
    }
  }

  Future<void> trackQuickCategoryView(String id) async {
    try {
      await _apiService.trackQuickCategoryView(id);

      // Update local view count
      final index = _quickCategories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _quickCategories[index] = _quickCategories[index].copyWith(
          viewCount: _quickCategories[index].viewCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      // Don't fail for analytics
      debugPrint('Failed to track view: $e');
    }
  }

  // ==================== FILE UPLOAD ====================

  Future<String?> uploadImage(String filePath) async {
    _setLoading(true);
    _setError(null);

    try {
      // For now, we'll handle image upload in the create/update methods
      // This method can be used for future standalone image uploads
      return filePath; // Return the local file path for now
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== UTILITY METHODS ====================

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  void clearError() {
    _setError(null);
  }

  // ==================== DISPOSE ====================

  @override
  void dispose() {
    _quickCategories.clear();
    _statistics.clear();
    super.dispose();
  }
}
