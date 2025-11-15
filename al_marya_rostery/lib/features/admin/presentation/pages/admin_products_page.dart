import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/coffee_product_model.dart';
import '../widgets/admin_sidebar.dart';
import '../providers/product_provider.dart';
import '../dialogs/add_edit_product_dialog.dart';

/// Admin Products Management Page
/// Full CRUD operations for product management
class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  bool _sidebarOpen = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load products and stats on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (!provider.isInitialized) {
        provider.fetchProducts(refresh: true);
        provider.fetchStats();
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
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: isMobile
          ? AppBar(
              title: const Text('Products Management'),
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => _showAddProductDialog(context),
                ),
              ],
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: AdminSidebar(
                isOpen: true,
                onToggle: () => setState(() => _sidebarOpen = !_sidebarOpen),
              ),
            )
          : null,
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar
        AdminSidebar(
          isOpen: _sidebarOpen,
          onToggle: () => setState(() => _sidebarOpen = !_sidebarOpen),
        ),

        // Main Content
        Expanded(
          child: Container(
            color: AppTheme.backgroundCream,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: AppTheme.primaryLightBrown),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Products Management',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _showAddProductDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBrown,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(children: [Expanded(child: _buildContent())]);
  }

  Widget _buildContent() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        // Loading state
        if (provider.isLoading && provider.products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading products...'),
              ],
            ),
          );
        }

        // Error state
        if (provider.error != null && provider.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error: ${provider.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchProducts(refresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Main content
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Stats Cards
              _buildStatsCards(provider),

              const SizedBox(height: 24),

              // Products Table
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Search and Filter Bar
                      _buildSearchAndFilters(provider),

                      const SizedBox(height: 16),

                      // Products List
                      Expanded(
                        child: provider.products.isEmpty
                            ? _buildEmptyState()
                            : _buildProductsList(provider),
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

  Widget _buildStatsCards(ProductProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Products',
            provider.totalProducts.toString(),
            Icons.inventory,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Active Products',
            provider.activeProducts.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Inactive',
            provider.inactiveProducts.toString(),
            Icons.remove_circle_outline,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Categories',
            provider.allCategories.length.toString(),
            Icons.category,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(ProductProvider provider) {
    return Row(
      children: [
        // Search field
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) => provider.setSearchQuery(value),
          ),
        ),

        const SizedBox(width: 16),

        // Category filter
        if (provider.allCategories.isNotEmpty)
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: provider.selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Categories'),
                ),
                ...provider.allCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }),
              ],
              onChanged: (value) => provider.setCategory(value),
            ),
          ),

        const SizedBox(width: 16),

        // Show inactive toggle
        ElevatedButton.icon(
          onPressed: () => provider.toggleShowInactive(),
          icon: Icon(
            provider.showInactive ? Icons.visibility : Icons.visibility_off,
          ),
          label: Text(
            provider.showInactive ? 'Hide Inactive' : 'Show Inactive',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryLightBrown,
            foregroundColor: AppTheme.textDark,
          ),
        ),

        const SizedBox(width: 8),

        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => provider.refresh(),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppTheme.primaryBrown.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Products Found',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppTheme.textMedium),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your first product',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddProductDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(ProductProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        itemCount: provider.products.length,
        itemBuilder: (context, index) {
          final product = provider.products[index];
          return _buildProductCard(product, provider);
        },
      ),
    );
  }

  Widget _buildProductCard(
    CoffeeProductModel product,
    ProductProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.coffee,
            color: AppTheme.primaryBrown,
            size: 30,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${product.origin} • ${product.roastLevel}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'AED ${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBrown,
                  ),
                ),
                const SizedBox(width: 16),
                Text('Stock: ${product.stock}'),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: product.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleProductAction(value, product, provider),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'stock',
              child: ListTile(
                leading: Icon(Icons.inventory),
                title: Text('Update Stock'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                leading: Icon(
                  product.isActive ? Icons.visibility_off : Icons.visibility,
                ),
                title: Text(product.isActive ? 'Deactivate' : 'Activate'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleProductAction(
    String action,
    CoffeeProductModel product,
    ProductProvider provider,
  ) {
    switch (action) {
      case 'edit':
        _showEditProductDialog(context, product);
        break;
      case 'stock':
        _showStockUpdateDialog(context, product, provider);
        break;
      case 'toggle':
        _toggleProductStatus(product, provider);
        break;
      case 'delete':
        _confirmDeleteProduct(context, product, provider);
        break;
    }
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddEditProductDialog(),
    );
  }

  void _showEditProductDialog(
    BuildContext context,
    CoffeeProductModel product,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddEditProductDialog(product: product),
    );
  }

  void _showStockUpdateDialog(
    BuildContext context,
    CoffeeProductModel product,
    ProductProvider provider,
  ) {
    final controller = TextEditingController(text: product.stock.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock: ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Stock Quantity',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStock = int.tryParse(controller.text);
              if (newStock != null) {
                try {
                  await provider.updateStock(product.id, newStock);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Stock updated successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _toggleProductStatus(
    CoffeeProductModel product,
    ProductProvider provider,
  ) async {
    try {
      await provider.toggleActiveStatus(product.id, !product.isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Product ${product.isActive ? 'deactivated' : 'activated'} successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmDeleteProduct(
    BuildContext context,
    CoffeeProductModel product,
    ProductProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.deleteProduct(product.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMedium),
          ),
        ],
      ),
    );
  }
}
