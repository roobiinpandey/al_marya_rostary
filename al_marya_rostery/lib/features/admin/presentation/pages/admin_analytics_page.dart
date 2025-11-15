import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/analytics_service.dart';
import '../widgets/admin_sidebar.dart';

/// Admin Analytics Dashboard Page
/// Connected to real analytics data from backend
class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  bool _sidebarOpen = true;
  String _selectedPeriod = '7d';
  final AnalyticsService _analyticsService = AnalyticsService();

  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _topProducts = [];
  Map<String, dynamic> _customerAnalytics = {};
  Map<String, dynamic> _performanceMetrics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _analyticsService.getDashboardOverview(period: _selectedPeriod),
        _analyticsService.getTopProducts(limit: 5, period: _selectedPeriod),
        _analyticsService.getCustomerAnalytics(period: _selectedPeriod),
        _analyticsService.getPerformanceMetrics(period: _selectedPeriod),
      ]);

      setState(() {
        _dashboardData = results[0] as Map<String, dynamic>;
        _topProducts = results[1] as List<Map<String, dynamic>>;
        _customerAnalytics = results[2] as Map<String, dynamic>;
        _performanceMetrics = results[3] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading analytics: $e')));
      }
    }
  }

  void _onPeriodChanged(String? period) {
    if (period != null && period != _selectedPeriod) {
      setState(() => _selectedPeriod = period);
      _loadAnalyticsData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: isMobile
          ? AppBar(
              title: const Text('Analytics Dashboard'),
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen),
              ),
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
                        'Analytics Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      DropdownButton<String>(
                        value: _selectedPeriod,
                        onChanged: _onPeriodChanged,
                        items: const [
                          DropdownMenuItem(
                            value: '7d',
                            child: Text('Last 7 Days'),
                          ),
                          DropdownMenuItem(
                            value: '30d',
                            child: Text('Last 30 Days'),
                          ),
                          DropdownMenuItem(
                            value: '90d',
                            child: Text('Last 90 Days'),
                          ),
                          DropdownMenuItem(
                            value: '1y',
                            child: Text('Last Year'),
                          ),
                        ],
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Key Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Revenue',
                  '\$${_dashboardData['revenue']?.toStringAsFixed(0) ?? '0'}',
                  '${_dashboardData['revenueChange'] >= 0 ? '+' : ''}${_dashboardData['revenueChange']?.toStringAsFixed(1) ?? '0'}%',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Orders',
                  '${_dashboardData['orders'] ?? 0}',
                  '${_dashboardData['ordersChange'] >= 0 ? '+' : ''}${_dashboardData['ordersChange']?.toStringAsFixed(1) ?? '0'}%',
                  Icons.receipt_long,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Customers',
                  '${_dashboardData['customers'] ?? 0}',
                  '${_dashboardData['customersChange'] >= 0 ? '+' : ''}${_dashboardData['customersChange']?.toStringAsFixed(1) ?? '0'}%',
                  Icons.people,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Avg Order',
                  '\$${_dashboardData['avgOrder']?.toStringAsFixed(2) ?? '0.00'}',
                  '${_dashboardData['avgOrderChange'] >= 0 ? '+' : ''}${_dashboardData['avgOrderChange']?.toStringAsFixed(1) ?? '0'}%',
                  Icons.shopping_cart,
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Charts Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sales Chart
              Expanded(
                flex: 2,
                child: _buildChartCard(
                  'Sales Trends',
                  Icons.trending_up,
                  child: Container(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sales Chart Coming Soon',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Top Products
              Expanded(
                flex: 1,
                child: _buildChartCard(
                  'Top Products',
                  Icons.star,
                  child: Container(
                    height: 300,
                    child: Column(
                      children: [
                        ..._topProducts.asMap().entries.map((entry) {
                          final index = entry.key;
                          final product = entry.value;
                          return _buildTopProductItem(
                            product['name'] ?? 'Unknown Product',
                            '${product['orders'] ?? 0} orders',
                            index + 1,
                          );
                        }),
                        const Spacer(),
                        if (_topProducts.isEmpty)
                          const Text(
                            'No product data available',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Additional Analytics Row
          Row(
            children: [
              // Customer Analytics
              Expanded(
                child: _buildChartCard(
                  'Customer Analytics',
                  Icons.people_outline,
                  child: Container(
                    height: 200,
                    child: Column(
                      children: [
                        _buildAnalyticRow(
                          'New Customers',
                          '${_customerAnalytics['newCustomers'] ?? 0}',
                          '${_customerAnalytics['newCustomersChange'] >= 0 ? '+' : ''}${_customerAnalytics['newCustomersChange']?.toStringAsFixed(0) ?? '0'}%',
                        ),
                        _buildAnalyticRow(
                          'Returning Customers',
                          '${_customerAnalytics['returningCustomers'] ?? 0}',
                          '${_customerAnalytics['returningCustomersChange'] >= 0 ? '+' : ''}${_customerAnalytics['returningCustomersChange']?.toStringAsFixed(0) ?? '0'}%',
                        ),
                        _buildAnalyticRow(
                          'Customer Retention',
                          '${_customerAnalytics['retentionRate']?.toStringAsFixed(0) ?? '0'}%',
                          '${_customerAnalytics['retentionChange'] >= 0 ? '+' : ''}${_customerAnalytics['retentionChange']?.toStringAsFixed(0) ?? '0'}%',
                        ),
                        _buildAnalyticRow(
                          'Avg Session Duration',
                          _customerAnalytics['avgSessionDuration'] ?? 'N/A',
                          '${_customerAnalytics['sessionDurationChange'] >= 0 ? '+' : ''}${_customerAnalytics['sessionDurationChange']?.toStringAsFixed(0) ?? '0'}%',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Performance Metrics
              Expanded(
                child: _buildChartCard(
                  'Performance Metrics',
                  Icons.speed,
                  child: Container(
                    height: 200,
                    child: Column(
                      children: [
                        _buildAnalyticRow(
                          'Avg Order Time',
                          _performanceMetrics['avgOrderTime'] ?? 'N/A',
                          '${_performanceMetrics['avgOrderTimeChange'] >= 0 ? '+' : ''}${_performanceMetrics['avgOrderTimeChange']?.toStringAsFixed(0) ?? '0'}%',
                        ),
                        _buildAnalyticRow(
                          'Order Completion',
                          '${_performanceMetrics['orderCompletion']?.toStringAsFixed(1) ?? '0'}%',
                          '${_performanceMetrics['orderCompletionChange'] >= 0 ? '+' : ''}${_performanceMetrics['orderCompletionChange']?.toStringAsFixed(0) ?? '0'}%',
                        ),
                        _buildAnalyticRow(
                          'Customer Satisfaction',
                          '${_performanceMetrics['customerSatisfaction']?.toStringAsFixed(1) ?? '0'}/5',
                          '${_performanceMetrics['satisfactionChange'] >= 0 ? '+' : ''}${_performanceMetrics['satisfactionChange']?.toStringAsFixed(1) ?? '0'}',
                        ),
                        _buildAnalyticRow(
                          'Cancellation Rate',
                          '${_performanceMetrics['cancellationRate']?.toStringAsFixed(1) ?? '0'}%',
                          '${_performanceMetrics['cancellationChange'] >= 0 ? '+' : ''}${_performanceMetrics['cancellationChange']?.toStringAsFixed(1) ?? '0'}%',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
  ) {
    final isPositive = change.startsWith('+');

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.green : Colors.red).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildChartCard(String title, IconData icon, {required Widget child}) {
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
            children: [
              Icon(icon, color: AppTheme.primaryBrown, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTopProductItem(String name, String orders, int rank) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: rank <= 3 ? AppTheme.primaryBrown : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  color: rank <= 3 ? Colors.white : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  orders,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticRow(String label, String value, String change) {
    final isPositive = change.startsWith('+');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                change,
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
