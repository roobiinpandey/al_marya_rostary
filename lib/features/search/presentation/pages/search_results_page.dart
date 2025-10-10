import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/coffee_product_model.dart';
import '../../../coffee/presentation/widgets/coffee_product_card.dart';
import '../../../coffee/presentation/pages/product_detail_page.dart';

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
  List<CoffeeProductModel> _allProducts = [];
  bool _isLoading = true;
  String _sortBy = 'relevance';
  RangeValues _priceRange = const RangeValues(10, 100);
  Set<String> _selectedCategories = {};
  Set<String> _selectedOrigins = {};

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

  void _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Replace with actual API call
    // Mock data for now
    await Future.delayed(const Duration(milliseconds: 500));

    _allProducts = [
      CoffeeProductModel(
        id: '1',
        name: 'Ethiopian Single Origin',
        description: 'Premium Ethiopian coffee with floral notes',
        price: 45.0,
        imageUrl:
            'https://via.placeholder.com/300x300/8B4513/FFFFFF?text=Ethiopian',
        origin: 'Ethiopia',
        categories: ['Arabica'],
        rating: 4.8,
        roastLevel: 'Medium',
        isFeatured: true,
        stock: 100,
      ),
      CoffeeProductModel(
        id: '2',
        name: 'Yemeni Mocha',
        description: 'Traditional Yemeni coffee with chocolate undertones',
        price: 55.0,
        imageUrl:
            'https://via.placeholder.com/300x300/8B4513/FFFFFF?text=Yemeni',
        origin: 'Yemen',
        categories: ['Traditional'],
        rating: 4.9,
        roastLevel: 'Dark',
        isFeatured: true,
        stock: 50,
      ),
      CoffeeProductModel(
        id: '3',
        name: 'Colombian Supremo',
        description: 'Rich Colombian coffee with balanced acidity',
        price: 40.0,
        imageUrl:
            'https://via.placeholder.com/300x300/8B4513/FFFFFF?text=Colombian',
        origin: 'Colombia',
        categories: ['Arabica'],
        rating: 4.6,
        roastLevel: 'Medium',
        isFeatured: false,
        stock: 75,
      ),
      CoffeeProductModel(
        id: '4',
        name: 'Espresso Blend',
        description: 'Perfect espresso blend for your morning shot',
        price: 38.0,
        imageUrl:
            'https://via.placeholder.com/300x300/8B4513/FFFFFF?text=Espresso',
        origin: 'Brazil',
        categories: ['Espresso'],
        rating: 4.5,
        roastLevel: 'Dark',
        isFeatured: false,
        stock: 120,
      ),
      CoffeeProductModel(
        id: '5',
        name: 'Cold Brew Special',
        description: 'Smooth cold brew coffee concentrate',
        price: 32.0,
        imageUrl:
            'https://via.placeholder.com/300x300/8B4513/FFFFFF?text=Cold+Brew',
        origin: 'Guatemala',
        categories: ['Cold Brew'],
        rating: 4.4,
        roastLevel: 'Medium',
        isFeatured: false,
        stock: 0,
      ),
    ];

    if (widget.initialResults != null) {
      _searchResults = widget.initialResults!;
    } else {
      _performSearch();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _performSearch() {
    String query = _searchController.text.toLowerCase().trim();

    List<CoffeeProductModel> results = _allProducts.where((product) {
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
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
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
      color: AppTheme.surfaceWhite,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: (value) => _performSearch(),
              decoration: InputDecoration(
                hintText: 'Search for coffee...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.backgroundCream,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryBrown),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: _performSearch,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.backgroundCream,
      child: Row(
        children: [
          Text(
            '${_searchResults.length} results found',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMedium),
          ),
          const Spacer(),
          DropdownButton<String>(
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
                child: Text(_getSortLabel(option)),
              );
            }).toList(),
            underline: Container(),
            icon: const Icon(Icons.arrow_drop_down),
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
            Icon(Icons.search_off, size: 64, color: AppTheme.textLight),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms or filters',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMedium),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _selectedCategories.clear();
                      _selectedOrigins.clear();
                      _priceRange = const RangeValues(10, 100);
                    });
                    _performSearch();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryBrown),
                  ),
                  child: const Text('Clear Filters'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/coffee',
                      (route) => route.settings.name == '/home',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrown,
                  ),
                  child: const Text('Browse All'),
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
