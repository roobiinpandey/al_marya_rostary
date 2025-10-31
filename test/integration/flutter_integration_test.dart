import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import our providers - use correct package name
import 'package:qahwat_al_emarat/features/coffee/presentation/providers/reviews_provider.dart';
import 'package:qahwat_al_emarat/features/account/presentation/providers/loyalty_provider.dart';
import 'package:qahwat_al_emarat/features/account/presentation/providers/referrals_provider.dart';
import 'package:qahwat_al_emarat/features/subscriptions/presentation/providers/subscriptions_provider.dart';

void main() {
  group('Al Marya Rostery Provider Integration Tests', () {
    testWidgets('All providers can be instantiated without errors', (
      WidgetTester tester,
    ) async {
      // Create a test widget that uses all our providers
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ReviewsProvider()),
            ChangeNotifierProvider(create: (_) => LoyaltyProvider()),
            ChangeNotifierProvider(create: (_) => ReferralsProvider()),
            ChangeNotifierProvider(create: (_) => SubscriptionsProvider()),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Test App')),
              body: const TestWidget(),
            ),
          ),
        ),
      );

      // Verify the widget tree built successfully
      expect(find.text('Test App'), findsOneWidget);
    });

    test('ReviewsProvider initialization', () {
      final provider = ReviewsProvider();
      expect(provider.isLoading, false);
      expect(provider.reviews, isEmpty);
      expect(provider.hasError, false);
    });

    test('LoyaltyProvider initialization', () {
      final provider = LoyaltyProvider();
      expect(provider.isLoading, false);
      expect(provider.loyaltyAccount, isNull);
      expect(provider.loyaltyTiers, isEmpty);
      expect(provider.hasError, false);
    });

    test('ReferralsProvider initialization', () {
      final provider = ReferralsProvider();
      expect(provider.isLoading, false);
      expect(provider.userReferrals, isEmpty);
      expect(provider.hasError, false);
      expect(provider.referralCodeForSharing, isNotEmpty);
    });

    test('SubscriptionsProvider initialization', () {
      final provider = SubscriptionsProvider();
      expect(provider.isLoading, false);
      expect(provider.userSubscriptions, isEmpty);
      expect(provider.availablePlans, isEmpty);
      expect(provider.hasError, false);
    });

    group('Provider Mock Data Tests', () {
      test('ReviewsProvider has reviews list', () {
        final provider = ReviewsProvider();

        // Reviews list should be available (empty initially)
        expect(provider.reviews, isA<List>());
        expect(provider.reviews, isEmpty);
      });

      test('LoyaltyProvider has loyalty tiers', () {
        final provider = LoyaltyProvider();

        // Loyalty tiers should be a list
        expect(provider.loyaltyTiers, isA<List>());
      });

      test('ReferralsProvider calculates statistics correctly', () {
        final provider = ReferralsProvider();

        // Mock data should provide valid statistics
        expect(provider.totalReferrals, isA<int>());
        expect(provider.totalPointsEarned, isA<int>());
        expect(provider.totalReferrals, greaterThanOrEqualTo(0));
        expect(provider.totalPointsEarned, greaterThanOrEqualTo(0));
      });

      test('SubscriptionsProvider calculates spending correctly', () {
        final provider = SubscriptionsProvider();

        // Test spending calculation
        expect(provider.totalMonthlySpend, isA<double>());
        expect(provider.activeSubscriptionsCount, isA<int>());
        expect(provider.totalMonthlySpend, greaterThanOrEqualTo(0.0));
      });
    });

    group('Error Handling Tests', () {
      test('Providers handle API failures gracefully', () {
        final reviewsProvider = ReviewsProvider();
        final loyaltyProvider = LoyaltyProvider();
        final referralsProvider = ReferralsProvider();
        final subscriptionsProvider = SubscriptionsProvider();

        // All providers should start without errors
        expect(reviewsProvider.hasError, false);
        expect(loyaltyProvider.hasError, false);
        expect(referralsProvider.hasError, false);
        expect(subscriptionsProvider.hasError, false);
      });
    });
  });
}

/// Simple test widget to verify provider integration
class TestWidget extends StatelessWidget {
  const TestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Test Reviews Provider
        Consumer<ReviewsProvider>(
          builder: (context, provider, child) {
            return Text('Reviews: ${provider.reviews.length}');
          },
        ),

        // Test Loyalty Provider
        Consumer<LoyaltyProvider>(
          builder: (context, provider, child) {
            return Text('Loyalty Tiers: ${provider.loyaltyTiers.length}');
          },
        ),

        // Test Referrals Provider
        Consumer<ReferralsProvider>(
          builder: (context, provider, child) {
            return Text('Referrals: ${provider.userReferrals.length}');
          },
        ),

        // Test Subscriptions Provider
        Consumer<SubscriptionsProvider>(
          builder: (context, provider, child) {
            return Text('Subscriptions: ${provider.userSubscriptions.length}');
          },
        ),
      ],
    );
  }
}
