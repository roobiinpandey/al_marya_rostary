import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quick_category_provider.dart';
import '../dialogs/add_edit_quick_category_dialog.dart';
import '../../../../data/models/quick_category_model.dart';
import '../../../../core/theme/app_theme.dart';

/// Admin Quick Categories Page
/// Manages quick categories with CRUD operations
class AdminQuickCategoriesPage extends StatefulWidget {
  const AdminQuickCategoriesPage({Key? key}) : super(key: key);

  @override
  State<AdminQuickCategoriesPage> createState() =>
      _AdminQuickCategoriesPageState();
}

class _AdminQuickCategoriesPageState extends State<AdminQuickCategoriesPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuickCategoryProvider>().fetchQuickCategories(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<QuickCategoryProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () => context.read<QuickCategoryProvider>().refresh(),
        child: Column(
          children: [
            _buildStatistics(),
            _buildFilters(),
            Expanded(child: _buildQuickCategoryGrid()),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Quick Categories'),
      backgroundColor: AppTheme.primaryBrown,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<QuickCategoryProvider>().refresh(),
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.analytics),
          onPressed: () => _showAnalytics(),
          tooltip: 'Analytics',
        ),
      ],
    );
  }

  // ==================== STATISTICS ====================

  Widget _buildStatistics() {
    return Consumer<QuickCategoryProvider>(
      builder: (context, provider, child) {
        final stats = provider.statistics;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  stats['total']?.toString() ?? '0',
                  Colors.blue,
                  Icons.category,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  stats['active']?.toString() ?? '0',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Clicks',
                  stats['totalClicks']?.toString() ?? '0',
                  Colors.orange,
                  Icons.mouse,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'CTR',
                  '${stats['avgClickThroughRate']?.toStringAsFixed(1) ?? '0'}%',
                  Colors.purple,
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FILTERS ====================

  Widget _buildFilters() {
    return Consumer<QuickCategoryProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  // Search
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search quick categories...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        provider.updateSearchQuery(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status Filter
                  Expanded(
                    child: DropdownButtonFormField<bool?>(
                      value: provider.statusFilter,
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
                        DropdownMenuItem(value: null, child: Text('All')),
                        DropdownMenuItem(value: true, child: Text('Active')),
                        DropdownMenuItem(value: false, child: Text('Inactive')),
                      ],
                      onChanged: (value) {
                        provider.updateStatusFilter(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Sort
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: provider.sortBy,
                      decoration: InputDecoration(
                        labelText: 'Sort By',
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
                          value: 'displayOrder',
                          child: Text('Order'),
                        ),
                        DropdownMenuItem(value: 'title', child: Text('Title')),
                        DropdownMenuItem(
                          value: 'createdAt',
                          child: Text('Created'),
                        ),
                        DropdownMenuItem(
                          value: 'clickCount',
                          child: Text('Clicks'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) provider.updateSortBy(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action Buttons
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => provider.refresh(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBrown,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showReorderDialog(),
                    icon: const Icon(Icons.reorder, size: 18),
                    label: const Text('Reorder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${provider.quickCategories.length} categories',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== QUICK CATEGORY GRID ====================

  Widget _buildQuickCategoryGrid() {
    return Consumer<QuickCategoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.quickCategories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.quickCategories.isEmpty) {
          return _buildEmptyState();
        }

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount:
              provider.quickCategories.length + (provider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= provider.quickCategories.length) {
              return const Center(child: CircularProgressIndicator());
            }

            final category = provider.quickCategories[index];
            return _buildQuickCategoryCard(category);
          },
        );
      },
    );
  }

  Widget _buildQuickCategoryCard(QuickCategoryModel category) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(category.color.substring(1), radix: 16) +
                        0xFF000000,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      category.safeImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 40,
                          ),
                        );
                      },
                    ),
                    // Status overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: category.isActive ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Order badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${category.displayOrder}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${category.viewCount}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.mouse, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${category.clickCount}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _editQuickCategory(category),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: Icon(
                    category.isActive ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                  ),
                  onPressed: () => _toggleStatus(category),
                  tooltip: category.isActive ? 'Deactivate' : 'Activate',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => _deleteQuickCategory(category),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Quick Categories',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first quick category to get started',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addQuickCategory,
            icon: const Icon(Icons.add),
            label: const Text('Add Quick Category'),
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

  // ==================== FAB ====================

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _addQuickCategory,
      backgroundColor: AppTheme.primaryBrown,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Add Category'),
    );
  }

  // ==================== ACTIONS ====================

  void _addQuickCategory() {
    showDialog(
      context: context,
      builder: (context) => const AddEditQuickCategoryDialog(),
    );
  }

  void _editQuickCategory(QuickCategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AddEditQuickCategoryDialog(category: category),
    );
  }

  void _deleteQuickCategory(QuickCategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quick Category'),
        content: Text('Are you sure you want to delete "${category.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<QuickCategoryProvider>().deleteQuickCategory(
                category.id,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleStatus(QuickCategoryModel category) {
    context.read<QuickCategoryProvider>().toggleQuickCategoryStatus(
      category.id,
    );
  }

  void _showReorderDialog() {
    showDialog(
      context: context,
      builder: (context) => _ReorderDialog(
        categories: context.read<QuickCategoryProvider>().quickCategories,
        onReorder: (orderedIds) {
          context.read<QuickCategoryProvider>().reorderQuickCategories(
            orderedIds,
          );
        },
      ),
    );
  }

  void _showAnalytics() {
    showDialog(
      context: context,
      builder: (context) => _AnalyticsDialog(
        statistics: context.read<QuickCategoryProvider>().statistics,
        categories: context.read<QuickCategoryProvider>().quickCategories,
      ),
    );
  }
}

// ==================== REORDER DIALOG ====================

class _ReorderDialog extends StatefulWidget {
  final List<QuickCategoryModel> categories;
  final Function(List<String>) onReorder;

  const _ReorderDialog({required this.categories, required this.onReorder});

  @override
  State<_ReorderDialog> createState() => _ReorderDialogState();
}

class _ReorderDialogState extends State<_ReorderDialog> {
  late List<QuickCategoryModel> _categories;

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.categories);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reorder Quick Categories'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ReorderableListView.builder(
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return ListTile(
              key: ValueKey(category.id),
              leading: CircleAvatar(
                backgroundColor: Color(
                  int.parse(category.color.substring(1), radix: 16) +
                      0xFF000000,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(category.title),
              subtitle: Text(category.subtitle),
              trailing: const Icon(Icons.drag_handle),
            );
          },
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = _categories.removeAt(oldIndex);
              _categories.insert(newIndex, item);
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final orderedIds = _categories.map((c) => c.id).toList();
            widget.onReorder(orderedIds);
            Navigator.pop(context);
          },
          child: const Text('Save Order'),
        ),
      ],
    );
  }
}

