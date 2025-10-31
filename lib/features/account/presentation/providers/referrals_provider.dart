import 'package:flutter/foundation.dart';
import '../../../../data/datasources/remote/referrals_api_service.dart';

/// Provider for managing referral program state and operations
class ReferralsProvider with ChangeNotifier {
  final ReferralsApiService _referralsApiService = ReferralsApiService();

  // State variables
  List<Map<String, dynamic>> _userReferrals = [];
  Map<String, dynamic>? _referralStats;
  List<Map<String, dynamic>> _referralEarnings = [];
  Map<String, dynamic>? _programInfo;
  String? _activeReferralCode;
  bool _isLoading = false;
  bool _isCreatingReferral = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get userReferrals => _userReferrals;
  Map<String, dynamic>? get referralStats => _referralStats;
  List<Map<String, dynamic>> get referralEarnings => _referralEarnings;
  Map<String, dynamic>? get programInfo => _programInfo;
  String? get activeReferralCode => _activeReferralCode;
  bool get isLoading => _isLoading;
  bool get isCreatingReferral => _isCreatingReferral;
  String? get error => _error;
  bool get hasError => _error != null;

  /// Load user's referrals
  Future<void> loadUserReferrals(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('🔗 Loading referrals for user: $userId');

      final referrals = await _referralsApiService.getUserReferrals(userId);
      _userReferrals = referrals;

      // Extract active referral code from user's referrals
      if (referrals.isNotEmpty) {
        _activeReferralCode = referrals.first['code'];
      }

      debugPrint('✅ Loaded ${referrals.length} referrals for user $userId');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading user referrals: $e');
      _setError(
        'Unable to load referral information. Please check your connection and try again.',
      );
      _userReferrals = [];
      _activeReferralCode = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Get user's referral statistics
  Future<void> loadReferralStats(String userId) async {
    try {
      debugPrint('📊 Loading referral stats for user: $userId');

      final stats = await _referralsApiService.getUserReferralStats(userId);
      _referralStats = stats;

      debugPrint('✅ Loaded referral statistics');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading referral stats: $e');
      _setError('Unable to load referral statistics. Please try again.');
      _referralStats = null;
      notifyListeners();
    }
  }

  /// Get user's referral earnings
  Future<void> loadReferralEarnings(String userId) async {
    try {
      debugPrint('💰 Loading referral earnings for user: $userId');

      final earnings = await _referralsApiService.getUserReferralEarnings(
        userId,
      );
      _referralEarnings = earnings;

      debugPrint('✅ Loaded ${earnings.length} referral earnings');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading referral earnings: $e');
      _referralEarnings = [];
    }
  }

  /// Load referral program information
  Future<void> loadProgramInfo() async {
    try {
      debugPrint('ℹ️ Loading referral program information');

      final info = await _referralsApiService.getReferralProgram();
      _programInfo = info;

      debugPrint('✅ Loaded referral program information');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading program info: $e');
      _setError('Unable to load program information. Please try again.');
      _programInfo = null;
      notifyListeners();
    }
  }

  /// Create a new referral
  Future<Map<String, dynamic>?> createReferral({
    required String referrerId,
    String? refereeEmail,
    String? refereePhone,
  }) async {
    _setCreatingReferral(true);
    _clearError();

    try {
      debugPrint('🔗 Creating referral for user: $referrerId');

      final result = await _referralsApiService.createReferral(
        referrerId: referrerId,
        refereeEmail: refereeEmail,
        refereePhone: refereePhone,
      );

      debugPrint('✅ Referral created successfully: ${result['code']}');

      // Update active referral code
      _activeReferralCode = result['code'];

      // Refresh user referrals
      await loadUserReferrals(referrerId);

      return result;
    } catch (e) {
      debugPrint('❌ Error creating referral: $e');
      _setError('Failed to create referral: ${e.toString()}');
      return null;
    } finally {
      _setCreatingReferral(false);
    }
  }

  /// Track referral click/use
  Future<bool> trackReferralClick(String referralCode) async {
    try {
      debugPrint('👆 Tracking referral click: $referralCode');

      await _referralsApiService.trackReferralClick(referralCode);

      debugPrint('✅ Referral click tracked successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error tracking referral click: $e');
      return false;
    }
  }

  /// Validate referral code
  Future<Map<String, dynamic>?> validateReferralCode(String code) async {
    try {
      debugPrint('🔍 Validating referral code: $code');

      final referral = await _referralsApiService.getReferralByCode(code);

      if (referral != null) {
        debugPrint('✅ Referral code is valid');
      } else {
        debugPrint('⚠️ Referral code not found');
      }

      return referral;
    } catch (e) {
      debugPrint('❌ Error validating referral code: $e');
      return null;
    }
  }

  /// Load all user referral data at once
  Future<void> loadUserReferralData(String userId) async {
    await Future.wait([
      loadUserReferrals(userId),
      loadReferralStats(userId),
      loadReferralEarnings(userId),
    ]);
  }

  /// Initialize referral system data
  Future<void> initializeReferralData(String? userId) async {
    await loadProgramInfo();

    if (userId != null) {
      await loadUserReferralData(userId);
    }
  }

  /// Refresh all data
  Future<void> refresh(String? userId) async {
    if (userId != null) {
      await initializeReferralData(userId);
    } else {
      await loadProgramInfo();
    }
  }
  // All mock data removed - app now relies entirely on backend API

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setCreatingReferral(bool creating) {
    _isCreatingReferral = creating;
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
  int get totalReferrals =>
      _referralStats?['totalReferrals'] ?? _userReferrals.length;
  int get completedReferrals =>
      _referralStats?['completedReferrals'] ??
      _userReferrals.where((r) => r['status'] == 'completed').length;
  int get pendingReferrals =>
      _referralStats?['pendingReferrals'] ??
      _userReferrals.where((r) => r['status'] == 'pending').length;
  int get totalPointsEarned =>
      _referralStats?['totalPointsEarned'] ??
      _userReferrals.fold<int>(
        0,
        (sum, r) => sum + ((r['pointsEarned'] as int?) ?? 0),
      );
  bool get hasReferralData => _userReferrals.isNotEmpty;
  String get referralCodeForSharing => _activeReferralCode ?? 'COFFEE2024';
}
