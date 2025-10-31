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

      if (sliders.isEmpty) {
        // If no banners in backend, use fallback mockup banners
        _loadFallbackBanners();
      } else {
        setState(() {
          _banners = sliders;
          _isLoading = false;
        });
        _startAutoScroll();
      }

      debugPrint('✅ Loaded ${_banners.length} banners from backend');
    } catch (e) {
      debugPrint('❌ Error loading banners: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      // Use fallback banners if API fails
      _loadFallbackBanners();
    }
  }

  /// Fallback to mockup banners if backend is unavailable
  void _loadFallbackBanners() {
    final now = DateTime.now();

    setState(() {
      _banners = [
        SliderModel(
          id: 'fallback_1',
          title: 'Premium Arabica Beans',
          description: 'Fresh from the mountains of Yemen',
          image:
              'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=800',
          isActive: true,
          displayOrder: 1,
          createdAt: now,
          updatedAt: now,
        ),
        SliderModel(
          id: 'fallback_2',
          title: 'Single Origin Excellence',
          description: 'Ethiopian Yirgacheffe - Light & Bright',
          image:
              'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=800',
          isActive: true,
          displayOrder: 2,
          createdAt: now,
          updatedAt: now,
        ),
        SliderModel(
          id: 'fallback_3',
          title: 'Artisan Roasted',
          description: 'Master roasters, perfect extraction',
          image:
              'https://images.unsplash.com/photo-1459755486867-b55449bb39ff?w=800',
          isActive: true,
          displayOrder: 3,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      _isLoading = false;
    });
    _startAutoScroll();
    debugPrint('⚠️ Using fallback mockup banners (backend unavailable)');
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

    // Show error message if banners failed to load and no fallback
    if (_banners.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'No banners available',
                style: TextStyle(color: Colors.grey),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
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
                  ElevatedButton(
                    onPressed: () {
                      // Track banner click
                      _sliderService.trackClick(banner.id);

                      // Navigate based on buttonLink if available
                      if (banner.buttonLink != null &&
                          banner.buttonLink!.isNotEmpty) {
                        // TODO: Implement navigation based on linkType
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Opening: ${banner.buttonLink}'),
                            backgroundColor: AppTheme.primaryBrown,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Exploring ${banner.title}'),
                            backgroundColor: AppTheme.primaryBrown,
                          ),
                        );
                      }
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
                      banner.buttonText ?? 'Explore Now',
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
}
