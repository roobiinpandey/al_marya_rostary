import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// A reusable widget for displaying product images with proper constraints and error handling
class ProductImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final double? width;
  final BoxFit fit;
  final Widget? placeholder;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;
  final double placeholderIconSize;
  final Color placeholderIconColor;
  final List<Color>? gradientColors;

  const ProductImageWidget({
    super.key,
    this.imageUrl,
    this.height = 120,
    this.width,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.borderRadius,
    this.placeholderIcon = Icons.image,
    this.placeholderIconSize = 48,
    this.placeholderIconColor = Colors.white,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final finalWidth = width ?? double.infinity;
    final finalBorderRadius = borderRadius ?? BorderRadius.circular(8);

    // If no image URL or invalid URL, show placeholder
    if (imageUrl == null || imageUrl!.isEmpty || !_isValidUrl(imageUrl!)) {
      return _buildPlaceholder(finalWidth, finalBorderRadius);
    }

    return Container(
      height: height,
      width: finalWidth,
      decoration: BoxDecoration(borderRadius: finalBorderRadius),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl!,
        height: height,
        width: finalWidth,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Product image loading error for $imageUrl: $error');
          return _buildPlaceholder(finalWidth, finalBorderRadius);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return Container(
            height: height,
            width: finalWidth,
            decoration: BoxDecoration(
              borderRadius: finalBorderRadius,
              color: AppTheme.backgroundCream,
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryBrown,
                ),
                strokeWidth: 2,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder(double finalWidth, BorderRadius finalBorderRadius) {
    if (placeholder != null) {
      return Container(
        height: height,
        width: finalWidth,
        decoration: BoxDecoration(borderRadius: finalBorderRadius),
        child: placeholder!,
      );
    }

    final colors =
        gradientColors ??
        [
          AppTheme.accentAmber.withValues(alpha: 0.8),
          AppTheme.primaryBrown.withValues(alpha: 0.6),
        ];

    return Container(
      height: height,
      width: finalWidth,
      decoration: BoxDecoration(
        borderRadius: finalBorderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          placeholderIcon,
          size: placeholderIconSize,
          color: placeholderIconColor,
        ),
      ),
    );
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}

/// A specialized widget for gift set cards
class GiftSetImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final double? width;

  const GiftSetImageWidget({
    super.key,
    this.imageUrl,
    this.height = 120,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ProductImageWidget(
      imageUrl: imageUrl,
      height: height,
      width: width,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      placeholderIcon: Icons.card_giftcard,
      placeholderIconSize: 48,
      gradientColors: [
        AppTheme.accentAmber.withValues(alpha: 0.8),
        AppTheme.primaryBrown.withValues(alpha: 0.6),
      ],
    );
  }
}

/// A specialized widget for accessory product cards
class AccessoryImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final double? width;
  final IconData fallbackIcon;

  const AccessoryImageWidget({
    super.key,
    this.imageUrl,
    this.height = 120,
    this.width,
    this.fallbackIcon = Icons.settings,
  });

  @override
  Widget build(BuildContext context) {
    return ProductImageWidget(
      imageUrl: imageUrl,
      height: height,
      width: width,
      placeholderIcon: fallbackIcon,
      placeholderIconSize: 48,
      gradientColors: [
        Colors.grey.shade300.withValues(alpha: 0.8),
        Colors.grey.shade500.withValues(alpha: 0.6),
      ],
    );
  }
}

/// A specialized widget for coffee product cards
class CoffeeImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final double? width;

  const CoffeeImageWidget({
    super.key,
    this.imageUrl,
    this.height = 120,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ProductImageWidget(
      imageUrl: imageUrl,
      height: height,
      width: width,
      placeholderIcon: Icons.coffee,
      placeholderIconSize: 48,
      gradientColors: [
        AppTheme.primaryLightBrown.withValues(alpha: 0.8),
        AppTheme.primaryBrown.withValues(alpha: 0.6),
      ],
    );
  }
}
