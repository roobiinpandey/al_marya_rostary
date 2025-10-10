class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime? createdAt;
  final DateTime? lastSignInTime;
  final Map<String, dynamic>? preferences;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    this.createdAt,
    this.lastSignInTime,
    this.preferences,
  });

  // Convert Realtime Database JSON to User object
  factory AppUser.fromJson(Map<String, dynamic> json, String id) {
    return AppUser(
      id: id,
      email: json['email'] ?? '',
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : null,
      lastSignInTime: json['lastSignInTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastSignInTime'])
          : null,
      preferences: json['preferences'] != null
          ? Map<String, dynamic>.from(json['preferences'])
          : null,
    );
  }

  // Convert User object to JSON for Realtime Database
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt':
          createdAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      'lastSignInTime':
          lastSignInTime?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      'preferences': preferences,
    };
  }

  // Create a copy with updated fields
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastSignInTime,
    Map<String, dynamic>? preferences,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastSignInTime: lastSignInTime ?? this.lastSignInTime,
      preferences: preferences ?? this.preferences,
    );
  }
}
