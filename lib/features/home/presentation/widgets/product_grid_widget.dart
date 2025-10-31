import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../coffee/presentation/providers/coffee_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../data/models/coffee_product_model.dart';

/// Product grid widget displaying products in a 2x2 grid layout
class ProductGridWidget extends StatefulWidget {
  const ProductGridWidget({super.key});

  @override
  State<ProductGridWidget> createState() => _ProductGridWidgetState();
}

class _ProductGridWidgetState extends State<ProductGridWidget> {
  @override
  void initState() {
    super.initState();
    // Load products from API when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final coffeeProvider = Provider.of<CoffeeProvider>(
        context,
        listen: false,
      );
      if (coffeeProvider.featuredCoffees.isEmpty && !coffeeProvider.isLoading) {
        coffeeProvider.loadCoffees(limit: 4); // Load only 4 products for grid
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoffeeProvider>(
      builder: (context, coffeeProvider, child) {
        // Loading state
        if (coffeeProvider.isLoading &&
            coffeeProvider.featuredCoffees.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
            ),
          );
        }

        // Error state
        if (coffeeProvider.hasError && coffeeProvider.featuredCoffees.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load products',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  coffeeProvider.error ?? 'Unknown error',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    coffeeProvider.loadCoffees(limit: 4);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Success state with data
        final products = coffeeProvider.featuredCoffees.take(4).toList();
        if (products.isEmpty) {
          return const Center(child: Text('No products available'));
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio:
                  0.7, // Increased to give more height and prevent overflow
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildGridProductCard(context, product);
            },
          ),
        );
      },
    );
  }

  Widget _buildGridProductCard(
    BuildContext context,
    CoffeeProductModel product,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBrown.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                image: DecorationImage(
                  image: NetworkImage(product.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Gradient overlay for better text readability
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                  // Roast level badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBrown.withValues(alpha: 0.9),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        product.roastLevel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Product Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(6), // Further reduced from 8 to 6
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 11, // Further reduced from 12 to 11
                    ),
                    maxLines: 1, // Reduced to 1 line to save space
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 1), // Further reduced from 2 to 1
                  // Origin
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 10, // Reduced from 12 to 10
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        product.origin,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMedium,
                          fontSize: 10, // Reduced from 11 to 10
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Price and Add Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.pricePerKgDisplay,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.primaryBrown,
                              fontWeight: FontWeight.bold,
                              fontSize: 12, // Reduced from 14 to 12
                            ),
                      ),
                      Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          final isInCart = cartProvider.items.any(
                            (item) =>
                                item.itemType == CartItemType.coffee &&
                                item.id == product.id,
                          );

                          return IconButton(
                            onPressed: () {
                              if (isInCart) {
                                cartProvider.removeItem(product.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${product.name} removed from cart',
                                    ),
                                    backgroundColor: AppTheme.primaryBrown,
                                  ),
                                );
                              } else {
                                cartProvider.addItem(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${product.name} added to cart',
                                    ),
                                    backgroundColor: AppTheme.primaryBrown,
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              isInCart
                                  ? Icons.remove_shopping_cart
                                  : Icons.add_shopping_cart,
                              size: 18, // Reduced from 20 to 18
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: isInCart
                                  ? AppTheme.textLight
                                  : AppTheme.primaryBrown,
                              foregroundColor: isInCart
                                  ? AppTheme.textDark
                                  : Colors.white,
                              padding: const EdgeInsets.all(
                                6,
                              ), // Reduced from 8 to 6
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
