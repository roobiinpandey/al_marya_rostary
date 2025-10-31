import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/accessory_model.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

/// Accessory detail page showing full accessory information
class AccessoryDetailPage extends StatefulWidget {
  final Accessory accessory;

  const AccessoryDetailPage({super.key, required this.accessory});

  @override
  State<AccessoryDetailPage> createState() => _AccessoryDetailPageState();
}

class _AccessoryDetailPageState extends State<AccessoryDetailPage> {
  int _quantity = 1;

  String _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    return '${AppConstants.baseUrl}$imageUrl';
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'grinder':
        return Icons.settings;
      case 'mug':
        return Icons.coffee;
      case 'filter':
        return Icons.filter_alt;
      case 'scale':
        return Icons.monitor_weight;
      case 'kettle':
        return Icons.water_drop;
      case 'dripper':
        return Icons.water;
      case 'press':
        return Icons.coffee_maker;
      case 'machine':
        return Icons.coffee_maker;
      default:
        return Icons.shopping_bag;
    }
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getFullImageUrl(widget.accessory.primaryImageUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.accessory.name.en,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Favorite button
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to favorites')),
              );
            },
            color: Colors.white,
          ),
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality coming soon'),
                ),
              );
            },
            color: Colors.white,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade100),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            _getIconForType(widget.accessory.type),
                            size: 100,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryBrown,
                            ),
                          ),
                        );
                      },
                    )
                  : Icon(
                      _getIconForType(widget.accessory.type),
                      size: 100,
                      color: Colors.grey.shade400,
                    ),
            ),

            // Product Info Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Category
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.accessory.name.en,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.category,
                                  size: 18,
                                  color: AppTheme.textLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.accessory.category,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: AppTheme.textMedium),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getIconForType(widget.accessory.type),
                              size: 18,
                              color: AppTheme.primaryBrown,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.accessory.type.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.primaryBrown,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Price and Stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textLight),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.accessory.formattedPrice,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppTheme.primaryBrown,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      // Stock Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: widget.accessory.stock.isInStock
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.accessory.stock.isInStock
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.accessory.stock.isInStock
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 18,
                              color: widget.accessory.stock.isInStock
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.accessory.stock.isInStock
                                  ? 'In Stock'
                                  : 'Out of Stock',
                              style: TextStyle(
                                color: widget.accessory.stock.isInStock
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.accessory.description.en,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textMedium,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Specifications
                  if (widget.accessory.specifications != null) ...[
                    Text(
                      'Specifications',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundCream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryBrown.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Material
                          if (widget
                              .accessory
                              .specifications!
                              .material
                              .isNotEmpty) ...[
                            _buildSpecRow(
                              'Material',
                              widget.accessory.specifications!.material.join(
                                ', ',
                              ),
                            ),
                          ],
                          // Dimensions
                          if (widget.accessory.specifications!.dimensions !=
                              null) ...[
                            _buildSpecRow(
                              'Dimensions',
                              '${widget.accessory.specifications!.dimensions!.length ?? '-'} x '
                                  '${widget.accessory.specifications!.dimensions!.width ?? '-'} x '
                                  '${widget.accessory.specifications!.dimensions!.height ?? '-'} '
                                  '${widget.accessory.specifications!.dimensions!.unit}',
                            ),
                            if (widget
                                    .accessory
                                    .specifications!
                                    .dimensions!
                                    .weight !=
                                null)
                              _buildSpecRow(
                                'Weight',
                                '${widget.accessory.specifications!.dimensions!.weight} g',
                              ),
                          ],
                          // Capacity
                          if (widget.accessory.specifications!.capacity !=
                                  null &&
                              widget
                                      .accessory
                                      .specifications!
                                      .capacity!
                                      .value !=
                                  null) ...[
                            _buildSpecRow(
                              'Capacity',
                              '${widget.accessory.specifications!.capacity!.value} '
                                  '${widget.accessory.specifications!.capacity!.unit}',
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Features
                  if (widget.accessory.specifications?.features.isNotEmpty ??
                      false) ...[
                    Text(
                      'Features',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.accessory.specifications!.features.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryBrown,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    feature.name.en,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: AppTheme.textDark,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    feature.description.en,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.textMedium,
                                          height: 1.5,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Brand
                  if (widget.accessory.brand != null &&
                      widget.accessory.brand!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.business,
                          size: 20,
                          color: AppTheme.textMedium,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Brand: ',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppTheme.textMedium),
                        ),
                        Text(
                          widget.accessory.brand!,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // SKU
                  if (widget.accessory.sku != null &&
                      widget.accessory.sku!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.qr_code,
                          size: 20,
                          color: AppTheme.textMedium,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SKU: ',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textMedium),
                        ),
                        Text(
                          widget.accessory.sku!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.textLight,
                                fontFamily: 'monospace',
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Quantity Selector (if in stock)
                  if (widget.accessory.stock.isInStock) ...[
                    Text(
                      'Quantity',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Decrease button
                        Material(
                          color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {
                              if (_quantity > 1) {
                                setState(() {
                                  _quantity--;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: const Icon(
                                Icons.remove,
                                color: AppTheme.primaryBrown,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Quantity display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.primaryBrown.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _quantity.toString(),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Increase button
                        Material(
                          color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {
                              if (_quantity < widget.accessory.stock.quantity) {
                                setState(() {
                                  _quantity++;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: const Icon(
                                Icons.add,
                                color: AppTheme.primaryBrown,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Available stock
                        Text(
                          '${widget.accessory.stock.quantity} available',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      // Bottom bar with Add to Cart button
      bottomNavigationBar: widget.accessory.stock.isInStock
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Total price
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Price',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textLight),
                          ),
                          Text(
                            '${(widget.accessory.price.sale ?? widget.accessory.price.regular) * _quantity} ${widget.accessory.price.currency}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppTheme.primaryBrown,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Add to Cart button
                    Expanded(
                      child: Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          final isInCart = cartProvider.items.any(
                            (item) =>
                                item.itemType == CartItemType.accessory &&
                                item.accessory!.id == widget.accessory.id,
                          );

                          return ElevatedButton.icon(
                            onPressed: () {
                              if (isInCart) {
                                // Remove from cart
                                cartProvider.removeItem(widget.accessory.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${widget.accessory.name.en} removed from cart',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } else {
                                // Add to cart
                                cartProvider.addAccessory(
                                  widget.accessory,
                                  quantity: _quantity,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Added ${widget.accessory.name.en} (x$_quantity) to cart',
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'VIEW CART',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/cart');
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              isInCart
                                  ? Icons.remove_shopping_cart
                                  : Icons.shopping_cart,
                            ),
                            label: Text(
                              isInCart ? 'Remove from Cart' : 'Add to Cart',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isInCart
                                  ? Colors.orange
                                  : AppTheme.primaryBrown,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
