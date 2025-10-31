import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/product_api_service.dart';
import '../../../../data/models/coffee_product_model.dart';

/// ProductProvider manages the state for admin product management
///
/// Provides:
/// - Product list with loading/error states
/// - CRUD operations with state updates
/// - Search and filter functionality
/// - Product statistics
/// - Image upload handling
class ProductProvider extends ChangeNotifier {
  final ProductApiService _productApiService;

  ProductProvider(this._productApiService) {
    _init();
  }

  // State management
  List<CoffeeProductModel> _products = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  Map<String, dynamic>? _stats;

  // Filtering and search
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showInactive = true;

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 50;
  bool _hasMore = true;

  // Getters
  List<CoffeeProductModel> get products => _filteredProducts;
  List<CoffeeProductModel> get allProducts => _products;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  Map<String, dynamic>? get stats => _stats;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  bool get showInactive => _showInactive;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  int get totalProducts => _products.length;
  int get activeProducts => _products.where((p) => p.isActive).length;
  int get inactiveProducts => _products.where((p) => !p.isActive).length;

  /// Initialize the provider
  Future<void> _init() async {
    try {
      await _productApiService.init();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ ProductProvider: Initialization error: $e');
      _error = 'Failed to initialize: $e';
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Get filtered products based on search and filters
  List<CoffeeProductModel> get _filteredProducts {
    var filtered = _products;

    // Filter by active status
    if (!_showInactive) {
      filtered = filtered.where((p) => p.isActive).toList();
    }

    // Filter by category
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered
          .where((p) => p.categories.contains(_selectedCategory))
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.description.toLowerCase().contains(query) ||
            p.origin.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  /// Fetch all products from the API
  Future<void> fetchProducts({bool refresh = false}) async {
    if (_isLoading) return;

    try {
      if (refresh) {
        _currentPage = 1;
        _hasMore = true;
      }

      _setLoading(true);
      _clearError();

      final fetchedProducts = await _productApiService.fetchAllProducts(
        page: _currentPage,
        limit: _itemsPerPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _selectedCategory,
        includeInactive: _showInactive,
      );

      if (refresh) {
        _products = fetchedProducts;
      } else {
        _products.addAll(fetchedProducts);
      }

      _hasMore = fetchedProducts.length == _itemsPerPage;
      _setLoading(false);

      debugPrint(
        '✅ ProductProvider: Fetched ${fetchedProducts.length} products',
      );
    } catch (e) {
      debugPrint('❌ ProductProvider: Error fetching products: $e');
      _setError('Failed to fetch products: $e');
      _setLoading(false);
    }
  }

  /// Fetch product statistics
  Future<void> fetchStats() async {
    try {
      _stats = await _productApiService.getProductStats();
      notifyListeners();
      debugPrint('✅ ProductProvider: Stats fetched successfully');
    } catch (e) {
      debugPrint('❌ ProductProvider: Error fetching stats: $e');
      // Don't set error state for stats failure, just log it
    }
  }

  /// Create a new product
  Future<CoffeeProductModel> createProduct({
    required String nameEn,
    required String nameAr,
    required String descriptionEn,
    required String descriptionAr,
    required double price,
    required String origin,
    required String roastLevel,
    int? stock,
    List<String>? categories,
    File? imageFile,
    List<Map<String, dynamic>>? variants,
  }) async {
    try {
      _clearError();

      debugPrint('📦 ProductProvider: Creating product: $nameEn');

      final newProduct = await _productApiService.createProduct(
        nameEn: nameEn,
        nameAr: nameAr,
        descriptionEn: descriptionEn,
        descriptionAr: descriptionAr,
        price: price,
        origin: origin,
        roastLevel: roastLevel,
        stock: stock,
        categories: categories,
        imageFile: imageFile,
        variants: variants,
      );

      // Add to local list
      _products.insert(0, newProduct);
      notifyListeners();

      // Refresh stats
      fetchStats();

      debugPrint('✅ ProductProvider: Product created successfully');
      return newProduct;
    } catch (e) {
      debugPrint('❌ ProductProvider: Error creating product: $e');
      _setError('Failed to create product: $e');
      rethrow;
    }
  }

  /// Update an existing product
  Future<CoffeeProductModel> updateProduct({
    required String productId,
    String? nameEn,
    String? nameAr,
    String? descriptionEn,
    String? descriptionAr,
    double? price,
    String? origin,
    String? roastLevel,
    int? stock,
    List<String>? categories,
    File? imageFile,
    List<Map<String, dynamic>>? variants,
    bool? isActive,
  }) async {
    try {
      _clearError();

      debugPrint('📦 ProductProvider: Updating product: $productId');

      final updatedProduct = await _productApiService.updateProduct(
        productId: productId,
        nameEn: nameEn,
        nameAr: nameAr,
        descriptionEn: descriptionEn,
        descriptionAr: descriptionAr,
        price: price,
        origin: origin,
        roastLevel: roastLevel,
        stock: stock,
        categories: categories,
        imageFile: imageFile,
        variants: variants,
        isActive: isActive,
      );

      // Update in local list
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = updatedProduct;
        notifyListeners();
      }

      // Refresh stats
      fetchStats();

      debugPrint('✅ ProductProvider: Product updated successfully');
      return updatedProduct;
    } catch (e) {
      debugPrint('❌ ProductProvider: Error updating product: $e');
      _setError('Failed to update product: $e');
      rethrow;
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      _clearError();

      debugPrint('📦 ProductProvider: Deleting product: $productId');

      await _productApiService.deleteProduct(productId);

      // Remove from local list
      _products.removeWhere((p) => p.id == productId);
      notifyListeners();

      // Refresh stats
      fetchStats();

      debugPrint('✅ ProductProvider: Product deleted successfully');
    } catch (e) {
      debugPrint('❌ ProductProvider: Error deleting product: $e');
      _setError('Failed to delete product: $e');
      rethrow;
    }
  }

  /// Update product stock
  Future<void> updateStock(String productId, int newStock) async {
    try {
      _clearError();

      debugPrint(
        '📦 ProductProvider: Updating stock for product: $productId to $newStock',
      );

      final updatedProduct = await _productApiService.updateStock(
        productId,
        newStock,
      );

      // Update in local list
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = updatedProduct;
        notifyListeners();
      }

      debugPrint('✅ ProductProvider: Stock updated successfully');
    } catch (e) {
      debugPrint('❌ ProductProvider: Error updating stock: $e');
      _setError('Failed to update stock: $e');
      rethrow;
    }
  }

  /// Toggle product active status
  Future<void> toggleActiveStatus(String productId, bool isActive) async {
    try {
      _clearError();

      debugPrint(
        '📦 ProductProvider: Toggling active status for product: $productId to $isActive',
      );

      final updatedProduct = await _productApiService.toggleActiveStatus(
        productId,
        isActive,
      );

      // Update in local list
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = updatedProduct;
        notifyListeners();
      }

      // Refresh stats
      fetchStats();

      debugPrint('✅ ProductProvider: Active status toggled successfully');
    } catch (e) {
      debugPrint('❌ ProductProvider: Error toggling active status: $e');
      _setError('Failed to toggle active status: $e');
      rethrow;
    }
  }

