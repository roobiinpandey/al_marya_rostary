/// Slider Model
/// Represents a banner/slider for the homepage
class SliderModel {
  final String id;
  final String title;
  final String? description;
  final String image;
  final String? mobileImage;
  final String? buttonText;
  final String? buttonLink;
  final String? actionType; // none, category, products, url, offers
  final String? actionValue; // category ID, URL, etc.
  final String backgroundColor;
  final String textColor;
  final String position; // left, center, right
  final int displayOrder;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int clickCount;
  final int viewCount;
  final List<String> targetAudience;
  final List<String> categories;
  final List<String> tags;
  final String? altText;
  final DateTime createdAt;
  final DateTime updatedAt;

  SliderModel({
    required this.id,
    required this.title,
    this.description,
    required this.image,
    this.mobileImage,
    this.buttonText,
    this.buttonLink,
    this.actionType,
    this.actionValue,
    this.backgroundColor = '#A89A6A',
    this.textColor = '#FFFFFF',
    this.position = 'center',
    this.displayOrder = 0,
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.clickCount = 0,
    this.viewCount = 0,
    this.targetAudience = const [],
    this.categories = const [],
    this.tags = const [],
    this.altText,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create SliderModel from JSON
  factory SliderModel.fromJson(Map<String, dynamic> json) {
    return SliderModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      image: json['image']?.toString() ?? '',
      mobileImage: json['mobileImage']?.toString(),
      buttonText: json['buttonText']?.toString(),
      buttonLink: json['buttonLink']?.toString(),
      actionType: json['actionType']?.toString(),
      actionValue: json['actionValue']?.toString(),
      backgroundColor: json['backgroundColor']?.toString() ?? '#A89A6A',
      textColor: json['textColor']?.toString() ?? '#FFFFFF',
      position: json['position']?.toString() ?? 'center',
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      clickCount: json['clickCount'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
      targetAudience:
          (json['targetAudience'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      altText: json['seo'] != null
          ? (json['seo'] as Map<String, dynamic>)['altText']?.toString()
          : json['altText']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Convert SliderModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      'image': image,
      if (mobileImage != null) 'mobileImage': mobileImage,
      if (buttonText != null) 'buttonText': buttonText,
      if (buttonLink != null) 'buttonLink': buttonLink,
      if (actionType != null) 'actionType': actionType,
      if (actionValue != null) 'actionValue': actionValue,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'position': position,
      'displayOrder': displayOrder,
      'isActive': isActive,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      'clickCount': clickCount,
      'viewCount': viewCount,
      'targetAudience': targetAudience,
      'categories': categories,
      'tags': tags,
      if (altText != null) 'altText': altText,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get status of the slider
  String get status {
    final now = DateTime.now();
    if (!isActive) return 'Inactive';
    if (startDate != null && now.isBefore(startDate!)) return 'Scheduled';
    if (endDate != null && now.isAfter(endDate!)) return 'Expired';
    return 'Active';
  }

  /// Check if slider is currently visible
  bool get isVisible {
    final now = DateTime.now();
    if (!isActive) return false;
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  /// Get formatted start date
  String? get formattedStartDate {
    if (startDate == null) return null;
    return '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}';
  }

  /// Get formatted end date
  String? get formattedEndDate {
    if (endDate == null) return null;
    return '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}';
  }

  /// Get click-through rate (CTR)
  double get clickThroughRate {
    if (viewCount == 0) return 0.0;
    return (clickCount / viewCount) * 100;
  }

  /// Copy with method for immutable updates
  SliderModel copyWith({
    String? id,
    String? title,
    String? description,
    String? image,
    String? mobileImage,
    String? buttonText,
    String? buttonLink,
    String? backgroundColor,
    String? textColor,
    String? position,
    int? displayOrder,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    int? clickCount,
    int? viewCount,
    List<String>? targetAudience,
    List<String>? categories,
    List<String>? tags,
    String? altText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SliderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      mobileImage: mobileImage ?? this.mobileImage,
      buttonText: buttonText ?? this.buttonText,
      buttonLink: buttonLink ?? this.buttonLink,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      position: position ?? this.position,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      clickCount: clickCount ?? this.clickCount,
      viewCount: viewCount ?? this.viewCount,
      targetAudience: targetAudience ?? this.targetAudience,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      altText: altText ?? this.altText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SliderModel(id: $id, title: $title, status: $status, displayOrder: $displayOrder)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SliderModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
