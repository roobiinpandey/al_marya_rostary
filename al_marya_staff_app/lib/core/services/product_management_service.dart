import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import './staff_admin_auth_service.dart';

/// Service for Product Management operations
/// Requires staff admin authentication
class ProductManagementService {
  static final ProductManagementService _instance =
      ProductManagementService._internal();
  factory ProductManagementService() => _instance;
  ProductManagementService._internal();

  final StaffAdminAuthService _authService = StaffAdminAuthService();

  /// Get all products with optional filters
  Future<Map<String, dynamic>> getProducts({
    String? type, // 'Coffee', 'Accessory', 'GiftSet', or null for all
    String? category,
    String? search,
    bool? isActive,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final token = await _authService.getAdminToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated. Please login first.',
        };
      }

      // Build query parameters
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (type != null) queryParams['type'] = type;
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;
      if (isActive != null) queryParams['isActive'] = isActive.toString();

      final uri = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/staff/products',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return data;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load products',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Get single product by ID
  Future<Map<String, dynamic>> getProduct(String productId) async {
    try {
      final token = await _authService.getAdminToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated. Please login first.',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/staff/products/$productId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Create new product
  Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> productData,
  ) async {
    try {
      final token = await _authService.getAdminToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated. Please login first.',
        };
      }

      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/api/staff/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(productData),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create product',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Update existing product
  Future<Map<String, dynamic>> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    try {
      final token = await _authService.getAdminToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated. Please login first.',
        };
      }

      final response = await http.put(
        Uri.parse('${ApiEndpoints.baseUrl}/api/staff/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(productData),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return data;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update product',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Delete product
  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      final token = await _authService.getAdminToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated. Please login first.',
        };
      }

      final response = await http.delete(
        Uri.parse('${ApiEndpoints.baseUrl}/api/staff/products/$productId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return data;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete product',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Toggle product visibility (active/inactive)
  Future<Map<String, dynamic>> toggleVisibility(String productId) async {
    try {
      final token = await _authService.getAdminToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated. Please login first.',
        };
      }

      final response = await http.patch(
        Uri.parse(
          '${ApiEndpoints.baseUrl}/api/staff/products/$productId/visibility',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return data;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to toggle visibility',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Get product stats
  Future<Map<String, dynamic>> getProductStats() async {
    try {
      final token = await _authService.getAdminToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated. Please login first.',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/staff/products/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
