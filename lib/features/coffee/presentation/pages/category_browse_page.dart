import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coffee_provider.dart';
import '../../../../data/models/coffee_product_model.dart';
import '../../../../core/theme/app_theme.dart';

class CategoryBrowsePage extends StatefulWidget {
  final String? initialCategory;

  const CategoryBrowsePage({super.key, this.initialCategory});

  @override
  State<CategoryBrowsePage> createState() => _CategoryBrowsePageState();
}

class _CategoryBrowsePageState extends State<CategoryBrowsePage> {
  String? _selectedCategory;
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view, 'color': AppTheme.primaryBrown},
    {
      'name': 'Espresso',
      'icon': Icons.local_cafe,
      'color': AppTheme.primaryBrown,
    },
    {'name': 'Arabica', 'icon': Icons.coffee, 'color': AppTheme.primaryBrown},
    {
      'name': 'Robusta',
      'icon': Icons.coffee_maker,
      'color': AppTheme.primaryBrown,
    },
    {'name': 'Specialty', 'icon': Icons.star, 'color': Colors.amber.shade800},
    {'name': 'Organic', 'icon': Icons.eco, 'color': Colors.green.shade700},
    {
      'name': 'Dark Roast',
      'icon': Icons.nights_stay,
      'color': AppTheme.primaryBrown,
    },
    {
      'name': 'Medium Roast',
      'icon': Icons.wb_twilight,
      'color': AppTheme.primaryLightBrown,
    },
    {
      'name': 'Light Roast',
      'icon': Icons.wb_sunny,
      'color': Colors.orange.shade300,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse by Category'), elevation: 0),
      body: Column(
        children: [
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
                if (coffeeProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (coffeeProvider.error != null) {
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
                        ),
                      ],
                    ),
                  );
                }

                // Filter products by category
                List<CoffeeProductModel> filteredProducts =
                    _selectedCategory == 'All'
                    ? coffeeProvider.coffees
                    : coffeeProvider.coffees.where((product) {
                        // Check if product's categories contain the selected category
                        return product.categories.any(
                              (cat) =>
                                  cat.toLowerCase() ==
                                  _selectedCategory?.toLowerCase(),
                            ) ||
                            product.name.toLowerCase().contains(
                              _selectedCategory?.toLowerCase() ?? '',
                            );
                      }).toList();

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
                          'No products in this category',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try selecting a different category',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
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
                          '\$${product.price.toStringAsFixed(2)}',
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
