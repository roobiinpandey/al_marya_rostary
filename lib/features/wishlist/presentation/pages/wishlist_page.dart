import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/coffee_product_model.dart';
import '../../../coffee/presentation/pages/product_detail_page.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<CoffeeProductModel> _favorites = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'name'; // name, price, dateAdded

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    // TODO: Load favorites from API or local storage
    // Mock data for now
    setState(() {
      _favorites = [
        CoffeeProductModel(
          id: '1',
          name: 'Emirati Qahwa',
          description: 'Traditional cardamom coffee',
          price: 25.00,
          imageUrl:
              'https://via.placeholder.com/300x300/8B4513/FFFFFF?text=Emirati+Qahwa',
          categories: ['Traditional'],
          rating: 4.8,
          origin: 'UAE',
          roastLevel: 'Dark',
          stock: 50,
        ),
        CoffeeProductModel(
          id: '2',
          name: 'Cold Brew',
          description: 'Smooth and refreshing cold coffee',
          price: 18.00,
          imageUrl:
              'https://via.placeholder.com/300x300/8B4513/FFFFFF?text=Cold+Brew',
          categories: ['Cold Drinks'],
          rating: 4.5,
          origin: 'Colombia',
          roastLevel: 'Medium',
          stock: 30,
        ),
        CoffeeProductModel(
          id: '3',
          name: 'Arabic Mocha',
          description: 'Rich chocolate and coffee blend',
          price: 22.00,
          imageUrl:
              'https://via.placeholder.com/300x300/8B4513/FFFFFF?text=Arabic+Mocha',
          categories: ['Specialty'],
          rating: 4.7,
          origin: 'Yemen',
          roastLevel: 'Dark',
          stock: 0, // Out of stock
        ),
      ];
      _isLoading = false;
    });
  }

  List<CoffeeProductModel> get _filteredAndSortedFavorites {
    List<CoffeeProductModel> filtered = _favorites;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                item.categories.any(
                  (cat) =>
                      cat.toLowerCase().contains(_searchQuery.toLowerCase()),
                ),
          )
          .toList();
    }

    // Sort
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'dateAdded':
        // Mock date added sorting - in real app would be stored
        filtered.sort((a, b) => a.id.compareTo(b.id));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Wishlist',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (String value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'price', child: Text('Sort by Price')),
              const PopupMenuItem(
                value: 'dateAdded',
                child: Text('Sort by Date Added'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceWhite,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search wishlist...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.primaryBrown,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryBrown),
                ),
                filled: true,
                fillColor: AppTheme.backgroundCream,
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryBrown,
                    ),
                  )
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final filteredFavorites = _filteredAndSortedFavorites;

    if (filteredFavorites.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredFavorites.length,
      itemBuilder: (context, index) {
        return _buildFavoriteCard(filteredFavorites[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.favorite_border,
            size: 80,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No favorites found' : 'No favorites yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Start adding items to your wishlist',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_searchQuery.isNotEmpty) {
                setState(() {
                  _searchQuery = '';
                });
              } else {
                Navigator.pushNamed(context, '/coffee');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _searchQuery.isNotEmpty ? 'Clear Search' : 'Browse Coffee',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(CoffeeProductModel item) {
    final isAvailable = item.stock > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToProductDetail(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.backgroundCream,
                    child: const Icon(
                      Icons.coffee,
                      color: AppTheme.primaryBrown,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.backgroundCream,
                    child: const Icon(
                      Icons.coffee,
                      color: AppTheme.primaryBrown,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                          ),
                        ),
                        if (!isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Out of Stock',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.categories.isNotEmpty
                                ? item.categories.first
                                : 'Coffee',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryBrown,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.star, size: 14, color: AppTheme.accentAmber),
                        const SizedBox(width: 2),
                        Text(
                          item.rating.toString(),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textMedium,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${item.origin}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textLight),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Text(
                          '${AppConstants.currencySymbol}${item.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBrown,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          '${item.roastLevel} Roast',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Action Buttons
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () => _removeFromFavorites(item),
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      tooltip: 'Remove from wishlist',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isAvailable)
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () => _addToCart(item),
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          color: AppTheme.primaryBrown,
                        ),
                        tooltip: 'Add to cart',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToProductDetail(CoffeeProductModel item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ProductDetailPage(product: item)),
    );
  }

  void _removeFromFavorites(CoffeeProductModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Wishlist'),
        content: Text(
          'Are you sure you want to remove "${item.name}" from your wishlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _favorites.removeWhere((fav) => fav.id == item.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} removed from wishlist'),
                  backgroundColor: Colors.orange,
                  action: SnackBarAction(
                    label: 'Undo',
                    textColor: Colors.white,
                    onPressed: () {
                      setState(() {
                        _favorites.add(item);
                      });
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _addToCart(CoffeeProductModel item) {
    // TODO: Implement add to cart functionality with CartProvider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),
      ),
    );
  }
}
