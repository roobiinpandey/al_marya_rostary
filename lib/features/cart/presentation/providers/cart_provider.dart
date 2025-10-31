import 'package:flutter/material.dart';
import 'package:qahwat_al_emarat/data/models/coffee_product_model.dart';
import '../../../accessories/data/accessory_model.dart';

/// CartItemType to distinguish between different product types
enum CartItemType { coffee, accessory }

/// CartItem represents an item in the cart with quantity
class CartItem {
  final CoffeeProductModel? product; // For coffee products
  final Accessory? accessory; // For accessories
  final int quantity;
  final String? selectedSize;
  final double? price; // Custom price for size variants
  final CartItemType itemType;

  CartItem({
    this.product,
    this.accessory,
    this.quantity = 1,
    this.selectedSize,
    this.price,
    required this.itemType,
  }) : assert(
         (itemType == CartItemType.coffee && product != null) ||
             (itemType == CartItemType.accessory && accessory != null),
         'Product must match item type',
       );

  // Factory constructor for coffee products
  factory CartItem.coffee({
    required CoffeeProductModel product,
    int quantity = 1,
    String? selectedSize,
    double? price,
  }) {
    return CartItem(
      product: product,
      quantity: quantity,
      selectedSize: selectedSize,
      price: price,
      itemType: CartItemType.coffee,
    );
  }

  // Factory constructor for accessories
  factory CartItem.accessory({required Accessory accessory, int quantity = 1}) {
    return CartItem(
      accessory: accessory,
      quantity: quantity,
      price: accessory.price.sale ?? accessory.price.regular,
      itemType: CartItemType.accessory,
    );
  }

  CartItem copyWith({
    CoffeeProductModel? product,
    Accessory? accessory,
    int? quantity,
    String? selectedSize,
    double? price,
    CartItemType? itemType,
  }) {
    return CartItem(
      product: product ?? this.product,
      accessory: accessory ?? this.accessory,
      quantity: quantity ?? this.quantity,
      selectedSize: selectedSize ?? this.selectedSize,
      price: price ?? this.price,
      itemType: itemType ?? this.itemType,
    );
  }

  // Helper getters for common operations
  String get id {
    switch (itemType) {
      case CartItemType.coffee:
        return product!.id;
      case CartItemType.accessory:
        return accessory!.id;
    }
  }

  String get name {
    switch (itemType) {
      case CartItemType.coffee:
        return product!.name;
      case CartItemType.accessory:
        return accessory!.name.en;
    }
  }

  String get imageUrl {
    switch (itemType) {
      case CartItemType.coffee:
        return product!.imageUrl;
      case CartItemType.accessory:
        return accessory!.primaryImageUrl;
    }
  }

  double get unitPrice {
    if (price != null) return price!;
    switch (itemType) {
      case CartItemType.coffee:
        return product!.price;
      case CartItemType.accessory:
        return accessory!.price.sale ?? accessory!.price.regular;
    }
  }

  double get totalPrice => unitPrice * quantity;
}

/// CartProvider manages cart state
class CartProvider extends ChangeNotifier {
  // Guest info for checkout
  String? guestName;
  String? guestEmail;
  String? guestAddress;

  void setGuestInfo({
    required String name,
    required String email,
    required String address,
  }) {
    guestName = name;
    guestEmail = email;
    guestAddress = address;
    notifyListeners();
  }

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  void addItem(CoffeeProductModel product) {
    final existingIndex = _items.indexWhere(
      (item) =>
          item.itemType == CartItemType.coffee &&
          item.product!.id == product.id,
    );
    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + 1,
      );
    } else {
      _items.add(CartItem.coffee(product: product));
    }
    notifyListeners();
  }

  void addItemWithSize(CartItem cartItem) {
    final existingIndex = _items.indexWhere(
      (item) =>
          item.itemType == cartItem.itemType &&
          item.id == cartItem.id &&
          item.selectedSize == cartItem.selectedSize,
    );
    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + cartItem.quantity,
      );
    } else {
      _items.add(cartItem);
    }
    notifyListeners();
  }

  // Add accessory to cart
  void addAccessory(Accessory accessory, {int quantity = 1}) {
    final existingIndex = _items.indexWhere(
      (item) =>
          item.itemType == CartItemType.accessory &&
          item.accessory!.id == accessory.id,
    );
    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + quantity,
      );
    } else {
      _items.add(CartItem.accessory(accessory: accessory, quantity: quantity));
    }
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void incrementQuantity(String itemId) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + 1,
      );
      notifyListeners();
    }
  }

  void decrementQuantity(String itemId) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index] = _items[index].copyWith(
          quantity: _items[index].quantity - 1,
        );
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
