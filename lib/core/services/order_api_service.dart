import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../models/order.dart';

/// API Service for managing orders in the admin panel
///
/// Provides CRUD operations for orders:
/// - Fetch all orders with optional filtering
/// - Update order status (pending, processing, completed, cancelled)
/// - Update payment status
/// - Get order details by ID
/// - Delete orders
class OrderApiService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  String? _cachedAuthToken;

  OrderApiService({Dio? dio, FlutterSecureStorage? secureStorage})
    : _dio = dio ?? Dio(),
      _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
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
    } catch (e) {
      print('Error loading auth token: $e');
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

    return {
      'Authorization': 'Bearer $_cachedAuthToken',
      'Content-Type': 'application/json',
    };
  }

  /// Fetch all orders with optional status filter
  ///
  /// Parameters:
  /// - [status]: Filter by order status (pending, processing, completed, cancelled)
  /// - [limit]: Maximum number of orders to return
  /// - [page]: Page number for pagination
  ///
  /// Returns: List of Order objects
  Future<List<Order>> fetchAllOrders({
    String? status,
    int? limit,
    int? page,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (limit != null) {
        queryParams['limit'] = limit;
      }
      if (page != null) {
        queryParams['page'] = page;
      }

      print('Fetching orders with params: $queryParams');

      final headers = await _authHeaders;
      final response = await _dio.get(
        '/api/orders',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      print('Orders API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> ordersJson =
            response.data['orders'] ?? response.data;

        final orders = ordersJson.map((json) {
          try {
            // Extract ID from backend response (_id field)
            final String id = json['_id'] ?? json['id'] ?? '';

            // Adapt backend Order model to Flutter Order model
            return Order.fromJson(json, id);
          } catch (e) {
            print('Error parsing order: $e');
            print('Order JSON: $json');
            rethrow;
          }
        }).toList();

        print('Successfully fetched ${orders.length} orders');
        return orders;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to fetch orders: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('DioException fetching orders: ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to server. Please check if backend is running.',
        );
      } else if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Error fetching orders: $e');
      rethrow;
    }
  }

  /// Get order details by ID
  ///
  /// Parameters:
  /// - [orderId]: The unique identifier of the order
  ///
  /// Returns: Order object with full details
  Future<Order> getOrderDetails(String orderId) async {
    try {
      print('Fetching order details for: $orderId');

      final headers = await _authHeaders;
      final response = await _dio.get(
        '/api/orders/$orderId',
        options: Options(headers: headers),
      );

      print('Order details API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final orderJson = response.data['order'] ?? response.data;
        final String id = orderJson['_id'] ?? orderJson['id'] ?? '';
        final order = Order.fromJson(orderJson, id);

        print('Successfully fetched order details');
        return order;
      } else if (response.statusCode == 404) {
        throw Exception('Order not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception(
          'Failed to fetch order details: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      print('DioException fetching order details: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Order not found');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Error fetching order details: $e');
      rethrow;
    }
  }

  /// Update order status
  ///
  /// Parameters:
  /// - [orderId]: The unique identifier of the order
  /// - [newStatus]: New status (pending, processing, completed, cancelled)
  ///
  /// Returns: Updated Order object
  Future<Order> updateOrderStatus(String orderId, String newStatus) async {
    try {
      print('Updating order $orderId status to: $newStatus');

      final headers = await _authHeaders;
      final response = await _dio.put(
        '/api/orders/$orderId/status',
        data: {'status': newStatus},
        options: Options(headers: headers),
      );

      print('Update order status API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final orderJson = response.data['order'] ?? response.data;
        final String id = orderJson['_id'] ?? orderJson['id'] ?? '';
        final order = Order.fromJson(orderJson, id);

        print('Successfully updated order status');
        return order;
      } else if (response.statusCode == 404) {
        throw Exception('Order not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 400) {
        final errorMessage = response.data['error'] ?? 'Invalid status';
        throw Exception(errorMessage);
      } else {
        throw Exception(
          'Failed to update order status: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      print('DioException updating order status: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Order not found');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data['error'] ?? 'Invalid status';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  /// Update payment status
  ///
  /// Parameters:
  /// - [orderId]: The unique identifier of the order
  /// - [newPaymentStatus]: New payment status (pending, paid, failed, refunded)
  ///
  /// Returns: Updated Order object
  Future<Order> updatePaymentStatus(
    String orderId,
    String newPaymentStatus,
  ) async {
    try {
      print('Updating order $orderId payment status to: $newPaymentStatus');

      final headers = await _authHeaders;
      final response = await _dio.put(
        '/api/orders/$orderId/payment',
        data: {'paymentStatus': newPaymentStatus},
        options: Options(headers: headers),
      );

      print('Update payment status API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final orderJson = response.data['order'] ?? response.data;
        final String id = orderJson['_id'] ?? orderJson['id'] ?? '';
        final order = Order.fromJson(orderJson, id);

        print('Successfully updated payment status');
        return order;
      } else if (response.statusCode == 404) {
        throw Exception('Order not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 400) {
        final errorMessage = response.data['error'] ?? 'Invalid payment status';
        throw Exception(errorMessage);
      } else {
        throw Exception(
          'Failed to update payment status: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      print('DioException updating payment status: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Order not found');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (e.response?.statusCode == 400) {
        final errorMessage =
            e.response?.data['error'] ?? 'Invalid payment status';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Error updating payment status: $e');
      rethrow;
    }
  }

  /// Delete an order
  ///
  /// Parameters:
  /// - [orderId]: The unique identifier of the order to delete
  ///
  /// Returns: Success message
  Future<String> deleteOrder(String orderId) async {
    try {
      print('Deleting order: $orderId');

      final headers = await _authHeaders;
      final response = await _dio.delete(
        '/api/orders/$orderId',
        options: Options(headers: headers),
      );

      print('Delete order API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final message =
            response.data['message'] ?? 'Order deleted successfully';
        print('Successfully deleted order');
        return message;
      } else if (response.statusCode == 404) {
        throw Exception('Order not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('You do not have permission to delete orders');
      } else {
        throw Exception('Failed to delete order: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('DioException deleting order: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Order not found');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('You do not have permission to delete orders');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Error deleting order: $e');
      rethrow;
    }
  }

  /// Get order statistics
  ///
  /// Returns: Map with order statistics (total, pending, processing, completed, cancelled, totalRevenue)
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      print('Fetching order statistics');

      final headers = await _authHeaders;
      final response = await _dio.get(
        '/api/orders/stats',
        options: Options(headers: headers),
      );

      print('Order stats API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final stats = response.data['stats'] ?? response.data;
        print('Successfully fetched order stats');
        return stats;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception(
          'Failed to fetch order stats: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      print('DioException fetching order stats: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Error fetching order stats: $e');
      rethrow;
    }
  }

  /// Fetch orders analytics data
  ///
  /// Parameters:
  /// - [startDate]: Start date for analytics (ISO 8601 format)
  /// - [endDate]: End date for analytics (ISO 8601 format)
  ///
  /// Returns: Analytics data with daily breakdown
  Future<Map<String, dynamic>> getOrdersAnalytics({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate;
      }

      print('Fetching orders analytics with params: $queryParams');

      final headers = await _authHeaders;
      final response = await _dio.get(
        '/api/orders/analytics',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      print('Orders analytics API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final analytics = response.data;
        print('Successfully fetched orders analytics');
        return analytics;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception(
          'Failed to fetch orders analytics: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      print('DioException fetching orders analytics: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Error fetching orders analytics: $e');
      rethrow;
    }
  }
}
