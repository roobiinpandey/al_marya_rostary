import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/slider_api_service.dart';
import '../../../../../data/models/slider_model.dart';
import '../../../../../core/constants/app_constants.dart';

/// Hero banner carousel widget with auto-scrolling and navigation
class HeroBannerCarousel extends StatefulWidget {
  const HeroBannerCarousel({super.key});

  @override
  State<HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<HeroBannerCarousel> {
  final PageController _pageController = PageController();
  final SliderApiService _sliderService = SliderApiService();
  int _currentPage = 0;
  List<SliderModel> _banners = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBannersFromBackend();
  }

  /// Load banners from backend API
  Future<void> _loadBannersFromBackend() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await _sliderService.fetchAllSliders(
        isActive: true, // Only fetch active banners
        sortBy: 'displayOrder',
        sortOrder: 'asc',
      );

      final sliders = result['sliders'] as List<SliderModel>;

      setState(() {
        _banners = sliders;
        _isLoading = false;
      });

      if (_banners.isNotEmpty) {
        _startAutoScroll();
      }

      debugPrint('✅ Loaded ${_banners.length} banners from backend');
    } catch (e) {
      debugPrint('❌ Error loading banners: $e');
      setState(() {
        _error =
            'Unable to load banners. Please check your connection and try again.';
        _isLoading = false;
        _banners = []; // Clear any existing banners
      });
    }
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        final nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while fetching banners
    if (_isLoading) {
      return SizedBox(
        height: 250,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.accentAmber),
        ),
      );
    }

    // Show friendly error message if banners failed to load
    if (_banners.isEmpty) {
      return Container(
        height: 250,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryBrown.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryBrown.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 56,
                  color: AppTheme.primaryBrown.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'No banners available',
                  style: TextStyle(
                    color: AppTheme.primaryBrown.withValues(alpha: 0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loadBannersFromBackend,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBrown,
                    side: BorderSide(color: AppTheme.primaryBrown),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          // PageView for carousel
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              return _buildBannerItem(_banners[index]);
            },
          ),

          // Navigation arrows
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: () {
                  final prevPage = _currentPage > 0
                      ? _currentPage - 1
                      : _banners.length - 1;
                  _pageController.animateToPage(
                    prevPage,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.3),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
          ),

          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: () {
                  final nextPage = (_currentPage + 1) % _banners.length;
                  _pageController.animateToPage(
                    nextPage,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.3),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
          ),

          // Page indicators
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _banners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.accentAmber
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get full image URL from relative path
  String _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=800'; // Fallback image
    }

    // If already a full URL, return as is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // Otherwise, prepend base URL
    return '${AppConstants.baseUrl}$imageUrl';
  }

  Widget _buildBannerItem(SliderModel banner) {
    final imageUrl = _getFullImageUrl(banner.mobileImage ?? banner.image);

    debugPrint('🖼️ Loading banner image: $imageUrl');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ Error loading banner image: $imageUrl');
                debugPrint('Error: $error');
                // Fallback to a placeholder
                return Container(
                  color: AppTheme.primaryBrown.withValues(alpha: 0.3),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image unavailable',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppTheme.primaryBrown.withValues(alpha: 0.2),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppTheme.accentAmber,
                    ),
                  ),
                );
              },
            ),
            // Color overlay
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryBrown.withValues(alpha: 0.3),
              ),
            ),
            // Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner.title,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  if (banner.description != null &&
                      banner.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      banner.description!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Only show button if actionType is not 'none'
                  if (banner.actionType != null && banner.actionType != 'none')
                    ElevatedButton(
                      onPressed: () {
                        // Track banner click
                        _sliderService.trackClick(banner.id);
                        // Handle action based on type
                        _handleBannerAction(context, banner);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentAmber,
                        foregroundColor: AppTheme.textDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        banner.buttonText ??
                            _getDefaultButtonText(banner.actionType ?? 'none'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle banner action based on actionType
  void _handleBannerAction(BuildContext context, SliderModel banner) {
    final actionType = banner.actionType;
    final actionValue = banner.actionValue;

    switch (actionType) {
      case 'category':
        // Navigate to category page
        if (actionValue != null && actionValue.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/category-products',
            arguments: {'categoryId': actionValue},
          );
        }
        break;

      case 'products':
        // Navigate to all products page
        Navigator.pushNamed(context, '/products');
        break;

      case 'offers':
        // Navigate to offers/promotions page
        Navigator.pushNamed(context, '/offers');
        break;

      case 'url':
        // Open external URL
        if (actionValue != null && actionValue.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening: $actionValue'),
              backgroundColor: AppTheme.primaryBrown,
            ),
          );
          // Note: Use url_launcher package to open external URLs
          // launchUrl(Uri.parse(actionValue));
        }
        break;

      default:
        // Do nothing for 'none' or unknown types
        break;
    }
  }

  /// Get default button text based on action type
  String _getDefaultButtonText(String actionType) {
    switch (actionType) {
      case 'category':
        return 'View Category';
      case 'products':
        return 'Shop Now';
      case 'offers':
        return 'View Offers';
      case 'url':
        return 'Learn More';
      default:
        return 'Explore Now';
    }
  }
}
