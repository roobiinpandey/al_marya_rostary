class Accessory {
  final String id;
  final BilingualText name;
  final BilingualText description;
  final String type;
  final String category;
  final String? subCategory;
  final String? brand;
  final String? model;
  final String? sku;
  final AccessoryPrice price;
  final AccessorySpecifications? specifications;
  final BilingualText? usageInstructions;
  final BilingualText? careInstructions;
  final List<String> compatibility;
  final List<AccessoryImage> images;
  final String color;
  final AccessoryStock stock;
  final bool isActive;
  final bool isFeatured;
  final int displayOrder;
  final List<String> tags;
  final AccessoryAnalytics analytics;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Accessory({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    this.subCategory,
    this.brand,
    this.model,
    this.sku,
    required this.price,
    this.specifications,
    this.usageInstructions,
    this.careInstructions,
    required this.compatibility,
    required this.images,
    required this.color,
    required this.stock,
    required this.isActive,
    required this.isFeatured,
    required this.displayOrder,
    required this.tags,
    required this.analytics,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Accessory.fromJson(Map<String, dynamic> json) {
    return Accessory(
      id: json['_id'] ?? '',
      name: BilingualText.fromJson(json['name'] ?? {}),
      description: BilingualText.fromJson(json['description'] ?? {}),
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['subCategory'],
      brand: json['brand'],
      model: json['model'],
      sku: json['sku'],
      price: AccessoryPrice.fromJson(json['price'] ?? {}),
      specifications: json['specifications'] != null
          ? AccessorySpecifications.fromJson(json['specifications'])
          : null,
      usageInstructions: json['usageInstructions'] != null
          ? BilingualText.fromJson(json['usageInstructions'])
          : null,
      careInstructions: json['careInstructions'] != null
          ? BilingualText.fromJson(json['careInstructions'])
          : null,
      compatibility:
          (json['compatibility'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => AccessoryImage.fromJson(e))
              .toList() ??
          [],
      color: json['color'] ?? '#A89A6A',
      stock: AccessoryStock.fromJson(json['stock'] ?? {}),
      isActive: json['isActive'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      analytics: AccessoryAnalytics.fromJson(json['analytics'] ?? {}),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  String get primaryImageUrl {
    if (images.isEmpty) return '';
    final primaryImage = images.firstWhere(
      (img) => img.isPrimary,
      orElse: () => images.first,
    );
    return primaryImage.url;
  }

  String get formattedPrice {
    if (price.sale != null && price.sale! < price.regular) {
      return '${price.sale} ${price.currency}';
    }
    return '${price.regular} ${price.currency}';
  }

  int? get discountPercentage {
    if (price.sale != null && price.sale! < price.regular) {
      return (((price.regular - price.sale!) / price.regular) * 100).round();
    }
    return null;
  }

  String get stockStatus {
    if (!stock.isInStock || stock.quantity == 0) {
      return 'Out of Stock';
    } else if (stock.quantity <= stock.lowStockThreshold) {
      return 'Low Stock';
    }
    return 'In Stock';
  }
}

class BilingualText {
  final String en;
  final String ar;

  const BilingualText({required this.en, required this.ar});

  factory BilingualText.fromJson(Map<String, dynamic> json) {
    return BilingualText(en: json['en'] ?? '', ar: json['ar'] ?? '');
  }
}

class AccessoryPrice {
  final double regular;
  final double? sale;
  final String currency;

  const AccessoryPrice({
    required this.regular,
    this.sale,
    required this.currency,
  });

  factory AccessoryPrice.fromJson(Map<String, dynamic> json) {
    return AccessoryPrice(
      regular: (json['regular'] as num?)?.toDouble() ?? 0.0,
      sale: (json['sale'] as num?)?.toDouble(),
      currency: json['currency'] ?? 'AED',
    );
  }
}

class AccessorySpecifications {
  final List<String> material;
  final AccessoryDimensions? dimensions;
  final AccessoryCapacity? capacity;
  final List<AccessoryFeature> features;

  const AccessorySpecifications({
    required this.material,
    this.dimensions,
    this.capacity,
    required this.features,
  });

  factory AccessorySpecifications.fromJson(Map<String, dynamic> json) {
    return AccessorySpecifications(
      material:
          (json['material'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dimensions: json['dimensions'] != null
          ? AccessoryDimensions.fromJson(json['dimensions'])
          : null,
      capacity: json['capacity'] != null
          ? AccessoryCapacity.fromJson(json['capacity'])
          : null,
      features:
          (json['features'] as List<dynamic>?)
              ?.map((e) => AccessoryFeature.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AccessoryDimensions {
  final double? length;
  final double? width;
  final double? height;
  final double? weight;
  final String unit;

  const AccessoryDimensions({
    this.length,
    this.width,
    this.height,
    this.weight,
    required this.unit,
  });

  factory AccessoryDimensions.fromJson(Map<String, dynamic> json) {
    return AccessoryDimensions(
      length: (json['length'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      unit: json['unit'] ?? 'cm',
    );
  }
}

class AccessoryCapacity {
  final double? value;
  final String unit;

  const AccessoryCapacity({this.value, required this.unit});

  factory AccessoryCapacity.fromJson(Map<String, dynamic> json) {
    return AccessoryCapacity(
      value: (json['value'] as num?)?.toDouble(),
      unit: json['unit'] ?? 'ml',
    );
  }
}

class AccessoryFeature {
  final BilingualText name;
  final BilingualText description;

  const AccessoryFeature({required this.name, required this.description});

  factory AccessoryFeature.fromJson(Map<String, dynamic> json) {
    return AccessoryFeature(
      name: BilingualText.fromJson(json['name'] ?? {}),
      description: BilingualText.fromJson(json['description'] ?? {}),
    );
  }
}

class AccessoryImage {
  final String url;
  final BilingualText? alt;
  final bool isPrimary;

  const AccessoryImage({required this.url, this.alt, required this.isPrimary});

  factory AccessoryImage.fromJson(Map<String, dynamic> json) {
    return AccessoryImage(
      url: json['url'] ?? '',
      alt: json['alt'] != null ? BilingualText.fromJson(json['alt']) : null,
      isPrimary: json['isPrimary'] ?? false,
    );
  }
}

class AccessoryStock {
  final int quantity;
  final int lowStockThreshold;
  final bool isInStock;

  const AccessoryStock({
    required this.quantity,
    required this.lowStockThreshold,
    required this.isInStock,
  });

  factory AccessoryStock.fromJson(Map<String, dynamic> json) {
    return AccessoryStock(
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 5,
      isInStock: json['isInStock'] ?? false,
    );
  }
}

class AccessoryAnalytics {
  final int viewCount;
  final int purchaseCount;
  final double avgRating;
  final int totalRatings;

  const AccessoryAnalytics({
    required this.viewCount,
    required this.purchaseCount,
    required this.avgRating,
    required this.totalRatings,
  });

  factory AccessoryAnalytics.fromJson(Map<String, dynamic> json) {
    return AccessoryAnalytics(
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      purchaseCount: (json['purchaseCount'] as num?)?.toInt() ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (json['totalRatings'] as num?)?.toInt() ?? 0,
    );
  }
}
