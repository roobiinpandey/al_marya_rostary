import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../coffee/presentation/widgets/coffee_list_widget.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../../core/theme/theme_extensions.dart';
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
            Icon(Icons.location_on, color: context.colors.secondary, size: 20),
            const SizedBox(width: 4),
            Text(
              'Dubai, UAE',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Search button
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
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
                    icon: Icon(Icons.shopping_cart, color: Colors.white),
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
                          color: context.colors.secondary,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${cartProvider.items.length}',
                          style: TextStyle(
                            color: context.colors.onSurface,
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
            bottom: 100,
          ), // Account for FAB with extra space
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
                    Icon(Icons.star, color: context.colors.secondary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Featured Products',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to all products page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('View all products coming soon!'),
                          ),
                        );
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Product Grid (2x2)
              const ProductGridWidget(),
              // All Products Section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.grid_view,
                      color: context.colors.secondary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All Products',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: context.colors.onSurface,
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
          color: Colors.white, // White background
          child: Column(
            children: [
              // Drawer Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFFA89A6A), // Hardcoded olive gold
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: Color(0xFFCBBE8C), // Light gold
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: Color(0xFF2C2C2C), // Dark charcoal
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        color: Colors.white, // White text on olive gold
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Explore our premium coffee collection',
                      style: TextStyle(
                        color: Colors.white, // White text on olive gold
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Category Navigation
              Expanded(
                child: SingleChildScrollView(child: CategoryNavigation()),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'ALMARYAH ROSTERY v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black.withValues(alpha: 0.6), // Black text
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
        backgroundColor: context.colors.secondary,
        foregroundColor: context.colors.onSurface,
        child: Icon(Icons.add_shopping_cart),
      ),
    );
  }
}
