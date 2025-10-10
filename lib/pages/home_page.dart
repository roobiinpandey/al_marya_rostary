import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/i18n_utils.dart';
import '../widgets/common/app_drawer.dart';
import '../features/home/presentation/widgets/hero_banner_carousel.dart';

import '../features/home/presentation/widgets/featured_products.dart';
import '../features/coffee/presentation/widgets/coffee_list_widget.dart';
import '../features/cart/presentation/providers/cart_provider.dart';
import '../features/coffee/presentation/providers/coffee_provider.dart';
import '../widgets/language_toggle_widget.dart';

import 'cart_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          final coffeeProvider = Provider.of<CoffeeProvider>(
            context,
            listen: false,
          );
          await coffeeProvider.refresh();
        },
        backgroundColor: Colors.white,
        color: AppTheme.primaryBrown,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner Carousel
              const HeroBannerCarousel(),

              const SizedBox(height: 24),

              // Coffee Beans Category Section
              _buildCoffeeBeansCategory(context),

              const SizedBox(height: 24),

              // Featured Products
              const FeaturedProducts(),

              const SizedBox(height: 24),

              // All Items Section
              _buildAllItemsSection(context),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.primaryBrown,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: AppTheme.primaryBrown.withValues(alpha: 0.3),
      title: Row(
        children: [
          Image.asset(
            'assets/images/common/logo.png',
            height: 32,
            width: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              context.l10n.appName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        const LanguageToggleWidget(
          showLabel: false,
          iconSize: 20,
          iconColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 4),
        ),
        IconButton(
          onPressed: () {
            // TODO: Implement search functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Search functionality coming soon'),
                backgroundColor: AppTheme.primaryBrown,
              ),
            );
          },
          icon: const Icon(Icons.search),
        ),
        Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            return Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartPage()),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart),
                ),
                if (cartProvider.items.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cartProvider.items.length}',
                        style: const TextStyle(
                          color: Colors.white,
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
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCoffeeBeansCategory(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryBrown, AppTheme.primaryLightBrown],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBrown.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.coffee,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.coffee,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        context.isArabic
                            ? 'محمصة طازجة، مباشرة من المنشأ'
                            : 'Freshly roasted, direct from origin',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.isArabic
                          ? 'تصفح فئة حبوب القهوة'
                          : 'Browsing coffee beans category',
                    ),
                    backgroundColor: AppTheme.primaryBrown,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryBrown,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.isArabic
                        ? 'تصفح حبوب القهوة'
                        : 'Browse Coffee Beans',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    context.isArabic ? Icons.arrow_back : Icons.arrow_forward,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllItemsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Coffee Products',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening full catalog'),
                      backgroundColor: AppTheme.primaryBrown,
                    ),
                  );
                },
                child: Text(
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
        const SizedBox(height: 16),
        const CoffeeListWidget(),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return const AppDrawer();
  }
}
