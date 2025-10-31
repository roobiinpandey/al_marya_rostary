import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class BrewingMethodFilterBar extends StatelessWidget {
  final List<String> selectedCategories;
  final List<String> selectedDifficulties;
  final String? searchQuery;
  final Function(List<String>) onCategoriesChanged;
  final Function(List<String>) onDifficultiesChanged;
  final Function(String?) onSearchChanged;
  final VoidCallback? onClearFilters;

  const BrewingMethodFilterBar({
    super.key,
    required this.selectedCategories,
    required this.selectedDifficulties,
    this.searchQuery,
    required this.onCategoriesChanged,
    required this.onDifficultiesChanged,
    required this.onSearchChanged,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    // Simple language detection - in a real app you'd use proper localization
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final hasActiveFilters =
        selectedCategories.isNotEmpty ||
        selectedDifficulties.isNotEmpty ||
        (searchQuery?.isNotEmpty ?? false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          _buildSearchBar(context, isArabic),
          const SizedBox(height: 12),

          // Filter Chips Row
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        context,
                        isArabic ? 'الفئات' : 'Categories',
                        Icons.category,
                        selectedCategories.isNotEmpty,
                        () => _showCategoriesDialog(context, isArabic),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        isArabic ? 'الصعوبة' : 'Difficulty',
                        Icons.bar_chart,
                        selectedDifficulties.isNotEmpty,
                        () => _showDifficultyDialog(context, isArabic),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        isArabic ? 'الوقت' : 'Time',
                        Icons.access_time,
                        false,
                        () => _showTimeDialog(context, isArabic),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasActiveFilters) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onClearFilters,
                  icon: Icon(Icons.clear_all, color: AppTheme.primaryBrown),
                  tooltip: isArabic ? 'مسح الفلاتر' : 'Clear filters',
                ),
              ],
            ],
          ),

          // Active Filters
          if (hasActiveFilters) ...[
            const SizedBox(height: 12),
            _buildActiveFilters(context, isArabic),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: isArabic
              ? 'ابحث عن طريقة تحضير...'
              : 'Search brewing methods...',
          prefixIcon: Icon(Icons.search, color: AppTheme.textMedium),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          hintStyle: TextStyle(color: AppTheme.textMedium),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? Colors.white : AppTheme.primaryBrown,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isActive,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryBrown,
      backgroundColor: Colors.white,
      side: BorderSide(color: AppTheme.primaryBrown.withOpacity(0.3)),
      labelStyle: TextStyle(
        color: isActive ? Colors.white : AppTheme.primaryBrown,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildActiveFilters(BuildContext context, bool isArabic) {
    final activeFilters = <Widget>[];

    // Add selected categories
    for (final category in selectedCategories) {
      activeFilters.add(
        _buildActiveFilterChip(category, () {
          final updated = List<String>.from(selectedCategories)
            ..remove(category);
          onCategoriesChanged(updated);
        }),
      );
    }

    // Add selected difficulties
    for (final difficulty in selectedDifficulties) {
      activeFilters.add(
        _buildActiveFilterChip(difficulty, () {
          final updated = List<String>.from(selectedDifficulties)
            ..remove(difficulty);
          onDifficultiesChanged(updated);
        }),
      );
    }

    if (activeFilters.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'الفلاتر النشطة:' : 'Active filters:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textMedium,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: activeFilters),
      ],
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: AppTheme.accentAmber.withOpacity(0.1),
      side: BorderSide(color: AppTheme.accentAmber.withOpacity(0.3)),
      labelStyle: TextStyle(color: AppTheme.accentAmber, fontSize: 12),
    );
  }

  void _showCategoriesDialog(BuildContext context, bool isArabic) {
    final categories = [
      {'en': 'Espresso-based', 'ar': 'مبني على الإسبريسو'},
      {'en': 'Filter Coffee', 'ar': 'قهوة مفلترة'},
      {'en': 'Cold Brew', 'ar': 'قهوة باردة'},
      {'en': 'Traditional', 'ar': 'تقليدية'},
      {'en': 'Specialty', 'ar': 'مختصة'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'اختر الفئات' : 'Select Categories'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: categories.map((category) {
              final categoryName = isArabic ? category['ar']! : category['en']!;
              final isSelected = selectedCategories.contains(categoryName);

              return CheckboxListTile(
                title: Text(categoryName),
                value: isSelected,
                onChanged: (bool? value) {
                  final updated = List<String>.from(selectedCategories);
                  if (value == true) {
                    updated.add(categoryName);
                  } else {
                    updated.remove(categoryName);
                  }
                  onCategoriesChanged(updated);
                },
                activeColor: AppTheme.primaryBrown,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              isArabic ? 'تم' : 'Done',
              style: TextStyle(color: AppTheme.primaryBrown),
            ),
          ),
        ],
      ),
    );
  }

  void _showDifficultyDialog(BuildContext context, bool isArabic) {
    final difficulties = [
      {'en': 'Beginner', 'ar': 'مبتدئ'},
      {'en': 'Intermediate', 'ar': 'متوسط'},
      {'en': 'Advanced', 'ar': 'متقدم'},
      {'en': 'Expert', 'ar': 'خبير'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'اختر مستوى الصعوبة' : 'Select Difficulty'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: difficulties.map((difficulty) {
              final difficultyName = isArabic
                  ? difficulty['ar']!
                  : difficulty['en']!;
              final isSelected = selectedDifficulties.contains(difficultyName);

              return CheckboxListTile(
                title: Text(difficultyName),
                value: isSelected,
                onChanged: (bool? value) {
                  final updated = List<String>.from(selectedDifficulties);
                  if (value == true) {
                    updated.add(difficultyName);
                  } else {
                    updated.remove(difficultyName);
                  }
                  onDifficultiesChanged(updated);
                },
                activeColor: AppTheme.primaryBrown,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              isArabic ? 'تم' : 'Done',
              style: TextStyle(color: AppTheme.primaryBrown),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimeDialog(BuildContext context, bool isArabic) {
    // Placeholder for time filter dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'فلتر الوقت' : 'Time Filter'),
        content: Text(
          isArabic ? 'سيتم إضافة فلتر الوقت قريباً' : 'Time filter coming soon',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              isArabic ? 'موافق' : 'OK',
              style: TextStyle(color: AppTheme.primaryBrown),
            ),
          ),
        ],
      ),
    );
  }
}
