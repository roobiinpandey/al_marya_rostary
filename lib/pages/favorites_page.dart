import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<FavoriteItem> _favorites = [];
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
        FavoriteItem(
          id: '1',
          name: 'Emirati Qahwa',
          description: 'Traditional cardamom coffee',
          price: 25.00,
          imageUrl:
              'https://via.placeholder.com/300x300/8B4513/FFFFFF?text=Emirati+Qahwa',
          category: 'Traditional',
          rating: 4.8,
          dateAdded: DateTime.now().subtract(const Duration(days: 2)),
          isAvailable: true,
        ),
        FavoriteItem(
          id: '2',
          name: 'Cold Brew',
          description: 'Smooth and refreshing cold coffee',
          price: 18.00,
          imageUrl:
              'https://via.placeholder.com/300x300/8B4513/FFFFFF?text=Cold+Brew',
          category: 'Cold Drinks',
          rating: 4.5,
          dateAdded: DateTime.now().subtract(const Duration(days: 5)),
          isAvailable: true,
        ),
        FavoriteItem(
          id: '3',
          name: 'Arabic Mocha',
          description: 'Rich chocolate and coffee blend',
          price: 22.00,
          imageUrl:
              'https://via.placeholder.com/300x300/8B4513/FFFFFF?text=Arabic+Mocha',
          category: 'Specialty',
          rating: 4.7,
          dateAdded: DateTime.now().subtract(const Duration(days: 1)),
          isAvailable: false,
        ),
      ];
      _isLoading = false;
    });
  }

  List<FavoriteItem> get _filteredAndSortedFavorites {
    List<FavoriteItem> filtered = _favorites;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                item.category.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
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
        filtered.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorites',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8B4513), // primaryBrown
        foregroundColor: Colors.white,
        elevation: 0,
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
      backgroundColor: const Color(0xFFF5F5F5), // backgroundLight
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search favorites...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8B4513)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF8B4513)),
                ),
                filled: true,
                fillColor: const Color(0xFFF9F9F9),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B4513)),
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
            size: 64,
            color: const Color(0xFF8C8C8C), // textLight
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No favorites found' : 'No favorites yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5D5D5D), // textMedium
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Start adding items to your favorites',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8C8C8C), // textLight
            ),
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
              backgroundColor: const Color(0xFF8B4513),
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

  Widget _buildFavoriteCard(FavoriteItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToProductDetail(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFFF0F0F0),
                    child: const Icon(Icons.coffee, color: Color(0xFF8B4513)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFFF0F0F0),
                    child: const Icon(Icons.coffee, color: Color(0xFF8B4513)),
                  ),
                ),
              ),

              const SizedBox(width: 12),

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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E2E2E), // textDark
                            ),
                          ),
                        ),
                        if (!item.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8C8C8C), // textLight
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B4513).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF8B4513),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.star,
                          size: 14,
                          color: const Color(0xFFFFA000), // accentAmber
                        ),
                        const SizedBox(width: 2),
                        Text(
                          item.rating.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5D5D5D), // textMedium
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Text(
                          '${item.price.toStringAsFixed(2)} AED',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B4513), // primaryBrown
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Added ${_formatDate(item.dateAdded)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8C8C8C), // textLight
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Action Buttons
              Column(
                children: [
                  IconButton(
                    onPressed: () => _removeFromFavorites(item),
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    tooltip: 'Remove from favorites',
                  ),
                  if (item.isAvailable)
                    IconButton(
                      onPressed: () => _addToCart(item),
                      icon: const Icon(
                        Icons.add_shopping_cart,
                        color: Color(0xFF8B4513),
                      ),
                      tooltip: 'Add to cart',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
  }

  void _navigateToProductDetail(FavoriteItem item) {
    // TODO: Navigate to product detail page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${item.name}...'),
        backgroundColor: const Color(0xFF8B4513),
      ),
    );
  }

  void _removeFromFavorites(FavoriteItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Favorites'),
        content: Text(
          'Are you sure you want to remove "${item.name}" from your favorites?',
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
                  content: Text('${item.name} removed from favorites'),
                  backgroundColor: Colors.orange,
                  action: SnackBarAction(
                    label: 'Undo',
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

  void _addToCart(FavoriteItem item) {
    // TODO: Implement add to cart functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart!'),
        backgroundColor: const Color(0xFF4CAF50), // success green
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),
      ),
    );
  }
}

class FavoriteItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double rating;
  final DateTime dateAdded;
  final bool isAvailable;

  FavoriteItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.rating,
    required this.dateAdded,
    required this.isAvailable,
  });
}
