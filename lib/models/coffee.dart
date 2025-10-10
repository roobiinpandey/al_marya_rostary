class Coffee {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double rating;
  final List<String> sizes;
  final bool isPopular;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Coffee({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.rating = 4.5,
    this.sizes = const ['Small', 'Medium', 'Large'],
    this.isPopular = false,
    this.createdAt,
    this.updatedAt,
  });

  // Convert Realtime Database JSON to Coffee object
  factory Coffee.fromJson(Map<String, dynamic> json, String id) {
    return Coffee(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      rating: (json['rating'] ?? 4.5).toDouble(),
      sizes: json['sizes'] != null
          ? List<String>.from(json['sizes'])
          : ['Small', 'Medium', 'Large'],
      isPopular: json['isPopular'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : null,
    );
  }

  // Convert Coffee object to JSON for Realtime Database
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'rating': rating,
      'sizes': sizes,
      'isPopular': isPopular,
      'createdAt':
          createdAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Create a copy with updated fields
  Coffee copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    double? rating,
    List<String>? sizes,
    bool? isPopular,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Coffee(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      sizes: sizes ?? this.sizes,
      isPopular: isPopular ?? this.isPopular,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
