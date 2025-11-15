/// Model representing a JWT token with metadata
class TokenModel {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final DateTime issuedAt;
  int rotationCount;

  TokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.issuedAt,
    this.rotationCount = 0,
  });

  /// Check if token is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Get remaining time in seconds
  int get remainingSeconds {
    final difference = expiresAt.difference(DateTime.now());
    return difference.inSeconds > 0 ? difference.inSeconds : 0;
  }

  /// Get token age in seconds
  int get ageSeconds => DateTime.now().difference(issuedAt).inSeconds;

  /// Create a copy with modified fields
  TokenModel copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    DateTime? issuedAt,
    int? rotationCount,
  }) {
    return TokenModel(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      issuedAt: issuedAt ?? this.issuedAt,
      rotationCount: rotationCount ?? this.rotationCount,
    );
  }

  @override
  String toString() =>
      'TokenModel(accessToken: $accessToken, refreshToken: $refreshToken, expiresAt: $expiresAt, issuedAt: $issuedAt, rotationCount: $rotationCount, isExpired: $isExpired, remainingSeconds: $remainingSeconds)';
}
