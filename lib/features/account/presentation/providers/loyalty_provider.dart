import 'package:flutter/foundation.dart';
import '../../../../data/datasources/remote/loyalty_api_service.dart';

/// Provider for managing loyalty program state and operations
class LoyaltyProvider with ChangeNotifier {
  final LoyaltyApiService _loyaltyApiService = LoyaltyApiService();

  // State variables
  Map<String, dynamic>? _loyaltyAccount;
  List<Map<String, dynamic>> _pointsHistory = [];
  List<Map<String, dynamic>> _loyaltyTiers = [];
  List<Map<String, dynamic>> _availableRewards = [];
  List<Map<String, dynamic>> _redemptionHistory = [];
  Map<String, dynamic>? _programInfo;
  bool _isLoading = false;
  bool _isRedeeming = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get loyaltyAccount => _loyaltyAccount;
  List<Map<String, dynamic>> get pointsHistory => _pointsHistory;
  List<Map<String, dynamic>> get loyaltyTiers => _loyaltyTiers;
  List<Map<String, dynamic>> get availableRewards => _availableRewards;
  List<Map<String, dynamic>> get redemptionHistory => _redemptionHistory;
  Map<String, dynamic>? get programInfo => _programInfo;
  bool get isLoading => _isLoading;
  bool get isRedeeming => _isRedeeming;
  String? get error => _error;
  bool get hasError => _error != null;

