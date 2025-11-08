import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/coffee_product_model.dart';
import '../../../../data/models/subscription_model.dart';
import '../../../../data/datasources/remote/subscriptions_api_service.dart';
import '../../../../core/network/api_client.dart';
import '../providers/custom_subscription_provider.dart';
import '../widgets/coffee_card_selectable.dart';
import '../widgets/product_size_selection_dialog.dart';
import '../../../checkout/presentation/pages/payment_page.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

/// Coffee Subscription Builder Page
/// Allows users to create custom coffee subscriptions by selecting products
class CoffeeSubscriptionBuilderPage extends StatefulWidget {
  const CoffeeSubscriptionBuilderPage({super.key});

  @override
  State<CoffeeSubscriptionBuilderPage> createState() =>
      _CoffeeSubscriptionBuilderPageState();
}

class _CoffeeSubscriptionBuilderPageState
    extends State<CoffeeSubscriptionBuilderPage> {
  final SubscriptionsApiService _subscriptionsApi = SubscriptionsApiService();
  final ApiClient _apiClient = ApiClient();

  List<SubscriptionPlanModel> _plans = [];
  List<CoffeeProductModel> _coffeeProducts = [];

  bool _isLoadingPlans = true;
  bool _isLoadingProducts = true;
  String? _errorMessage;

  // Category filter
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Featured',
    'Asia',
    'Africa',
    'Latin America',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadPlans(), _loadCoffeeProducts()]);
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoadingPlans = true;
      _errorMessage = null;
    });

    try {
      final plansData = await _subscriptionsApi.getSubscriptionPlans();
      final plans = plansData
          .map((json) => SubscriptionPlanModel.fromJson(json))
          .where((plan) => plan.isActive)
          .toList();

      setState(() {
        _plans = plans;
        _isLoadingPlans = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading plans: $e');
      setState(() {
        _errorMessage = 'Failed to load subscription plans';
        _isLoadingPlans = false;
      });
    }
  }

  Future<void> _loadCoffeeProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final response = await _apiClient.get('/api/coffees');

      if (_apiClient.isSuccessful(response)) {
        final data = _apiClient.parseResponse(response);
        final productsData = data['coffees'] ?? data['data'] ?? [];

        final products = (productsData as List)
            .map((json) => CoffeeProductModel.fromJson(json))
            .where((product) => product.isActive && product.stock > 0)
            .toList();

        setState(() {
          _coffeeProducts = products;
          _isLoadingProducts = false;
        });
      } else {
        throw Exception('Failed to load coffee products');
      }
    } catch (e) {
      debugPrint('❌ Error loading coffee products: $e');
      setState(() {
        _errorMessage = 'Failed to load coffee products';
        _isLoadingProducts = false;
      });
    }
  }

  List<CoffeeProductModel> get _filteredProducts {
    if (_selectedCategory == 'All') {
      return _coffeeProducts;
    } else if (_selectedCategory == 'Featured') {
      return _coffeeProducts.where((p) => p.isFeatured).toList();
    } else {
      return _coffeeProducts
          .where((p) => p.categories.contains(_selectedCategory))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomSubscriptionProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Build Your Subscription'),
          elevation: 0,
        ),
        body: _isLoadingPlans || _isLoadingProducts
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : _buildContent(),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<CustomSubscriptionProvider>(
      builder: (context, provider, child) {
        return CustomScrollView(
          slivers: [
            // Plans Section
            SliverToBoxAdapter(child: _buildPlansSection(provider)),

            // Category Filters
            SliverToBoxAdapter(child: _buildCategoryFilters()),

            // Coffee Products Grid
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: _buildProductsGrid(provider),
            ),

            // Bottom spacing for fixed bottom bar
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      },
    );
  }

  Widget _buildPlansSection(CustomSubscriptionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 1: Choose Your Plan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                final isSelected = provider.selectedPlan?.id == plan.id;

                return _buildPlanCard(plan, isSelected, provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    SubscriptionPlanModel plan,
    bool isSelected,
    CustomSubscriptionProvider provider,
  ) {
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => provider.selectPlan(plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primaryColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? primaryColor : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: primaryColor, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plan.frequency,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${plan.discountPercentage.toStringAsFixed(0)}% OFF',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 2: Select Your Coffees',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(CustomSubscriptionProvider provider) {
    final filteredProducts = _filteredProducts;

    if (filteredProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No coffee products available in this category',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return SliverGrid(
      delegate: SliverChildBuilderDelegate((context, index) {
        final product = filteredProducts[index];
        final isSelected = provider.isProductSelected(product.id);

        return CoffeeCardSelectable(
          product: product,
          isSelected: isSelected,
          onTap: () => _showProductSizeDialog(context, product),
          selectedSize: null, // Null ensures the card displays 1kg pricing
          onSizeChanged: null, // Not used with dialog flow
        );
      }, childCount: filteredProducts.length),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio:
            0.75, // Increased from 0.7 to give more vertical space
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
    );
  }

  /// Show dialog to select product size and quantity
  Future<void> _showProductSizeDialog(
    BuildContext context,
    CoffeeProductModel product,
  ) async {
    final provider = Provider.of<CustomSubscriptionProvider>(
      context,
      listen: false,
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ProductSizeSelectionDialog(product: product),
    );

    if (result != null) {
      final size = result['size'] as String?;
      final quantity = result['quantity'] as int?;

      if (size != null && quantity != null) {
        provider.addProduct(product, size, quantity);

        // Show confirmation snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $quantity x ${product.name} ($size)'),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () {
                  // Remove the last added product
                  final selections = provider.getProductSelections(product.id);
                  if (selections.isNotEmpty) {
                    provider.removeProduct(selections.last.uniqueId);
                  }
                },
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildBottomBar() {
    return Consumer<CustomSubscriptionProvider>(
      builder: (context, provider, child) {
        if (!provider.hasSelectedPlan && !provider.hasSelectedProducts) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selected Products Summary
                if (provider.hasSelectedProducts) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${provider.selectedProductsCount} item${provider.selectedProductsCount == 1 ? '' : 's'} selected',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showSelectedProductsSheet(context),
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Duration Selection (Step 3)
                if (provider.hasSelectedPlan &&
                    provider.hasSelectedProducts) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Step 3: Select Duration',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [1, 2, 3, 6, 12].map((months) {
                            final isSelected =
                                provider.durationMonths == months;
                            return InkWell(
                              onTap: () => provider.setDuration(months),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                child: Text(
                                  '$months ${months == 1 ? 'Month' : 'Months'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Price Summary
                if (provider.hasSelectedProducts &&
                    provider.hasSelectedPlan) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Per Delivery:',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        provider.formattedTotalPrice,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total (${provider.durationMonths} month${provider.durationMonths == 1 ? '' : 's'}):',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        provider.formattedTotalSubscriptionPrice,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: provider.canSubmit && !provider.isSubmitting
                        ? () => _showConfirmationDialog(provider)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: provider.isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Proceed to Checkout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show bottom sheet with selected products
  void _showSelectedProductsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Selected Products',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Products List
            Expanded(
              child: Consumer<CustomSubscriptionProvider>(
                builder: (context, provider, child) {
                  if (!provider.hasSelectedProducts) {
                    return const Center(child: Text('No products selected'));
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.selectedProducts.length,
                    itemBuilder: (context, index) {
                      final item = provider.selectedProducts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Product Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.coffee),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Product Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.size} • Qty: ${item.quantity}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.totalPrice.toStringAsFixed(2)} AED',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Remove Button
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  provider.removeProduct(item.uniqueId);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(CustomSubscriptionProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Subscription'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Plan: ${provider.selectedPlan!.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Frequency: ${provider.selectedPlan!.frequency}'),
              const SizedBox(height: 16),
              const Text(
                'Selected Coffees:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...provider.selectedProducts.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${item.name} (${item.quantity})'),
                );
              }),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:'),
                  Text(provider.formattedSubtotal),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discount (${provider.selectedPlan!.discountPercentage.toStringAsFixed(0)}%):',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                  Text(
                    provider.formattedDiscount,
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    provider.formattedTotalPrice,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment will be processed next',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _addSubscriptionToCart(provider);
            },
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Add to Cart'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _proceedToPayment(provider);
            },
            icon: const Icon(Icons.payment),
            label: const Text('Pay Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Add subscription to cart for later checkout
  void _addSubscriptionToCart(CustomSubscriptionProvider provider) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Add each selected product to cart
    for (final selectedProduct in provider.selectedProducts) {
      // CartProvider.addItem expects CoffeeProductModel
      cartProvider.addItem(selectedProduct.product);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${provider.selectedProductsCount} ${provider.selectedProductsCount == 1 ? 'item' : 'items'} added to cart',
          ),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ),
      );

      // Clear selection after adding to cart
      provider.clearAll();
    }
  }

  /// Proceed directly to payment for subscription
  void _proceedToPayment(CustomSubscriptionProvider provider) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to continue')));
      return;
    }

    // Prepare order data for payment page
    final orderData = {
      'orderType': 'subscription',
      'subscriptionPlanId': provider.selectedPlan!.id,
      'subscriptionPlanName': provider.selectedPlan!.name,
      'subscriptionFrequency': provider.selectedPlan!.frequency,
      'subscriptionDiscount': provider.selectedPlan!.discountPercentage,
      'userId': user.uid,
      'userEmail': user.email ?? '',
      'userName': user.displayName ?? 'Customer',
      'items': provider.selectedProducts.map((item) {
        return {
          'productId': item.productId,
          'productName': item.name,
          'size': item.size,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'totalPrice': item.totalPrice,
          'imageUrl': item.imageUrl,
        };
      }).toList(),
      'subtotal': provider.productsSubtotal,
      'discount': provider.discountAmount,
      'deliveryFee': 0.0, // Subscriptions have free delivery
      'totalPerDelivery': provider.totalPricePerDelivery,
      'totalSubscription': provider.totalSubscriptionPrice,
      'durationMonths': provider.durationMonths,
      'currency': 'AED',
      'selectedProducts': provider.selectedProducts.map((item) {
        return {
          'productId': item.productId,
          'name': item.name,
          'size': item.size,
          'quantity': item.quantity,
          'totalPrice': item.totalPrice,
        };
      }).toList(),
    };

    // Navigate to payment page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(orderData: orderData),
      ),
    );

    // If payment successful, create subscription
    if (result == true && mounted) {
      await _createSubscriptionAfterPayment(provider, orderData);
    }
  }

  /// Create subscription in backend after successful payment
  Future<void> _createSubscriptionAfterPayment(
    CustomSubscriptionProvider provider,
    Map<String, dynamic> orderData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Basic delivery address - in production, get from user's saved addresses
    final deliveryAddress = {
      'name': user.displayName ?? 'Customer',
      'phone': user.phoneNumber ?? '',
      'street': 'Address to be provided',
      'city': 'Dubai',
      'emirate': 'Dubai',
      'area': 'TBD',
      'isDefault': true,
    };

    final success = await provider.submitSubscription(
      userId: user.uid,
      deliveryAddress: deliveryAddress,
      preferences:
          'Custom coffee selection - Paid via ${orderData['paymentMethod'] ?? 'card'}',
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Subscription created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back or to subscription management
      Navigator.pop(context);
    } else if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment succeeded but subscription creation failed: ${provider.errorMessage}',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
