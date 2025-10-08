import 'package:flutter/material.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/dashboard_metrics_cards.dart';
import '../widgets/recent_orders_widget.dart';
import '../widgets/sales_chart_widget.dart';
import '../widgets/quick_actions_widget.dart';
import '../../../../core/theme/app_theme.dart';

/// Admin dashboard page showing key metrics and business overview
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _sidebarOpen = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768; // Mobile breakpoint

    return Scaffold(
      appBar: isMobile ? AppBar(
        backgroundColor: AppTheme.primaryBrown,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // TODO: Refresh dashboard data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dashboard refreshed')),
              );
            },
          ),
        ],
      ) : null,
      drawer: isMobile ? Drawer(
        child: AdminSidebar(
          isOpen: true,
          onToggle: () => setState(() => _sidebarOpen = !_sidebarOpen),
        ),
      ) : null,
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (!_sidebarOpen)
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => setState(() => _sidebarOpen = true),
                        ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Welcome back, Admin',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textMedium,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Refresh Button
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          // TODO: Refresh dashboard data
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dashboard refreshed')),
                          );
                        },
                        tooltip: 'Refresh',
                      ),
                      // Notifications
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications),
                            onPressed: () {
                              // TODO: Show notifications
                            },
                            tooltip: 'Notifications',
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Dashboard Content
                Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Metrics Cards
                        const DashboardMetricsCards(),

                        const SizedBox(height: 32),

                        // Charts Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sales Chart
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 400,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const SalesChartWidget(),
                              ),
                            ),

                            const SizedBox(width: 24),

                            // Recent Orders
                            Expanded(
                              flex: 1,
                              child: Container(
                                height: 400,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const RecentOrdersWidget(),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Quick Actions
                        const QuickActionsWidget(),

                        const SizedBox(height: 24), // Extra padding at bottom
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      color: AppTheme.backgroundCream,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Welcome back, Admin',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Metrics Cards
              const DashboardMetricsCards(),

              const SizedBox(height: 24),

              // Sales Chart
              Container(
                width: double.infinity,
                height: 300, // Reduced height for mobile
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const SalesChartWidget(),
              ),

              const SizedBox(height: 24),

              // Recent Orders
              Container(
                width: double.infinity,
                height: 300, // Reduced height for mobile
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const RecentOrdersWidget(),
              ),

              const SizedBox(height: 24),

              // Quick Actions
              const QuickActionsWidget(),

              const SizedBox(height: 24), // Extra padding at bottom
            ],
          ),
        ),
      ),
    );
  }
}
