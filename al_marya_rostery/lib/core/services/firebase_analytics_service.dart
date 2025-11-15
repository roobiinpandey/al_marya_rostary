import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Service for Firebase Analytics event tracking
/// Tracks user behavior, conversions, and custom events
class FirebaseAnalyticsService {
  static final FirebaseAnalyticsService _instance =
      FirebaseAnalyticsService._internal();
  factory FirebaseAnalyticsService() => _instance;
  FirebaseAnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Get FirebaseAnalyticsObserver for route tracking
  FirebaseAnalyticsObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  // ============================================================================
  // USER PROPERTIES
  // ============================================================================

  /// Set user ID for tracking across sessions
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error - Set User ID: $e');
      }
    }
  }

  /// Set user properties
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error - Set User Property: $e');
      }
    }
  }

  // ============================================================================
  // AUTHENTICATION EVENTS
  // ============================================================================

  Future<void> logLogin({required String method}) async {
    await _logEvent('login', parameters: {'method': method});
  }

  Future<void> logSignUp({required String method}) async {
    await _logEvent('sign_up', parameters: {'method': method});
  }

  Future<void> logLogout() async {
    await _logEvent('logout');
  }

  // ============================================================================
  // E-COMMERCE EVENTS
  // ============================================================================

  Future<void> logViewItem({
    required String itemId,
    required String itemName,
    required String itemCategory,
    required double price,
  }) async {
    await _logEvent(
      'view_item',
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
        'item_category': itemCategory,
        'price': price,
      },
    );
  }

  Future<void> logAddToCart({
    required String itemId,
    required String itemName,
    required double price,
    required int quantity,
  }) async {
    await _logEvent(
      'add_to_cart',
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
        'price': price,
        'quantity': quantity,
        'value': price * quantity,
      },
    );
  }

  Future<void> logRemoveFromCart({
    required String itemId,
    required String itemName,
    required double price,
    required int quantity,
  }) async {
    await _logEvent(
      'remove_from_cart',
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
        'price': price,
        'quantity': quantity,
      },
    );
  }

  Future<void> logBeginCheckout({
    required double value,
    required int itemCount,
  }) async {
    await _logEvent(
      'begin_checkout',
      parameters: {'value': value, 'item_count': itemCount},
    );
  }

  Future<void> logPurchase({
    required String transactionId,
    required double value,
    required String currency,
    required int itemCount,
    String? coupon,
  }) async {
    await _logEvent(
      'purchase',
      parameters: {
        'transaction_id': transactionId,
        'value': value,
        'currency': currency,
        'item_count': itemCount,
        if (coupon != null) 'coupon': coupon,
      },
    );
  }

  Future<void> logRefund({
    required String transactionId,
    required double value,
  }) async {
    await _logEvent(
      'refund',
      parameters: {'transaction_id': transactionId, 'value': value},
    );
  }

  // ============================================================================
  // SUBSCRIPTION EVENTS
  // ============================================================================

  Future<void> logSubscriptionStart({
    required String subscriptionId,
    required String planName,
    required double price,
    required String frequency,
  }) async {
    await _logEvent(
      'subscription_start',
      parameters: {
        'subscription_id': subscriptionId,
        'plan_name': planName,
        'price': price,
        'frequency': frequency,
      },
    );
  }

  Future<void> logSubscriptionCancel({
    required String subscriptionId,
    required String reason,
  }) async {
    await _logEvent(
      'subscription_cancel',
      parameters: {'subscription_id': subscriptionId, 'reason': reason},
    );
  }

  // ============================================================================
  // ENGAGEMENT EVENTS
  // ============================================================================

  Future<void> logSearch({required String searchTerm}) async {
    await _logEvent('search', parameters: {'search_term': searchTerm});
  }

  Future<void> logShare({
    required String contentType,
    required String itemId,
  }) async {
    await _logEvent(
      'share',
      parameters: {'content_type': contentType, 'item_id': itemId},
    );
  }

  Future<void> logAddToWishlist({
    required String itemId,
    required String itemName,
    required double price,
  }) async {
    await _logEvent(
      'add_to_wishlist',
      parameters: {'item_id': itemId, 'item_name': itemName, 'price': price},
    );
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  // ============================================================================
  // LOYALTY EVENTS
  // ============================================================================

  Future<void> logEarnPoints({
    required int points,
    required String source,
  }) async {
    await _logEvent(
      'earn_points',
      parameters: {'points': points, 'source': source},
    );
  }

  Future<void> logRedeemPoints({
    required int points,
    required String rewardType,
  }) async {
    await _logEvent(
      'redeem_points',
      parameters: {'points': points, 'reward_type': rewardType},
    );
  }

  Future<void> logReferral({
    required String referralCode,
    bool isReferrer = false,
  }) async {
    await _logEvent(
      'referral',
      parameters: {'referral_code': referralCode, 'is_referrer': isReferrer},
    );
  }

  // ============================================================================
  // REVIEW EVENTS
  // ============================================================================

  Future<void> logSubmitReview({
    required String itemId,
    required double rating,
  }) async {
    await _logEvent(
      'submit_review',
      parameters: {'item_id': itemId, 'rating': rating},
    );
  }

  // ============================================================================
  // ERROR EVENTS
  // ============================================================================

  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
  }) async {
    await _logEvent(
      'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        if (stackTrace != null) 'stack_trace': stackTrace,
      },
    );
  }

  Future<void> logApiError({
    required String endpoint,
    required int statusCode,
    required String errorMessage,
  }) async {
    await _logEvent(
      'api_error',
      parameters: {
        'endpoint': endpoint,
        'status_code': statusCode,
        'error_message': errorMessage,
      },
    );
  }

  // ============================================================================
  // CUSTOM EVENTS
  // ============================================================================

  Future<void> logCustomEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _logEvent(name, parameters: parameters);
  }

  // ============================================================================
  // PRIVATE HELPER
  // ============================================================================

  Future<void> _logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error - Log Event ($name): $e');
      }
    }
  }
}
