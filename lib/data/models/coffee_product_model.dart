import '../../core/constants/app_constants.dart';
import '../../domain/entities/coffee_product.dart';

/// Variant model for different coffee sizes and prices
class CoffeeVariant {
  final String size;
  final double price;
  final int stock;

  const CoffeeVariant({
    required this.size,
    required this.price,
    required this.stock,
  });

  factory CoffeeVariant.fromJson(Map<String, dynamic> json) {
    return CoffeeVariant(
      size: json['size'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'size': size, 'price': price, 'stock': stock};
  }
}

/// Data model for CoffeeProduct, used for serialization/deserialization
class CoffeeProductModel extends CoffeeProduct {
  final List<CoffeeVariant> variants;
  final List<String> categories;
  final bool isActive;
  final bool isFeatured;
  final double rating;
  final int reviewCount;

  const CoffeeProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.imageUrl,
    required super.origin,
    required super.roastLevel,
    required super.stock,
    this.variants = const [],
    this.categories = const [],
    this.isActive = true,
    this.isFeatured = false,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  factory CoffeeProductModel.fromJson(Map<String, dynamic> json) {
    // Parse variants if they exist
    List<CoffeeVariant> variants = [];
    if (json['variants'] != null && json['variants'] is List) {
      variants = (json['variants'] as List)
          .map((variant) => CoffeeVariant.fromJson(variant))
          .toList();
    }

    // Parse categories if they exist
    List<String> categories = [];
    if (json['categories'] != null && json['categories'] is List) {
      categories = (json['categories'] as List)
          .map((category) => category.toString())
          .toList();
    }

    // Handle image URL - it might come with or without the base URL
    String imageUrl = json['image'] ?? json['imageUrl'] ?? '';
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      // If it's a relative path, we'll need to prepend the base URL
      if (imageUrl.startsWith('/uploads/')) {
        // Use AppConstants to get the correct base URL for current environment
        imageUrl = '${AppConstants.baseUrl}$imageUrl';
      }
    }

    // Handle bilingual name - prefer localized version if available
    String name = '';
    if (json['name'] is Map) {
      final nameMap = json['name'] as Map<String, dynamic>;
      name = nameMap['en'] ?? nameMap['ar'] ?? '';
    } else if (json['localizedName'] is String) {
      name = json['localizedName'];
    } else if (json['name'] is String) {
      name = json['name'];
    }

    // Handle bilingual description - prefer localized version if available
    String description = '';
    if (json['description'] is Map) {
      final descMap = json['description'] as Map<String, dynamic>;
      description = descMap['en'] ?? descMap['ar'] ?? '';
    } else if (json['localizedDescription'] is String) {
      description = json['localizedDescription'];
    } else if (json['description'] is String) {
      description = json['description'];
    }

    return CoffeeProductModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: name,
      description: description,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: imageUrl,
      origin: json['origin'] ?? 'Unknown',
      roastLevel: json['roastLevel'] ?? 'Medium',
      stock: json['stock'] as int? ?? 0,
      variants: variants,
      categories: categories,
      isActive: json['isActive'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'origin': origin,
      'roastLevel': roastLevel,
      'stock': stock,
      'variants': variants.map((v) => v.toJson()).toList(),
      'categories': categories,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  /// Convert to domain entity
  CoffeeProduct toEntity() {
    return CoffeeProduct(
      id: id,
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
      origin: origin,
      roastLevel: roastLevel,
      stock: stock,
    );
  }

  /// Get the minimum price from variants or return the base price
  double get minPrice {
    if (variants.isEmpty) return price;
    return variants
        .map((v) => v.price)
        .reduce((min, price) => price < min ? price : min);
  }

  /// Get the maximum price from variants or return the base price
  double get maxPrice {
    if (variants.isEmpty) return price;
    return variants
        .map((v) => v.price)
        .reduce((max, price) => price > max ? price : max);
  }

  /// Check if the product has multiple price variants
  bool get hasVariants => variants.isNotEmpty;

  /// Get price range text for display (for compatibility with existing code)
  String get priceRangeText {
    if (!hasVariants) return '${price.toStringAsFixed(0)} AED';

    final min = minPrice;
    final max = maxPrice;

    if (min == max) {
      return '${min.toStringAsFixed(0)} AED';
    } else {
      return '${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)} AED';
    }
  }

  /// Get per kg price display for home page
  String get pricePerKgDisplay {
    return '${price.toStringAsFixed(0)} AED/kg';
  }
}
