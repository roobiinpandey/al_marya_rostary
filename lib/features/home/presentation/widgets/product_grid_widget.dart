import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../data/models/coffee_product_model.dart';

/// Product grid widget displaying products in a 2x2 grid layout
class ProductGridWidget extends StatefulWidget {
  const ProductGridWidget({super.key});

  @override
  State<ProductGridWidget> createState() => _ProductGridWidgetState();
}

class _ProductGridWidgetState extends State<ProductGridWidget> {
  late Future<List<CoffeeProductModel>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchFeaturedProducts();
  }

  Future<List<CoffeeProductModel>> _fetchFeaturedProducts() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Return featured products (subset of all products)
    return [
      const CoffeeProductModel(
        id: '1',
        name: 'Ethiopian Yirgacheffe',
        description:
            'Light roasted single origin coffee from Ethiopia with floral notes',
        price: 24.99,
        imageUrl:
            'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400',
        origin: 'Ethiopia',
        roastLevel: 'Light',
        stock: 50,
      ),
      const CoffeeProductModel(
        id: '2',
        name: 'Colombian Supremo',
        description: 'Medium roasted coffee from the mountains of Colombia',
        price: 19.99,
        imageUrl:
            'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=400',
        origin: 'Colombia',
        roastLevel: 'Medium',
        stock: 30,
      ),
      const CoffeeProductModel(
        id: '3',
        name: 'Brazilian Santos',
        description: 'Dark roasted coffee with chocolate notes from Brazil',
        price: 22.99,
        imageUrl:
            'https://images.unsplash.com/photo-1459755486867-b55449bb39ff?w=400',
        origin: 'Brazil',
        roastLevel: 'Dark',
        stock: 40,
      ),
      const CoffeeProductModel(
        id: '4',
        name: 'Guatemala Antigua',
        description: 'Full-bodied coffee with spicy undertones from Guatemala',
        price: 26.99,
        imageUrl:
            'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400',
        origin: 'Guatemala',
        roastLevel: 'Medium-Dark',
        stock: 25,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CoffeeProductModel>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
            ),
          );
        } else if (snapshot.hasError) {
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
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _productsFuture = _fetchFeaturedProducts();
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (snapshot.hasData) {
          final products = snapshot.data!;
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
        } else {
          return const Center(child: Text('No data available'));
        }
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
                            (item) => item.product.id == product.id,
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