// ==================== ANALYTICS DIALOG ====================

class _AnalyticsDialog extends StatelessWidget {
  final Map<String, dynamic> statistics;
  final List<QuickCategoryModel> categories;

  const _AnalyticsDialog({required this.statistics, required this.categories});

  @override
  Widget build(BuildContext context) {
    final popularCategories = categories.where((c) => c.clickCount > 0).toList()
      ..sort((a, b) => b.clickCount.compareTo(a.clickCount));

    return AlertDialog(
      title: const Text('Quick Categories Analytics'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Stats
            const Text(
              'Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Total Categories',
              statistics['totalCategories']?.toString() ?? '0',
            ),
            _buildStatRow(
              'Active Categories',
              statistics['activeCategories']?.toString() ?? '0',
            ),
            _buildStatRow(
              'Total Clicks',
              statistics['totalClicks']?.toString() ?? '0',
            ),
            _buildStatRow(
              'Total Views',
              statistics['totalViews']?.toString() ?? '0',
            ),
            _buildStatRow(
              'Average CTR',
              '${statistics['avgClickThroughRate']?.toStringAsFixed(2) ?? '0'}%',
            ),

            const SizedBox(height: 24),
            const Text(
              'Top Performing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: popularCategories.take(5).length,
                itemBuilder: (context, index) {
                  final category = popularCategories[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(
                        int.parse(category.color.substring(1), radix: 16) +
                            0xFF000000,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(category.title),
                    subtitle: Text(
                      '${category.clickCount} clicks • ${category.clickThroughRate.toStringAsFixed(1)}% CTR',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
