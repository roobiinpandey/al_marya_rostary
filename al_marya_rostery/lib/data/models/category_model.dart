/// Category Model for Coffee Categories
/// Represents a product category with bilingual support
class CategoryModel {
  final String id;
  final Map<String, String> name; // {en: "", ar: ""}
  final Map<String, String> description; // {en: "", ar: ""}
  final String? parentId;
  final String color;
  final bool isActive;
  final int displayOrder;
  final String fullSlug;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    this.parentId,
    required this.color,
    required this.isActive,
    required this.displayOrder,
    required this.fullSlug,
    this.createdAt,
    this.updatedAt,
  });

  /// Create CategoryModel from JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: {
        'en': (json['name']?['en'] ?? json['nameEn'] ?? '') as String,
        'ar': (json['name']?['ar'] ?? json['nameAr'] ?? '') as String,
      },
      description: {
        'en':
            (json['description']?['en'] ?? json['descriptionEn'] ?? '')
                as String,
        'ar':
            (json['description']?['ar'] ?? json['descriptionAr'] ?? '')
                as String,
      },
      parentId: json['parentId'] as String?,
      color: json['color'] as String? ?? '#8B4513',
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: json['displayOrder'] as int? ?? 0,
      fullSlug: json['fullSlug'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convert CategoryModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      if (parentId != null) 'parentId': parentId,
      'color': color,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'fullSlug': fullSlug,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Get localized name based on current language
  /// Defaults to English if language not found
  String getLocalizedName(String languageCode) {
    return name[languageCode] ?? name['en'] ?? '';
  }

  /// Get localized description based on current language
  /// Defaults to English if language not found
  String getLocalizedDescription(String languageCode) {
    return description[languageCode] ?? description['en'] ?? '';
  }

  /// Create a copy of CategoryModel with updated fields
  CategoryModel copyWith({
    String? id,
    Map<String, String>? name,
    Map<String, String>? description,
    String? parentId,
    String? color,
    bool? isActive,
    int? displayOrder,
    String? fullSlug,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      fullSlug: fullSlug ?? this.fullSlug,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: ${name['en']}, isActive: $isActive, displayOrder: $displayOrder)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
