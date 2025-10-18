/// Firebase User Model for Admin Panel
class FirebaseUserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoUrl;
  final bool emailVerified;
  final bool disabled;
  final String creationTime;
  final String lastSignInTime;
  final Map<String, dynamic>? customClaims;

  FirebaseUserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.photoUrl,
    required this.emailVerified,
    required this.disabled,
    required this.creationTime,
    required this.lastSignInTime,
    this.customClaims,
  });

  factory FirebaseUserModel.fromJson(Map<String, dynamic> json) {
    return FirebaseUserModel(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      photoUrl: json['photoURL'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      disabled: json['disabled'] as bool? ?? false,
      creationTime: json['metadata']?['creationTime'] as String? ?? '',
      lastSignInTime: json['metadata']?['lastSignInTime'] as String? ?? '',
      customClaims: json['customClaims'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoUrl,
      'emailVerified': emailVerified,
      'disabled': disabled,
      'metadata': {
        'creationTime': creationTime,
        'lastSignInTime': lastSignInTime,
      },
      'customClaims': customClaims,
    };
  }

  // Helper getters
  bool get isAdmin => customClaims?['admin'] == true;
  bool get isActive => !disabled;
  String get role => customClaims?['role'] as String? ?? 'user';
}
