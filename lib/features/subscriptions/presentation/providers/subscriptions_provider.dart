import 'package:flutter/foundation.dart';
import '../../../../data/datasources/remote/subscriptions_api_service.dart';

class SubscriptionsProvider with ChangeNotifier {
  final SubscriptionsApiService _subscriptionsApiService =
      SubscriptionsApiService();

  // State variables
  List<Map<String, dynamic>> _userSubscriptions = [];
  List<Map<String, dynamic>> _availablePlans = [];
  List<Map<String, dynamic>> _subscriptionHistory = [];
  List<Map<String, dynamic>> _upcomingDeliveries = [];
  Map<String, dynamic>? _subscriptionStats;

  bool _isLoading = false;
  bool _isCreatingSubscription = false;
  bool _isUpdatingSubscription = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get userSubscriptions => _userSubscriptions;
  List<Map<String, dynamic>> get availablePlans => _availablePlans;
  List<Map<String, dynamic>> get subscriptionHistory => _subscriptionHistory;
  List<Map<String, dynamic>> get upcomingDeliveries => _upcomingDeliveries;
  Map<String, dynamic>? get subscriptionStats => _subscriptionStats;

  bool get isLoading => _isLoading;
  bool get isCreatingSubscription => _isCreatingSubscription;
  bool get isUpdatingSubscription => _isUpdatingSubscription;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasActiveSubscriptions =>
      _userSubscriptions.any((s) => s['status'] == 'active');

  /// Load user subscriptions
  Future<void> loadUserSubscriptions(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('📦 Loading subscriptions for user: $userId');

      final subscriptions = await _subscriptionsApiService.getUserSubscriptions(
        userId,
      );
      _userSubscriptions = subscriptions;

      debugPrint(
        '✅ Loaded ${subscriptions.length} subscriptions for user $userId',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading user subscriptions: $e');
      _setError('Failed to load subscriptions: ${e.toString()}');

      // Load mock data as fallback
      _loadMockUserSubscriptions();
    } finally {
      _setLoading(false);
    }
  }

  /// Load available subscription plans
  Future<void> loadSubscriptionPlans() async {
    try {
      debugPrint('📋 Loading subscription plans');

      final plans = await _subscriptionsApiService.getSubscriptionPlans();
      _availablePlans = plans;

      debugPrint('✅ Loaded ${plans.length} subscription plans');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading subscription plans: $e');
      _setError('Failed to load plans: ${e.toString()}');

      // Load mock plans as fallback
      _loadMockSubscriptionPlans();
    }
  }

