import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Category navigation widget with expandable categories
class CategoryNavigation extends StatefulWidget {
  const CategoryNavigation({super.key});

  @override
  State<CategoryNavigation> createState() => _CategoryNavigationState();
}

class _CategoryNavigationState extends State<CategoryNavigation> {
  final Map<String, bool> _expandedCategories = {};

  final List<CategoryItem> _categories = [
    CategoryItem(
      title: 'Coffee Beans',
      icon: Icons.coffee,
      subcategories: ['Arabica', 'Robusta', 'Blends'],
    ),
    CategoryItem(
      title: 'Brewing Methods',
      icon: Icons.local_cafe,
      subcategories: ['Drip', 'French Press', 'Espresso'],
    ),
    CategoryItem(
      title: 'Accessories',
      icon: Icons.build,
      subcategories: ['Grinders', 'Mugs', 'Filters'],
    ),
    CategoryItem(
      title: 'Gifts',
      icon: Icons.card_giftcard,
      subcategories: ['Gift Sets', 'Subscriptions'],
    ),
  ];

  final List<SectionItem> _sections = [
    SectionItem(
      title: 'Featured Products',
      icon: Icons.star,
      type: SectionType.featured,
    ),
    SectionItem(
      title: 'Best Sellers',
      icon: Icons.trending_up,
      type: SectionType.bestSellers,
    ),
    SectionItem(
      title: 'New Arrivals',
      icon: Icons.new_releases,
      type: SectionType.newArrivals,
    ),
  ];

  final List<QuickActionItem> _quickActions = [
    QuickActionItem(
      title: 'Store Locator',
      icon: Icons.location_on,
      action: QuickAction.storeLocator,
    ),
    QuickActionItem(
      title: 'Brewing Guide',
      icon: Icons.menu_book,
      action: QuickAction.brewingGuide,
    ),
    QuickActionItem(
      title: 'Subscription',
      icon: Icons.repeat,
      action: QuickAction.subscription,
    ),
    QuickActionItem(
      title: 'Contact Us',
      icon: Icons.contact_support,
      action: QuickAction.contactUs,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceWhite,
      child: Column(
        children: [
          // Categories Section
          _buildSectionHeader(context, 'Categories', Icons.category),
          ..._categories.map(
            (category) => _buildCategoryItem(context, category),
          ),

          // Divider
          Divider(
            color: AppTheme.primaryLightBrown.withValues(alpha:0.3),
            height: 1,
          ),

          // Featured Sections
          _buildSectionHeader(context, 'Discover', Icons.explore),
          ..._sections.map((section) => _buildSectionItem(context, section)),

          // Divider
          Divider(
            color: AppTheme.primaryLightBrown.withValues(alpha:0.3),
            height: 1,
          ),

          // Quick Actions
          _buildSectionHeader(context, 'Quick Actions', Icons.flash_on),
          ..._quickActions.map(
            (action) => _buildQuickActionItem(context, action),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryBrown),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, CategoryItem category) {
    final isExpanded = _expandedCategories[category.title] ?? false;

    return Column(
      children: [
        ListTile(
          leading: Icon(category.icon, color: AppTheme.primaryBrown),
          title: Text(
            category.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            color: AppTheme.primaryBrown,
          ),
          onTap: () {
            setState(() {
              _expandedCategories[category.title] = !isExpanded;
            });
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 4,
          ),
        ),
        if (isExpanded)
          ...category.subcategories.map(
            (subcategory) => _buildSubcategoryItem(context, subcategory),
          ),
      ],
    );
  }

  Widget _buildSubcategoryItem(BuildContext context, String subcategory) {
    return Container(
      margin: const EdgeInsets.only(left: 56, right: 24),
      child: ListTile(
        title: Text(
          subcategory,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textMedium,
            fontWeight: FontWeight.w400,
          ),
        ),
        onTap: () {
          // TODO: Navigate to subcategory page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exploring $subcategory'),
              backgroundColor: AppTheme.primaryBrown,
            ),
          );
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        dense: true,
      ),
    );
  }

  Widget _buildSectionItem(BuildContext context, SectionItem section) {
    return ListTile(
      leading: Icon(section.icon, color: AppTheme.accentAmber),
      title: Text(
        section.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.textDark,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        // TODO: Navigate to section page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing ${section.title}'),
            backgroundColor: AppTheme.primaryBrown,
          ),
        );
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Widget _buildQuickActionItem(BuildContext context, QuickActionItem action) {
    return ListTile(
      leading: Icon(action.icon, color: AppTheme.primaryBrown),
      title: Text(
        action.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.textDark,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        // TODO: Handle quick action
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${action.title}'),
            backgroundColor: AppTheme.primaryBrown,
          ),
        );
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}

/// Data models for navigation items
class CategoryItem {
  final String title;
  final IconData icon;
  final List<String> subcategories;

  CategoryItem({
    required this.title,
    required this.icon,
    required this.subcategories,
  });
}

class SectionItem {
  final String title;
  final IconData icon;
  final SectionType type;

  SectionItem({required this.title, required this.icon, required this.type});
}

class QuickActionItem {
  final String title;
  final IconData icon;
  final QuickAction action;

  QuickActionItem({
    required this.title,
    required this.icon,
    required this.action,
  });
}

enum SectionType { featured, bestSellers, newArrivals }

enum QuickAction { storeLocator, brewingGuide, subscription, contactUs }
