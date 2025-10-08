import '../entities/coffee_product.dart';
import '../../data/datasources/coffee_api_service.dart';

/// Abstract repository interface for coffee products
abstract class CoffeeRepository {
  Future<List<CoffeeProduct>> getCoffeeProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
  });

  Future<CoffeeProduct> getCoffeeProduct(String id);

  Future<List<String>> getCategories();
}

/// Implementation of CoffeeRepository using API service
class CoffeeRepositoryImpl implements CoffeeRepository {
  final CoffeeApiService _apiService;

  CoffeeRepositoryImpl(this._apiService);

  @override
  Future<List<CoffeeProduct>> getCoffeeProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
  }) async {
    try {
      final models = await _apiService.fetchCoffeeProducts(
        page: page,
        limit: limit,
        category: category,
        search: search,
      );
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      // If API fails, return mock data as fallback
      return _getMockCoffeeProducts();
    }
  }

  @override
  Future<CoffeeProduct> getCoffeeProduct(String id) async {
    try {
      final model = await _apiService.fetchCoffeeProduct(id);
      return model.toEntity();
    } catch (e) {
      // If API fails, return mock data as fallback
      final mockProducts = _getMockCoffeeProducts();
      return mockProducts.firstWhere(
        (product) => product.id == id,
        orElse: () => throw Exception('Product not found'),
      );
    }
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      return await _apiService.fetchCategories();
    } catch (e) {
      // Return mock categories as fallback
      return [
        'Arabica',
        'Robusta',
        'Blends',
        'Single Origin',
        'Light Roast',
        'Dark Roast'
      ];
    }
  }

  // Mock data fallback for development and testing
  List<CoffeeProduct> _getMockCoffeeProducts() {
    return [
      const CoffeeProduct(
        id: '1',
        name: 'Ethiopian Yirgacheffe',
        description:
            'Light roasted single origin coffee from Ethiopia with floral notes and bright acidity. Perfect for pour-over brewing.',
        price: 24.99,
        imageUrl:
            'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400',
        origin: 'Ethiopia',
        roastLevel: 'Light',
        stock: 50,
      ),
      const CoffeeProduct(
        id: '2',
        name: 'Colombian Supremo',
        description:
            'Medium roasted coffee from the mountains of Colombia with balanced sweetness and nutty undertones.',
        price: 19.99,
        imageUrl:
            'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=400',
        origin: 'Colombia',
        roastLevel: 'Medium',
        stock: 30,
      ),
      const CoffeeProduct(
        id: '3',
        name: 'Brazilian Santos',
        description:
            'Dark roasted coffee with rich chocolate notes and low acidity. Ideal for espresso and milk-based drinks.',
        price: 22.99,
        imageUrl:
            'https://images.unsplash.com/photo-1459755486867-b55449bb39ff?w=400',
        origin: 'Brazil',
        roastLevel: 'Dark',
        stock: 40,
      ),
      const CoffeeProduct(
        id: '4',
        name: 'Guatemala Antigua',
        description:
            'Full-bodied coffee with spicy undertones and smoky finish. A classic choice for traditional brewing methods.',
        price: 26.99,
        imageUrl:
            'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400',
        origin: 'Guatemala',
        roastLevel: 'Medium-Dark',
        stock: 25,
      ),
      const CoffeeProduct(
        id: '5',
        name: 'Jamaican Blue Mountain',
        description:
            'Premium coffee with mild flavor, low acidity, and clean finish. Considered one of the world\'s finest coffees.',
        price: 49.99,
        imageUrl:
            'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=400',
        origin: 'Jamaica',
        roastLevel: 'Medium',
        stock: 15,
      ),
      const CoffeeProduct(
        id: '6',
        name: 'Sumatra Mandheling',
        description:
            'Full-bodied coffee with earthy, herbal notes and low acidity. Excellent for cold brew and strong espresso.',
        price: 21.99,
        imageUrl:
            'https://images.unsplash.com/photo-1459755486867-b55449bb39ff?w=400',
        origin: 'Indonesia',
        roastLevel: 'Dark',
        stock: 35,
      ),
    ];
  }
}
