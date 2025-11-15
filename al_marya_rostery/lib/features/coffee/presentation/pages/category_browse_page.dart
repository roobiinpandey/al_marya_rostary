import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coffee_provider.dart';
import '../../../../data/models/coffee_product_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

/// Unified Coffee Products Page with Category Filtering and Search
/// This page replaces all separate regional pages (Asia, Africa, Latin America, etc.)
/// Products are filtered by category dynamically instead of having separate pages
class CategoryBrowsePage extends StatefulWidget {
  final String? initialCategory;

  const CategoryBrowsePage({super.key, this.initialCategory});

  @override
  State<CategoryBrowsePage> createState() => _CategoryBrowsePageState();
}

class _CategoryBrowsePageState extends State<CategoryBrowsePage> {
  String? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view, 'color': AppTheme.primaryBrown},

    // Origin-based categories
    {
      'name': 'Asia',
      'icon': Icons.public,
      'color': const Color(0xFF8B4513), // Saddle Brown
    },
    {
      'name': 'Africa',
      'icon': Icons.terrain,
      'color': const Color(0xFFCD853F), // Peru
    },
    {
      'name': 'Latin America',
      'icon': Icons.language,
      'color': const Color(0xFFA0522D), // Sienna
    },

    // Premium category
    {
      'name': 'Premium',
      'icon': Icons.diamond,
      'color': const Color(0xFFDAA520), // Goldenrod
    },

    // Roast levels
    {
      'name': 'Dark Roast',
      'icon': Icons.nights_stay,
      'color': const Color(0xFF2F1B14), // Very Dark Brown
    },
    {
      'name': 'Medium Dark Roast',
      'icon': Icons.wb_twilight,
      'color': const Color(0xFF5D4037), // Brown 700
    },
    {
      'name': 'Medium Roast',
      'icon': Icons.wb_sunny,
      'color': const Color(0xFF8D6E63), // Brown 400
    },

    // Additional categories
    {
      'name': 'Single Origin',
      'icon': Icons.place,
      'color': const Color(0xFF795548), // Brown 500
    },
    {
      'name': 'Blends',
      'icon': Icons.grain,
      'color': const Color(0xFF6D4C41), // Brown 600
    },
    {
      'name': 'Organic',
      'icon': Icons.eco,
      'color': const Color(0xFF689F38), // Light Green 700
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
    // Load products when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CoffeeProvider>(context, listen: false);
      if (provider.coffees.isEmpty && !provider.isLoading) {
        provider.loadCoffees();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedCategory == 'All'
              ? 'All Coffee Products'
              : '$_selectedCategory Coffee',
        ),
        elevation: 0,
        actions: [
          // Product count badge
          Consumer<CoffeeProvider>(
            builder: (context, provider, _) {
              final count = _getFilteredProducts(provider).length;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Chip(
                    label: Text(
                      '$count items',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: AppTheme.primaryBrown.withValues(
                      alpha: 0.2,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search coffee products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Category chips
          Container(
            height: 60,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['name'];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : category['color'],
                        ),
                        const SizedBox(width: 6),
                        Text(category['name'] as String),
                      ],
                    ),
                    selectedColor: category['color'] as Color,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category['name'] as String;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Products grid
          Expanded(
            child: Consumer<CoffeeProvider>(
              builder: (context, coffeeProvider, child) {
                if (coffeeProvider.isLoading &&
                    coffeeProvider.coffees.isEmpty) {
                  return _buildShimmerLoading();
                }

                if (coffeeProvider.error != null &&
                    coffeeProvider.coffees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          coffeeProvider.error!,
                          style: TextStyle(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => coffeeProvider.loadCoffees(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBrown,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Get filtered products
                List<CoffeeProductModel> filteredProducts =
                    _getFilteredProducts(coffeeProvider);

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No products found for "$_searchQuery"'
                              : 'No products in this category',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'Try selecting a different category',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty ||
                            _selectedCategory != 'All')
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                  _selectedCategory = 'All';
                                });
                              },
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Clear Filters'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBrown,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Filter products by category and search query
  List<CoffeeProductModel> _getFilteredProducts(CoffeeProvider provider) {
    List<CoffeeProductModel> filtered = provider.coffees;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((product) {
        return product.categories.any(
              (cat) => cat.toLowerCase() == _selectedCategory?.toLowerCase(),
            ) ||
            product.roastLevel.toLowerCase().contains(
              _selectedCategory?.toLowerCase() ?? '',
            );
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query) ||
            product.origin.toLowerCase().contains(query) ||
            product.roastLevel.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  /// Shimmer loading effect
  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Expanded(flex: 3, child: Container(color: Colors.grey.shade300)),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 80,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard(CoffeeProductModel product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/product', arguments: product);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade200),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.coffee,
                            size: 48,
                            color: Colors.grey.shade400,
                          );
                        },
                      )
                    : Icon(Icons.coffee, size: 48, color: Colors.grey.shade400),
              ),
            ),
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.origin,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${AppConstants.currencySymbol} ${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryBrown,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey.shade400,
                        ),
                      ],
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
}
