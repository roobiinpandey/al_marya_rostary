import 'package:flutter/foundation.dart';
import '../../../../data/datasources/coffee_api_service.dart';
import '../../../../data/models/coffee_product_model.dart';

/// CoffeeProvider manages coffee data state and API interactions
class CoffeeProvider with ChangeNotifier {
  final CoffeeApiService _coffeeApiService;

  // State variables
  List<CoffeeProductModel> _coffees = [];
  List<CoffeeProductModel> _featuredCoffees = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _error;

  // Constructor
  CoffeeProvider({CoffeeApiService? coffeeApiService})
    : _coffeeApiService = coffeeApiService ?? CoffeeApiService() {
    _init();
  }

  // Getters
  List<CoffeeProductModel> get coffees => _coffees;
  List<CoffeeProductModel> get featuredCoffees => _featuredCoffees;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  // Initialize the provider
  Future<void> _init() async {
    try {
      // Try to load real data from MongoDB first
      await _coffeeApiService.init();
      await loadCoffees();
      await loadCategories();
      debugPrint('✅ Successfully loaded real MongoDB data');
    } catch (e) {
      debugPrint('⚠️ MongoDB failed, using fallback data: $e');
      // Only use fallback if MongoDB completely fails
      _loadMockDataFallback();
    }
  }

  // Load all coffees from API
  Future<void> loadCoffees({
    int page = 1,
    int limit = 50,
    String? category,
    String? search,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint('🔄 Loading coffees from API...');

      final coffees = await _coffeeApiService.fetchCoffeeProducts(
        page: page,
        limit: limit,
        category: category,
        search: search,
      );

      _coffees = coffees;
      // Set featured coffees (first 4 or those marked as featured)
      _featuredCoffees = coffees.take(4).toList();
      debugPrint('✅ Loaded ${coffees.length} real coffees from MongoDB API');

      notifyListeners();
    } catch (e) {
      _setError('Failed to load coffees: ${e.toString()}');
      debugPrint('❌ Error loading coffees: $e');

      // Fallback to mock data if API fails
      _loadMockDataFallback();
    } finally {
      _setLoading(false);
    }
  }

  // Load categories from API
  Future<void> loadCategories() async {
    try {
      debugPrint('🔄 Loading categories from API...');
      final categories = await _coffeeApiService.fetchCategories();
      _categories = categories;
      debugPrint('✅ Loaded ${categories.length} categories from API');
      notifyListeners();
    } catch (e) {
      _setError('Failed to load categories: ${e.toString()}');
      debugPrint('❌ Error loading categories: $e');

      // Fallback categories
      _categories = ['Espresso', 'Single Origin', 'Blends', 'Decaf'];
      notifyListeners();
    }
  }

  // Get coffee by ID
  Future<CoffeeProductModel?> getCoffeeById(String id) async {
    try {
      // First check if we have it in memory
      final existingCoffee = _coffees.firstWhere(
        (coffee) => coffee.id == id,
        orElse: () => throw StateError('Coffee not found in memory'),
      );
      return existingCoffee;
    } catch (e) {
      // If not in memory, fetch from API
      try {
        return await _coffeeApiService.fetchCoffeeProduct(id);
      } catch (apiError) {
        debugPrint('❌ Error fetching coffee $id: $apiError');
        return null;
      }
    }
  }

  // Refresh all data
  Future<void> refresh() async {
    debugPrint('🔄 Refreshing all coffee data...');
    await Future.wait([loadCoffees(), loadCategories()]);
  }

  // Search coffees
  Future<void> searchCoffees(String query) async {
    if (query.isEmpty) {
      await loadCoffees();
      return;
    }

    await loadCoffees(search: query);
  }

  // Filter by category
  Future<void> filterByCategory(String category) async {
    await loadCoffees(category: category);
  }

  // Filter by origin/region
  Future<void> filterByOrigin(String origin) async {
    await loadCoffees(search: origin);
  }

  // Filter by multiple origins (for regions)
  Future<void> filterByRegion(List<String> origins) async {
    final searchQuery = origins.join(' OR ');
    await loadCoffees(search: searchQuery);
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Minimal fallback mock data when API is completely unavailable
  void _loadMockDataFallback() {
    debugPrint('📦 Loading minimal fallback data due to API unavailability...');

    // Minimal fallback data - just to prevent empty state when API is down
    _coffees = [
      const CoffeeProductModel(
        id: 'fallback-1',
        name: 'Al Marya House Blend',
        description:
            'Our signature coffee blend - temporarily using offline data',
        price: 45.0,
        imageUrl: 'assets/images/default-coffee.jpg', // Use local asset instead
        origin: 'Multi-Origin',
        roastLevel: 'Medium',
        stock: 100,
        variants: [
          CoffeeVariant(size: '250g', price: 45.0, stock: 30),
          CoffeeVariant(size: '500g', price: 85.0, stock: 25),
        ],
        categories: ['House Blend'],
        isActive: true,
        isFeatured: true,
      ),
      const CoffeeProductModel(
        id: 'fallback-2',
        name: 'Arabic Traditional',
        description:
            'Traditional Arabic coffee - temporarily using offline data',
        price: 50.0,
        imageUrl: 'assets/images/default-coffee.jpg', // Use local asset instead
        origin: 'Yemen',
        roastLevel: 'Dark',
        stock: 80,
        variants: [CoffeeVariant(size: '250g', price: 50.0, stock: 20)],
        categories: ['Traditional'],
        isActive: true,
        isFeatured: true,
      ),
    ];

    _featuredCoffees = _coffees;
    _categories = ['House Blend', 'Traditional'];

    // Show a clear message to the user that they're viewing offline data
    _setError('Using offline data - connect to internet for latest products');

    notifyListeners();
  }
}
