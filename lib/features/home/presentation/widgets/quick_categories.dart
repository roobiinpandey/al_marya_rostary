import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Quick categories widget for easy navigation
class QuickCategories extends StatelessWidget {
  const QuickCategories({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      CategoryItem(
        icon: Icons.local_fire_department,
        label: 'Hot Coffee',
        color: AppTheme.primaryBrown,
      ),
      CategoryItem(
        icon: Icons.ac_unit,
        label: 'Iced Coffee',
        color: AppTheme.accentAmber,
      ),
      CategoryItem(
        icon: Icons.grain,
        label: 'Coffee Beans',
        color: AppTheme.primaryLightBrown,
      ),
      CategoryItem(
        icon: Icons.cake,
        label: 'Pastries',
        color: AppTheme.secondaryBrown,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Categories',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return _buildCategoryCard(context, categories[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryItem category) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to category page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening ${category.label}'),
              backgroundColor: category.color,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: category.color.withValues(alpha:0.3),
                  width: 1,
                ),
              ),
              child: Icon(category.icon, color: category.color, size: 28),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                category.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data model for category items
class CategoryItem {
  final IconData icon;
  final String label;
  final Color color;

  CategoryItem({required this.icon, required this.label, required this.color});
}
