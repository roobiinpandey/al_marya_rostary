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
    final models = await _apiService.fetchCoffeeProducts(
      page: page,
      limit: limit,
      category: category,
      search: search,
    );
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<CoffeeProduct> getCoffeeProduct(String id) async {
    final model = await _apiService.fetchCoffeeProduct(id);
    return model.toEntity();
  }

  @override
  Future<List<String>> getCategories() async {
    return await _apiService.fetchCategories();
  }

  // All mock data removed - app now relies entirely on backend API
}
