import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../coffee/presentation/widgets/coffee_list_widget.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/hero_banner_carousel.dart';
import '../widgets/quick_categories_widget.dart';
import '../widgets/product_grid_widget.dart';
import '../widgets/category_navigation.dart';

/// HomePage displays featured coffee products and navigation
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.coffee,
              color: AppTheme.accentAmber,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'Qahwat Al Emarat',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
          ),
          // Cart button with badge
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CartPage(),
                        ),
                      );
                    },
                  ),
                  if (cartProvider.items.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentAmber,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${cartProvider.items.length}',
                          style: const TextStyle(
                            color: AppTheme.textDark,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
              bottom: 100), // Account for FAB with extra space
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner Carousel
              const HeroBannerCarousel(),

              // Quick Categories
              const QuickCategoriesWidget(),

              // Featured Products Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppTheme.accentAmber,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Featured Products',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to all products page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('View all products coming soon!')),
                        );
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: AppTheme.primaryBrown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Product Grid (2x2)
              const ProductGridWidget(),

              // All Products Section (keeping the original list as "All Products")
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.grid_view,
                      color: AppTheme.accentAmber,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All Products',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),

              // Coffee List (original full list)
              const CoffeeListWidget(),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: AppTheme.surfaceWhite,
          child: Column(
            children: [
              // Drawer Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBrown,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: AppTheme.accentAmber,
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome Back!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Explore our premium coffee collection',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryLightBrown,
                          ),
                    ),
                  ],
                ),
              ),

              // Category Navigation
              const Expanded(
                child: SingleChildScrollView(
                  child: CategoryNavigation(),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Qahwat Al Emarat v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Quick add to cart or navigate to favorites
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quick actions coming soon!')),
          );
        },
        backgroundColor: AppTheme.accentAmber,
        foregroundColor: AppTheme.textDark,
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }
}
