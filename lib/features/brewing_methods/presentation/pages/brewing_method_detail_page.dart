import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/brewing_method_model.dart';
import '../../data/brewing_method_api_service.dart';
import '../widgets/brewing_equipment_card.dart';
import '../widgets/brewing_parameters_card.dart';
import '../widgets/brewing_tips_card.dart';
import '../widgets/brewing_variations_card.dart';

class BrewingMethodDetailPage extends StatefulWidget {
  final BrewingMethod brewingMethod;

  const BrewingMethodDetailPage({super.key, required this.brewingMethod});

  @override
  State<BrewingMethodDetailPage> createState() =>
      _BrewingMethodDetailPageState();
}

class _BrewingMethodDetailPageState extends State<BrewingMethodDetailPage> {
  final BrewingMethodApiService _apiService = BrewingMethodApiService();
  late BrewingMethod _method;
  bool _isLoading = false;
  int _userRating = 0;

  @override
  void initState() {
    super.initState();
    _method = widget.brewingMethod;
  }

  Future<void> _rateMethod(int rating) async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // In a real app, you'd get the auth token from a provider or storage
      final result = await _apiService.rateBrewingMethod(
        _method.id,
        rating,
        // authToken: 'your_auth_token_here',
      );

      setState(() {
        _userRating = rating;
        // Update the method with new rating data
        _method = BrewingMethod(
          id: _method.id,
          name: _method.name,
          description: _method.description,
          instructions: _method.instructions,
          equipment: _method.equipment,
          parameters: _method.parameters,
          difficulty: _method.difficulty,
          totalTime: _method.totalTime,
          servings: _method.servings,
          categories: _method.categories,
          tags: _method.tags,
          isActive: _method.isActive,
          displayOrder: _method.displayOrder,
          isPopular: _method.isPopular,
          image: _method.image,
          icon: _method.icon,
          color: _method.color,
          tips: _method.tips,
          variations: _method.variations,
          analytics: BrewingAnalytics(
            viewCount: _method.analytics.viewCount,
            likeCount: _method.analytics.likeCount,
            shareCount: _method.analytics.shareCount,
            avgRating: result['avgRating'] ?? _method.analytics.avgRating,
            totalRatings:
                result['totalRatings']?.toInt() ??
                _method.analytics.totalRatings,
          ),
          seo: _method.seo,
          createdAt: _method.createdAt,
          updatedAt: _method.updatedAt,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.isArabic
                ? 'تم إرسال تقييمك بنجاح!'
                : 'Thank you for your rating!',
          ),
          backgroundColor: AppTheme.primaryBrown,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.isArabic
                ? 'فشل في إرسال التقييم'
                : 'Failed to submit rating',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isArabic),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildMethodHeader(isArabic),
              _buildDescription(isArabic),
              _buildParameters(),
              _buildEquipment(isArabic),
              _buildInstructions(isArabic),
              if (_method.tips.isNotEmpty) _buildTips(isArabic),
              if (_method.variations.isNotEmpty) _buildVariations(isArabic),
              _buildRatingSection(isArabic),
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isArabic) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppTheme.primaryBrown,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          isArabic ? _method.name.ar : _method.name.en,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: _method.image != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _getFullImageUrl(_method.image!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppTheme.primaryBrown,
                      child: const Icon(
                        Icons.coffee,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.primaryBrown.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                color: AppTheme.primaryBrown,
                child: const Icon(Icons.coffee, size: 64, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildMethodHeader(bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? _method.name.ar : _method.name.en,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildInfoChip(
                          _method.difficultyIcon,
                          _method.difficulty,
                          _getDifficultyColor(_method.difficulty),
                        ),
                        _buildInfoChip(
                          '⏱️',
                          _method.formattedTotalTime,
                          AppTheme.primaryBrown,
                        ),
                        _buildInfoChip(
                          '👥',
                          '${_method.servings} ${isArabic ? "حصص" : "servings"}',
                          AppTheme.accentAmber,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_method.isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        isArabic ? 'مشهور' : 'Popular',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_method.analytics.totalRatings > 0)
            Row(
              children: [
                _buildStarRating(_method.analytics.avgRating),
                const SizedBox(width: 8),
                Text(
                  '${_method.analytics.avgRating.toStringAsFixed(1)} (${_method.analytics.totalRatings} ${isArabic ? "تقييم" : "reviews"})',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMedium),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDescription(bool isArabic) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'الوصف' : 'Description',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isArabic ? _method.description.ar : _method.description.en,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textDark,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: BrewingParametersCard(parameters: _method.parameters),
    );
  }

  Widget _buildEquipment(bool isArabic) {
    if (_method.equipment.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: BrewingEquipmentCard(
        equipment: _method.equipment,
        isArabic: isArabic,
      ),
    );
  }

  Widget _buildInstructions(bool isArabic) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'تعليمات التحضير' : 'Brewing Instructions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isArabic ? _method.instructions.ar : _method.instructions.en,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textDark,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTips(bool isArabic) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: BrewingTipsCard(
        tips: _method.tips.map((tip) => tip.tip).toList(),
        isArabic: isArabic,
      ),
    );
  }

  Widget _buildVariations(bool isArabic) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: BrewingVariationsCard(
        variations: _method.variations,
        isArabic: isArabic,
      ),
    );
  }

  Widget _buildRatingSection(bool isArabic) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'قيم هذه الطريقة' : 'Rate this method',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return GestureDetector(
                onTap: () => _rateMethod(starIndex),
                child: Icon(
                  starIndex <= _userRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 20);
        }
      }),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.blue;
      case 'Advanced':
        return Colors.orange;
      case 'Expert':
        return Colors.red;
      default:
        return AppTheme.textMedium;
    }
  }

  /// Get full image URL by prepending base URL if needed
  String _getFullImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath; // Already a full URL
    }
    // For relative paths starting with /uploads/, prepend base URL
    if (imagePath.startsWith('/uploads/')) {
      return '${AppConstants.baseUrl}$imagePath';
    }
    return imagePath;
  }
}
