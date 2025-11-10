import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/token_model.dart';

/// Manages JWT token lifecycle with automatic refresh and rotation
///
/// Features:
/// - Automatic token refresh before expiry
/// - Token rotation on each refresh for enhanced security
/// - Secure token storage using platform-specific mechanisms
/// - Exponential backoff retry logic
/// - Token validity verification
/// - Emergency token invalidation
class TokenManagementService {
  static final TokenManagementService _instance =
      TokenManagementService._internal();

  factory TokenManagementService() {
    return _instance;
  }

  TokenManagementService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Token storage keys
  static const String _accessTokenKey = 'jwt_access_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';
  static const String _tokenExpiryKey = 'jwt_token_expiry';
  static const String _tokenRotationKey = 'jwt_token_rotation_count';

  // Token refresh timing (refresh 5 minutes before expiry for safety)
  static const Duration _refreshBuffer = Duration(minutes: 5);

  // Maximum retry attempts for token refresh
  static const int _maxRetryAttempts = 3;

  // Exponential backoff base delay (in milliseconds)
  static const int _retryBaseDelayMs = 100;

  // Token model cache
  TokenModel? _cachedToken;

  // Timer for automatic token refresh
  Timer? _refreshTimer;

  // Callbacks for token lifecycle events
  final List<Function(TokenModel)> _onTokenRefreshed = [];
  final List<Function()> _onTokenExpired = [];
  final List<Function(String)> _onRefreshError = [];

  // Refresh callback (to be provided by auth service)
  Function(String refreshToken)? _refreshCallback;

  // ========== PUBLIC API ==========

  /// Initialize token management service
  /// Call this during app startup
  Future<void> initialize({
    required Function(String refreshToken) refreshCallback,
  }) async {
    _refreshCallback = refreshCallback;
    await _loadStoredToken();
    _scheduleTokenRefresh();
  }

