import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/brewing_method_model.dart';

class BrewingMethodCard extends StatelessWidget {
  final BrewingMethod brewingMethod;
  final VoidCallback? onTap;

  const BrewingMethodCard({super.key, required this.brewingMethod, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isArabic),
              const SizedBox(height: 12),
              _buildDescription(context, isArabic),
              const SizedBox(height: 12),
              _buildDetails(context, isArabic),
              const SizedBox(height: 12),
              _buildFooter(context, isArabic),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isArabic) {
    return Row(
      children: [
        // Method Image/Icon
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Color(
              int.parse(brewingMethod.color.replaceFirst('#', '0xFF')),
            ),
          ),
          child: brewingMethod.image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _getFullImageUrl(brewingMethod.image!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.coffee, color: Colors.white, size: 30),
                  ),
                )
              : Icon(
                  brewingMethod.icon != null
                      ? IconData(
                          int.parse(brewingMethod.icon!),
                          fontFamily: 'MaterialIcons',
                        )
                      : Icons.coffee,
                  color: Colors.white,
                  size: 30,
                ),
        ),
        const SizedBox(width: 12),
        // Method Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isArabic ? brewingMethod.name.ar : brewingMethod.name.en,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (brewingMethod.isPopular) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            isArabic ? 'مشهور' : 'Popular',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              // Rating
              if (brewingMethod.analytics.totalRatings > 0)
                Row(
                  children: [
                    _buildStarRating(brewingMethod.analytics.avgRating),
                    const SizedBox(width: 4),
                    Text(
                      '${brewingMethod.analytics.avgRating.toStringAsFixed(1)} (${brewingMethod.analytics.totalRatings})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, bool isArabic) {
    return Text(
      isArabic ? brewingMethod.description.ar : brewingMethod.description.en,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMedium, height: 1.4),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDetails(BuildContext context, bool isArabic) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildDetailChip(
          brewingMethod.difficultyIcon,
          brewingMethod.difficulty,
          _getDifficultyColor(brewingMethod.difficulty),
        ),
        _buildDetailChip(
          '⏱️',
          brewingMethod.formattedTotalTime,
          AppTheme.primaryBrown,
        ),
        _buildDetailChip(
          '👥',
          '${brewingMethod.servings} ${isArabic ? "حصص" : "servings"}',
          AppTheme.accentAmber,
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, bool isArabic) {
    return Row(
      children: [
        // Categories
        if (brewingMethod.categories.isNotEmpty) ...[
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 2,
              children: brewingMethod.categories.take(2).map((category) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.accentAmber.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.accentAmber,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        // View count
        if (brewingMethod.analytics.viewCount > 0) ...[
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility, size: 14, color: AppTheme.textMedium),
              const SizedBox(width: 2),
              Text(
                '${brewingMethod.analytics.viewCount}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textMedium),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDetailChip(String icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
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
          return const Icon(Icons.star, color: Colors.amber, size: 14);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 14);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 14);
        }
      }),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.blue;
      case 'advanced':
        return Colors.orange;
      case 'expert':
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