  /// Set search query and refresh products
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
      // Optionally trigger API search for server-side filtering
      // fetchProducts(refresh: true);
    }
  }

  /// Set category filter and refresh products
  void setCategory(String? category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
      // Optionally trigger API fetch with category filter
      // fetchProducts(refresh: true);
    }
  }

  /// Toggle show inactive products
  void toggleShowInactive() {
    _showInactive = !_showInactive;
    notifyListeners();
  }

  /// Load more products (pagination)
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;

    _currentPage++;
    await fetchProducts();
  }

  /// Refresh products (pull to refresh)
  Future<void> refresh() async {
    await fetchProducts(refresh: true);
    await fetchStats();
  }

  /// Clear search and filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _showInactive = true;
    notifyListeners();
  }

  /// Get product by ID
  CoffeeProductModel? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Get products by category
  List<CoffeeProductModel> getProductsByCategory(String category) {
    return _products.where((p) => p.categories.contains(category)).toList();
  }

  /// Get low stock products
  List<CoffeeProductModel> getLowStockProducts({int threshold = 10}) {
    return _products.where((p) => p.stock < threshold && p.isActive).toList();
  }

  /// Get all unique categories
  List<String> get allCategories {
    final categories = <String>{};
    for (final product in _products) {
      categories.addAll(product.categories);
    }
    return categories.toList()..sort();
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    debugPrint('🧹 ProductProvider: Disposing');
    super.dispose();
  }
}
