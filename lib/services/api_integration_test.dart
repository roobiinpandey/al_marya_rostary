import 'package:flutter/foundation.dart';
import '../data/datasources/remote/reviews_api_service.dart';
import '../data/datasources/remote/loyalty_api_service.dart';
import '../data/datasources/remote/referrals_api_service.dart';
import '../data/datasources/remote/subscriptions_api_service.dart';

/// Test service to verify API connectivity with the backend
class ApiIntegrationTest {
  static final ApiIntegrationTest _instance = ApiIntegrationTest._internal();
  factory ApiIntegrationTest() => _instance;
  ApiIntegrationTest._internal();

  final ReviewsApiService _reviewsService = ReviewsApiService();
  final LoyaltyApiService _loyaltyService = LoyaltyApiService();
  final ReferralsApiService _referralsService = ReferralsApiService();
  final SubscriptionsApiService _subscriptionsService =
      SubscriptionsApiService();

  /// Test all API services connectivity
  Future<Map<String, bool>> testAllServices() async {
    final results = <String, bool>{};

    // Test Reviews API
    try {
      await _reviewsService.getProductReviews('test-product-id');
      results['reviews'] = true;
      debugPrint('✅ Reviews API: Connected');
    } catch (e) {
      results['reviews'] = false;
      debugPrint('❌ Reviews API Error: $e');
    }

    // Test Loyalty API
    try {
      await _loyaltyService.getLoyaltyTiers();
      results['loyalty'] = true;
      debugPrint('✅ Loyalty API: Connected');
    } catch (e) {
      results['loyalty'] = false;
      debugPrint('❌ Loyalty API Error: $e');
    }

    // Test Referrals API
    try {
      await _referralsService.getReferralProgram();
      results['referrals'] = true;
      debugPrint('✅ Referrals API: Connected');
    } catch (e) {
      results['referrals'] = false;
      debugPrint('❌ Referrals API Error: $e');
    }

    // Test Subscriptions API
    try {
      await _subscriptionsService.getSubscriptionPlans();
      results['subscriptions'] = true;
      debugPrint('✅ Subscriptions API: Connected');
    } catch (e) {
      results['subscriptions'] = false;
      debugPrint('❌ Subscriptions API Error: $e');
    }

    return results;
  }

  /// Test individual service
  Future<bool> testReviewsService() async {
    try {
      await _reviewsService.getProductReviews('test-product');
      debugPrint('✅ Reviews Service: Working');
      return true;
    } catch (e) {
      debugPrint('❌ Reviews Service Error: $e');
      return false;
    }
  }

  Future<bool> testLoyaltyService() async {
    try {
      await _loyaltyService.getLoyaltyTiers();
      debugPrint('✅ Loyalty Service: Working');
      return true;
    } catch (e) {
      debugPrint('❌ Loyalty Service Error: $e');
      return false;
    }
  }

  Future<bool> testReferralsService() async {
    try {
      await _referralsService.getReferralProgram();
      debugPrint('✅ Referrals Service: Working');
      return true;
    } catch (e) {
      debugPrint('❌ Referrals Service Error: $e');
      return false;
    }
  }

  Future<bool> testSubscriptionsService() async {
    try {
      await _subscriptionsService.getSubscriptionPlans();
      debugPrint('✅ Subscriptions Service: Working');
      return true;
    } catch (e) {
      debugPrint('❌ Subscriptions Service Error: $e');
      return false;
    }
  }

  /// Print connectivity report
  void printConnectivityReport(Map<String, bool> results) {
    debugPrint('\n🔗 API CONNECTIVITY REPORT');
    debugPrint('========================');

    results.forEach((service, isConnected) {
      final status = isConnected ? '✅ Connected' : '❌ Failed';
      debugPrint('$service: $status');
    });

    final connectedCount = results.values.where((v) => v).length;
    final totalCount = results.length;

    debugPrint('\nOverall: $connectedCount/$totalCount services connected');

    if (connectedCount == totalCount) {
      debugPrint('🎉 All services are ready for Flutter integration!');
    } else {
      debugPrint('⚠️ Some services need attention before full integration');
    }

    debugPrint('========================\n');
  }
}
