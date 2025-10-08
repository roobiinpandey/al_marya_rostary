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
    await _coffeeApiService.init();
    await loadCoffees();
    await loadCategories();
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

      debugPrint('✅ Loaded ${coffees.length} coffees from API');
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

  // Fallback mock data when API is not available
  void _loadMockDataFallback() {
    debugPrint('📦 Loading fallback mock data...');
    _coffees = [
      const CoffeeProductModel(
        id: '1',
        name: 'Yemen Mocha',
        description: 'Rich and bold flavor from the mountains of Yemen',
        price: 45.0,
        imageUrl:
            'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400',
        origin: 'Yemen',
        roastLevel: 'Medium',
        stock: 100,
        variants: [
          CoffeeVariant(size: '250g', price: 45.0, stock: 30),
          CoffeeVariant(size: '500g', price: 85.0, stock: 25),
          CoffeeVariant(size: '1kg', price: 160.0, stock: 15),
        ],
        categories: ['Hot Coffee', 'Specialty'],
        isActive: true,
        isFeatured: true,
      ),
      const CoffeeProductModel(
        id: '2',
        name: 'Ethiopian Yirgacheffe',
        description: 'Light and fruity with floral notes',
        price: 42.0,
        imageUrl:
            'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=400',
        origin: 'Ethiopia',
        roastLevel: 'Light',
        stock: 85,
        variants: [
          CoffeeVariant(size: '250g', price: 42.0, stock: 35),
          CoffeeVariant(size: '500g', price: 80.0, stock: 30),
          CoffeeVariant(size: '1kg', price: 150.0, stock: 20),
        ],
        categories: ['Single Origin'],
        isActive: true,
        isFeatured: true,
      ),
      const CoffeeProductModel(
        id: '3',
        name: 'House Blend',
        description: 'Our signature blend, perfect for everyday enjoyment',
        price: 38.0,
        imageUrl:
            'https://images.unsplash.com/photo-1459755486867-b55449bb39ff?w=400',
        origin: 'Multi-Origin',
        roastLevel: 'Medium',
        stock: 120,
        variants: [
          CoffeeVariant(size: '250g', price: 38.0, stock: 40),
          CoffeeVariant(size: '500g', price: 70.0, stock: 40),
          CoffeeVariant(size: '1kg', price: 130.0, stock: 40),
        ],
        categories: ['Blends'],
        isActive: true,
        isFeatured: true,
      ),
      const CoffeeProductModel(
        id: '4',
        name: 'Dark Roast Supreme',
        description: 'Bold and intense for the strong coffee lovers',
        price: 40.0,
        imageUrl:
            'https://images.unsplash.com/photo-1447933601403-0c6688de566e?w=400',
        origin: 'Brazil',
        roastLevel: 'Dark',
        stock: 90,
        variants: [
          CoffeeVariant(size: '250g', price: 40.0, stock: 30),
          CoffeeVariant(size: '500g', price: 75.0, stock: 30),
          CoffeeVariant(size: '1kg', price: 140.0, stock: 30),
        ],
        categories: ['Dark Roast'],
        isActive: true,
        isFeatured: true,
      ),
    ];

    _featuredCoffees = _coffees;
    _categories = ['Espresso', 'Single Origin', 'Blends', 'Dark Roast'];

    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
