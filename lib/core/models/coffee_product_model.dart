/// CoffeeProductModel represents a coffee product in the app
class CoffeeProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final List<String> ingredients;
  final String origin;
  final String roastLevel;

  const CoffeeProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.isAvailable,
    required this.ingredients,
    required this.origin,
    required this.roastLevel,
  });

  /// Creates a CoffeeProductModel from JSON data
  factory CoffeeProductModel.fromJson(Map<String, dynamic> json) {
    return CoffeeProductModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] as String? ?? '',
      category: json['category'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      origin: json['origin'] as String? ?? '',
      roastLevel: json['roastLevel'] as String? ?? '',
    );
  }

  /// Converts the model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'rating': rating,
      'reviewCount': reviewCount,
      'isAvailable': isAvailable,
      'ingredients': ingredients,
      'origin': origin,
      'roastLevel': roastLevel,
    };
  }

  /// Creates a copy of the model with updated fields
  CoffeeProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    double? rating,
    int? reviewCount,
    bool? isAvailable,
    List<String>? ingredients,
    String? origin,
    String? roastLevel,
  }) {
    return CoffeeProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isAvailable: isAvailable ?? this.isAvailable,
      ingredients: ingredients ?? this.ingredients,
      origin: origin ?? this.origin,
      roastLevel: roastLevel ?? this.roastLevel,
    );
  }

  @override
  String toString() {
    return 'CoffeeProductModel(id: $id, name: $name, price: $price, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CoffeeProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
