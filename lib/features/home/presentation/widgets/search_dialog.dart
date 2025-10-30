import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Popular search suggestions
  final List<String> _popularSearches = [
    'Arabica Coffee',
    'Espresso',
    'Cold Brew',
    'Turkish Coffee',
    'Premium Blends',
    'Organic Coffee',
    'Ethiopian Coffee',
    'Colombian Coffee',
  ];

  // Recent searches (in real app, get from shared preferences)
  final List<String> _recentSearches = [
    'Cappuccino',
    'Dark Roast',
    'Coffee Beans',
  ];

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with search field
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBrown,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Search for coffee, accessories...',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (query) => _performSearch(query),
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recent Searches
                    if (_recentSearches.isNotEmpty) ...[
                      _buildSectionHeader('Recent Searches', Icons.history),
                      const SizedBox(height: 12),
                      _buildSearchChips(_recentSearches, isRecent: true),
                      const SizedBox(height: 24),
                    ],

                    // Popular Searches
                    _buildSectionHeader('Popular Searches', Icons.trending_up),
                    const SizedBox(height: 12),
                    _buildSearchChips(_popularSearches),
                    const SizedBox(height: 24),

                    // Quick Categories
                    _buildSectionHeader('Browse Categories', Icons.category),
                    const SizedBox(height: 12),
                    _buildCategoryOptions(),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryBrown),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppTheme.primaryBrown),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _performSearch(_searchController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Search'),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryBrown),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchChips(List<String> searches, {bool isRecent = false}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: searches.map((search) {
        return ActionChip(
          label: Text(search),
          onPressed: () => _performSearch(search),
          backgroundColor: isRecent
              ? Colors.blue.withValues(alpha: 0.1)
              : AppTheme.primaryBrown.withValues(alpha: 0.1),
          labelStyle: TextStyle(
            color: isRecent ? Colors.blue : AppTheme.primaryBrown,
            fontWeight: FontWeight.w500,
          ),
          avatar: Icon(
            isRecent ? Icons.history : Icons.trending_up,
            size: 16,
            color: isRecent ? Colors.blue : AppTheme.primaryBrown,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryOptions() {
    final categories = [
      {'name': 'Coffee Beans', 'icon': Icons.coffee, 'color': Colors.brown},
      {'name': 'Espresso', 'icon': Icons.local_cafe, 'color': Colors.orange},
      {'name': 'Cold Brew', 'icon': Icons.ac_unit, 'color': Colors.blue},
      {'name': 'Accessories', 'icon': Icons.settings, 'color': Colors.grey},
      {'name': 'Gift Sets', 'icon': Icons.card_giftcard, 'color': Colors.pink},
      {'name': 'Subscription', 'icon': Icons.star, 'color': Colors.amber},
    ];

    return Column(
      children: categories.map((category) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (category['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                category['icon'] as IconData,
                color: category['color'] as Color,
                size: 20,
              ),
            ),
            title: Text(
              category['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => _performSearch(category['name'] as String),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      return;
    }

    // Close the dialog
    Navigator.of(context).pop();

    // Navigate to search results page with the query
    Navigator.of(context).pushNamed('/search', arguments: query.trim());
  }
}
