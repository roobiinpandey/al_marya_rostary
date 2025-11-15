import 'package:flutter/foundation.dart';
// Note: Re-enable when reviews_api_service is implemented
// import '../../../data/datasources/remote/reviews_api_service.dart';

/// Review model for type safety
class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final int helpfulCount;
  final String status;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.helpfulCount,
    required this.status,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['_id'] as String? ?? map['id'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Anonymous',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment'] as String? ?? '',
      helpfulCount: (map['helpfulCount'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'pending',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'helpfulCount': helpfulCount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Review copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userName,
    int? rating,
    String? comment,
    int? helpfulCount,
    String? status,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Review statistics model
class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory ReviewStats.fromMap(Map<String, dynamic> map) {
    final distribution = <int, int>{};
    final rawDistribution =
        map['ratingDistribution'] as Map<String, dynamic>? ?? {};

    for (int i = 1; i <= 5; i++) {
      distribution[i] = (rawDistribution[i.toString()] as num?)?.toInt() ?? 0;
    }

    return ReviewStats(
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (map['totalReviews'] as num?)?.toInt() ?? 0,
      ratingDistribution: distribution,
    );
  }
}

/// Provider for managing product reviews state and operations
class ReviewsProvider with ChangeNotifier {
  // Note: Add API service when implemented
  // late final ReviewsApiService _reviewsApiService;

  ReviewsProvider();

  // State variables - Using type-safe models
  List<Review> _reviews = [];
  ReviewStats? _reviewStats;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isMarkingHelpful = false;
  String? _error;
  String? _currentProductId;

  // Getters
  List<Review> get reviews => List.unmodifiable(_reviews);
  ReviewStats? get reviewStats => _reviewStats;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isMarkingHelpful => _isMarkingHelpful;
  String? get error => _error;
  bool get hasError => _error != null;
  String? get currentProductId => _currentProductId;

  /// Get reviews for a specific product
  Future<void> loadProductReviews(String productId) async {
    if (_isLoading) return; // Prevent concurrent loads

    _setLoadingState(true);
    _clearError();
    _currentProductId = productId;

    try {
      debugPrint('🔍 Loading reviews for product: $productId');

      // Simulate API calls - replace with actual service calls
      final reviewsData = await _fetchProductReviews(productId);
      final statsData = await _fetchReviewStats(productId);

      _reviews = reviewsData.map((data) => Review.fromMap(data)).toList();
      _reviewStats = ReviewStats.fromMap(statsData);

      debugPrint('✅ Loaded ${_reviews.length} reviews for product $productId');
    } catch (e) {
      debugPrint('❌ Error loading product reviews: $e');
      _setError(
        'Unable to load reviews. Please check your connection and try again.',
      );
      _reviews = [];
      _reviewStats = ReviewStats(
        totalReviews: 0,
        averageRating: 0.0,
        ratingDistribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      );
    } finally {
      _setLoadingState(false);
    }
  }

  /// Submit a new review for a product
  Future<bool> submitReview({
    required String productId,
    required int rating,
    required String comment,
    String? userId,
    String? userName,
  }) async {
    if (_isSubmitting) return false; // Prevent concurrent submissions

    // Validate input
    if (rating < 1 || rating > 5) {
      _setError('Rating must be between 1 and 5');
      return false;
    }

    if (comment.trim().isEmpty) {
      _setError('Comment cannot be empty');
      return false;
    }

    _setSubmittingState(true);
    _clearError();

    try {
      debugPrint('📝 Submitting review for product: $productId');

      // Simulate API call - replace with actual service call
      final result = await _submitReviewToApi(
        productId: productId,
        rating: rating,
        comment: comment.trim(),
        userId: userId,
        userName: userName,
      );

      debugPrint('✅ Review submitted successfully: ${result['reviewId']}');

      // Reload reviews to show the new one
      await loadProductReviews(productId);

      return true;
    } catch (e) {
      debugPrint('❌ Error submitting review: $e');
      _setError('Failed to submit review: ${e.toString()}');
      return false;
    } finally {
      _setSubmittingState(false);
    }
  }

  /// Mark a review as helpful
  Future<bool> markReviewHelpful(String reviewId) async {
    if (_isMarkingHelpful) return false; // Prevent concurrent operations

    _isMarkingHelpful = true;
    notifyListeners();

    try {
      debugPrint('👍 Marking review as helpful: $reviewId');

      // Simulate API call - replace with actual service call
      await _markReviewHelpfulApi(reviewId);

      // Update the review in local state
      final reviewIndex = _reviews.indexWhere(
        (review) => review.id == reviewId,
      );
      if (reviewIndex != -1) {
        _reviews[reviewIndex] = _reviews[reviewIndex].copyWith(
          helpfulCount: _reviews[reviewIndex].helpfulCount + 1,
        );
        notifyListeners();
      }

      debugPrint('✅ Review marked as helpful successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error marking review as helpful: $e');
      _setError('Failed to mark review as helpful');
      return false;
    } finally {
      _isMarkingHelpful = false;
      notifyListeners();
    }
  }

  /// Get reviews by a specific user
  Future<void> loadUserReviews(String userId) async {
    if (_isLoading) return;

    _setLoadingState(true);
    _clearError();

    try {
      debugPrint('🔍 Loading reviews for user: $userId');
      final reviewsData = await _fetchUserReviews(userId);

      _reviews = reviewsData.map((data) => Review.fromMap(data)).toList();

      debugPrint('✅ Loaded ${_reviews.length} reviews for user $userId');
    } catch (e) {
      debugPrint('❌ Error loading user reviews: $e');
      _setError('Failed to load user reviews: ${e.toString()}');
    } finally {
      _setLoadingState(false);
    }
  }

  /// Sort reviews by different criteria
  void sortReviews(String sortBy) {
    switch (sortBy) {
      case 'helpful':
        _reviews.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
        break;
      case 'highest':
        _reviews.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'lowest':
        _reviews.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case 'recent':
      default:
        _reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    notifyListeners();
  }

  // All mock data removed - app now relies entirely on backend API

  /// Clear all reviews and stats
  void clearReviews() {
    _reviews.clear();
    _reviewStats = null;
    _currentProductId = null;
    _clearError();
    notifyListeners();
  }

  /// Refresh reviews for current product
  Future<void> refresh([String? productId]) async {
    final targetProductId = productId ?? _currentProductId;
    if (targetProductId != null) {
      await loadProductReviews(targetProductId);
    }
  }

  // Private helper methods
  void _setLoadingState(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setSubmittingState(bool submitting) {
    if (_isSubmitting != submitting) {
      _isSubmitting = submitting;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // API simulation methods - Replace with actual API service calls
  Future<List<Map<String, dynamic>>> _fetchProductReviews(
    String productId,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Replace with actual API call:
    // return await _reviewsApiService.getProductReviews(productId);

    // For now, return empty list (will fallback to mock data)
    throw Exception('API not implemented yet');
  }

  Future<Map<String, dynamic>> _fetchReviewStats(String productId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Replace with actual API call:
    // return await _reviewsApiService.getReviewStats(productId);

    throw Exception('API not implemented yet');
  }

  Future<List<Map<String, dynamic>>> _fetchUserReviews(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Replace with actual API call:
    // return await _reviewsApiService.getUserReviews(userId);

    throw Exception('API not implemented yet');
  }

  Future<Map<String, dynamic>> _submitReviewToApi({
    required String productId,
    required int rating,
    required String comment,
    String? userId,
    String? userName,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    // Replace with actual API call:
    // return await _reviewsApiService.submitReview(...);

    return {'reviewId': 'new_review_${DateTime.now().millisecondsSinceEpoch}'};
  }

  Future<void> _markReviewHelpfulApi(String reviewId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Replace with actual API call:
    // return await _reviewsApiService.markReviewHelpful(reviewId);

    // For now, just simulate success
  }

  /// Get formatted average rating
  String get formattedAverageRating {
    if (_reviewStats == null) return '0.0';
    return _reviewStats!.averageRating.toStringAsFixed(1);
  }

  /// Get total number of reviews
  int get totalReviews {
    if (_reviewStats == null) return _reviews.length;
    return _reviewStats!.totalReviews;
  }

  /// Check if there are any reviews
  bool get hasReviews => _reviews.isNotEmpty;

  /// Dispose method to clean up resources
  @override
  void dispose() {
    // Clean up any streams, timers, or other resources here
    super.dispose();
  }
}
