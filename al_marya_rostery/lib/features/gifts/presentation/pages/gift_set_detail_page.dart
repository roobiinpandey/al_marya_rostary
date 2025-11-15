import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/gift_set_model.dart';
import '../../../../providers/gift_set_provider.dart';
import '../../../../services/wishlist_api_service.dart';

class GiftSetDetailPage extends StatefulWidget {
  final String giftSetId;

  const GiftSetDetailPage({super.key, required this.giftSetId});

  @override
  State<GiftSetDetailPage> createState() => _GiftSetDetailPageState();
}

class _GiftSetDetailPageState extends State<GiftSetDetailPage> {
  final WishlistApiService _wishlistService = WishlistApiService();
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGiftSetDetails();
      _checkWishlistStatus();
    });
  }

  Future<void> _loadGiftSetDetails() async {
    final provider = context.read<GiftSetProvider>();
    await provider.fetchGiftSetById(widget.giftSetId);
  }

  Future<void> _checkWishlistStatus() async {
    try {
      final isInWishlist = await _wishlistService.isInWishlist(
        widget.giftSetId,
      );
      if (mounted) {
        setState(() {
          _isFavorite = isInWishlist;
        });
      }
    } catch (e) {
      debugPrint('Error checking wishlist status: $e');
    }
  }

  Future<void> _toggleWishlist() async {
    if (_isLoadingFavorite) return;

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      bool success;
      if (_isFavorite) {
        success = await _wishlistService.removeFromWishlist(widget.giftSetId);
      } else {
        success = await _wishlistService.addToWishlist(
          widget.giftSetId,
          'GiftSet',
        );
      }

      if (success && mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? 'Added to favorites' : 'Removed from favorites',
            ),
            backgroundColor: _isFavorite ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<GiftSetProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.selectedGiftSet == null) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          );
        }

        if (provider.error != null && provider.selectedGiftSet == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: TextStyle(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadGiftSetDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final giftSet = provider.selectedGiftSet;
        if (giftSet == null) {
          return Scaffold(
            body: const Center(child: Text('Gift set not found')),
          );
        }

        return _buildDetailContent(giftSet);
      },
    );
  }

  Widget _buildDetailContent(GiftSetModel giftSet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: colorScheme.primary,
            iconTheme: IconThemeData(color: colorScheme.onPrimary),
            actions: [
              // Favorite button
              IconButton(
                icon: _isLoadingFavorite
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                      ),
                onPressed: _isLoadingFavorite ? null : _toggleWishlist,
                color: _isFavorite ? colorScheme.error : colorScheme.onPrimary,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Main Image
                  if (giftSet.images.isNotEmpty)
                    Image.network(
                      giftSet.images.first.url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.surfaceVariant,
                          child: Icon(
                            Icons.card_giftcard,
                            size: 100,
                            color: colorScheme.primary,
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.card_giftcard,
                        size: 100,
                        color: colorScheme.primary,
                      ),
                    ),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          colorScheme.surface.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),

                  // Badges
                  Positioned(
                    top: 60,
                    right: 16,
                    child: Column(
                      children: [
                        if (giftSet.isFeatured)
                          _buildBadge('Featured', Colors.orange),
                        if (giftSet.isPopular)
                          _buildBadge('Popular', Colors.purple),
                        if (giftSet.discountPercentage > 0)
                          _buildBadge(
                            '-${giftSet.discountPercentage}%',
                            Colors.red,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Price Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        giftSet.name['en'] ?? '',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            giftSet.formattedPrice,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          if (giftSet.price.sale != null &&
                              giftSet.price.sale! < giftSet.price.regular)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                '${giftSet.price.regular} ${giftSet.price.currency}',
                                style: TextStyle(
                                  fontSize: 16,
                                  decoration: TextDecoration.lineThrough,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.inventory,
                            '${giftSet.totalItems} items',
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.star,
                            '${giftSet.analytics.avgRating.toStringAsFixed(1)}',
                          ),
                          const SizedBox(width: 8),
                          _buildAvailabilityChip(giftSet.availability),
                        ],
                      ),
                    ],
                  ),
                ),

                // Description
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        giftSet.description['en'] ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Contents
                if (giftSet.contents.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What\'s Included',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...giftSet.contents.map((content) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${content.quantity}x ${content.item.customItem?.name['en'] ?? 'Item'}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                // Occasion & Target Audience
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Perfect For',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTag(giftSet.occasion.toUpperCase()),
                          _buildTag(giftSet.targetAudience.toUpperCase()),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80), // Space for bottom button
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(giftSet),
    );
  }

  Widget _buildBadge(String text, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityChip(GiftSetAvailability availability) {
    final isAvailable = availability.isAvailable;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAvailable ? 'Available' : 'Unavailable',
        style: TextStyle(
          fontSize: 13,
          color: isAvailable ? Colors.green : Colors.red,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.primary),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomBar(GiftSetModel giftSet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: giftSet.availability.isAvailable
              ? () => _addToCart(giftSet)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: colorScheme.surfaceVariant,
          ),
          child: Text(
            giftSet.availability.isAvailable
                ? 'Add to Cart - ${giftSet.formattedPrice}'
                : 'Currently Unavailable',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _addToCart(GiftSetModel giftSet) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${giftSet.name['en']} added to cart'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    // TODO: Implement actual add to cart functionality
  }
}
