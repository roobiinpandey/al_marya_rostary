class UpdateProfileRequest {
  final String? name;
  final String? phone;
  final String? avatar;

  UpdateProfileRequest({
    this.name,
    this.phone,
    this.avatar,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (avatar != null) 'avatar': avatar,
    };
  }
}
