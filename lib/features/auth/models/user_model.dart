class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? avatar;
  final bool isEmailVerified;
  final List<String> roles;

  UserModel({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.avatar,
    this.isEmailVerified = false,
    this.roles = const [],
  });

  factory UserModel.fromFirebase(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'],
      email: data['email'],
      phone: data['phone'],
      avatar: data['avatar'],
      isEmailVerified: data['isEmailVerified'] ?? false,
      roles: List<String>.from(data['roles'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'isEmailVerified': isEmailVerified,
      'roles': roles,
    };
  }
}
