/// User Model
/// Represents a user/customer in the system
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final List<String> roles;
  final String? firebaseUid;
  final String? firebaseSyncStatus;
  final String? firebaseSyncError;
  final bool isEmailVerified;
  final bool isActive;
  final String? authProvider;

  // Preferences
  final UserPreferences preferences;

  // Loyalty Program
  final LoyaltyProgram loyaltyProgram;

  // Statistics
  final UserStatistics statistics;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.roles,
    this.firebaseUid,
    this.firebaseSyncStatus,
    this.firebaseSyncError,
    required this.isEmailVerified,
    required this.isActive,
    this.authProvider,
    required this.preferences,
    required this.loyaltyProgram,
    required this.statistics,
    this.createdAt,
    this.updatedAt,
    this.lastLogin,
  });

  // ==================== FACTORY CONSTRUCTORS ====================

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _parseId(json['_id']),
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      phone: json['phone'],
      roles: List<String>.from(json['roles'] ?? ['customer']),
      firebaseUid: json['firebaseUid'],
      firebaseSyncStatus: json['firebaseSyncStatus'],
      firebaseSyncError: json['firebaseSyncError'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      authProvider: json['authProvider'],
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
      loyaltyProgram: LoyaltyProgram.fromJson(json['loyaltyProgram'] ?? {}),
      statistics: UserStatistics.fromJson(json['statistics'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
    );
  }

  static String _parseId(dynamic id) {
    if (id is String) return id;
    if (id is Map && id.containsKey('\$oid')) return id['\$oid'];
    if (id is Map && id.containsKey('buffer')) {
      // Convert buffer to hex string
      final buffer = id['buffer'] as Map;
      return buffer.values
          .map((v) => v.toRadixString(16).padLeft(2, '0'))
          .join();
    }
    return id.toString();
  }

  // ==================== TO JSON ====================

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'roles': roles,
      'firebaseUid': firebaseUid,
      'firebaseSyncStatus': firebaseSyncStatus,
      'firebaseSyncError': firebaseSyncError,
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
      'authProvider': authProvider,
      'preferences': preferences.toJson(),
      'loyaltyProgram': loyaltyProgram.toJson(),
      'statistics': statistics.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  // ==================== GETTERS ====================

  /// Get user's display name
  String get displayName => name.isNotEmpty ? name : email;

  /// Get user's primary role
  String get primaryRole => roles.isNotEmpty ? roles.first : 'customer';

  /// Check if user is admin
  bool get isAdmin => roles.contains('admin') || roles.contains('super_admin');

  /// Check if user is customer
  bool get isCustomer => roles.contains('customer');

  /// Get account status
  String get accountStatus {
    if (!isActive) return 'Inactive';
    if (!isEmailVerified) return 'Unverified';
    return 'Active';
  }

  /// Get account status color
  String get statusColor {
    if (!isActive) return 'red';
    if (!isEmailVerified) return 'orange';
    return 'green';
  }

  /// Get Firebase sync status display
  String get syncStatusDisplay {
    switch (firebaseSyncStatus) {
      case 'synced':
        return 'Synced';
      case 'manual':
        return 'Manual';
      case 'pending':
        return 'Pending';
      case 'error':
        return 'Error';
      default:
        return 'Unknown';
    }
  }

  /// Get formatted creation date
  String get formattedCreatedAt {
    if (createdAt == null) return 'N/A';
    return '${createdAt!.year}-${createdAt!.month.toString().padLeft(2, '0')}-${createdAt!.day.toString().padLeft(2, '0')}';
  }

  /// Get formatted last login
  String get formattedLastLogin {
    if (lastLogin == null) return 'Never';
    return '${lastLogin!.year}-${lastLogin!.month.toString().padLeft(2, '0')}-${lastLogin!.day.toString().padLeft(2, '0')}';
  }

  // ==================== COPY WITH ====================

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    List<String>? roles,
    String? firebaseUid,
    String? firebaseSyncStatus,
    String? firebaseSyncError,
    bool? isEmailVerified,
    bool? isActive,
    String? authProvider,
    UserPreferences? preferences,
    LoyaltyProgram? loyaltyProgram,
    UserStatistics? statistics,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      roles: roles ?? this.roles,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      firebaseSyncStatus: firebaseSyncStatus ?? this.firebaseSyncStatus,
      firebaseSyncError: firebaseSyncError ?? this.firebaseSyncError,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
      authProvider: authProvider ?? this.authProvider,
      preferences: preferences ?? this.preferences,
      loyaltyProgram: loyaltyProgram ?? this.loyaltyProgram,
      statistics: statistics ?? this.statistics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, roles: $roles, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ==================== USER PREFERENCES ====================

class UserPreferences {
  final NotificationPreferences notifications;
  final String language;
  final String currency;

  UserPreferences({
    required this.notifications,
    required this.language,
    required this.currency,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      notifications: NotificationPreferences.fromJson(
        json['notifications'] ?? {},
      ),
      language: json['language'] ?? 'en',
      currency: json['currency'] ?? 'AED',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications': notifications.toJson(),
      'language': language,
      'currency': currency,
    };
  }
}

class NotificationPreferences {
  final bool email;
  final bool push;
  final bool sms;
  final bool orderUpdates;
  final bool promotions;
  final bool newsletter;

  NotificationPreferences({
    required this.email,
    required this.push,
    required this.sms,
    required this.orderUpdates,
    required this.promotions,
    required this.newsletter,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      email: json['email'] ?? true,
      push: json['push'] ?? true,
      sms: json['sms'] ?? false,
      orderUpdates: json['orderUpdates'] ?? true,
      promotions: json['promotions'] ?? true,
      newsletter: json['newsletter'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'push': push,
      'sms': sms,
      'orderUpdates': orderUpdates,
      'promotions': promotions,
      'newsletter': newsletter,
    };
  }
}

// ==================== LOYALTY PROGRAM ====================

class LoyaltyProgram {
  final int points;
  final String tier;
  final double totalSpent;

  LoyaltyProgram({
    required this.points,
    required this.tier,
    required this.totalSpent,
  });

  factory LoyaltyProgram.fromJson(Map<String, dynamic> json) {
    return LoyaltyProgram(
      points: json['points'] ?? 0,
      tier: json['tier'] ?? 'Bronze',
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'points': points, 'tier': tier, 'totalSpent': totalSpent};
  }

  String get tierColor {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return '#CD7F32';
      case 'silver':
        return '#C0C0C0';
      case 'gold':
        return '#FFD700';
      case 'platinum':
        return '#E5E4E2';
      default:
        return '#808080';
    }
  }
}

// ==================== USER STATISTICS ====================

class UserStatistics {
  final int totalOrders;
  final double totalSpent;
  final double averageOrderValue;

  UserStatistics({
    required this.totalOrders,
    required this.totalSpent,
    required this.averageOrderValue,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      totalOrders: json['totalOrders'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      averageOrderValue: (json['averageOrderValue'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
      'averageOrderValue': averageOrderValue,
    };
  }

  String get formattedTotalSpent => '${totalSpent.toStringAsFixed(2)} AED';
  String get formattedAverageOrderValue =>
      '${averageOrderValue.toStringAsFixed(2)} AED';
}
