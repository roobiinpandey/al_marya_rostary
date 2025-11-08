import 'package:flutter/material.dart';

import '../../../../data/models/coffee_product_model.dart';

/// Selectable coffee card widget for the subscription builder grid.
/// Displays product summary information and a consistent price point.
class CoffeeCardSelectable extends StatelessWidget {
  final CoffeeProductModel product;
  final bool isSelected;
  final VoidCallback onTap;
  final String? selectedSize;
  final Function(String)? onSizeChanged;

  const CoffeeCardSelectable({
    super.key,
    required this.product,
    required this.isSelected,
    required this.onTap,
    this.selectedSize,
    this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textPrimaryColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primaryColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductImage(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textPrimaryColor,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 9,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                product.origin,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey.shade600,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          product.roastLevel,
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey.shade600,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        _buildPriceDisplay(primaryColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey.shade400,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
            if (product.isFeatured)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Featured',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: AspectRatio(
        aspectRatio: 1,
        child: product.imageUrl.isNotEmpty
            ? Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholderImage();
                },
              )
            : _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(Icons.coffee, size: 48, color: Colors.grey.shade400),
    );
  }

  String _normalizeSize(String size) {
    return size.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  double _getCurrentPrice() {
    if (!product.hasVariants) return product.price;

    if (selectedSize == null) {
      // Find 1kg variant - check for common 1kg labels
      final oneKgVariant = product.variants.firstWhere(
        (variant) => _isOneKgVariant(variant.size),
        orElse: () => product.variants.last, // Usually largest size is last
      );
      return oneKgVariant.price;
    }

    final normalizedSelected = _normalizeSize(selectedSize!);
    final variant = product.variants.firstWhere(
      (variant) => _normalizeSize(variant.size) == normalizedSelected,
      orElse: () => product.variants.first,
    );
    return variant.price;
  }

  bool _isOneKgVariant(String size) {
    final normalized = _normalizeSize(size);
    // Check for 1kg in various formats: "1kg", "1.0kg", "1000g", "1000gm"
    return normalized == '1kg' ||
        normalized == '10kg' || // "1.0 kg" becomes "10kg" after normalization
        normalized == '1000g' ||
        normalized == '1000gm' ||
        normalized.startsWith('1kg') ||
        normalized.startsWith('10kg');
  }

  Widget _buildPriceDisplay(Color primaryColor) {
    final currentPrice = _getCurrentPrice();

    return Row(
      children: [
        Text(
          '${_formatPrice(currentPrice)} AED',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: primaryColor,
            height: 1.1,
          ),
        ),
        if (selectedSize != null) ...[
          const SizedBox(width: 3),
          Text(
            '• $selectedSize',
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey.shade600,
              height: 1.1,
            ),
          ),
        ],
      ],
    );
  }

  String _formatPrice(double price) {
    return price % 1 == 0 ? price.toStringAsFixed(0) : price.toStringAsFixed(2);
  }
}
