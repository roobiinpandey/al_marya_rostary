import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/gift_set_provider.dart';
import '../../../../data/models/gift_set_model.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../widgets/common/product_image_widget.dart';

class GiftSetsProductPage extends StatefulWidget {
  const GiftSetsProductPage({super.key});

  @override
  State<GiftSetsProductPage> createState() => _GiftSetsProductPageState();
}

class _GiftSetsProductPageState extends State<GiftSetsProductPage> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedOccasion;
  String? _selectedAudience;
  double? _minPrice;
  double? _maxPrice;
  bool _showFeaturedOnly = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Fetch gift sets when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GiftSetProvider>().fetchGiftSets();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Load more when scrolled to bottom
      context.read<GiftSetProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        title: const Text('Gift Sets'),
        backgroundColor: AppTheme.accentAmber,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Consumer<GiftSetProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.giftSets.isEmpty) {
            return const LoadingWidget(message: 'Loading gift sets...');
          }

          if (provider.error != null && provider.giftSets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading gift sets',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchGiftSets(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.giftSets.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Filter chips
              _buildFilterChips(provider),

              // Gift sets grid
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.fetchGiftSets(),
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount:
                        provider.giftSets.length +
                        (provider.hasMorePages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= provider.giftSets.length) {
                        // Loading indicator for pagination
                        return const Center(child: CircularProgressIndicator());
                      }

                      final giftSet = provider.giftSets[index];
                      return _buildGiftSetCard(giftSet);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(GiftSetProvider provider) {
    final chips = <Widget>[];

    if (_selectedOccasion != null) {
      chips.add(
        _buildFilterChip(
          'Occasion: $_selectedOccasion',
          () => setState(() {
            _selectedOccasion = null;
            provider.setOccasionFilter(null);
          }),
        ),
      );
    }

    if (_selectedAudience != null) {
      chips.add(
        _buildFilterChip(
          'Audience: $_selectedAudience',
          () => setState(() {
            _selectedAudience = null;
            provider.setAudienceFilter(null);
          }),
        ),
      );
    }

    if (_minPrice != null || _maxPrice != null) {
      final priceText = _minPrice != null && _maxPrice != null
          ? 'Price: \$${_minPrice!.toInt()}-\$${_maxPrice!.toInt()}'
          : _minPrice != null
          ? 'Min: \$${_minPrice!.toInt()}'
          : 'Max: \$${_maxPrice!.toInt()}';

      chips.add(
        _buildFilterChip(
          priceText,
          () => setState(() {
            _minPrice = null;
            _maxPrice = null;
            provider.setPriceRange(null, null);
          }),
        ),
      );
    }

    if (_showFeaturedOnly) {
      chips.add(
        _buildFilterChip(
          'Featured Only',
          () => setState(() {
            _showFeaturedOnly = false;
            provider.setFeaturedFilter(false);
          }),
        ),
      );
    }

    if (chips.isNotEmpty) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: TextButton(
            onPressed: () {
              setState(() {
                _selectedOccasion = null;
                _selectedAudience = null;
                _minPrice = null;
                _maxPrice = null;
                _showFeaturedOnly = false;
              });
              provider.clearFilters();
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppTheme.primaryBrown),
            ),
          ),
        ),
      );
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(scrollDirection: Axis.horizontal, children: chips),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        onDeleted: onRemove,
        backgroundColor: AppTheme.accentAmber.withValues(alpha: 0.1),
        deleteIconColor: AppTheme.primaryBrown,
      ),
    );
  }

  Widget _buildGiftSetCard(GiftSetModel giftSet) {
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';

    final name = isArabic
        ? giftSet.name['ar'] ?? giftSet.name['en'] ?? 'Unknown'
        : giftSet.name['en'] ?? giftSet.name['ar'] ?? 'Unknown';

    final description = isArabic
        ? giftSet.description['ar'] ?? giftSet.description['en'] ?? ''
        : giftSet.description['en'] ?? giftSet.description['ar'] ?? '';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openGiftSetDetails(giftSet),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with proper constraints
            Stack(
              children: [
                GiftSetImageWidget(
                  imageUrl: giftSet.primaryImageUrl.isNotEmpty
                      ? giftSet.primaryImageUrl
                      : null,
                  height: 120,
                ),
                // Featured badge
                if (giftSet.isFeatured)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Featured',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Popular badge
                if (giftSet.isPopular)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Popular',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Description
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Price and items count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          giftSet.formattedPrice,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryBrown,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentAmber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${giftSet.totalItems} items',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryBrown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Availability status
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: giftSet.availability.isAvailable
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        giftSet.availabilityStatus,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: giftSet.availability.isAvailable
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 80,
            color: AppTheme.textMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'No Gift Sets Found',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppTheme.textMedium),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or check back later',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<GiftSetProvider>().clearFilters();
              setState(() {
                _selectedOccasion = null;
                _selectedAudience = null;
                _minPrice = null;
                _maxPrice = null;
                _showFeaturedOnly = false;
              });
            },
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  void _openGiftSetDetails(GiftSetModel giftSet) {
    // Navigate to gift set detail page
    Navigator.pushNamed(context, '/gift-set-detail', arguments: giftSet.id);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: AppTheme.primaryBrown),
                    SizedBox(width: 8),
                    Text(
                      'Filter Gift Sets',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 32),

              // Filter content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildFilterSection(
                      'Occasion',
                      context.read<GiftSetProvider>().availableOccasions,
                      _selectedOccasion,
                      (value) => setState(() => _selectedOccasion = value),
                    ),
                    const SizedBox(height: 20),
                    _buildFilterSection(
                      'Target Audience',
                      context.read<GiftSetProvider>().availableAudiences,
                      _selectedAudience,
                      (value) => setState(() => _selectedAudience = value),
                    ),
                    const SizedBox(height: 20),
                    _buildPriceRangeSection(),
                    const SizedBox(height: 20),
                    _buildSwitchSection(),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedOccasion = null;
                                _selectedAudience = null;
                                _minPrice = null;
                                _maxPrice = null;
                                _showFeaturedOnly = false;
                              });
                            },
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final provider = context.read<GiftSetProvider>();
                              provider.setOccasionFilter(_selectedOccasion);
                              provider.setAudienceFilter(_selectedAudience);
                              provider.setPriceRange(_minPrice, _maxPrice);
                              provider.setFeaturedFilter(_showFeaturedOnly);
                              Navigator.pop(context);
                            },
                            child: const Text('Apply Filters'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) => onChanged(selected ? option : null),
              backgroundColor: Colors.grey[100],
              selectedColor: AppTheme.accentAmber.withValues(alpha: 0.3),
              checkmarkColor: AppTheme.primaryBrown,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Min Price',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _minPrice = double.tryParse(value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Max Price',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _maxPrice = double.tryParse(value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwitchSection() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Featured Only'),
          subtitle: const Text('Show only featured gift sets'),
          value: _showFeaturedOnly,
          onChanged: (value) => setState(() => _showFeaturedOnly = value),
          activeColor: AppTheme.accentAmber,
        ),
      ],
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Gift Sets'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter search terms...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (query) {
            Navigator.pop(context);
            if (query.isNotEmpty) {
              _performSearch(query);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    // For now, this could navigate to a search results page
    // or update the current filter to include search
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching for: $query'),
        backgroundColor: AppTheme.primaryBrown,
      ),
    );
  }
}
