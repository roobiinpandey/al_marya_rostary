import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/admin_sidebar.dart';

/// Admin Products Management Page
/// TODO: Implement full product management functionality
class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  bool _sidebarOpen = true;

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
                  onPressed: () {
                    // TODO: Implement add product functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Add Product - Coming Soon'),
                      ),
                    );
                  },
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
                        onPressed: () {
                          // TODO: Implement add product functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Add Product - Coming Soon'),
                            ),
                          );
                        },
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
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Products',
                  '156',
                  Icons.inventory,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Active Products',
                  '142',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Out of Stock',
                  '14',
                  Icons.error,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Categories',
                  '8',
                  Icons.category,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Products Table Placeholder
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement filter functionality
                        },
                        icon: const Icon(Icons.filter_list),
                        label: const Text('Filter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryLightBrown,
                          foregroundColor: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Coming Soon Message
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory,
                            size: 64,
                            color: AppTheme.primaryBrown.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Product Management Coming Soon',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: AppTheme.textMedium),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Full product CRUD operations will be available in the next update',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textLight),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/admin/dashboard');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBrown,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Back to Dashboard'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
