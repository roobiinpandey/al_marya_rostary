class GiftSetModel {
  final String id;
  final Map<String, String> name;
  final Map<String, String> description;
  final String occasion;
  final String targetAudience;
  final GiftSetPrice price;
  final List<GiftSetContent> contents;
  final GiftSetPackaging packaging;
  final GiftSetAvailability availability;
  final bool isActive;
  final bool isFeatured;
  final bool isPopular;
  final int displayOrder;
  final List<String> tags;
  final GiftSetMarketing? marketingMessages;
  final GiftSetAnalytics analytics;
  final List<GiftSetReview> reviews;
  final List<GiftSetImage> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Virtual properties
  final String formattedPrice;
  final int discountPercentage;
  final String availabilityStatus;
  final int totalItems;

  const GiftSetModel({
    required this.id,
    required this.name,
    required this.description,
    required this.occasion,
    required this.targetAudience,
    required this.price,
    required this.contents,
    required this.packaging,
    required this.availability,
    required this.isActive,
    required this.isFeatured,
    required this.isPopular,
    required this.displayOrder,
    required this.tags,
    this.marketingMessages,
    required this.analytics,
    required this.reviews,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    required this.formattedPrice,
    required this.discountPercentage,
    required this.availabilityStatus,
    required this.totalItems,
  });

  // Convenience getters for localized content
  String get localizedName => name['en'] ?? '';
  String get localizedDescription => description['en'] ?? '';

  factory GiftSetModel.fromJson(Map<String, dynamic> json) {
    return GiftSetModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: Map<String, String>.from(json['name'] ?? {}),
      description: Map<String, String>.from(json['description'] ?? {}),
      occasion: json['occasion'] ?? '',
      targetAudience: json['targetAudience'] ?? '',
      price: GiftSetPrice.fromJson(json['price'] ?? {}),
      contents: (json['contents'] as List<dynamic>? ?? [])
          .map((content) => GiftSetContent.fromJson(content))
          .toList(),
      packaging: GiftSetPackaging.fromJson(json['packaging'] ?? {}),
      availability: GiftSetAvailability.fromJson(json['availability'] ?? {}),
      isActive: json['isActive'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      isPopular: json['isPopular'] ?? false,
      displayOrder: json['displayOrder'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      marketingMessages: json['marketingMessages'] != null
          ? GiftSetMarketing.fromJson(json['marketingMessages'])
          : null,
      analytics: GiftSetAnalytics.fromJson(json['analytics'] ?? {}),
      reviews: (json['reviews'] as List<dynamic>? ?? [])
          .map((review) => GiftSetReview.fromJson(review))
          .toList(),
      images: (json['images'] as List<dynamic>? ?? [])
          .map((image) => GiftSetImage.fromJson(image))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      formattedPrice: json['formattedPrice'] ?? '',
      discountPercentage: json['discountPercentage'] ?? 0,
      availabilityStatus: json['availabilityStatus'] ?? 'Available',
      totalItems: json['totalItems'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'occasion': occasion,
      'targetAudience': targetAudience,
      'price': price.toJson(),
      'contents': contents.map((content) => content.toJson()).toList(),
      'packaging': packaging.toJson(),
      'availability': availability.toJson(),
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isPopular': isPopular,
      'displayOrder': displayOrder,
      'tags': tags,
      'marketingMessages': marketingMessages?.toJson(),
      'analytics': analytics.toJson(),
      'reviews': reviews.map((review) => review.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  GiftSetModel copyWith({
    String? id,
    Map<String, String>? name,
    Map<String, String>? description,
    String? occasion,
    String? targetAudience,
    GiftSetPrice? price,
    List<GiftSetContent>? contents,
    GiftSetPackaging? packaging,
    GiftSetAvailability? availability,
    bool? isActive,
    bool? isFeatured,
    bool? isPopular,
    int? displayOrder,
    List<String>? tags,
    GiftSetMarketing? marketingMessages,
    GiftSetAnalytics? analytics,
    List<GiftSetReview>? reviews,
    List<GiftSetImage>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GiftSetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      occasion: occasion ?? this.occasion,
      targetAudience: targetAudience ?? this.targetAudience,
      price: price ?? this.price,
      contents: contents ?? this.contents,
      packaging: packaging ?? this.packaging,
      availability: availability ?? this.availability,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isPopular: isPopular ?? this.isPopular,
      displayOrder: displayOrder ?? this.displayOrder,
      tags: tags ?? this.tags,
      marketingMessages: marketingMessages ?? this.marketingMessages,
      analytics: analytics ?? this.analytics,
      reviews: reviews ?? this.reviews,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      formattedPrice: formattedPrice,
      discountPercentage: discountPercentage,
      availabilityStatus: availabilityStatus,
      totalItems: totalItems,
    );
  }

  /// Get the primary image URL, or first image if no primary is set
  String get primaryImageUrl {
    if (images.isEmpty) return '';

    // Try to find primary image first
    final primaryImage = images.where((img) => img.isPrimary).firstOrNull;
    if (primaryImage != null) return primaryImage.url;

    // Fall back to first image
    return images.first.url;
  }

  /// Get all image URLs
  List<String> get imageUrls {
    return images.map((img) => img.url).toList();
  }
}

class GiftSetPrice {
  final double regular;
  final double? sale;
  final String currency;

  const GiftSetPrice({
    required this.regular,
    this.sale,
    required this.currency,
  });

  factory GiftSetPrice.fromJson(Map<String, dynamic> json) {
    return GiftSetPrice(
      regular: (json['regular'] ?? 0).toDouble(),
      sale: json['sale']?.toDouble(),
      currency: json['currency'] ?? 'AED',
    );
  }

  Map<String, dynamic> toJson() {
    return {'regular': regular, 'sale': sale, 'currency': currency};
  }
}

class GiftSetContent {
  final GiftSetItem item;
  final int quantity;
  final bool isHighlight;

  const GiftSetContent({
    required this.item,
    required this.quantity,
    required this.isHighlight,
  });

  factory GiftSetContent.fromJson(Map<String, dynamic> json) {
    return GiftSetContent(
      item: GiftSetItem.fromJson(json['item'] ?? {}),
      quantity: json['quantity'] ?? 1,
      isHighlight: json['isHighlight'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item': item.toJson(),
      'quantity': quantity,
      'isHighlight': isHighlight,
    };
  }
}

class GiftSetItem {
  final String itemType;
  final String? itemId;
  final CustomItem? customItem;

  const GiftSetItem({required this.itemType, this.itemId, this.customItem});

  factory GiftSetItem.fromJson(Map<String, dynamic> json) {
    return GiftSetItem(
      itemType: json['itemType'] ?? '',
      itemId: json['itemId'],
      customItem: json['customItem'] != null
          ? CustomItem.fromJson(json['customItem'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemType': itemType,
      'itemId': itemId,
      'customItem': customItem?.toJson(),
    };
  }
}

class CustomItem {
  final Map<String, String> name;
  final Map<String, String> description;

  const CustomItem({required this.name, required this.description});

  String get localizedName => name['en'] ?? '';
  String get localizedDescription => description['en'] ?? '';

  factory CustomItem.fromJson(Map<String, dynamic> json) {
    return CustomItem(
      name: Map<String, String>.from(json['name'] ?? {}),
      description: Map<String, String>.from(json['description'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description};
  }
}

class GiftSetPackaging {
  final String type;
  final String? material;
  final String? color;

  const GiftSetPackaging({required this.type, this.material, this.color});

  factory GiftSetPackaging.fromJson(Map<String, dynamic> json) {
    return GiftSetPackaging(
      type: json['type'] ?? 'box',
      material: json['material'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'material': material, 'color': color};
  }
}

class GiftSetAvailability {
  final bool isAvailable;

  const GiftSetAvailability({required this.isAvailable});

  factory GiftSetAvailability.fromJson(Map<String, dynamic> json) {
    return GiftSetAvailability(isAvailable: json['isAvailable'] ?? true);
  }

  Map<String, dynamic> toJson() {
    return {'isAvailable': isAvailable};
  }
}

class GiftSetMarketing {
  final Map<String, String>? shortDescription;
  final List<Map<String, String>>? highlights;

  const GiftSetMarketing({this.shortDescription, this.highlights});

  factory GiftSetMarketing.fromJson(Map<String, dynamic> json) {
    return GiftSetMarketing(
      shortDescription: json['shortDescription'] != null
          ? Map<String, String>.from(json['shortDescription'])
          : null,
      highlights: json['highlights'] != null
          ? (json['highlights'] as List)
                .map((h) => Map<String, String>.from(h))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'shortDescription': shortDescription, 'highlights': highlights};
  }
}

class GiftSetAnalytics {
  final int viewCount;
  final int purchaseCount;
  final double avgRating;
  final int totalRatings;
  final double conversionRate;

  const GiftSetAnalytics({
    required this.viewCount,
    required this.purchaseCount,
    required this.avgRating,
    required this.totalRatings,
    required this.conversionRate,
  });

  factory GiftSetAnalytics.fromJson(Map<String, dynamic> json) {
    return GiftSetAnalytics(
      viewCount: json['viewCount'] ?? 0,
      purchaseCount: json['purchaseCount'] ?? 0,
      avgRating: (json['avgRating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      conversionRate: (json['conversionRate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'viewCount': viewCount,
      'purchaseCount': purchaseCount,
      'avgRating': avgRating,
      'totalRatings': totalRatings,
      'conversionRate': conversionRate,
    };
  }
}

class GiftSetReview {
  final String userId;
  final int rating;
  final String? comment;
  final String? occasion;
  final String? recipientType;
  final bool wouldRecommend;
  final DateTime createdAt;

  const GiftSetReview({
    required this.userId,
    required this.rating,
    this.comment,
    this.occasion,
    this.recipientType,
    required this.wouldRecommend,
    required this.createdAt,
  });

  factory GiftSetReview.fromJson(Map<String, dynamic> json) {
    return GiftSetReview(
      userId: json['userId'] ?? '',
      rating: json['rating'] ?? 5,
      comment: json['comment'],
      occasion: json['occasion'],
      recipientType: json['recipientType'],
      wouldRecommend: json['wouldRecommend'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'occasion': occasion,
      'recipientType': recipientType,
      'wouldRecommend': wouldRecommend,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class GiftSetImage {
  final String url;
  final Map<String, String> alt;
  final bool isPrimary;
  final bool showsContents;

  const GiftSetImage({
    required this.url,
    required this.alt,
    required this.isPrimary,
    required this.showsContents,
  });

  factory GiftSetImage.fromJson(Map<String, dynamic> json) {
    return GiftSetImage(
      url: json['url'] ?? '',
      alt: Map<String, String>.from(json['alt'] ?? {'en': '', 'ar': ''}),
      isPrimary: json['isPrimary'] ?? false,
      showsContents: json['showsContents'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'alt': alt,
      'isPrimary': isPrimary,
      'showsContents': showsContents,
    };
  }
}
