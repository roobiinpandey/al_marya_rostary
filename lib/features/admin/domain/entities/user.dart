/// Domain entity for User
class UserEntity {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEmailVerified;
  final List<String> roles;
  final bool isAnonymous; // Added isAnonymous property

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
    required this.isEmailVerified,
    required this.roles,
    required this.isAnonymous, // Added to constructor
  });

  bool get isAdmin => roles.contains('admin');
  bool get isCustomer => roles.contains('customer');

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEmailVerified,
    List<String>? roles,
    bool? isAnonymous, // Added to copyWith
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      roles: roles ?? this.roles,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserEntity &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.avatar == avatar &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isEmailVerified == isEmailVerified &&
        other.isAnonymous == isAnonymous && // Added to equality check
        other.roles == roles;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        avatar.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        isEmailVerified.hashCode ^
        isAnonymous.hashCode ^ // Added to hashCode
        roles.hashCode;
  }

  @override
  String toString() {
    return 'UserEntity(id: $id, name: $name, email: $email, phone: $phone, avatar: $avatar, createdAt: $createdAt, updatedAt: $updatedAt, isEmailVerified: $isEmailVerified, isAnonymous: $isAnonymous, roles: $roles)';
  }
}
