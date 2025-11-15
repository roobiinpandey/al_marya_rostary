import 'package:flutter/foundation.dart';
import '../../../../data/models/coffee_product_model.dart';
import '../../../../data/models/subscription_model.dart';
import '../../../../data/datasources/remote/subscriptions_api_service.dart';

/// Selected product with size/quantity information
class SelectedProduct {
  final String
  uniqueId; // Unique ID for this selection (productId_size_timestamp)
  final CoffeeProductModel product;
  final String size; // e.g., "250gm", "500gm", "1kg"
  final int quantity; // Number of bags/units

  SelectedProduct({
    required this.uniqueId,
    required this.product,
    required this.size,
    this.quantity = 1,
  });

  /// Get price based on selected variant size
  double get unitPrice {
    if (!product.hasVariants) return product.price;

    // Find the variant matching the selected size
    final variant = product.variants.firstWhere(
      (v) => v.size == size,
      orElse: () => product.variants.first,
    );
    return variant.price;
  }

  /// Get total price (unit price * quantity)
  double get totalPrice => unitPrice * quantity;

  String get productId => product.id;
  String get name => product.name;
  String get imageUrl => product.imageUrl;

  /// Create a copy with updated values
  SelectedProduct copyWith({
    String? uniqueId,
    CoffeeProductModel? product,
    String? size,
    int? quantity,
  }) {
    return SelectedProduct(
      uniqueId: uniqueId ?? this.uniqueId,
      product: product ?? this.product,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Provider for managing custom coffee subscription builder state
class CustomSubscriptionProvider with ChangeNotifier {
  final SubscriptionsApiService _subscriptionsApi = SubscriptionsApiService();

  // Selected plan
  SubscriptionPlanModel? _selectedPlan;

  // Selected products (uniqueId -> SelectedProduct)
  final Map<String, SelectedProduct> _selectedProducts = {};

  // Subscription duration in months
  int _durationMonths = 1;

  // Loading and error states
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSubmitting = false;

  // Getters
  SubscriptionPlanModel? get selectedPlan => _selectedPlan;
  List<SelectedProduct> get selectedProducts =>
      _selectedProducts.values.toList();
  int get selectedProductsCount => _selectedProducts.length;
  int get durationMonths => _durationMonths;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;
  bool get hasSelectedPlan => _selectedPlan != null;
  bool get hasSelectedProducts => _selectedProducts.isNotEmpty;
  bool get canSubmit => hasSelectedPlan && hasSelectedProducts && !isSubmitting;

  /// Get base plan price (could be 0 if plans are discount-based only)
  double get basePlanPrice => 0.0;

  /// Calculate total products price before discount
  double get productsSubtotal {
    return _selectedProducts.values.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  /// Calculate discount amount based on plan
  double get discountAmount {
    if (_selectedPlan == null) return 0.0;
    return (productsSubtotal * _selectedPlan!.discountPercentage) / 100;
  }

  /// Calculate final total price per delivery
  double get totalPricePerDelivery {
    return basePlanPrice + productsSubtotal - discountAmount;
  }

  /// Calculate total for entire subscription duration
  double get totalSubscriptionPrice {
    // Calculate deliveries based on frequency and duration
    int deliveriesPerMonth = _selectedPlan?.frequency == 'weekly'
        ? 4
        : _selectedPlan?.frequency == 'bi-weekly'
        ? 2
        : 1; // monthly

    int totalDeliveries = deliveriesPerMonth * _durationMonths;
    return totalPricePerDelivery * totalDeliveries;
  }

  /// Get formatted price string
  String get formattedTotalPrice {
    return '${totalPricePerDelivery.toStringAsFixed(2)} AED';
  }

  /// Get formatted total subscription price
  String get formattedTotalSubscriptionPrice {
    return '${totalSubscriptionPrice.toStringAsFixed(2)} AED';
  }

  /// Get formatted subtotal string
  String get formattedSubtotal {
    return '${productsSubtotal.toStringAsFixed(2)} AED';
  }

  /// Get formatted discount string
  String get formattedDiscount {
    return '-${discountAmount.toStringAsFixed(2)} AED';
  }

  /// Select a subscription plan
  void selectPlan(SubscriptionPlanModel plan) {
    _selectedPlan = plan;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear selected plan
  void clearPlan() {
    _selectedPlan = null;
    notifyListeners();
  }

  /// Set subscription duration in months
  void setDuration(int months) {
    if (months > 0) {
      _durationMonths = months;
      notifyListeners();
    }
  }

  /// Add product with specific size and quantity
  void addProduct(CoffeeProductModel product, String size, int quantity) {
    // Generate unique ID: productId_size_timestamp
    final uniqueId =
        '${product.id}_${size}_${DateTime.now().millisecondsSinceEpoch}';

    _selectedProducts[uniqueId] = SelectedProduct(
      uniqueId: uniqueId,
      product: product,
      size: size,
      quantity: quantity,
    );

    _errorMessage = null;
    notifyListeners();
  }

  /// Remove a selected product by unique ID
  void removeProduct(String uniqueId) {
    _selectedProducts.remove(uniqueId);
    notifyListeners();
  }

  /// Update product quantity
  void updateProductQuantity(String uniqueId, int quantity) {
    if (_selectedProducts.containsKey(uniqueId)) {
      final current = _selectedProducts[uniqueId]!;
      _selectedProducts[uniqueId] = current.copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  /// Check if a product is selected (any size)
  bool isProductSelected(String productId) {
    return _selectedProducts.values.any((item) => item.productId == productId);
  }

  /// Get all selections for a specific product
  List<SelectedProduct> getProductSelections(String productId) {
    return _selectedProducts.values
        .where((item) => item.productId == productId)
        .toList();
  }

  /// Clear all selected products
  void clearProducts() {
    _selectedProducts.clear();
    notifyListeners();
  }

  /// Clear entire selection (plan + products + duration)
  void clearAll() {
    _selectedPlan = null;
    _selectedProducts.clear();
    _durationMonths = 1;
    _errorMessage = null;
    notifyListeners();
  }

  /// Submit custom subscription to backend
  Future<bool> submitSubscription({
    required String userId,
    required Map<String, dynamic> deliveryAddress,
    String? preferences,
  }) async {
    if (!canSubmit) {
      _errorMessage = 'Please select a plan and at least one coffee product';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Prepare selected products data
      final selectedProductsData = _selectedProducts.values.map((item) {
        return {
          'id': item.productId,
          'name': item.name,
          'size': item.size,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'totalPrice': item.totalPrice,
        };
      }).toList();

      // Create subscription via API
      final result = await _subscriptionsApi.createSubscription(
        userId: userId,
        planId: _selectedPlan!.id,
        frequency: _selectedPlan!.frequency,
        deliveryAddress: deliveryAddress,
        preferences: preferences,
        customization: {
          'selectedProducts': selectedProductsData,
          'durationMonths': _durationMonths,
          'totalPricePerDelivery': totalPricePerDelivery,
          'totalSubscriptionPrice': totalSubscriptionPrice,
          'basePlanPrice': basePlanPrice,
          'productsSubtotal': productsSubtotal,
          'discountAmount': discountAmount,
        },
      );

      debugPrint(
        '✅ Subscription created successfully: ${result['subscription']}',
      );

      // Clear selection after successful submission
      clearAll();

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error creating subscription: $e');
      _errorMessage = 'Failed to create subscription. Please try again.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get subscription summary for display
  Map<String, dynamic> getSubscriptionSummary() {
    return {
      'planName': _selectedPlan?.name ?? 'No plan selected',
      'frequency': _selectedPlan?.frequency ?? '',
      'discountPercentage': _selectedPlan?.discountPercentage ?? 0,
      'durationMonths': _durationMonths,
      'productsCount': _selectedProducts.length,
      'products': _selectedProducts.values
          .map(
            (item) => {
              'name': item.name,
              'size': item.size,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'totalPrice': item.totalPrice,
            },
          )
          .toList(),
      'subtotal': productsSubtotal,
      'discount': discountAmount,
      'totalPerDelivery': totalPricePerDelivery,
      'totalSubscription': totalSubscriptionPrice,
    };
  }
}
