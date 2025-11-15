import 'package:flutter/material.dart';
import '../../core/services/staff_admin_auth_service.dart';
import '../../core/services/product_management_service.dart';
import './admin_login_dialog.dart';
import './product_form_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _authService = StaffAdminAuthService();
  final _productService = ProductManagementService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  List<dynamic> _products = [];
  String? _errorMessage;

  String? _searchQuery;
  bool? _filterActive;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final hasAccess = await _authService.hasAdminAccess();
    setState(() {
      _isAuthenticated = hasAccess;
    });

    if (hasAccess) {
      await _loadProducts();
    } else {
      _showLoginDialog();
    }
  }

  Future<void> _showLoginDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AdminLoginDialog(),
    );

    if (result == true) {
      setState(() {
        _isAuthenticated = true;
      });
      await _loadProducts();
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _productService.getProducts(
      type: 'Coffee', // Only show Coffee products, no Accessories or GiftSets
      search: _searchQuery,
      isActive: _filterActive,
    );

    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _products = result['data'] ?? [];
      } else {
        _errorMessage = result['message'];
      }
    });
  }

  Future<void> _toggleVisibility(String productId, bool currentStatus) async {
    final result = await _productService.toggleVisibility(productId);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Product ${currentStatus ? 'hidden' : 'activated'} successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _loadProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to update product'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteProduct(String productId, String productName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$productName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _productService.deleteProduct(productId);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openProductForm({Map<String, dynamic>? product}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormPage(product: product),
      ),
    );

    if (result == true) {
      await _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        backgroundColor: const Color(0xFF8B4513),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                _searchQuery = value.isEmpty ? null : value;
                _loadProducts();
              },
            ),
          ),

          const SizedBox(height: 16),

          // Products List (Coffee only)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProducts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _products.isEmpty
                ? const Center(child: Text('No products found'))
                : ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return _buildProductCard(product);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductForm(),
        backgroundColor: const Color(0xFF8B4513),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final isActive = product['isActive'] ?? true;

    // Handle name - could be string or object {en: '...', ar: '...'}
    String name;
    if (product['name'] is Map) {
      name = product['name']['en'] ?? product['name']['ar'] ?? 'Unknown';
    } else {
      name = product['name'] ?? 'Unknown';
    }

    final type = product['productType'] ?? product['type'] ?? 'Coffee';
    final price = product['price'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isActive ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getProductIcon(type),
            color: isActive ? Colors.green[700] : Colors.red[700],
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text('$type • OMR ${price.toStringAsFixed(2)}'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(isActive ? 'Hide' : 'Show'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _openProductForm(product: product);
                break;
              case 'toggle':
                _toggleVisibility(product['_id'], isActive);
                break;
              case 'delete':
                _deleteProduct(product['_id'], name);
                break;
            }
          },
        ),
        onTap: () => _openProductForm(product: product),
      ),
    );
  }

  IconData _getProductIcon(String type) {
    switch (type) {
      case 'Coffee':
        return Icons.coffee;
      case 'Accessory':
        return Icons.shopping_bag;
      case 'GiftSet':
        return Icons.card_giftcard;
      default:
        return Icons.inventory;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Products'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Show All'),
              leading: Radio<bool?>(
                value: null,
                groupValue: _filterActive,
                onChanged: (value) {
                  setState(() {
                    _filterActive = value;
                  });
                  Navigator.pop(context);
                  _loadProducts();
                },
              ),
            ),
            ListTile(
              title: const Text('Active Only'),
              leading: Radio<bool?>(
                value: true,
                groupValue: _filterActive,
                onChanged: (value) {
                  setState(() {
                    _filterActive = value;
                  });
                  Navigator.pop(context);
                  _loadProducts();
                },
              ),
            ),
            ListTile(
              title: const Text('Hidden Only'),
              leading: Radio<bool?>(
                value: false,
                groupValue: _filterActive,
                onChanged: (value) {
                  setState(() {
                    _filterActive = value;
                  });
                  Navigator.pop(context);
                  _loadProducts();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