  /// Store new token after successful authentication
  Future<void> storeToken({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    try {
      final token = TokenModel(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
        issuedAt: DateTime.now(),
        rotationCount: 0,
      );

      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      await _secureStorage.write(
        key: _tokenExpiryKey,
        value: expiresAt.toIso8601String(),
      );
      await _secureStorage.write(key: _tokenRotationKey, value: '0');

      _cachedToken = token;
      _scheduleTokenRefresh();

      debugPrint(
        '✅ Token stored successfully (expires at: ${expiresAt.toIso8601String()})',
      );
    } catch (e) {
      debugPrint('❌ Failed to store token: $e');
      rethrow;
    }
  }

  /// Get current valid access token
  /// Returns null if token is expired or unavailable
  Future<String?> getAccessToken() async {
    try {
      final token = await _ensureValidToken();
      return token?.accessToken;
    } catch (e) {
      debugPrint('❌ Error getting access token: $e');
      return null;
    }
  }

  /// Get the full token model
  Future<TokenModel?> getToken() async {
    try {
      return await _ensureValidToken();
    } catch (e) {
      debugPrint('❌ Error getting token: $e');
      return null;
    }
  }

  /// Check if token is still valid
  Future<bool> isTokenValid() async {
    try {
      final token = await _loadStoredToken();
      if (token == null) return false;

      // Token is valid if it expires more than refresh buffer in the future
      final now = DateTime.now();
      return token.expiresAt.isAfter(now);
    } catch (e) {
      debugPrint('❌ Error checking token validity: $e');
      return false;
    }
  }

  /// Force token refresh immediately
  /// Useful for handling 401 unauthorized responses
  Future<String?> forceRefreshToken() async {
    try {
      debugPrint('🔄 Force refreshing token...');
      if (_cachedToken?.refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final newToken = await _refreshTokenWithRetry(_cachedToken!.refreshToken);
      return newToken?.accessToken;
    } catch (e) {
      _notifyRefreshError('Force refresh failed: $e');
      return null;
    }
  }

  /// Invalidate all tokens (used on logout)
  Future<void> invalidateTokens() async {
    try {
      // Cancel refresh timer
      _refreshTimer?.cancel();
      _refreshTimer = null;

      // Clear secure storage
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _tokenExpiryKey);
      await _secureStorage.delete(key: _tokenRotationKey);

      _cachedToken = null;

      debugPrint('✅ Tokens invalidated');
      _notifyTokenExpired();
    } catch (e) {
      debugPrint('❌ Error invalidating tokens: $e');
    }
  }

  /// Register callback for when token is refreshed
  void onTokenRefreshed(Function(TokenModel) callback) {
    _onTokenRefreshed.add(callback);
  }

  /// Register callback for when token expires
  void onTokenExpired(Function() callback) {
    _onTokenExpired.add(callback);
  }

  /// Register callback for refresh errors
  void onRefreshError(Function(String) callback) {
    _onRefreshError.add(callback);
  }

  /// Get token rotation count (security metric)
  int? getTokenRotationCount() {
    return _cachedToken?.rotationCount;
  }

  /// Get token age in seconds
  int? getTokenAgeSeconds() {
    if (_cachedToken == null) return null;
    return DateTime.now().difference(_cachedToken!.issuedAt).inSeconds;
  }

  /// Get time until token expiry in seconds
  int? getTimeToExpirySeconds() {
    if (_cachedToken == null) return null;
    final timeLeft = _cachedToken!.expiresAt.difference(DateTime.now());
    return timeLeft.inSeconds > 0 ? timeLeft.inSeconds : 0;
  }

  // ========== PRIVATE METHODS ==========

  /// Load token from secure storage
  Future<TokenModel?> _loadStoredToken() async {
    try {
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      final expiryStr = await _secureStorage.read(key: _tokenExpiryKey);
      final rotationStr = await _secureStorage.read(key: _tokenRotationKey);

      if (accessToken == null || refreshToken == null || expiryStr == null) {
        _cachedToken = null;
        return null;
      }

      final token = TokenModel(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: DateTime.parse(expiryStr),
        issuedAt: DateTime.now(), // We don't store this, so approximate it
        rotationCount: int.tryParse(rotationStr ?? '0') ?? 0,
      );

      _cachedToken = token;
      return token;
    } catch (e) {
      debugPrint('❌ Error loading stored token: $e');
      _cachedToken = null;
      return null;
    }
  }

  /// Ensure we have a valid token, refreshing if necessary
  Future<TokenModel?> _ensureValidToken() async {
    try {
      final token = _cachedToken ?? await _loadStoredToken();

      if (token == null) {
        return null;
      }

      // Check if token needs refresh
      final now = DateTime.now();
      final refreshTime = token.expiresAt.subtract(_refreshBuffer);

      if (now.isAfter(refreshTime)) {
        // Token needs refresh
        debugPrint('🔄 Token is about to expire, refreshing...');
        return await _refreshTokenWithRetry(token.refreshToken);
      }

      return token;
    } catch (e) {
      debugPrint('❌ Error ensuring valid token: $e');
      return null;
    }
  }

  /// Refresh token with exponential backoff retry logic
  Future<TokenModel?> _refreshTokenWithRetry(
    String refreshToken, {
    int attempt = 1,
  }) async {
    try {
      if (_refreshCallback == null) {
        throw Exception('Refresh callback not initialized');
      }

      debugPrint(
        '🔄 Attempting to refresh token (attempt $attempt/$_maxRetryAttempts)...',
      );

      // Call the refresh callback provided by auth service
      await _refreshCallback!(refreshToken);

      // After successful refresh, reload from storage
      final newToken = await _loadStoredToken();

      if (newToken != null) {
        // Increment rotation count
        newToken.rotationCount++;
        await _secureStorage.write(
          key: _tokenRotationKey,
          value: newToken.rotationCount.toString(),
        );

        debugPrint(
          '✅ Token refreshed successfully (rotation: ${newToken.rotationCount})',
        );
        _notifyTokenRefreshed(newToken);
        _scheduleTokenRefresh();
      }

      return newToken;
    } catch (e) {
      debugPrint('❌ Token refresh attempt $attempt failed: $e');

      if (attempt < _maxRetryAttempts) {
        // Calculate exponential backoff delay
        final delayMs =
            _retryBaseDelayMs * (1 << (attempt - 1)); // 2^(attempt-1)
        debugPrint(
          '⏳ Retrying in ${delayMs}ms... (attempt ${attempt + 1}/$_maxRetryAttempts)',
        );

        await Future.delayed(Duration(milliseconds: delayMs));
        return _refreshTokenWithRetry(refreshToken, attempt: attempt + 1);
      } else {
        // Max retries exceeded
        debugPrint('❌ Token refresh failed after $_maxRetryAttempts attempts');
        _notifyRefreshError(
          'Failed to refresh token after $_maxRetryAttempts attempts: $e',
        );
        _notifyTokenExpired();
        return null;
      }
    }
  }

  /// Schedule automatic token refresh
  void _scheduleTokenRefresh() {
    _refreshTimer?.cancel();

    if (_cachedToken == null) {
      debugPrint('⏰ No token to refresh');
      return;
    }

    final now = DateTime.now();
    final refreshTime = _cachedToken!.expiresAt.subtract(_refreshBuffer);

    if (now.isAfter(refreshTime)) {
      // Token is already expired or about to expire, refresh immediately
      debugPrint(
        '🔄 Token already expired or about to expire, refreshing immediately',
      );
      _ensureValidToken();
    } else {
      // Schedule refresh at the refresh time
      final timeUntilRefresh = refreshTime.difference(now);
      debugPrint(
        '⏰ Token refresh scheduled in ${timeUntilRefresh.inSeconds} seconds',
      );

      _refreshTimer = Timer(timeUntilRefresh, () {
        debugPrint('⏰ Token refresh timer triggered');
        _ensureValidToken();
      });
    }
  }

  /// Notify all token refreshed listeners
  void _notifyTokenRefreshed(TokenModel token) {
    for (final callback in _onTokenRefreshed) {
      try {
        callback(token);
      } catch (e) {
        debugPrint('❌ Error in onTokenRefreshed callback: $e');
      }
    }
  }

  /// Notify all token expired listeners
  void _notifyTokenExpired() {
    for (final callback in _onTokenExpired) {
      try {
        callback();
      } catch (e) {
        debugPrint('❌ Error in onTokenExpired callback: $e');
      }
    }
  }

  /// Notify all refresh error listeners
  void _notifyRefreshError(String error) {
    for (final callback in _onRefreshError) {
      try {
        callback(error);
      } catch (e) {
        debugPrint('❌ Error in onRefreshError callback: $e');
      }
    }
  }

  /// Cleanup resources
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _cachedToken = null;
    _onTokenRefreshed.clear();
    _onTokenExpired.clear();
    _onRefreshError.clear();
  }
}