  /// Get user's loyalty account information
  Future<void> loadLoyaltyAccount(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('🏆 Loading loyalty account for user: $userId');

      final account = await _loyaltyApiService.getLoyaltyAccount(userId);
      _loyaltyAccount = account;

      debugPrint('✅ Loaded loyalty account with ${account['points']} points');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading loyalty account: $e');
      _setError('Failed to load loyalty account: ${e.toString()}');

      // Load fallback mock data if API fails
      _loadMockLoyaltyAccount(userId);
    } finally {
      _setLoading(false);
    }
  }

  /// Get user's points history
  Future<void> loadPointsHistory(String userId) async {
    try {
      debugPrint('📊 Loading points history for user: $userId');

      final history = await _loyaltyApiService.getPointsHistory(userId);
      _pointsHistory = history;

      debugPrint('✅ Loaded ${history.length} points history entries');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading points history: $e');
      _loadMockPointsHistory();
    }
  }

  /// Load loyalty tiers
  Future<void> loadLoyaltyTiers() async {
    try {
      debugPrint('🎯 Loading loyalty tiers');

      final tiers = await _loyaltyApiService.getLoyaltyTiers();
      _loyaltyTiers = tiers;

      debugPrint('✅ Loaded ${tiers.length} loyalty tiers');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading loyalty tiers: $e');
      _loadMockLoyaltyTiers();
    }
  }

  /// Get available rewards for user
  Future<void> loadAvailableRewards(String userId) async {
    try {
      debugPrint('🎁 Loading available rewards for user: $userId');

      final rewards = await _loyaltyApiService.getAvailableRewards(userId);
      _availableRewards = rewards;

      debugPrint('✅ Loaded ${rewards.length} available rewards');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading available rewards: $e');
      _loadMockAvailableRewards();
    }
  }

  /// Get redemption history
  Future<void> loadRedemptionHistory(String userId) async {
    try {
      debugPrint('🏷️ Loading redemption history for user: $userId');

      final history = await _loyaltyApiService.getRedemptionHistory(userId);
      _redemptionHistory = history;

      debugPrint('✅ Loaded ${history.length} redemption history entries');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading redemption history: $e');
      _redemptionHistory = [];
    }
  }

  /// Load loyalty program information
  Future<void> loadProgramInfo() async {
    try {
      debugPrint('ℹ️ Loading loyalty program information');

      final info = await _loyaltyApiService.getLoyaltyProgram();
      _programInfo = info;

      debugPrint('✅ Loaded loyalty program information');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading program info: $e');
      _loadMockProgramInfo();
    }
  }

  /// Redeem a reward
  Future<bool> redeemReward({
    required String userId,
    required String rewardId,
    required int pointsRequired,
  }) async {
    _setRedeeming(true);
    _clearError();

    try {
      debugPrint('🎯 Redeeming reward: $rewardId for $pointsRequired points');

      await _loyaltyApiService.redeemReward(
        userId: userId,
        rewardId: rewardId,
        pointsRequired: pointsRequired,
      );

      debugPrint('✅ Reward redeemed successfully');

      // Refresh account and history data
      await loadLoyaltyAccount(userId);
      await loadRedemptionHistory(userId);

      return true;
    } catch (e) {
      debugPrint('❌ Error redeeming reward: $e');
      _setError('Failed to redeem reward: ${e.toString()}');
      return false;
    } finally {
      _setRedeeming(false);
    }
  }

  /// Load all user loyalty data at once
  Future<void> loadUserLoyaltyData(String userId) async {
    await Future.wait([
      loadLoyaltyAccount(userId),
      loadPointsHistory(userId),
      loadAvailableRewards(userId),
      loadRedemptionHistory(userId),
    ]);
  }

  /// Initialize loyalty system data
  Future<void> initializeLoyaltyData(String? userId) async {
    await loadLoyaltyTiers();
    await loadProgramInfo();

    if (userId != null) {
      await loadUserLoyaltyData(userId);
    }
  }

  /// Refresh all data
  Future<void> refresh(String? userId) async {
    if (userId != null) {
      await initializeLoyaltyData(userId);
    } else {
      await loadLoyaltyTiers();
      await loadProgramInfo();
    }
  }

  // Mock data methods for fallback
  void _loadMockLoyaltyAccount(String userId) {
    _loyaltyAccount = {
      'userId': userId,
      'points': 1250,
      'tier': 'Gold',
      'tierProgress': 0.75,
      'nextTierPoints': 500,
      'lifetimePoints': 3750,
      'totalRedemptions': 5,
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 180))
          .toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    debugPrint('📱 Loaded mock loyalty account');
    notifyListeners();
  }

  void _loadMockPointsHistory() {
    _pointsHistory = [
      {
        '_id': 'mock_1',
        'userId': 'user1',
        'points': 150,
        'type': 'earned',
        'description': 'Purchase - Ethiopian Yirgacheffe',
        'orderId': 'order_123',
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 2))
            .toIso8601String(),
      },
      {
        '_id': 'mock_2',
        'userId': 'user1',
        'points': -500,
        'type': 'redeemed',
        'description': 'Redeemed - Free 250g Coffee',
        'rewardId': 'reward_123',
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 5))
            .toIso8601String(),
      },
      {
        '_id': 'mock_3',
        'userId': 'user1',
        'points': 200,
        'type': 'earned',
        'description': 'Purchase - Colombian Supremo',
        'orderId': 'order_124',
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 10))
            .toIso8601String(),
      },
      {
        '_id': 'mock_4',
        'userId': 'user1',
        'points': 100,
        'type': 'bonus',
        'description': 'Birthday Bonus',
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 15))
            .toIso8601String(),
      },
    ];

    debugPrint('📱 Loaded mock points history');
  }

  void _loadMockLoyaltyTiers() {
    _loyaltyTiers = [
      {
        '_id': 'bronze',
        'name': 'Bronze',
        'minPoints': 0,
        'maxPoints': 499,
        'benefits': ['5% discount on orders', 'Birthday bonus points'],
        'pointMultiplier': 1.0,
        'color': '#CD7F32',
      },
      {
        '_id': 'silver',
        'name': 'Silver',
        'minPoints': 500,
        'maxPoints': 999,
        'benefits': [
          '10% discount on orders',
          'Free shipping',
          'Priority support',
        ],
        'pointMultiplier': 1.2,
        'color': '#C0C0C0',
      },
      {
        '_id': 'gold',
        'name': 'Gold',
        'minPoints': 1000,
        'maxPoints': 1999,
        'benefits': [
          '15% discount on orders',
          'Exclusive products',
          'Monthly free coffee',
        ],
        'pointMultiplier': 1.5,
        'color': '#FFD700',
      },
      {
        '_id': 'platinum',
        'name': 'Platinum',
        'minPoints': 2000,
        'maxPoints': 4999,
        'benefits': [
          '20% discount on orders',
          'VIP events',
          'Personal coffee consultant',
        ],
        'pointMultiplier': 2.0,
        'color': '#E5E4E2',
      },
      {
        '_id': 'diamond',
        'name': 'Diamond',
        'minPoints': 5000,
        'maxPoints': null,
        'benefits': [
          '25% discount on orders',
          'Unlimited perks',
          'Custom blends',
        ],
        'pointMultiplier': 3.0,
        'color': '#B9F2FF',
      },
    ];

    debugPrint('📱 Loaded mock loyalty tiers');
  }

  void _loadMockAvailableRewards() {
    _availableRewards = [
      {
        '_id': 'reward_1',
        'title': 'Free 250g Coffee',
        'description': 'Choose any 250g coffee blend',
        'pointsRequired': 500,
        'category': 'coffee',
        'isActive': true,
      },
      {
        '_id': 'reward_2',
        'title': '10% Off Next Order',
        'description': 'Get 10% discount on your next purchase',
        'pointsRequired': 200,
        'category': 'discount',
        'isActive': true,
      },
      {
        '_id': 'reward_3',
        'title': 'Coffee Tasting Kit',
        'description': 'Sample pack of 5 different coffee origins',
        'pointsRequired': 750,
        'category': 'experience',
        'isActive': true,
      },
      {
        '_id': 'reward_4',
        'title': 'Premium Grinder',
        'description': 'High-quality burr grinder for perfect coffee',
        'pointsRequired': 2000,
        'category': 'equipment',
        'isActive': true,
      },
    ];

    debugPrint('📱 Loaded mock available rewards');
  }

  void _loadMockProgramInfo() {
    _programInfo = {
      'name': 'Al Marya Loyalty Program',
      'description':
          'Earn points with every purchase and unlock exclusive rewards',
      'pointsPerDollar': 10,
      'welcomeBonus': 100,
      'birthdayBonus': 200,
      'referralBonus': 300,
      'features': [
        'Earn 10 points for every AED spent',
        'Exclusive member-only deals',
        'Birthday and anniversary bonuses',
        'Free shipping on tier benefits',
        'Priority customer support',
      ],
    };

    debugPrint('📱 Loaded mock program info');
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setRedeeming(bool redeeming) {
    _isRedeeming = redeeming;
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
  int get currentPoints => _loyaltyAccount?['points'] ?? 0;
  String get currentTier => _loyaltyAccount?['tier'] ?? 'Bronze';
  int get pointsToNextTier => _loyaltyAccount?['nextTierPoints'] ?? 0;
  double get tierProgress => _loyaltyAccount?['tierProgress'] ?? 0.0;
  int get lifetimePoints => _loyaltyAccount?['lifetimePoints'] ?? 0;
  bool get hasLoyaltyAccount => _loyaltyAccount != null;
}
