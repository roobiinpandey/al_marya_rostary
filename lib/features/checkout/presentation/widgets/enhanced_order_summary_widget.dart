import 'package:flutter/material.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class EnhancedOrderSummaryWidget extends StatelessWidget {
  final CartProvider cartProvider;
  final double deliveryFee;
  final int pointsUsed;
  final double pointsDiscount;

  const EnhancedOrderSummaryWidget({
    super.key,
    required this.cartProvider,
    this.deliveryFee = 0.0,
    this.pointsUsed = 0,
    this.pointsDiscount = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = cartProvider.totalPrice;
    final totalBeforeDiscount = subtotal + deliveryFee;
    final finalTotal = totalBeforeDiscount - pointsDiscount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),

            // Order Items
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cartProvider.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = cartProvider.items[index];
                return Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.primaryLightBrown.withValues(
                          alpha: 0.2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              item.itemType == CartItemType.coffee
                                  ? Icons.coffee
                                  : Icons.shopping_bag,
                              color: AppTheme.primaryBrown,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Qty: ${item.quantity}${item.selectedSize != null ? ' • ${item.selectedSize}' : ''}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textMedium),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${AppConstants.currencySymbol}${item.totalPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  '${AppConstants.currencySymbol}${subtotal.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            // Delivery Fee (if applicable)
            if (deliveryFee > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Delivery Fee',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    '${AppConstants.currencySymbol}${deliveryFee.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            // Reward Points Discount (if applicable)
            if (pointsUsed > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stars, size: 16, color: AppTheme.primaryBrown),
                      const SizedBox(width: 4),
                      Text(
                        'Reward Points ($pointsUsed pts)',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.primaryBrown,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '-${AppConstants.currencySymbol}${pointsDiscount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBrown,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),
            const Divider(thickness: 2),
            const SizedBox(height: 8),

            // Final Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  '${AppConstants.currencySymbol}${finalTotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBrown,
                  ),
                ),
              ],
            ),

            // Savings information
            if (pointsDiscount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.savings, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'You saved ${AppConstants.currencySymbol}${pointsDiscount.toStringAsFixed(2)} with reward points!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            Text(
              'Items (${cartProvider.items.length})',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMedium),
            ),
          ],
        ),
      ),
    );
  }
}
