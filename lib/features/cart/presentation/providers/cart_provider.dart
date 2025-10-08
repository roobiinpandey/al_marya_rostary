import 'package:flutter/material.dart';
import 'package:qahwat_al_emarat/data/models/coffee_product_model.dart';

/// CartItem represents an item in the cart with quantity
class CartItem {
  final CoffeeProductModel product;
  final int quantity;
  final String? selectedSize;
  final double? price; // Custom price for size variants

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedSize,
    this.price,
  });

  CartItem copyWith({
    CoffeeProductModel? product,
    int? quantity,
    String? selectedSize,
    double? price,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedSize: selectedSize ?? this.selectedSize,
      price: price ?? this.price,
    );
  }

  double get totalPrice => (price ?? product.price) * quantity;
}

/// CartProvider manages cart state
class CartProvider extends ChangeNotifier {
  // Guest info for checkout
  String? guestName;
  String? guestEmail;
  String? guestAddress;

  void setGuestInfo(
      {required String name, required String email, required String address}) {
    guestName = name;
    guestEmail = email;
    guestAddress = address;
    notifyListeners();
  }

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  void addItem(CoffeeProductModel product) {
    final existingIndex =
        _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + 1,
      );
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void addItemWithSize(CartItem cartItem) {
    final existingIndex = _items.indexWhere(
      (item) =>
          item.product.id == cartItem.product.id &&
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

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void incrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + 1,
      );
      notifyListeners();
    }
  }

  void decrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
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
