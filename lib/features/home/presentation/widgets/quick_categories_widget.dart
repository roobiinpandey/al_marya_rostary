import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Quick categories widget with horizontal scrolling
class QuickCategoriesWidget extends StatelessWidget {
  const QuickCategoriesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      CategoryItem(
        title: 'Arabica',
        subtitle: 'Premium Quality',
        imageUrl: 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=300',
        color: AppTheme.primaryBrown,
      ),
      CategoryItem(
        title: 'Robusta',
        subtitle: 'Bold & Strong',
        imageUrl: 'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=300',
        color: AppTheme.accentAmber,
      ),
      CategoryItem(
        title: 'Single Origin',
        subtitle: 'Unique Flavors',
        imageUrl: 'https://images.unsplash.com/photo-1459755486867-b55449bb39ff?w=300',
        color: AppTheme.primaryLightBrown,
      ),
      CategoryItem(
        title: 'Blends',
        subtitle: 'Perfect Balance',
        imageUrl: 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=300',
        color: AppTheme.primaryBrown.withValues(alpha: 0.8),
      ),
      CategoryItem(
        title: 'Light Roast',
        subtitle: 'Bright & Acidic',
        imageUrl: 'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=300',
        color: AppTheme.accentAmber.withValues(alpha: 0.8),
      ),
      CategoryItem(
        title: 'Dark Roast',
        subtitle: 'Rich & Smoky',
        imageUrl: 'https://images.unsplash.com/photo-1459755486867-b55449bb39ff?w=300',
        color: AppTheme.primaryLightBrown.withValues(alpha: 0.8),
      ),
    ];

    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return _buildCategoryItem(context, categories[index]);
        },
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, CategoryItem category) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // TODO: Navigate to category page
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Exploring ${category.title} category'),
                backgroundColor: AppTheme.primaryBrown,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(category.imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  category.color.withValues(alpha: 0.7),
                  BlendMode.multiply,
                ),
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
}

/// Data model for category items
class CategoryItem {
  final String title;
  final String subtitle;
  final String imageUrl;
  final Color color;

  CategoryItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.color,
  });
}
