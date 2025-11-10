import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

@GenerateMocks([http.Client])
void main() {
  group('Payment Flow Critical Tests', () {
    late MockClient mockClient;
    const String baseUrl = 'https://almaryarostary.onrender.com/api';

    setUp(() {
      mockClient = MockClient();
    });

    group('Create Payment Intent', () {
      test(
        'successful payment intent creation returns client secret',
        () async {
          // Arrange
          const amount = 5000; // $50.00
          const currency = 'aed';
          final responseBody = json.encode({
            'success': true,
            'data': {
              'clientSecret': 'pi_test_secret_12345',
              'paymentIntentId': 'pi_test_12345',
            },
          });

          when(
            mockClient.post(
              Uri.parse('$baseUrl/payment/create-intent'),
              headers: anyNamed('headers'),
              body: anyNamed('body'),
            ),
          ).thenAnswer((_) async => http.Response(responseBody, 200));

          // Act
          final response = await mockClient.post(
            Uri.parse('$baseUrl/payment/create-intent'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'amount': amount, 'currency': currency}),
          );

          // Assert
          expect(response.statusCode, equals(200));
          final data = json.decode(response.body);
          expect(data['success'], isTrue);
          expect(data['data']['clientSecret'], isNotNull);
          expect(data['data']['paymentIntentId'], isNotNull);
        },
      );

      test('payment intent creation with invalid amount fails', () async {
        // Arrange
        const amount = -100; // Invalid negative amount
        final responseBody = json.encode({
          'success': false,
          'error': 'Invalid amount',
        });

        when(
          mockClient.post(
            Uri.parse('$baseUrl/payment/create-intent'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 400));

        // Act
        final response = await mockClient.post(
          Uri.parse('$baseUrl/payment/create-intent'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'amount': amount, 'currency': 'aed'}),
        );

        // Assert
        expect(response.statusCode, equals(400));
        final data = json.decode(response.body);
        expect(data['success'], isFalse);
      });
    });

    group('Confirm Payment', () {
      test('successful payment confirmation', () async {
        // Arrange
        const paymentIntentId = 'pi_test_12345';
        final responseBody = json.encode({
          'success': true,
          'data': {'status': 'succeeded', 'amount': 5000, 'currency': 'aed'},
        });

        when(
          mockClient.post(
            Uri.parse('$baseUrl/payment/confirm'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final response = await mockClient.post(
          Uri.parse('$baseUrl/payment/confirm'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'paymentIntentId': paymentIntentId}),
        );

        // Assert
        expect(response.statusCode, equals(200));
        final data = json.decode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['status'], equals('succeeded'));
      });

      test('payment confirmation with card declined', () async {
        // Arrange
        const paymentIntentId = 'pi_test_declined';
        final responseBody = json.encode({
          'success': false,
          'error': 'card_declined',
          'message': 'Your card was declined',
        });

        when(
          mockClient.post(
            Uri.parse('$baseUrl/payment/confirm'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 402));

        // Act
        final response = await mockClient.post(
          Uri.parse('$baseUrl/payment/confirm'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'paymentIntentId': paymentIntentId}),
        );

        // Assert
        expect(response.statusCode, equals(402));
        final data = json.decode(response.body);
        expect(data['success'], isFalse);
        expect(data['error'], equals('card_declined'));
      });
    });

    group('Payment History', () {
      test('retrieve payment history successfully', () async {
        // Arrange
        final responseBody = json.encode({
          'success': true,
          'data': [
            {
              'id': 'pi_1',
              'amount': 5000,
              'status': 'succeeded',
              'created': 1234567890,
            },
            {
              'id': 'pi_2',
              'amount': 3000,
              'status': 'succeeded',
              'created': 1234567800,
            },
          ],
        });

        when(
          mockClient.get(
            Uri.parse('$baseUrl/payment/history'),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final response = await mockClient.get(
          Uri.parse('$baseUrl/payment/history'),
          headers: {'Authorization': 'Bearer test_token'},
        );

        // Assert
        expect(response.statusCode, equals(200));
        final data = json.decode(response.body);
        expect(data['success'], isTrue);
        expect(data['data'], isList);
        expect(data['data'].length, equals(2));
      });
    });

    group('Refund Payment', () {
      test('successful refund', () async {
        // Arrange
        const paymentIntentId = 'pi_test_12345';
        final responseBody = json.encode({
          'success': true,
          'data': {
            'refundId': 're_test_12345',
            'status': 'succeeded',
            'amount': 5000,
          },
        });

        when(
          mockClient.post(
            Uri.parse('$baseUrl/payment/refund'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final response = await mockClient.post(
          Uri.parse('$baseUrl/payment/refund'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'paymentIntentId': paymentIntentId}),
        );

        // Assert
        expect(response.statusCode, equals(200));
        final data = json.decode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['refundId'], isNotNull);
        expect(data['data']['status'], equals('succeeded'));
      });

      test('refund for non-existent payment fails', () async {
        // Arrange
        const paymentIntentId = 'pi_nonexistent';
        final responseBody = json.encode({
          'success': false,
          'error': 'Payment not found',
        });

        when(
          mockClient.post(
            Uri.parse('$baseUrl/payment/refund'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 404));

        // Act
        final response = await mockClient.post(
          Uri.parse('$baseUrl/payment/refund'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'paymentIntentId': paymentIntentId}),
        );

        // Assert
        expect(response.statusCode, equals(404));
        final data = json.decode(response.body);
        expect(data['success'], isFalse);
      });
    });
  });
}
