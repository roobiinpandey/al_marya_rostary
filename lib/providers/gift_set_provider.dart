import 'package:flutter/material.dart';
import '../data/models/gift_set_model.dart';
import '../core/services/gift_set_api_service.dart';
import '../core/utils/app_logger.dart';

class GiftSetProvider with ChangeNotifier {
  final GiftSetApiService _apiService;

  GiftSetProvider(this._apiService);

  // State for all gift sets
  List<GiftSetModel> _giftSets = [];
  List<GiftSetModel> get giftSets => _giftSets;

  // State for featured gift sets
  List<GiftSetModel> _featuredGiftSets = [];
  List<GiftSetModel> get featuredGiftSets => _featuredGiftSets;

  // State for popular gift sets
  List<GiftSetModel> _popularGiftSets = [];
  List<GiftSetModel> get popularGiftSets => _popularGiftSets;

  // Current pagination info
  Map<String, dynamic> _pagination = {};
  Map<String, dynamic> get pagination => _pagination;

  // Loading states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isFeaturedLoading = false;
  bool get isFeaturedLoading => _isFeaturedLoading;

  bool _isPopularLoading = false;
  bool get isPopularLoading => _isPopularLoading;

  // Error states
  String? _error;
  String? get error => _error;

  String? _featuredError;
  String? get featuredError => _featuredError;

  String? _popularError;
  String? get popularError => _popularError;

  // Selected gift set for detail view
  GiftSetModel? _selectedGiftSet;
  GiftSetModel? get selectedGiftSet => _selectedGiftSet;

  // Filter states
  String? _currentOccasion;
  String? get currentOccasion => _currentOccasion;

  String? _currentAudience;
  String? get currentAudience => _currentAudience;

  double? _minPrice;
  double? get minPrice => _minPrice;

  double? _maxPrice;
  double? get maxPrice => _maxPrice;

  bool _showFeaturedOnly = false;
  bool get showFeaturedOnly => _showFeaturedOnly;

  bool _showAvailableOnly = true;
  bool get showAvailableOnly => _showAvailableOnly;

  String _sortBy = 'displayOrder';
  String get sortBy => _sortBy;

  String _sortOrder = 'asc';
  String get sortOrder => _sortOrder;

