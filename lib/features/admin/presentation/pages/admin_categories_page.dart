import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/category_model.dart';
import '../widgets/admin_sidebar.dart';
import '../providers/category_provider.dart';
import '../dialogs/add_edit_category_dialog.dart';

/// Admin Categories Management Page
/// Full CRUD operations for category management
class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  bool _sidebarOpen = true;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Fetch categories when page loads
    Future.delayed(Duration.zero, () {
      if (mounted) {
        final provider = Provider.of<CategoryProvider>(context, listen: false);
        provider.fetchCategories(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final provider = Provider.of<CategoryProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoading) {
        provider.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      body: Row(
        children: [
          // Sidebar
          AdminSidebar(
            isOpen: _sidebarOpen,
            onToggle: () => setState(() => _sidebarOpen = !_sidebarOpen),
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu toggle
          if (!_sidebarOpen)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => setState(() => _sidebarOpen = true),
            ),

          // Page title
          const Text(
            'Category Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBrown,
            ),
          ),

          const Spacer(),

          // Add Category button
          ElevatedButton.icon(
            onPressed: () => _showAddCategoryDialog(context),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Category'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () => provider.fetchCategories(refresh: true),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Statistics Dashboard
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildStatisticsPanel(provider),
                ),
              ),

              // Search and Filter Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSearchAndFilters(provider),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Categories Grid/List
              if (provider.isLoading && provider.categories.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.errorMessage != null)
                SliverFillRemaining(child: _buildErrorState(provider))
              else if (provider.filteredCategories.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(provider))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: _buildCategoriesGrid(provider),
                ),

              // Loading more indicator
              if (provider.isLoading && provider.categories.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsPanel(CategoryProvider provider) {
    final stats = provider.statistics;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildStatCard(
              icon: Icons.category,
              title: 'Total Categories',
              value: '${stats['total'] ?? 0}',
              color: AppTheme.primaryBrown,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              icon: Icons.check_circle,
              title: 'Active',
              value: '${stats['active'] ?? 0}',
              color: Colors.green,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              icon: Icons.cancel,
              title: 'Inactive',
              value: '${stats['inactive'] ?? 0}',
              color: Colors.orange,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              icon: Icons.account_tree,
              title: 'Top Level',
              value: '${stats['topLevel'] ?? 0}',
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(CategoryProvider provider) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Search bar
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) => provider.setSearchQuery(value),
                  ),
                ),

                const SizedBox(width: 16),

                // Active filter dropdown
                Expanded(
                  child: DropdownButtonFormField<bool?>(
                    value: provider.activeFilter,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      DropdownMenuItem(value: true, child: Text('Active Only')),
                      DropdownMenuItem(
                        value: false,
                        child: Text('Inactive Only'),
                      ),
                    ],
                    onChanged: (value) => provider.setActiveFilter(value),
                  ),
                ),

                const SizedBox(width: 16),

                // Clear filters button
                OutlinedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    provider.clearFilters();
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(CategoryProvider provider) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final category = provider.filteredCategories[index];
        return _buildCategoryCard(category, provider);
      }, childCount: provider.filteredCategories.length),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, CategoryProvider provider) {
    final nameEn = category.name['en'] ?? 'Unnamed';
    final nameAr = category.name['ar'] ?? '';
    final descEn = category.description['en'] ?? '';
    final color = _parseColor(category.color);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color header
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Center(
              child: Icon(Icons.category, color: Colors.white, size: 32),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category name (English)
                  Text(
                    nameEn,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Category name (Arabic)
                  if (nameAr.isNotEmpty)
                    Text(
                      nameAr,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 8),

                  // Description
                  Expanded(
                    child: Text(
                      descEn,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Display order and status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Order: ${category.displayOrder}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: category.isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 11,
                            color: category.isActive
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showEditCategoryDialog(context, category),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text(
                            'Edit',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () =>
                            _toggleActiveStatus(category, provider),
                        icon: Icon(
                          category.isActive
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                        ),
                        tooltip: category.isActive ? 'Deactivate' : 'Activate',
                        color: category.isActive ? Colors.orange : Colors.green,
                      ),
                      IconButton(
                        onPressed: () => _showDeleteConfirmation(
                          context,
                          category,
                          provider,
                        ),
                        icon: const Icon(Icons.delete, size: 20),
                        tooltip: 'Delete',
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(CategoryProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            provider.searchQuery.isNotEmpty
                ? 'No categories found'
                : 'No categories yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            provider.searchQuery.isNotEmpty
                ? 'Try adjusting your search'
                : 'Create your first category to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddCategoryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CategoryProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading categories',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            provider.errorMessage ?? 'Unknown error',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => provider.fetchCategories(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ==================== ACTIONS ====================

  void _showAddCategoryDialog(BuildContext context) {
    final provider = Provider.of<CategoryProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AddEditCategoryDialog(provider: provider),
    );
  }

  void _showEditCategoryDialog(BuildContext context, CategoryModel category) {
    final provider = Provider.of<CategoryProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) =>
          AddEditCategoryDialog(category: category, provider: provider),
    );
  }

  Future<void> _toggleActiveStatus(
    CategoryModel category,
    CategoryProvider provider,
  ) async {
    final success = await provider.toggleActiveStatus(
      category.id,
      !category.isActive,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Category ${category.isActive ? 'deactivated' : 'activated'} successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Failed to update category status',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    CategoryModel category,
    CategoryProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name['en']}"?\n\n'
          'This action cannot be undone. Products using this category may be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await provider.deleteCategory(category.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.errorMessage ?? 'Failed to delete category',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ==================== UTILITIES ====================

  Color _parseColor(String colorString) {
    try {
      // Remove # if present
      final hexColor = colorString.replaceAll('#', '');
      // Add FF for opacity if not present
      final colorValue = int.parse(
        hexColor.length == 6 ? 'FF$hexColor' : hexColor,
        radix: 16,
      );
      return Color(colorValue);
    } catch (e) {
      return AppTheme.primaryBrown; // Fallback color
    }
  }
}
