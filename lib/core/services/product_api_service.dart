import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/coffee_product_model.dart';

/// ProductApiService handles admin CRUD operations for coffee products
///
/// Provides comprehensive product management:
/// - Fetch all products (admin view, includes inactive)
/// - Create products with image upload
/// - Update products with optional image replacement
/// - Delete products
/// - Get product statistics
/// - Manage product variants and stock
class ProductApiService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  String? _cachedAuthToken;

  ProductApiService({Dio? dio, FlutterSecureStorage? secureStorage})
    : _dio = dio ?? Dio(),
      _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(
      seconds: 60,
    ); // Longer for file uploads
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.sendTimeout = const Duration(seconds: 60);
    _dio.options.validateStatus = (status) => status! < 500;
  }

  /// Initialize the service by loading the auth token
  Future<void> init() async {
    await _loadAuthToken();
  }

  /// Load authentication token from secure storage
  Future<void> _loadAuthToken() async {
    try {
      _cachedAuthToken = await _secureStorage.read(key: 'auth_token');
      debugPrint('🔑 ProductApiService: Auth token loaded');
    } catch (e) {
      debugPrint('❌ ProductApiService: Error loading auth token: $e');
      _cachedAuthToken = null;
    }
  }

  /// Get authorization headers with Bearer token
  Future<Map<String, String>> get _authHeaders async {
    // Ensure token is loaded
    if (_cachedAuthToken == null) {
      await _loadAuthToken();
    }

    if (_cachedAuthToken == null || _cachedAuthToken!.isEmpty) {
      throw Exception('Authentication token not set. Please login first.');
    }

    return {'Authorization': 'Bearer $_cachedAuthToken'};
  }

  /// Fetch all products (admin view - includes inactive products)
  ///
  /// Parameters:
  /// - [page]: Page number for pagination (default: 1)
  /// - [limit]: Number of products per page (default: 50)
  /// - [search]: Search query for filtering products
  /// - [category]: Filter by category
  /// - [includeInactive]: Include inactive products (default: true for admin)
  ///
  /// Returns: List of CoffeeProductModel objects
  Future<List<CoffeeProductModel>> fetchAllProducts({
    int page = 1,
    int limit = 50,
    String? search,
    String? category,
    bool includeInactive = true,
  }) async {
    try {
      debugPrint(
        '📦 ProductApiService: Fetching products (page: $page, limit: $limit)',
      );

      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      // Admin endpoint should return all products including inactive ones
      // We'll use the standard endpoint but may need to add admin-specific endpoint later
      final headers = await _authHeaders;
      final response = await _dio.get(
        '/api/coffees',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      debugPrint(
        '✅ ProductApiService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = response.data;

        List<dynamic> productsList;
        if (data is Map<String, dynamic> && data['data'] is List) {
          productsList = data['data'] as List;
        } else if (data is List) {
          productsList = data;
        } else {
          throw Exception('Invalid response format');
        }

        final products = productsList
            .map((json) => CoffeeProductModel.fromJson(json))
            .toList();

        debugPrint(
          '✅ ProductApiService: Successfully fetched ${products.length} products',
        );
        return products;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to fetch products: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ ProductApiService: DioException fetching products: ${e.message}',
      );
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ ProductApiService: Error fetching products: $e');
      rethrow;
    }
  }

  /// Get product details by ID
  ///
  /// Parameters:
  /// - [productId]: The unique identifier of the product
  ///
  /// Returns: CoffeeProductModel object
  Future<CoffeeProductModel> getProductDetails(String productId) async {
    try {
      debugPrint(
        '📦 ProductApiService: Fetching product details for: $productId',
      );

      final headers = await _authHeaders;
      final response = await _dio.get(
        '/api/coffees/$productId',
        options: Options(headers: headers),
      );

      debugPrint(
        '✅ ProductApiService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final productJson = response.data['data'] ?? response.data;
        final product = CoffeeProductModel.fromJson(productJson);

        debugPrint('✅ ProductApiService: Successfully fetched product details');
        return product;
      } else if (response.statusCode == 404) {
        throw Exception('Product not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception(
          'Failed to fetch product details: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ ProductApiService: DioException fetching product: ${e.message}',
      );
      if (e.response?.statusCode == 404) {
        throw Exception('Product not found');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ ProductApiService: Error fetching product details: $e');
      rethrow;
    }
  }

  /// Create a new product with optional image
  ///
  /// Parameters:
  /// - [nameEn]: Product name in English
  /// - [nameAr]: Product name in Arabic
  /// - [descriptionEn]: Product description in English
  /// - [descriptionAr]: Product description in Arabic
  /// - [price]: Base price (for 500gm variant)
  /// - [origin]: Coffee origin/country
  /// - [roastLevel]: Roast level (Light, Medium-Light, Medium, Medium-Dark, Dark)
  /// - [stock]: Initial stock quantity (optional)
  /// - [categories]: List of category names (optional)
  /// - [imageFile]: Product image file (optional)
  /// - [variants]: Custom variants (optional, defaults will be created)
  ///
  /// Returns: Created CoffeeProductModel object
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
      debugPrint('📦 ProductApiService: Creating new product: $nameEn');

      final headers = await _authHeaders;

      // Create FormData for multipart request
      final formData = FormData.fromMap({
        'nameEn': nameEn,
        'nameAr': nameAr,
        'descriptionEn': descriptionEn,
        'descriptionAr': descriptionAr,
        'price': price,
        'origin': origin,
        'roastLevel': roastLevel,
      });

      // Add optional fields
      if (stock != null) {
        formData.fields.add(MapEntry('stock', stock.toString()));
      }

      if (categories != null && categories.isNotEmpty) {
        // Backend expects categories as JSON array string
        formData.fields.add(MapEntry('categories', jsonEncode(categories)));
      }

      if (variants != null && variants.isNotEmpty) {
        // Send variants as JSON string
        formData.fields.add(MapEntry('variants', jsonEncode(variants)));
      }

      // Add image file if provided
      if (imageFile != null) {
        final fileName = imageFile.path.split('/').last;
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(imageFile.path, filename: fileName),
          ),
        );
        debugPrint('📤 ProductApiService: Image attached: $fileName');
      }

      final response = await _dio.post(
        '/api/coffees',
        data: formData,
        options: Options(headers: headers, contentType: 'multipart/form-data'),
      );

      debugPrint(
        '✅ ProductApiService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final productJson = response.data['data'] ?? response.data;
        final product = CoffeeProductModel.fromJson(productJson);

        debugPrint('✅ ProductApiService: Product created successfully');
        return product;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 400) {
        final errorMessage = response.data['error'] ?? 'Invalid product data';
        throw Exception(errorMessage);
      } else {
        throw Exception('Failed to create product: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ ProductApiService: DioException creating product: ${e.message}',
      );
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (e.response?.statusCode == 400) {
        final errorMessage =
            e.response?.data['error'] ?? 'Invalid product data';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ ProductApiService: Error creating product: $e');
      rethrow;
    }
  }

  /// Update an existing product with optional image replacement
  ///
  /// Parameters:
  /// - [productId]: The unique identifier of the product
  /// - [nameEn]: Product name in English (optional)
  /// - [nameAr]: Product name in Arabic (optional)
  /// - [descriptionEn]: Product description in English (optional)
  /// - [descriptionAr]: Product description in Arabic (optional)
  /// - [price]: Base price (optional)
  /// - [origin]: Coffee origin/country (optional)
  /// - [roastLevel]: Roast level (optional)
  /// - [stock]: Stock quantity (optional)
  /// - [categories]: List of category names (optional)
  /// - [imageFile]: New product image file (optional, replaces existing)
  /// - [variants]: Updated variants (optional)
  /// - [isActive]: Product active status (optional)
  ///
  /// Returns: Updated CoffeeProductModel object
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
      debugPrint('📦 ProductApiService: Updating product: $productId');

      final headers = await _authHeaders;

      // Create FormData for multipart request
      final formData = FormData();

      // Add only provided fields
      if (nameEn != null) {
        formData.fields.add(MapEntry('nameEn', nameEn));
      }
      if (nameAr != null) {
        formData.fields.add(MapEntry('nameAr', nameAr));
      }
      if (descriptionEn != null) {
        formData.fields.add(MapEntry('descriptionEn', descriptionEn));
      }
      if (descriptionAr != null) {
        formData.fields.add(MapEntry('descriptionAr', descriptionAr));
      }
      if (price != null) {
        formData.fields.add(MapEntry('price', price.toString()));
      }
      if (origin != null) {
        formData.fields.add(MapEntry('origin', origin));
      }
      if (roastLevel != null) {
        formData.fields.add(MapEntry('roastLevel', roastLevel));
      }
      if (stock != null) {
        formData.fields.add(MapEntry('stock', stock.toString()));
      }
      if (isActive != null) {
        formData.fields.add(MapEntry('isActive', isActive.toString()));
      }

      if (categories != null && categories.isNotEmpty) {
        formData.fields.add(MapEntry('categories', jsonEncode(categories)));
      }

      if (variants != null && variants.isNotEmpty) {
        formData.fields.add(MapEntry('variants', jsonEncode(variants)));
      }

      // Add new image file if provided
      if (imageFile != null) {
        final fileName = imageFile.path.split('/').last;
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(imageFile.path, filename: fileName),
          ),
        );
        debugPrint('📤 ProductApiService: New image attached: $fileName');
      }

      final response = await _dio.put(
        '/api/coffees/$productId',
        data: formData,
        options: Options(headers: headers, contentType: 'multipart/form-data'),
      );

      debugPrint(
        '✅ ProductApiService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final productJson = response.data['data'] ?? response.data;
        final product = CoffeeProductModel.fromJson(productJson);

        debugPrint('✅ ProductApiService: Product updated successfully');
        return product;
      } else if (response.statusCode == 404) {
        throw Exception('Product not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 400) {
        final errorMessage = response.data['error'] ?? 'Invalid product data';
        throw Exception(errorMessage);
      } else {
        throw Exception('Failed to update product: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ ProductApiService: DioException updating product: ${e.message}',
      );
      if (e.response?.statusCode == 404) {
        throw Exception('Product not found');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (e.response?.statusCode == 400) {
        final errorMessage =
            e.response?.data['error'] ?? 'Invalid product data';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ ProductApiService: Error updating product: $e');
      rethrow;
    }
  }

  /// Delete a product
  ///
  /// Parameters:
  /// - [productId]: The unique identifier of the product to delete
  ///
  /// Returns: Success message
  Future<String> deleteProduct(String productId) async {
    try {
      debugPrint('📦 ProductApiService: Deleting product: $productId');

      final headers = await _authHeaders;
      final response = await _dio.delete(
        '/api/coffees/$productId',
        options: Options(headers: headers),
      );

      debugPrint(
        '✅ ProductApiService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final message =
            response.data['message'] ?? 'Product deleted successfully';
        debugPrint('✅ ProductApiService: Product deleted successfully');
        return message;
      } else if (response.statusCode == 404) {
        throw Exception('Product not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('You do not have permission to delete products');
      } else {
        throw Exception('Failed to delete product: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ ProductApiService: DioException deleting product: ${e.message}',
      );
      if (e.response?.statusCode == 404) {
        throw Exception('Product not found');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('You do not have permission to delete products');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ ProductApiService: Error deleting product: $e');
      rethrow;
    }
  }

  /// Get product statistics
  ///
  /// Returns: Map with product statistics (total, active, inactive, categories, totalRevenue, etc.)
  Future<Map<String, dynamic>> getProductStats() async {
    try {
      debugPrint('📦 ProductApiService: Fetching product statistics');

      final headers = await _authHeaders;
      final response = await _dio.get(
        '/api/coffees/stats',
        options: Options(headers: headers),
      );

      debugPrint(
        '✅ ProductApiService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final stats = response.data['stats'] ?? response.data;
        debugPrint('✅ ProductApiService: Successfully fetched product stats');
        return stats;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception(
          'Failed to fetch product stats: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ ProductApiService: DioException fetching stats: ${e.message}',
      );
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ ProductApiService: Error fetching product stats: $e');
      rethrow;
    }
  }

  /// Update product stock (quick stock adjustment)
  ///
  /// Parameters:
  /// - [productId]: The unique identifier of the product
  /// - [newStock]: New stock quantity
  ///
  /// Returns: Updated CoffeeProductModel object
  Future<CoffeeProductModel> updateStock(String productId, int newStock) async {
    return updateProduct(productId: productId, stock: newStock);
  }

  /// Toggle product active status
  ///
  /// Parameters:
  /// - [productId]: The unique identifier of the product
  /// - [isActive]: New active status
  ///
  /// Returns: Updated CoffeeProductModel object
  Future<CoffeeProductModel> toggleActiveStatus(
    String productId,
    bool isActive,
  ) async {
    return updateProduct(productId: productId, isActive: isActive);
  }

  /// Bulk update products (e.g., bulk price change, bulk category assignment)
  ///
  /// Parameters:
  /// - [productIds]: List of product IDs to update
  /// - [updates]: Map of field updates to apply
  ///
  /// Returns: Number of products updated
  Future<int> bulkUpdateProducts(
    List<String> productIds,
    Map<String, dynamic> updates,
  ) async {
    // Note: This would require a backend endpoint for bulk operations
    // For now, we'll update products one by one
    int successCount = 0;

    for (final productId in productIds) {
      try {
        await updateProduct(
          productId: productId,
          nameEn: updates['nameEn'],
          nameAr: updates['nameAr'],
          descriptionEn: updates['descriptionEn'],
          descriptionAr: updates['descriptionAr'],
          price: updates['price'],
          origin: updates['origin'],
          roastLevel: updates['roastLevel'],
          stock: updates['stock'],
          categories: updates['categories'],
          isActive: updates['isActive'],
        );
        successCount++;
      } catch (e) {
        debugPrint('❌ Failed to update product $productId: $e');
      }
    }

    return successCount;
  }
}
