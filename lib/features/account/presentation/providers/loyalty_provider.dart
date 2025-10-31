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
      _setError(
        'Unable to load loyalty information. Please check your connection and try again.',
      );
      _loyaltyAccount = null;
      notifyListeners();
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
      _setError('Unable to load points history. Please try again.');
      _pointsHistory = [];
      notifyListeners();
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
      _setError('Unable to load loyalty tiers. Please try again.');
      _loyaltyTiers = [];
      notifyListeners();
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
      _setError('Unable to load available rewards. Please try again.');
      _availableRewards = [];
      notifyListeners();
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
      _setError('Unable to load program information. Please try again.');
      _programInfo = null;
      notifyListeners();
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

  // All mock data removed - app now relies entirely on backend API

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
