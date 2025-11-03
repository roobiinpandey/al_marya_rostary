import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/quick_category_model.dart';
import '../../../../core/services/quick_category_api_service.dart';

/// Quick categories widget with horizontal scrolling
class QuickCategoriesWidget extends StatefulWidget {
  const QuickCategoriesWidget({super.key});

  @override
  State<QuickCategoriesWidget> createState() => _QuickCategoriesWidgetState();
}

class _QuickCategoriesWidgetState extends State<QuickCategoriesWidget> {
  final QuickCategoryApiService _apiService = QuickCategoryApiService();
  List<QuickCategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuickCategories();
  }

  Future<void> _loadQuickCategories() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final categories = await _apiService.fetchActiveQuickCategories(
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Hide section on error instead of showing fallback
          _categories = [];
        });
        // Log error for debugging
        debugPrint('Error loading quick categories: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_categories.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          return _buildCategoryItem(context, _categories[index]);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4, // Show 4 loading placeholders
        itemBuilder: (context, index) {
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[300],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryBrown,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    // Return empty SizedBox when no categories to avoid empty space
    return const SizedBox.shrink();
  }

  Widget _buildCategoryItem(BuildContext context, QuickCategoryModel category) {
    final categoryColor = Color(
      int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
    );

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            // Track category click
            try {
              await _apiService.trackQuickCategoryClick(category.id);
            } catch (e) {
              // Don't fail user experience for analytics
              debugPrint('Failed to track click: $e');
            }

            // Navigate based on category configuration
            _handleCategoryNavigation(context, category);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(category.safeImageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  categoryColor.withValues(alpha: 0.7),
                  BlendMode.multiply,
                ),
                onError: (exception, stackTrace) {
                  debugPrint('Failed to load image: ${category.imageUrl}');
                },
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 10,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handle navigation based on quick category configuration
  void _handleCategoryNavigation(
    BuildContext context,
    QuickCategoryModel category,
  ) {
    switch (category.linkTo.toLowerCase()) {
      case 'category':
        // Navigate to category browse page with specific category
        Navigator.pushNamed(
          context,
          '/category-browse',
          arguments: category.linkValue,
        );
        break;

      case 'product':
        // Navigate to specific product detail page
        // Note: You might need to fetch the product by ID first
        _navigateToProduct(context, category.linkValue);
        break;

      case 'external':
        // Navigate to external URL (implement if needed)
        _showExternalLinkDialog(context, category.linkValue);
        break;

      case 'none':
      default:
        // Show default category browse or feedback
        _showDefaultNavigation(context, category);
        break;
    }
  }

  /// Navigate to specific product
  void _navigateToProduct(BuildContext context, String productId) {
    // For now, show a message. You can implement product fetch and navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening product: $productId'),
        backgroundColor: AppTheme.primaryBrown,
        duration: const Duration(seconds: 2),
      ),
    );

    // Note: Implement product navigation
    // 1. Fetch product by ID from API
    // 2. Navigate to ProductDetailPage
    // Example:
    // final product = await ProductApiService().fetchProduct(productId);
    // if (product != null) {
    //   Navigator.pushNamed(context, '/product', arguments: product);
    // }
  }

  /// Show external link dialog
  void _showExternalLinkDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('External Link'),
          content: Text('This will open:\n$url'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Note: Implement URL launcher
                // launch(url);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Would open: $url'),
                    backgroundColor: AppTheme.primaryBrown,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ],
        );
      },
    );
  }

  /// Show default navigation for categories without specific links
  void _showDefaultNavigation(
    BuildContext context,
    QuickCategoryModel category,
  ) {
    // Default: Navigate to category browse page with category title as filter
    Navigator.pushNamed(context, '/category-browse', arguments: category.title);
  }
}
