import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// CartPage displays the user's selected coffee products for purchase
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final cartItems = cartProvider.items;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Your Cart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppTheme.primaryBrown,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: cartItems.isEmpty
              ? _buildEmptyCart(context)
              : _buildCartContent(context, cartProvider, cartItems),
        );
      },
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundCream,
            AppTheme.primaryLightBrown.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceWhite,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some premium coffee to get started!',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMedium),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // When cart is in a tab view (bottom navigation),
                // we can't actually navigate away. Show a helpful message.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Tap the Home tab below to start shopping'),
                    backgroundColor: AppTheme.primaryBrown,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.home),
              label: const Text('Go to Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(
    BuildContext context,
    CartProvider cartProvider,
    List<CartItem> cartItems,
  ) {
    return Column(
      children: [
        // Cart Items List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBrown.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Product Image
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.primaryLightBrown.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                item.itemType == CartItemType.coffee
                                    ? Icons.coffee
                                    : Icons.shopping_bag,
                                color: AppTheme.primaryBrown,
                                size: 32,
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Product Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.itemType == CartItemType.coffee
                                  ? (item.product?.origin ?? 'Unknown Origin')
                                  : (item.accessory?.category ??
                                        'Unknown Category'),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.textMedium),
                            ),
                            if (item.selectedSize != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLightBrown.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.selectedSize!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.primaryBrown,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              item.itemType == CartItemType.coffee
                                  ? '${AppConstants.currencySymbol}${item.unitPrice.toStringAsFixed(2)} per ${item.selectedSize ?? 'kg'}'
                                  : '${item.unitPrice.toStringAsFixed(2)} ${item.accessory?.price.currency ?? 'AED'}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.primaryBrown,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      // Quantity Controls
                      Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    cartProvider.decrementQuantity(item.id),
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: AppTheme.primaryBrown,
                                ),
                                iconSize: 20,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLightBrown.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${item.quantity}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppTheme.textDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    cartProvider.incrementQuantity(item.id),
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: AppTheme.primaryBrown,
                                ),
                                iconSize: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${AppConstants.currencySymbol}${item.totalPrice.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.primaryBrown,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Order Summary and Checkout
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Order Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textMedium,
                    ),
                  ),
                  Text(
                    '${AppConstants.currencySymbol}${cartProvider.totalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Delivery',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textMedium,
                    ),
                  ),
                  Text(
                    'Free',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.accentAmber,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.primaryLightBrown),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${AppConstants.currencySymbol}${cartProvider.totalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primaryBrown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Checkout Button
              SizedBox(
                width: double.infinity,
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ElevatedButton(
                      onPressed: () {
                        // Route based on authentication status
                        if (authProvider.isAuthenticated &&
                            !authProvider.isGuest) {
                          // Authenticated user → regular checkout
                          Navigator.of(context).pushNamed('/checkout');
                        } else {
                          // Guest or unauthenticated → guest checkout
                          Navigator.of(context).pushNamed('/guest-checkout');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Proceed to Checkout',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Additional Info
              Text(
                'Secure checkout powered by Qahwat Al Emarat',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textLight),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
