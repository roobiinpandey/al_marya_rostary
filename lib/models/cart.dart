class CartItem {
  final String coffeeId;
  final String coffeeName;
  final String size;
  final double price;
  final int quantity;
  final String? imageUrl;

  const CartItem({
    required this.coffeeId,
    required this.coffeeName,
    required this.size,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      coffeeId: json['coffeeId'] ?? '',
      coffeeName: json['coffeeName'] ?? '',
      size: json['size'] ?? 'Medium',
      price: (json['price'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 1,
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coffeeId': coffeeId,
      'coffeeName': coffeeName,
      'size': size,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }

  double get total => price * quantity;

  CartItem copyWith({
    String? coffeeId,
    String? coffeeName,
    String? size,
    double? price,
    int? quantity,
    String? imageUrl,
  }) {
    return CartItem(
      coffeeId: coffeeId ?? this.coffeeId,
      coffeeName: coffeeName ?? this.coffeeName,
      size: size ?? this.size,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class Cart {
  final String userId;
  final List<CartItem> items;
  final DateTime? updatedAt;

  const Cart({required this.userId, required this.items, this.updatedAt});

  factory Cart.fromJson(Map<String, dynamic> json, String userId) {
    final itemsMap = json['items'] as Map<String, dynamic>? ?? {};
    final items = itemsMap.entries
        .map(
          (entry) => CartItem.fromJson(Map<String, dynamic>.from(entry.value)),
        )
        .toList();

    return Cart(
      userId: userId,
      items: items,
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final itemsMap = <String, Map<String, dynamic>>{};
    for (int i = 0; i < items.length; i++) {
      itemsMap[i.toString()] = items[i].toJson();
    }

    return {
      'items': itemsMap,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  double get total => items.fold(0.0, (sum, item) => sum + item.total);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}
