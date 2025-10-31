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
      _setError('Failed to load referrals: ${e.toString()}');

      // Load fallback mock data if API fails
      _loadMockUserReferrals(userId);
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
      _loadMockReferralStats();
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
      _loadMockProgramInfo();
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

  // Mock data methods for fallback
  void _loadMockUserReferrals(String userId) {
    _userReferrals = [
      {
        '_id': 'ref_1',
        'referrerId': userId,
        'code': 'COFFEE2024',
        'refereeName': 'Ahmed Hassan',
        'refereeEmail': 'ahmed@example.com',
        'status': 'completed',
        'pointsEarned': 500,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 5))
            .toIso8601String(),
        'completedAt': DateTime.now()
            .subtract(const Duration(days: 3))
            .toIso8601String(),
      },
      {
        '_id': 'ref_2',
        'referrerId': userId,
        'code': 'COFFEE2024',
        'refereeName': 'Fatima Al-Rashid',
        'refereeEmail': 'fatima@example.com',
        'status': 'completed',
        'pointsEarned': 500,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 10))
            .toIso8601String(),
        'completedAt': DateTime.now()
            .subtract(const Duration(days: 8))
            .toIso8601String(),
      },
      {
        '_id': 'ref_3',
        'referrerId': userId,
        'code': 'COFFEE2024',
        'refereeName': 'Mohammed Ali',
        'refereeEmail': 'mohammed@example.com',
        'status': 'pending',
        'pointsEarned': 0,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 12))
            .toIso8601String(),
      },
      {
        '_id': 'ref_4',
        'referrerId': userId,
        'code': 'COFFEE2024',
        'refereeName': 'Sara Abdullah',
        'refereeEmail': 'sara@example.com',
        'status': 'completed',
        'pointsEarned': 500,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 20))
            .toIso8601String(),
        'completedAt': DateTime.now()
            .subtract(const Duration(days: 18))
            .toIso8601String(),
      },
      {
        '_id': 'ref_5',
        'referrerId': userId,
        'code': 'COFFEE2024',
        'refereeName': 'Omar Khalid',
        'refereeEmail': 'omar@example.com',
        'status': 'pending',
        'pointsEarned': 0,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 25))
            .toIso8601String(),
      },
    ];

    _activeReferralCode = 'COFFEE2024';

    debugPrint('📱 Loaded mock user referrals');
    notifyListeners();
  }

  void _loadMockReferralStats() {
    _referralStats = {
      'totalReferrals': 5,
      'completedReferrals': 3,
      'pendingReferrals': 2,
      'totalPointsEarned': 1500,
      'conversionRate': 0.6,
      'averageTimeToComplete': '3 days',
    };

    debugPrint('📱 Loaded mock referral stats');
  }

  void _loadMockProgramInfo() {
    _programInfo = {
      'name': 'Al Marya Referral Program',
      'description': 'Refer friends and earn rewards for both of you',
      'referrerReward': 500,
      'refereeReward': 200,
      'currency': 'points',
      'terms': [
        'Both referrer and referee must be verified users',
        'Referee must make their first purchase within 30 days',
        'Rewards are credited after successful purchase',
        'Maximum 10 referrals per user per month',
      ],
      'howItWorks': [
        'Share your unique referral code with friends',
        'Your friend signs up using your code',
        'They make their first purchase',
        'Both of you earn rewards!',
      ],
    };

    debugPrint('📱 Loaded mock program info');
  }

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
