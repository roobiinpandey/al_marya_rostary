import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/slider_provider.dart';
import '../dialogs/add_edit_slider_dialog.dart';
import '../../../../data/models/slider_model.dart';

/// Admin Sliders Page
/// Manages banners/sliders with CRUD operations
class AdminSlidersPage extends StatefulWidget {
  const AdminSlidersPage({Key? key}) : super(key: key);

  @override
  State<AdminSlidersPage> createState() => _AdminSlidersPageState();
}

class _AdminSlidersPageState extends State<AdminSlidersPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SliderProvider>().fetchSliders(refresh: true);
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
      context.read<SliderProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () => context.read<SliderProvider>().refresh(),
        child: Column(
          children: [
            _buildStatistics(),
            _buildFilters(),
            Expanded(child: _buildSliderGrid()),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Sliders & Banners'),
      backgroundColor: const Color(0xFF6D4C3D),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<SliderProvider>().refresh(),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  // ==================== STATISTICS ====================

  Widget _buildStatistics() {
    return Consumer<SliderProvider>(
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
                  Icons.view_carousel,
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
                  'Scheduled',
                  stats['scheduled']?.toString() ?? '0',
                  Colors.orange,
                  Icons.schedule,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Expired',
                  stats['expired']?.toString() ?? '0',
                  Colors.red,
                  Icons.cancel,
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
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // ==================== FILTERS ====================

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildSearchBar()),
          const SizedBox(width: 12),
          _buildStatusFilter(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search sliders...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  context.read<SliderProvider>().setSearchQuery('');
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
        context.read<SliderProvider>().setSearchQuery(value);
      },
    );
  }

  Widget _buildStatusFilter() {
    return Consumer<SliderProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<bool?>(
            value: provider.activeFilter,
            hint: const Text('Status'),
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: null, child: Text('All')),
              DropdownMenuItem(value: true, child: Text('Active')),
              DropdownMenuItem(value: false, child: Text('Inactive')),
            ],
            onChanged: (value) {
              provider.setActiveFilter(value);
            },
          ),
        );
      },
    );
  }

  // ==================== SLIDER GRID ====================

  Widget _buildSliderGrid() {
    return Consumer<SliderProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.filteredSliders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && provider.filteredSliders.isEmpty) {
          return _buildErrorState(provider.errorMessage!);
        }

        if (provider.filteredSliders.isEmpty) {
          return _buildEmptyState();
        }

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(context),
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount:
              provider.filteredSliders.length + (provider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.filteredSliders.length) {
              return const Center(child: CircularProgressIndicator());
            }

            final slider = provider.filteredSliders[index];
            return _buildSliderCard(slider);
          },
        );
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 4;
    if (width > 1000) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildSliderCard(SliderModel slider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Preview
          Expanded(flex: 3, child: _buildImagePreview(slider)),
          // Content
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Status Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          slider.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(slider.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Description
                  if (slider.description != null)
                    Text(
                      slider.description!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const Spacer(),
                  // Analytics
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${slider.viewCount}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.touch_app, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${slider.clickCount}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'CTR: ${slider.clickThroughRate}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Actions
                  Row(
                    children: [
                      Text(
                        'Order: ${slider.displayOrder}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      _buildActionButton(
                        Icons.edit,
                        Colors.blue,
                        () => _showEditDialog(slider),
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        slider.isActive
                            ? Icons.visibility_off
                            : Icons.visibility,
                        slider.isActive ? Colors.orange : Colors.green,
                        () => _toggleActive(slider),
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        Icons.delete,
                        Colors.red,
                        () => _confirmDelete(slider),
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

  Widget _buildImagePreview(SliderModel slider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: slider.image.isNotEmpty
          ? ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                slider.image,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            )
          : const Center(
              child: Icon(Icons.image, size: 48, color: Colors.grey),
            ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Active':
        color = Colors.green;
        break;
      case 'Scheduled':
        color = Colors.orange;
        break;
      case 'Expired':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  // ==================== EMPTY & ERROR STATES ====================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.view_carousel, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No sliders found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first slider banner',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Slider'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6D4C3D),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading sliders',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<SliderProvider>().refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6D4C3D),
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
      onPressed: _showAddDialog,
      backgroundColor: const Color(0xFF6D4C3D),
      icon: const Icon(Icons.add),
      label: const Text('Add Slider'),
    );
  }

  // ==================== DIALOG ACTIONS ====================

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddEditSliderDialog(),
    );
  }

  void _showEditDialog(SliderModel slider) {
    showDialog(
      context: context,
      builder: (context) => AddEditSliderDialog(slider: slider),
    );
  }

  void _toggleActive(SliderModel slider) async {
    final provider = context.read<SliderProvider>();
    final success = await provider.toggleActiveStatus(
      slider.id,
      !slider.isActive,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Slider ${slider.isActive ? 'deactivated' : 'activated'}'
                : 'Failed to update status',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _confirmDelete(SliderModel slider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Slider'),
        content: Text('Are you sure you want to delete "${slider.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSlider(slider.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteSlider(String id) async {
    final provider = context.read<SliderProvider>();
    final success = await provider.deleteSlider(id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Slider deleted' : 'Failed to delete slider'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
