import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/coffee_product_model.dart';
import '../../../coffee/presentation/widgets/coffee_product_card.dart';
import '../../../coffee/presentation/pages/product_detail_page.dart';
import '../../../coffee/presentation/providers/coffee_provider.dart';

/// SearchResultsPage displays filtered and searched coffee products
class SearchResultsPage extends StatefulWidget {
  final String initialQuery;
  final String? category;
  final List<CoffeeProductModel>? initialResults;

  const SearchResultsPage({
    super.key,
    this.initialQuery = '',
    this.category,
    this.initialResults,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<CoffeeProductModel> _searchResults = [];
  bool _isLoading = true;
  String _sortBy = 'relevance';
  RangeValues _priceRange = const RangeValues(10, 100);
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedOrigins = {};

  // Available filter options
  final List<String> _categories = [
    'Espresso',
    'Arabica',
    'Robusta',
    'Cold Brew',
    'Traditional',
    'Specialty',
    'Organic',
  ];

  final List<String> _origins = [
    'Yemen',
    'Ethiopia',
    'Colombia',
    'Brazil',
    'Jamaica',
    'Guatemala',
    'UAE',
  ];

  final List<String> _sortOptions = [
    'relevance',
    'price_low',
    'price_high',
    'name',
    'rating',
    'popularity',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    if (widget.category != null) {
      _selectedCategories.add(widget.category!);
    }
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _isLoading = true;
    });

    // Load products from CoffeeProvider instead of hardcoded data
    final coffeeProvider = Provider.of<CoffeeProvider>(context, listen: false);

    if (widget.initialResults != null) {
      // Use provided initial results
      _searchResults = widget.initialResults!;
      setState(() {
        _isLoading = false;
      });
    } else if (coffeeProvider.coffees.isEmpty) {
      // Load from API if not already loaded
      coffeeProvider
          .loadCoffees()
          .then((_) {
            _performSearch();
            setState(() {
              _isLoading = false;
            });
          })
          .catchError((error) {
            setState(() {
              _isLoading = false;
            });
          });
    } else {
      // Use already loaded products
      _performSearch();
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _performSearch() {
    String query = _searchController.text.toLowerCase().trim();

    // Get products from CoffeeProvider instead of hardcoded _allProducts
    final coffeeProvider = Provider.of<CoffeeProvider>(context, listen: false);
    List<CoffeeProductModel> allProducts = coffeeProvider.coffees;

    List<CoffeeProductModel> results = allProducts.where((product) {
      // Text search
      bool matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          product.origin.toLowerCase().contains(query) ||
          product.categories.any((cat) => cat.toLowerCase().contains(query));

      // Category filter
      bool matchesCategory =
          _selectedCategories.isEmpty ||
          product.categories.any((cat) => _selectedCategories.contains(cat));

      // Origin filter
      bool matchesOrigin =
          _selectedOrigins.isEmpty || _selectedOrigins.contains(product.origin);

      // Price filter
      bool matchesPrice =
          product.price >= _priceRange.start &&
          product.price <= _priceRange.end;

      return matchesQuery && matchesCategory && matchesOrigin && matchesPrice;
    }).toList();

    // Apply sorting
    _sortResults(results);

    setState(() {
      _searchResults = results;
    });
  }

  void _sortResults(List<CoffeeProductModel> results) {
    switch (_sortBy) {
      case 'price_low':
        results.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        results.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'name':
        results.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'rating':
        results.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'popularity':
        results.sort((a, b) => b.isFeatured ? 1 : -1);
        break;
      case 'relevance':
      default:
        // Keep original order for relevance
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search Results',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: _showFilterSheet,
              tooltip: 'Filter results',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Results Header
          _buildResultsHeader(),

          // Results
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _searchResults.isEmpty
                ? _buildEmptyState()
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.white,
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (value) => _performSearch(),
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search for coffee...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.primaryBrown,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade600),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBrown.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: _performSearch,
              tooltip: 'Search',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCream,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search_outlined, size: 20, color: AppTheme.primaryBrown),
          const SizedBox(width: 8),
          Text(
            '${_searchResults.length} results found',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                _performSearch();
              },
              items: _sortOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(
                    _getSortLabel(option),
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              underline: Container(),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppTheme.primaryBrown,
                size: 20,
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primaryBrown),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: AppTheme.primaryBrown,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your search terms or filters',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMedium),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _selectedCategories.clear();
                      _selectedOrigins.clear();
                      _priceRange = const RangeValues(10, 100);
                    });
                    _performSearch();
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Filters'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryBrown),
                    foregroundColor: AppTheme.primaryBrown,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/coffee',
                      (route) => route.settings.name == '/home',
                    );
                  },
                  icon: const Icon(Icons.coffee),
                  label: const Text('Browse All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(product: product),
              ),
            );
          },
          child: CoffeeProductCard(coffeeProduct: product),
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          // Price Range
                          _buildPriceRangeFilter(setModalState),
                          const SizedBox(height: 24),

                          // Categories
                          _buildCategoryFilter(setModalState),
                          const SizedBox(height: 24),

                          // Origins
                          _buildOriginFilter(setModalState),
                        ],
                      ),
                    ),

                    // Apply Filters Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _performSearch();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBrown,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPriceRangeFilter(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 200,
          divisions: 20,
          labels: RangeLabels(
            '${AppConstants.currencySymbol}${_priceRange.start.round()}',
            '${AppConstants.currencySymbol}${_priceRange.end.round()}',
          ),
          activeColor: AppTheme.primaryBrown,
          onChanged: (values) {
            setModalState(() {
              _priceRange = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${AppConstants.currencySymbol}${_priceRange.start.round()}',
              style: const TextStyle(color: AppTheme.textMedium),
            ),
            Text(
              '${AppConstants.currencySymbol}${_priceRange.end.round()}',
              style: const TextStyle(color: AppTheme.textMedium),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setModalState(() {
                  if (selected) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
              },
              selectedColor: AppTheme.primaryBrown.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryBrown,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOriginFilter(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Origin',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _origins.map((origin) {
            final isSelected = _selectedOrigins.contains(origin);
            return FilterChip(
              label: Text(origin),
              selected: isSelected,
              onSelected: (selected) {
                setModalState(() {
                  if (selected) {
                    _selectedOrigins.add(origin);
                  } else {
                    _selectedOrigins.remove(origin);
                  }
                });
              },
              selectedColor: AppTheme.primaryBrown.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryBrown,
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'price_low':
        return 'Price: Low to High';
      case 'price_high':
        return 'Price: High to Low';
      case 'name':
        return 'Name: A to Z';
      case 'rating':
        return 'Rating: High to Low';
      case 'popularity':
        return 'Most Popular';
      case 'relevance':
      default:
        return 'Relevance';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