  /// Create new subscription
  Future<bool> createSubscription({
    required String userId,
    required String planId,
    required String frequency,
    required Map<String, dynamic> deliveryAddress,
    String? preferences,
    Map<String, dynamic>? customization,
  }) async {
    _setCreatingSubscription(true);
    _clearError();

    try {
      debugPrint('🆕 Creating subscription for user: $userId, plan: $planId');

      final subscription = await _subscriptionsApiService.createSubscription(
        userId: userId,
        planId: planId,
        frequency: frequency,
        deliveryAddress: deliveryAddress,
        preferences: preferences,
        customization: customization,
      );

      if (subscription.isNotEmpty) {
        // Add to user subscriptions
        _userSubscriptions.insert(0, subscription);
        debugPrint('✅ Subscription created successfully');
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error creating subscription: $e');
      _setError('Failed to create subscription: ${e.toString()}');
      return false;
    } finally {
      _setCreatingSubscription(false);
    }
  }

  /// Update subscription
  Future<bool> updateSubscription(
    String subscriptionId,
    Map<String, dynamic> updateData,
  ) async {
    _setUpdatingSubscription(true);
    _clearError();

    try {
      debugPrint('🔄 Updating subscription: $subscriptionId');

      final updatedSubscription = await _subscriptionsApiService
          .updateSubscription(subscriptionId, updateData);

      if (updatedSubscription.isNotEmpty) {
        // Update in local list
        final index = _userSubscriptions.indexWhere(
          (s) => s['_id'] == subscriptionId,
        );
        if (index != -1) {
          _userSubscriptions[index] = {
            ..._userSubscriptions[index],
            ...updatedSubscription,
          };
        }

        debugPrint('✅ Subscription updated successfully');
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error updating subscription: $e');
      _setError('Failed to update subscription: ${e.toString()}');
      return false;
    } finally {
      _setUpdatingSubscription(false);
    }
  }

  /// Pause subscription
  Future<bool> pauseSubscription(String subscriptionId) async {
    try {
      debugPrint('⏸️ Pausing subscription: $subscriptionId');

      final result = await _subscriptionsApiService.pauseSubscription(
        subscriptionId,
      );

      if (result.isNotEmpty) {
        // Update status in local list
        final index = _userSubscriptions.indexWhere(
          (s) => s['_id'] == subscriptionId,
        );
        if (index != -1) {
          _userSubscriptions[index]['status'] = 'paused';
        }

        debugPrint('✅ Subscription paused successfully');
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error pausing subscription: $e');
      _setError('Failed to pause subscription: ${e.toString()}');
      return false;
    }
  }

  /// Resume subscription
  Future<bool> resumeSubscription(String subscriptionId) async {
    try {
      debugPrint('▶️ Resuming subscription: $subscriptionId');

      final result = await _subscriptionsApiService.resumeSubscription(
        subscriptionId,
      );

      if (result.isNotEmpty) {
        // Update status in local list
        final index = _userSubscriptions.indexWhere(
          (s) => s['_id'] == subscriptionId,
        );
        if (index != -1) {
          _userSubscriptions[index]['status'] = 'active';
        }

        debugPrint('✅ Subscription resumed successfully');
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error resuming subscription: $e');
      _setError('Failed to resume subscription: ${e.toString()}');
      return false;
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription(
    String subscriptionId, {
    String? reason,
  }) async {
    try {
      debugPrint('❌ Canceling subscription: $subscriptionId');

      final result = await _subscriptionsApiService.cancelSubscription(
        subscriptionId,
        reason: reason,
      );

      if (result.isNotEmpty) {
        // Update status in local list
        final index = _userSubscriptions.indexWhere(
          (s) => s['_id'] == subscriptionId,
        );
        if (index != -1) {
          _userSubscriptions[index]['status'] = 'cancelled';
        }

        debugPrint('✅ Subscription cancelled successfully');
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error canceling subscription: $e');
      _setError('Failed to cancel subscription: ${e.toString()}');
      return false;
    }
  }

  /// Skip next delivery
  Future<bool> skipNextDelivery(String subscriptionId, {String? reason}) async {
    try {
      debugPrint('⏭️ Skipping next delivery for subscription: $subscriptionId');

      final result = await _subscriptionsApiService.skipNextDelivery(
        subscriptionId,
        reason: reason,
      );

      if (result.isNotEmpty) {
        debugPrint('✅ Next delivery skipped successfully');
        // Reload subscription data to get updated next delivery date
        final subscription = await _subscriptionsApiService
            .getSubscriptionDetails(subscriptionId);
        final index = _userSubscriptions.indexWhere(
          (s) => s['_id'] == subscriptionId,
        );
        if (index != -1) {
          _userSubscriptions[index] = {
            ..._userSubscriptions[index],
            ...subscription,
          };
        }

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error skipping delivery: $e');
      _setError('Failed to skip delivery: ${e.toString()}');
      return false;
    }
  }

  /// Load subscription history
  Future<void> loadSubscriptionHistory(String subscriptionId) async {
    try {
      debugPrint('📜 Loading subscription history for: $subscriptionId');

      final history = await _subscriptionsApiService.getSubscriptionDeliveries(
        subscriptionId,
      );
      _subscriptionHistory = history;

      debugPrint('✅ Loaded ${history.length} history entries');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading subscription history: $e');
      _subscriptionHistory = _generateMockHistory();
      notifyListeners();
    }
  }

  // Mock data methods for fallback
  void _loadMockUserSubscriptions() {
    _userSubscriptions = [
      {
        '_id': 'sub_001',
        'planId': 'plan_premium',
        'planName': 'Premium Coffee Plan',
        'status': 'active',
        'frequency': 'weekly',
        'nextDelivery': DateTime.now()
            .add(const Duration(days: 3))
            .toIso8601String(),
        'price': 75.0,
        'deliveryAddress': {
          'street': '123 Coffee Street',
          'city': 'Dubai',
          'country': 'UAE',
        },
        'preferences': {
          'coffeeType': 'Medium Roast',
          'grindSize': 'Medium',
          'quantity': '500g',
        },
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 30))
            .toIso8601String(),
      },
      {
        '_id': 'sub_002',
        'planId': 'plan_basic',
        'planName': 'Basic Coffee Plan',
        'status': 'paused',
        'frequency': 'monthly',
        'nextDelivery': DateTime.now()
            .add(const Duration(days: 15))
            .toIso8601String(),
        'price': 45.0,
        'deliveryAddress': {
          'street': '456 Bean Avenue',
          'city': 'Abu Dhabi',
          'country': 'UAE',
        },
        'preferences': {
          'coffeeType': 'Dark Roast',
          'grindSize': 'Fine',
          'quantity': '250g',
        },
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 60))
            .toIso8601String(),
      },
    ];

    debugPrint('📱 Loaded mock user subscriptions');
  }

  void _loadMockSubscriptionPlans() {
    _availablePlans = [
      {
        '_id': 'plan_basic',
        'name': 'Basic Coffee Plan',
        'description': 'Perfect for casual coffee drinkers',
        'price': 45.0,
        'frequency': 'monthly',
        'features': [
          '250g premium coffee beans',
          'Monthly delivery',
          'Free shipping',
          'Choose your roast level',
        ],
        'isPopular': false,
      },
      {
        '_id': 'plan_premium',
        'name': 'Premium Coffee Plan',
        'description': 'For the serious coffee enthusiast',
        'price': 75.0,
        'frequency': 'weekly',
        'features': [
          '500g premium coffee beans',
          'Weekly delivery',
          'Free shipping',
          'Choose roast level & grind size',
          'Exclusive blends',
          'Coffee brewing guide',
        ],
        'isPopular': true,
      },
      {
        '_id': 'plan_family',
        'name': 'Family Coffee Plan',
        'description': 'Great for families and offices',
        'price': 120.0,
        'frequency': 'bi-weekly',
        'features': [
          '1kg premium coffee beans',
          'Bi-weekly delivery',
          'Free shipping',
          'Multiple coffee types',
          'Family brewing guides',
          'Priority customer support',
        ],
        'isPopular': false,
      },
    ];

    debugPrint('📱 Loaded mock subscription plans');
  }

  List<Map<String, dynamic>> _generateMockHistory() {
    return [
      {
        'id': 'delivery_001',
        'date': DateTime.now()
            .subtract(const Duration(days: 7))
            .toIso8601String(),
        'status': 'delivered',
        'items': ['Premium Coffee Blend - 500g'],
        'trackingNumber': 'TRK123456789',
      },
      {
        'id': 'delivery_002',
        'date': DateTime.now()
            .subtract(const Duration(days: 14))
            .toIso8601String(),
        'status': 'delivered',
        'items': ['Premium Coffee Blend - 500g'],
        'trackingNumber': 'TRK123456788',
      },
      {
        'id': 'delivery_003',
        'date': DateTime.now()
            .subtract(const Duration(days: 21))
            .toIso8601String(),
        'status': 'delivered',
        'items': ['Premium Coffee Blend - 500g'],
        'trackingNumber': 'TRK123456787',
      },
    ];
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setCreatingSubscription(bool creating) {
    _isCreatingSubscription = creating;
    notifyListeners();
  }

  void _setUpdatingSubscription(bool updating) {
    _isUpdatingSubscription = updating;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Computed getters
  int get activeSubscriptionsCount =>
      _userSubscriptions.where((s) => s['status'] == 'active').length;
  int get pausedSubscriptionsCount =>
      _userSubscriptions.where((s) => s['status'] == 'paused').length;
  double get totalMonthlySpend => _userSubscriptions
      .where((s) => s['status'] == 'active')
      .fold(0.0, (sum, s) => sum + ((s['price'] as num?)?.toDouble() ?? 0.0));

  List<Map<String, dynamic>> get activeSubscriptions =>
      _userSubscriptions.where((s) => s['status'] == 'active').toList();

  List<Map<String, dynamic>> get pausedSubscriptions =>
      _userSubscriptions.where((s) => s['status'] == 'paused').toList();

  String? getNextDeliveryDate(String subscriptionId) {
    final subscription = _userSubscriptions.firstWhere(
      (s) => s['_id'] == subscriptionId,
      orElse: () => {},
    );
    return subscription['nextDelivery'];
  }

  Map<String, dynamic>? getSubscriptionById(String subscriptionId) {
    try {
      return _userSubscriptions.firstWhere((s) => s['_id'] == subscriptionId);
    } catch (e) {
      return null;
    }
  }
}
