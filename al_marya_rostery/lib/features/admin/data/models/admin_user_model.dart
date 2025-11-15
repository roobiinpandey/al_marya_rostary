/// Admin user model with comprehensive information
class AdminUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final List<String> roles;
  final bool isEmailVerified;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? preferences;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.roles,
    required this.isEmailVerified,
    required this.isActive,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
    this.preferences,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      roles: List<String>.from(json['roles'] ?? ['customer']),
      isEmailVerified: json['isEmailVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      preferences: json['preferences'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'roles': roles,
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'preferences': preferences,
    };
  }

  AdminUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    List<String>? roles,
    bool? isEmailVerified,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
  }) {
    return AdminUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      roles: roles ?? this.roles,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
    );
  }

  // Helper methods
  bool get isAdmin => roles.contains('admin');
  bool get isCustomer => roles.contains('customer');
  String get roleDisplay => roles.join(', ');
  String get statusDisplay => isActive ? 'Active' : 'Inactive';
}
