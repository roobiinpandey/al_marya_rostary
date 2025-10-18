class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime? createdAt;
  final DateTime? lastSignInTime;
  final Map<String, dynamic>? preferences;
  final bool isAnonymous; // Flag for guest users

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    this.createdAt,
    this.lastSignInTime,
    this.preferences,
    this.isAnonymous = false, // Default to false for regular users
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
      isAnonymous: json['isAnonymous'] ?? false, // Get guest flag from JSON
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
      'isAnonymous': isAnonymous, // Include guest flag in JSON
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
    bool? isAnonymous,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastSignInTime: lastSignInTime ?? this.lastSignInTime,
      preferences: preferences ?? this.preferences,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
}