  /// Fetch all gift sets with current filters
  Future<void> fetchGiftSets({
    int page = 1,
    int limit = 20,
    bool loadMore = false,
  }) async {
    try {
      if (!loadMore) {
        _isLoading = true;
        _error = null;
        notifyListeners();
      }

      AppLogger.debug('🎁 GiftSetProvider: Fetching gift sets (page $page)');

      final result = await _apiService.getGiftSets(
        page: page,
        limit: limit,
        occasion: _currentOccasion,
        targetAudience: _currentAudience,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        featured: _showFeaturedOnly ? true : null,
        available: _showAvailableOnly ? true : null,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      final newGiftSets = result['giftSets'] as List<GiftSetModel>;

      if (loadMore) {
        _giftSets.addAll(newGiftSets);
      } else {
        _giftSets = newGiftSets;
      }

      _pagination = result['pagination'] as Map<String, dynamic>;
      _error = null;

      AppLogger.debug(
        '✅ GiftSetProvider: Successfully fetched ${newGiftSets.length} gift sets',
      );
    } catch (e) {
      _error = e.toString();
      AppLogger.error('❌ GiftSetProvider: Error fetching gift sets: $e');

      if (!loadMore) {
        _giftSets = [];
        _pagination = {};
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch featured gift sets
  Future<void> fetchFeaturedGiftSets({int limit = 10}) async {
    try {
      _isFeaturedLoading = true;
      _featuredError = null;
      notifyListeners();

      AppLogger.debug('🎁 GiftSetProvider: Fetching featured gift sets');

      _featuredGiftSets = await _apiService.getFeaturedGiftSets(limit: limit);
      _featuredError = null;

      AppLogger.debug(
        '✅ GiftSetProvider: Successfully fetched ${_featuredGiftSets.length} featured gift sets',
      );
    } catch (e) {
      _featuredError = e.toString();
      _featuredGiftSets = [];
      AppLogger.error('❌ GiftSetProvider: Error fetching featured gift sets: $e');
    } finally {
      _isFeaturedLoading = false;
      notifyListeners();
    }
  }

  /// Fetch popular gift sets
  Future<void> fetchPopularGiftSets({int limit = 10}) async {
    try {
      _isPopularLoading = true;
      _popularError = null;
      notifyListeners();

      AppLogger.debug('🎁 GiftSetProvider: Fetching popular gift sets');

      _popularGiftSets = await _apiService.getPopularGiftSets(limit: limit);
      _popularError = null;

      AppLogger.debug(
        '✅ GiftSetProvider: Successfully fetched ${_popularGiftSets.length} popular gift sets',
      );
    } catch (e) {
      _popularError = e.toString();
      _popularGiftSets = [];
      AppLogger.error('❌ GiftSetProvider: Error fetching popular gift sets: $e');
    } finally {
      _isPopularLoading = false;
      notifyListeners();
    }
  }

  /// Fetch gift set by ID for detail view
  Future<void> fetchGiftSetById(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      AppLogger.debug('🎁 GiftSetProvider: Fetching gift set by ID: $id');

      _selectedGiftSet = await _apiService.getGiftSetById(id);
      _error = null;

      // Increment view count for analytics
      await _apiService.incrementViews(id);

      AppLogger.debug(
        '✅ GiftSetProvider: Successfully fetched gift set: ${_selectedGiftSet?.name['en'] ?? _selectedGiftSet?.name['ar'] ?? 'Unknown'}',
      );
    } catch (e) {
      _error = e.toString();
      _selectedGiftSet = null;
      AppLogger.error('❌ GiftSetProvider: Error fetching gift set by ID: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set filters and refresh data
  void setOccasionFilter(String? occasion) {
    if (_currentOccasion != occasion) {
      _currentOccasion = occasion;
      fetchGiftSets(); // Refresh with new filter
    }
  }

  void setAudienceFilter(String? audience) {
    if (_currentAudience != audience) {
      _currentAudience = audience;
      fetchGiftSets(); // Refresh with new filter
    }
  }

  void setPriceRange(double? minPrice, double? maxPrice) {
    if (_minPrice != minPrice || _maxPrice != maxPrice) {
      _minPrice = minPrice;
      _maxPrice = maxPrice;
      fetchGiftSets(); // Refresh with new filter
    }
  }

  void setFeaturedFilter(bool featuredOnly) {
    if (_showFeaturedOnly != featuredOnly) {
      _showFeaturedOnly = featuredOnly;
      fetchGiftSets(); // Refresh with new filter
    }
  }

  void setAvailabilityFilter(bool availableOnly) {
    if (_showAvailableOnly != availableOnly) {
      _showAvailableOnly = availableOnly;
      fetchGiftSets(); // Refresh with new filter
    }
  }

  void setSorting(String sortBy, String sortOrder) {
    if (_sortBy != sortBy || _sortOrder != sortOrder) {
      _sortBy = sortBy;
      _sortOrder = sortOrder;
      fetchGiftSets(); // Refresh with new sorting
    }
  }

  /// Clear all filters
  void clearFilters() {
    _currentOccasion = null;
    _currentAudience = null;
    _minPrice = null;
    _maxPrice = null;
    _showFeaturedOnly = false;
    _showAvailableOnly = true;
    _sortBy = 'displayOrder';
    _sortOrder = 'asc';

    fetchGiftSets(); // Refresh with cleared filters
  }

  /// Load more gift sets (pagination)
  Future<void> loadMore() async {
    if (_isLoading || _pagination.isEmpty) return;

    final currentPage = _pagination['currentPage'] ?? 1;
    final totalPages = _pagination['totalPages'] ?? 1;

    if (currentPage < totalPages) {
      await fetchGiftSets(page: currentPage + 1, loadMore: true);
    }
  }

  /// Check if more pages are available
  bool get hasMorePages {
    if (_pagination.isEmpty) return false;
    final currentPage = _pagination['currentPage'] ?? 1;
    final totalPages = _pagination['totalPages'] ?? 1;
    return currentPage < totalPages;
  }

  /// Add review to a gift set
  Future<bool> addReview(
    String giftSetId, {
    required int rating,
    String? comment,
    String? occasion,
    String? recipientType,
    bool wouldRecommend = true,
  }) async {
    try {
      AppLogger.debug('🎁 GiftSetProvider: Adding review to gift set: $giftSetId');

      await _apiService.addReview(
        giftSetId,
        rating: rating,
        comment: comment,
        occasion: occasion,
        recipientType: recipientType,
        wouldRecommend: wouldRecommend,
      );

      // Refresh the selected gift set to show updated reviews
      if (_selectedGiftSet?.id == giftSetId) {
        await fetchGiftSetById(giftSetId);
      }

      AppLogger.success('✅ GiftSetProvider: Successfully added review');
      return true;
    } catch (e) {
      AppLogger.error('❌ GiftSetProvider: Error adding review: $e');
      return false;
    }
  }

  /// Get gift sets by occasion
  Future<List<GiftSetModel>> getGiftSetsByOccasion(String occasion) async {
    try {
      AppLogger.debug('🎁 GiftSetProvider: Getting gift sets by occasion: $occasion');
      return await _apiService.getGiftSetsByOccasion(occasion);
    } catch (e) {
      AppLogger.error('❌ GiftSetProvider: Error getting gift sets by occasion: $e');
      return [];
    }
  }

  /// Get gift sets by audience
  Future<List<GiftSetModel>> getGiftSetsByAudience(String audience) async {
    try {
      AppLogger.debug('🎁 GiftSetProvider: Getting gift sets by audience: $audience');
      return await _apiService.getGiftSetsByAudience(audience);
    } catch (e) {
      AppLogger.error('❌ GiftSetProvider: Error getting gift sets by audience: $e');
      return [];
    }
  }

  /// Get gift sets by price range
  Future<List<GiftSetModel>> getGiftSetsByPriceRange(
    double minPrice,
    double maxPrice,
  ) async {
    try {
      AppLogger.debug(
        '🎁 GiftSetProvider: Getting gift sets by price range: $minPrice - $maxPrice',
      );
      return await _apiService.getGiftSetsByPriceRange(minPrice, maxPrice);
    } catch (e) {
      AppLogger.error('❌ GiftSetProvider: Error getting gift sets by price range: $e');
      return [];
    }
  }

  /// Clear selected gift set
  void clearSelectedGiftSet() {
    _selectedGiftSet = null;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _giftSets = [];
    _featuredGiftSets = [];
    _popularGiftSets = [];
    _selectedGiftSet = null;
    _pagination = {};
    _error = null;
    _featuredError = null;
    _popularError = null;
    _isLoading = false;
    _isFeaturedLoading = false;
    _isPopularLoading = false;

    // Reset filters
    _currentOccasion = null;
    _currentAudience = null;
    _minPrice = null;
    _maxPrice = null;
    _showFeaturedOnly = false;
    _showAvailableOnly = true;
    _sortBy = 'displayOrder';
    _sortOrder = 'asc';

    notifyListeners();
  }

  /// Get gift sets for home page (featured + popular)
  Future<void> fetchHomePageGiftSets() async {
    await Future.wait([
      fetchFeaturedGiftSets(limit: 5),
      fetchPopularGiftSets(limit: 5),
    ]);
  }

  /// Search gift sets
  Future<List<GiftSetModel>> searchGiftSets(String query) async {
    try {
      AppLogger.debug('🎁 GiftSetProvider: Searching gift sets: $query');

      final result = await _apiService.getGiftSets(
        search: query,
        available: true,
        limit: 50,
      );

      return result['giftSets'] as List<GiftSetModel>;
    } catch (e) {
      AppLogger.error('❌ GiftSetProvider: Error searching gift sets: $e');
      return [];
    }
  }

  /// Get occasions list
  List<String> get availableOccasions => [
    'Birthday',
    'Anniversary',
    'Wedding',
    'Holiday',
    'Corporate',
    'Thank You',
    'Congratulations',
    'Sympathy',
  ];

  /// Get audiences list
  List<String> get availableAudiences => [
    'Coffee Lover',
    'Beginner',
    'Professional',
    'Gift Giver',
    'Corporate Client',
    'Family',
    'Friend',
    'Colleague',
  ];
}
