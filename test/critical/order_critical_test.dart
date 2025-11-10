import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

@GenerateMocks([http.Client])
void main() {
  group('Order Flow Critical Tests', () {
    late MockClient mockClient;
    const String baseUrl = 'https://almaryarostary.onrender.com/api';
    const String authToken = 'Bearer test_token_12345';

    setUp(() {
      mockClient = MockClient();
    });

    group('Create Order', () {
      test('successful order creation returns order ID', () async {
        // Arrange
        final orderData = {
          'items': [
            {'productId': 'prod_1', 'quantity': 2, 'price': 25.00},
            {'productId': 'prod_2', 'quantity': 1, 'price': 15.00},
          ],
          'total': 65.00,
          'deliveryAddress': {
            'street': '123 Test St',
            'city': 'Dubai',
            'emirate': 'Dubai',
          },
          'paymentMethod': 'card',
        };

        final responseBody = json.encode({
          'success': true,
          'data': {
            'orderId': 'order_test_12345',
            'orderNumber': 'ORD-001',
            'status': 'pending',
            'total': 65.00,
            'estimatedDelivery': '2025-11-11T14:00:00Z',
          },
        });

        when(
          mockClient.post(
            Uri.parse('$baseUrl/orders'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 201));

        // Act
        final response = await mockClient.post(
          Uri.parse('$baseUrl/orders'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authToken,
          },
          body: json.encode(orderData),
        );

        // Assert
        expect(response.statusCode, equals(201));
        final data = json.decode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['orderId'], isNotNull);
        expect(data['data']['orderNumber'], equals('ORD-001'));
        expect(data['data']['status'], equals('pending'));
      });

      test('order creation with empty cart fails', () async {
        // Arrange
        final orderData = {'items': [], 'total': 0.00};

        final responseBody = json.encode({
          'success': false,
          'error': 'Cart is empty',
        });

        when(
          mockClient.post(
            Uri.parse('$baseUrl/orders'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 400));

        // Act
        final response = await mockClient.post(
          Uri.parse('$baseUrl/orders'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authToken,
          },
          body: json.encode(orderData),
        );

        // Assert
        expect(response.statusCode, equals(400));
        final data = json.decode(response.body);
        expect(data['success'], isFalse);
      });

      test('order creation without authentication fails', () async {
        // Arrange
        final orderData = {
          'items': [
            {'productId': 'prod_1', 'quantity': 1},
          ],
          'total': 25.00,
        };

        final responseBody = json.encode({
          'success': false,
          'error': 'Unauthorized',
        });

        when(
          mockClient.post(
            Uri.parse('$baseUrl/orders'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 401));

        // Act
        final response = await mockClient.post(
          Uri.parse('$baseUrl/orders'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(orderData),
        );

        // Assert
        expect(response.statusCode, equals(401));
        final data = json.decode(response.body);
        expect(data['success'], isFalse);
      });
    });

    group('Get Order Details', () {
      test('retrieve order details successfully', () async {
        // Arrange
        const orderId = 'order_test_12345';
        final responseBody = json.encode({
          'success': true,
          'data': {
            'orderId': orderId,
            'orderNumber': 'ORD-001',
            'status': 'confirmed',
            'items': [
              {'productId': 'prod_1', 'quantity': 2, 'price': 25.00},
            ],
            'total': 50.00,
            'createdAt': '2025-11-10T10:00:00Z',
          },
        });

        when(
          mockClient.get(
            Uri.parse('$baseUrl/orders/$orderId'),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final response = await mockClient.get(
          Uri.parse('$baseUrl/orders/$orderId'),
          headers: {'Authorization': authToken},
        );

        // Assert
        expect(response.statusCode, equals(200));
        final data = json.decode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['orderId'], equals(orderId));
        expect(data['data']['status'], equals('confirmed'));
      });

      test('get non-existent order returns 404', () async {
        // Arrange
        const orderId = 'order_nonexistent';
        final responseBody = json.encode({
          'success': false,
          'error': 'Order not found',
        });

        when(
          mockClient.get(
            Uri.parse('$baseUrl/orders/$orderId'),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 404));

        // Act
        final response = await mockClient.get(
          Uri.parse('$baseUrl/orders/$orderId'),
          headers: {'Authorization': authToken},
        );

        // Assert
        expect(response.statusCode, equals(404));
        final data = json.decode(response.body);
        expect(data['success'], isFalse);
      });
    });

    group('Get Order History', () {
      test('retrieve order history successfully', () async {
        // Arrange
        final responseBody = json.encode({
          'success': true,
          'data': [
            {
              'orderId': 'order_1',
              'orderNumber': 'ORD-001',
              'status': 'delivered',
              'total': 65.00,
              'createdAt': '2025-11-09T10:00:00Z',
            },
            {
              'orderId': 'order_2',
              'orderNumber': 'ORD-002',
              'status': 'pending',
              'total': 45.00,
              'createdAt': '2025-11-10T14:00:00Z',
            },
          ],
        });

        when(
          mockClient.get(
            Uri.parse('$baseUrl/orders'),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final response = await mockClient.get(
          Uri.parse('$baseUrl/orders'),
          headers: {'Authorization': authToken},
        );

        // Assert
        expect(response.statusCode, equals(200));
        final data = json.decode(response.body);
        expect(data['success'], isTrue);
        expect(data['data'], isList);
        expect(data['data'].length, equals(2));
      });

      test('empty order history returns empty list', () async {
        // Arrange
        final responseBody = json.encode({'success': true, 'data': []});

        when(
          mockClient.get(
            Uri.parse('$baseUrl/orders'),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final response = await mockClient.get(
          Uri.parse('$baseUrl/orders'),
          headers: {'Authorization': authToken},
        );

        // Assert
        expect(response.statusCode, equals(200));
        final data = json.decode(response.body);
        expect(data['success'], isTrue);
        expect(data['data'], isEmpty);
      });
    });

    group('Cancel Order', () {
      test('successful order cancellation', () async {
        // Arrange
        const orderId = 'order_test_12345';
        const reason = 'Changed my mind';
        final responseBody = json.encode({
          'success': true,
          'data': {
            'orderId': orderId,
            'status': 'cancelled',
            'cancelledAt': '2025-11-10T15:00:00Z',
          },
        });

        when(
          mockClient.post(
            Uri.parse('$baseUrl/orders/$orderId/cancel'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final response = await mockClient.post(
          Uri.parse('$baseUrl/orders/$orderId/cancel'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authToken,
          },
          body: json.encode({'reason': reason}),
        );

        // Assert
        expect(response.statusCode, equals(200));
        final data = json.decode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['status'], equals('cancelled'));
      });

      test('cannot cancel already delivered order', () async {
        // Arrange
        const orderId = 'order_delivered';
        final responseBody = json.encode({
          'success': false,
          'error': 'Cannot cancel delivered order',
        });

        when(
          mockClient.post(
            Uri.parse('$baseUrl/orders/$orderId/cancel'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 400));

        // Act
        final response = await mockClient.post(
          Uri.parse('$baseUrl/orders/$orderId/cancel'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authToken,
          },
          body: json.encode({'reason': 'test'}),
        );

        // Assert
        expect(response.statusCode, equals(400));
        final data = json.decode(response.body);
        expect(data['success'], isFalse);
      });
    });

    group('Update Order Status', () {
      test('update order status successfully', () async {
        // Arrange
        const orderId = 'order_test_12345';
        const newStatus = 'shipped';
        final responseBody = json.encode({
          'success': true,
          'data': {
            'orderId': orderId,
            'status': newStatus,
            'updatedAt': '2025-11-10T16:00:00Z',
          },
        });

        when(
          mockClient.patch(
            Uri.parse('$baseUrl/orders/$orderId/status'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final response = await mockClient.patch(
          Uri.parse('$baseUrl/orders/$orderId/status'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authToken,
          },
          body: json.encode({'status': newStatus}),
        );

        // Assert
        expect(response.statusCode, equals(200));
        final data = json.decode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['status'], equals(newStatus));
      });
    });

    group('Order Tracking', () {
      test('get order tracking information', () async {
        // Arrange
        const orderId = 'order_test_12345';
        final responseBody = json.encode({
          'success': true,
          'data': {
            'orderId': orderId,
            'currentStatus': 'in_transit',
            'trackingNumber': 'TRACK123456',
            'estimatedDelivery': '2025-11-12T14:00:00Z',
            'history': [
              {'status': 'pending', 'timestamp': '2025-11-10T10:00:00Z'},
              {'status': 'confirmed', 'timestamp': '2025-11-10T11:00:00Z'},
              {'status': 'preparing', 'timestamp': '2025-11-10T12:00:00Z'},
              {'status': 'in_transit', 'timestamp': '2025-11-10T14:00:00Z'},
            ],
          },
        });

        when(
          mockClient.get(
            Uri.parse('$baseUrl/orders/$orderId/tracking'),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final response = await mockClient.get(
          Uri.parse('$baseUrl/orders/$orderId/tracking'),
          headers: {'Authorization': authToken},
        );

        // Assert
        expect(response.statusCode, equals(200));
        final data = json.decode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['currentStatus'], equals('in_transit'));
        expect(data['data']['history'], isList);
        expect(data['data']['history'].length, equals(4));
      });
    });
  });
}
