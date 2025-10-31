import 'package:flutter/material.dart';
import '../../../../core/services/slider_api_service.dart';
import '../../../../data/models/slider_model.dart';

/// Slider Provider
/// Manages state for slider/banner management
class SliderProvider with ChangeNotifier {
  final SliderApiService _sliderApiService;

  SliderProvider({required SliderApiService sliderApiService})
    : _sliderApiService = sliderApiService;

  // ==================== STATE VARIABLES ====================

  List<SliderModel> _sliders = [];
  List<SliderModel> _filteredSliders = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  bool? _activeFilter;
  String _sortBy = 'displayOrder';
  String _sortOrder = 'asc';

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;

  // Statistics
  Map<String, dynamic> _statistics = {
    'total': 0,
    'active': 0,
    'inactive': 0,
    'scheduled': 0,
    'expired': 0,
  };

  // ==================== GETTERS ====================

  List<SliderModel> get sliders => _sliders;
  List<SliderModel> get filteredSliders => _filteredSliders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  bool? get activeFilter => _activeFilter;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMore => _hasMore;
  Map<String, dynamic> get statistics => _statistics;

  // ==================== FETCH OPERATIONS ====================

  /// Fetch sliders with optional pagination and filters
  Future<void> fetchSliders({int? page, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _sliders.clear();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _sliderApiService.fetchAllSliders(
        page: page ?? _currentPage,
        limit: 50,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        isActive: _activeFilter,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      final newSliders = response['sliders'] as List<SliderModel>? ?? [];
      final pagination = response['pagination'] as Map<String, dynamic>? ?? {};

      if (refresh) {
        _sliders = newSliders;
      } else {
        // Append new sliders, avoid duplicates
        for (var slider in newSliders) {
          if (!_sliders.any((s) => s.id == slider.id)) {
            _sliders.add(slider);
          }
        }
      }

      _filteredSliders = List.from(_sliders);
      _currentPage = pagination['page'] as int? ?? 1;
      _totalPages = pagination['pages'] as int? ?? 1;
      _hasMore = _currentPage < _totalPages;

      _errorMessage = null;

      // Fetch statistics
      await _fetchStatistics();
    } catch (e) {
      _errorMessage = e.toString();
      print('Error fetching sliders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more sliders (pagination)
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;

    _currentPage++;
    await fetchSliders(page: _currentPage);
  }

  /// Fetch statistics
  Future<void> _fetchStatistics() async {
    try {
      _statistics = await _sliderApiService.getSliderStats();
    } catch (e) {
      print('Error fetching statistics: $e');
      _statistics = {
        'total': _sliders.length,
        'active': _sliders.where((s) => s.status == 'Active').length,
        'inactive': _sliders.where((s) => s.status == 'Inactive').length,
        'scheduled': _sliders.where((s) => s.status == 'Scheduled').length,
        'expired': _sliders.where((s) => s.status == 'Expired').length,
      };
    }
  }

  // ==================== CREATE OPERATION ====================

  /// Create a new slider
  Future<bool> createSlider({
    required String title,
    required String imagePath,
    String? description,
    String? mobileImagePath,
    String? buttonText,
    String? buttonLink,
    String? backgroundColor,
    String? textColor,
    String? position,
    int? displayOrder,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? targetAudience,
    List<String>? categories,
    List<String>? tags,
    String? altText,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newSlider = await _sliderApiService.createSlider(
        title: title,
        imagePath: imagePath,
        description: description,
        mobileImagePath: mobileImagePath,
        buttonText: buttonText,
        buttonLink: buttonLink,
        backgroundColor: backgroundColor,
        textColor: textColor,
        position: position,
        displayOrder: displayOrder,
        isActive: isActive,
        startDate: startDate,
        endDate: endDate,
        targetAudience: targetAudience,
        categories: categories,
        tags: tags,
        altText: altText,
      );

      _sliders.insert(0, newSlider);
      _applyFilters();
      await _fetchStatistics();

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      print('Error creating slider: $e');
      return false;
    }
  }

  // ==================== UPDATE OPERATION ====================

  /// Update an existing slider
  Future<bool> updateSlider({
    required String id,
    String? title,
    String? imagePath,
    String? description,
    String? mobileImagePath,
    String? buttonText,
    String? buttonLink,
    String? backgroundColor,
    String? textColor,
    String? position,
    int? displayOrder,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? targetAudience,
    List<String>? categories,
    List<String>? tags,
    String? altText,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedSlider = await _sliderApiService.updateSlider(
        id: id,
        title: title,
        imagePath: imagePath,
        description: description,
        mobileImagePath: mobileImagePath,
        buttonText: buttonText,
        buttonLink: buttonLink,
        backgroundColor: backgroundColor,
        textColor: textColor,
        position: position,
        displayOrder: displayOrder,
        isActive: isActive,
        startDate: startDate,
        endDate: endDate,
        targetAudience: targetAudience,
        categories: categories,
        tags: tags,
        altText: altText,
      );

      final index = _sliders.indexWhere((s) => s.id == id);
      if (index != -1) {
        _sliders[index] = updatedSlider;
        _applyFilters();
        await _fetchStatistics();
      }

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      print('Error updating slider: $e');
      return false;
    }
  }

  // ==================== DELETE OPERATION ====================

  /// Delete a slider
  Future<bool> deleteSlider(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _sliderApiService.deleteSlider(id);

      if (success) {
        _sliders.removeWhere((s) => s.id == id);
        _applyFilters();
        await _fetchStatistics();
      }

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      print('Error deleting slider: $e');
      return false;
    }
  }

  // ==================== TOGGLE ACTIVE STATUS ====================

  /// Toggle slider active status
  Future<bool> toggleActiveStatus(String id, bool isActive) async {
    try {
      final success = await _sliderApiService.toggleActiveStatus(id, isActive);

      if (success) {
        final index = _sliders.indexWhere((s) => s.id == id);
        if (index != -1) {
          _sliders[index] = _sliders[index].copyWith(isActive: isActive);
          _applyFilters();
          await _fetchStatistics();
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error toggling status: $e');
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

  /// Set active filter
  void setActiveFilter(bool? isActive) {
    _activeFilter = isActive;
    fetchSliders(refresh: true);
  }

  /// Apply filters to slider list
  void _applyFilters() {
    _filteredSliders = _sliders.where((slider) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final titleMatch = slider.title.toLowerCase().contains(query);
        final descMatch =
            slider.description?.toLowerCase().contains(query) ?? false;
        if (!titleMatch && !descMatch) return false;
      }

      return true;
    }).toList();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _activeFilter = null;
    fetchSliders(refresh: true);
  }

  // ==================== ANALYTICS ====================

  /// Track slider click
  Future<void> trackClick(String id) async {
    try {
      await _sliderApiService.trackClick(id);

      // Update local state
      final index = _sliders.indexWhere((s) => s.id == id);
      if (index != -1) {
        _sliders[index] = _sliders[index].copyWith(
          clickCount: _sliders[index].clickCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error tracking click: $e');
    }
  }

  /// Track slider view
  Future<void> trackView(String id) async {
    try {
      await _sliderApiService.trackView(id);

      // Update local state
      final index = _sliders.indexWhere((s) => s.id == id);
      if (index != -1) {
        _sliders[index] = _sliders[index].copyWith(
          viewCount: _sliders[index].viewCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error tracking view: $e');
    }
  }

  // ==================== DISPLAY ORDER ====================

  /// Update display order of sliders
  Future<bool> updateDisplayOrder(List<String> sliderIds) async {
    try {
      final updates = sliderIds.asMap().entries.map((entry) {
        return {'id': entry.value, 'displayOrder': entry.key};
      }).toList();

      final success = await _sliderApiService.updateDisplayOrder(updates);

      if (success) {
        // Update local state
        for (var i = 0; i < sliderIds.length; i++) {
          final index = _sliders.indexWhere((s) => s.id == sliderIds[i]);
          if (index != -1) {
            _sliders[index] = _sliders[index].copyWith(displayOrder: i);
          }
        }

        _sliders.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        _applyFilters();
        notifyListeners();
      }

      return success;
    } catch (e) {
      print('Error updating display order: $e');
      return false;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Get slider by ID
  SliderModel? getSliderById(String id) {
    try {
      return _sliders.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get active sliders only
  List<SliderModel> getActiveSliders() {
    return _sliders.where((s) => s.isVisible).toList();
  }

  /// Get scheduled sliders
  List<SliderModel> getScheduledSliders() {
    return _sliders.where((s) => s.status == 'Scheduled').toList();
  }

  /// Get expired sliders
  List<SliderModel> getExpiredSliders() {
    return _sliders.where((s) => s.status == 'Expired').toList();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await fetchSliders(refresh: true);
  }
}
