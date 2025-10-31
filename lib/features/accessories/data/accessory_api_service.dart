import 'dart:convert';
import 'package:http/http.dart' as http;
import 'accessory_model.dart';
import '../../../core/constants/app_constants.dart';

class AccessoryApiService {
  static String get baseUrl => '${AppConstants.baseUrl}/api';

  /// Fetch all accessories with filtering and pagination
  Future<List<Accessory>> fetchAccessories({
    String? type,
    String? category,
    String? brand,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    bool? featured,
    String? search,
    int page = 1,
    int limit = 20,
    String sortBy = 'displayOrder',
    String sortOrder = 'asc',
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (type != null) queryParams['type'] = type;
      if (category != null) queryParams['category'] = category;
      if (brand != null) queryParams['brand'] = brand;
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (inStock != null) queryParams['inStock'] = inStock.toString();
      if (featured != null) queryParams['featured'] = featured.toString();
      if (search != null) queryParams['search'] = search;

      final uri = Uri.parse(
        '$baseUrl/accessories',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> accessoriesData = data['data'];
          return accessoriesData
              .map((json) => Accessory.fromJson(json))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch accessories');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching accessories: $e');
    }
  }

  /// Fetch featured accessories
  Future<List<Accessory>> fetchFeaturedAccessories({int limit = 10}) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/accessories/featured',
      ).replace(queryParameters: {'limit': limit.toString()});

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> accessoriesData = data['data'];
          return accessoriesData
              .map((json) => Accessory.fromJson(json))
              .toList();
        } else {
          throw Exception(
            data['message'] ?? 'Failed to fetch featured accessories',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching featured accessories: $e');
    }
  }

  /// Fetch accessories by type
  Future<List<Accessory>> fetchAccessoriesByType(
    String type, {
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/accessories/type/$type',
      ).replace(queryParameters: {'limit': limit.toString()});

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> accessoriesData = data['data'];
          return accessoriesData
              .map((json) => Accessory.fromJson(json))
              .toList();
        } else {
          throw Exception(
            data['message'] ?? 'Failed to fetch accessories by type',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching accessories by type: $e');
    }
  }

  /// Fetch in-stock accessories
  Future<List<Accessory>> fetchInStockAccessories() async {
    try {
      final uri = Uri.parse('$baseUrl/accessories/in-stock');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> accessoriesData = data['data'];
          return accessoriesData
              .map((json) => Accessory.fromJson(json))
              .toList();
        } else {
          throw Exception(
            data['message'] ?? 'Failed to fetch in-stock accessories',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching in-stock accessories: $e');
    }
  }

  /// Fetch single accessory by ID
  Future<Accessory> fetchAccessory(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/accessories/$id');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Accessory.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch accessory');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Accessory not found');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching accessory: $e');
    }
  }

  /// Search accessories
  Future<List<Accessory>> searchAccessories(
    String query, {
    String? type,
    String? category,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'search': query,
        'limit': limit.toString(),
      };

      if (type != null) queryParams['type'] = type;
      if (category != null) queryParams['category'] = category;

      final uri = Uri.parse(
        '$baseUrl/accessories',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> accessoriesData = data['data'];
          return accessoriesData
              .map((json) => Accessory.fromJson(json))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to search accessories');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error searching accessories: $e');
    }
  }
}
