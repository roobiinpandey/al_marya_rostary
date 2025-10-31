/// Quick Category Model
/// Represents a quick category displayed below the banner on homepage
class QuickCategoryModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String color;
  final int displayOrder;
  final bool isActive;
  final int clickCount;
  final int viewCount;
  final String linkTo; // category, product, external, none
  final String linkValue;
  final String description;
  final List<String> tags;
  final String? altText;
  final DateTime? lastClicked;
  final int totalInteractions;
  final double conversionRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuickCategoryModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.color,
    this.displayOrder = 0,
    this.isActive = true,
    this.clickCount = 0,
    this.viewCount = 0,
    this.linkTo = 'none',
    this.linkValue = '',
    this.description = '',
    this.tags = const [],
    this.altText,
    this.lastClicked,
    this.totalInteractions = 0,
    this.conversionRate = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create QuickCategoryModel from JSON
  factory QuickCategoryModel.fromJson(Map<String, dynamic> json) {
    return QuickCategoryModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      color: json['color']?.toString() ?? '#A89A6A',
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      clickCount: json['clickCount'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
      linkTo: json['linkTo']?.toString() ?? 'none',
      linkValue: json['linkValue']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      altText: json['seo'] != null
          ? (json['seo'] as Map<String, dynamic>)['altText']?.toString()
          : json['altText']?.toString(),
      lastClicked: json['analytics'] != null
          ? (json['analytics'] as Map<String, dynamic>)['lastClicked'] != null
                ? DateTime.tryParse(
                    (json['analytics'] as Map<String, dynamic>)['lastClicked']
                        .toString(),
                  )
                : null
          : null,
      totalInteractions: json['analytics'] != null
          ? (json['analytics'] as Map<String, dynamic>)['totalInteractions']
                    as int? ??
                0
          : 0,
      conversionRate: json['analytics'] != null
          ? ((json['analytics'] as Map<String, dynamic>)['conversionRate']
                        as num?)
                    ?.toDouble() ??
                0.0
          : 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Convert QuickCategoryModel to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'color': color,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'clickCount': clickCount,
      'viewCount': viewCount,
      'linkTo': linkTo,
      'linkValue': linkValue,
      'description': description,
      'tags': tags,
      'seo': altText != null ? {'altText': altText} : null,
      'analytics': {
        'lastClicked': lastClicked?.toIso8601String(),
        'totalInteractions': totalInteractions,
        'conversionRate': conversionRate,
      },
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  QuickCategoryModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? color,
    int? displayOrder,
    bool? isActive,
    int? clickCount,
    int? viewCount,
    String? linkTo,
    String? linkValue,
    String? description,
    List<String>? tags,
    String? altText,
    DateTime? lastClicked,
    int? totalInteractions,
    double? conversionRate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuickCategoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      color: color ?? this.color,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      clickCount: clickCount ?? this.clickCount,
      viewCount: viewCount ?? this.viewCount,
      linkTo: linkTo ?? this.linkTo,
      linkValue: linkValue ?? this.linkValue,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      altText: altText ?? this.altText,
      lastClicked: lastClicked ?? this.lastClicked,
      totalInteractions: totalInteractions ?? this.totalInteractions,
      conversionRate: conversionRate ?? this.conversionRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get click-through rate as percentage
  double get clickThroughRate {
    if (viewCount == 0) return 0.0;
    return (clickCount / viewCount) * 100;
  }

  /// Get status string
  String get status {
    return isActive ? 'Active' : 'Inactive';
  }

  /// Check if the category is visible (active)
  bool get isVisible {
    return isActive;
  }

  /// Get formatted creation date
  String get formattedCreatedAt {
    return createdAt.toLocal().toString().split(' ')[0]; // YYYY-MM-DD
  }

  /// Get formatted last clicked date
  String? get formattedLastClicked {
    return lastClicked?.toLocal().toString().split(' ')[0]; // YYYY-MM-DD
  }

  /// Get safe image URL (handles both relative and absolute URLs)
  String get safeImageUrl {
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    } else if (imageUrl.startsWith('/')) {
      // Relative URL from backend
      return imageUrl;
    } else {
      // Fallback or direct filename
      return '/uploads/$imageUrl';
    }
  }

  /// Check if this category has a valid link
  bool get hasValidLink {
    return linkTo != 'none' && linkValue.isNotEmpty;
  }

  /// Get display-friendly link description
  String get linkDescription {
    switch (linkTo) {
      case 'category':
        return 'Category: $linkValue';
      case 'product':
        return 'Product: $linkValue';
      case 'external':
        return 'External: $linkValue';
      case 'none':
      default:
        return 'No link';
    }
  }

  @override
  String toString() {
    return 'QuickCategoryModel(id: $id, title: $title, subtitle: $subtitle, color: $color, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuickCategoryModel && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
