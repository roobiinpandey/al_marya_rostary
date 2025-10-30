import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/admin_sidebar.dart';

/// Admin Reports Page
/// TODO: Implement comprehensive reporting system
class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  bool _sidebarOpen = true;
  String _selectedReportType = 'sales';

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: isMobile
          ? AppBar(
              title: const Text('Reports'),
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
                        'Reports & Analytics',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      DropdownButton<String>(
                        value: _selectedReportType,
                        onChanged: (value) =>
                            setState(() => _selectedReportType = value!),
                        items: const [
                          DropdownMenuItem(
                            value: 'sales',
                            child: Text('Sales Reports'),
                          ),
                          DropdownMenuItem(
                            value: 'products',
                            child: Text('Product Reports'),
                          ),
                          DropdownMenuItem(
                            value: 'customers',
                            child: Text('Customer Reports'),
                          ),
                          DropdownMenuItem(
                            value: 'financial',
                            child: Text('Financial Reports'),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement report export
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Export functionality - Coming Soon',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.file_download),
                        label: const Text('Export'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Report Type Cards
          Row(
            children: [
              Expanded(
                child: _buildReportTypeCard(
                  'Sales Reports',
                  'Revenue and transaction analysis',
                  Icons.trending_up,
                  'sales',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReportTypeCard(
                  'Product Reports',
                  'Inventory and performance data',
                  Icons.inventory,
                  'products',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReportTypeCard(
                  'Customer Reports',
                  'User behavior and demographics',
                  Icons.people,
                  'customers',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReportTypeCard(
                  'Financial Reports',
                  'Comprehensive financial overview',
                  Icons.account_balance,
                  'financial',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Report Content Based on Selection
          Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getReportIcon(),
                      color: AppTheme.primaryBrown,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getReportTitle(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Report Preview/Placeholder
                SizedBox(
                  height: 400,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getReportIcon(),
                          size: 64,
                          color: AppTheme.primaryBrown.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${_getReportTitle()} Coming Soon',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: AppTheme.textMedium),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getReportDescription(),
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

          const SizedBox(height: 24),
          _buildComingSoonNote(
            'Comprehensive reporting system with data visualization and export capabilities',
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeCard(
    String title,
    String description,
    IconData icon,
    String type,
  ) {
    final isSelected = _selectedReportType == type;

    return InkWell(
      onTap: () => setState(() => _selectedReportType = type),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBrown : Colors.transparent,
            width: 2,
          ),
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
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryBrown : AppTheme.textMedium,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected ? AppTheme.primaryBrown : AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textMedium),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonNote(String feature) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLightBrown.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryLightBrown),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaryBrown, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'TODO: $feature',
              style: TextStyle(
                color: AppTheme.textMedium,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getReportIcon() {
    switch (_selectedReportType) {
      case 'sales':
        return Icons.trending_up;
      case 'products':
        return Icons.inventory;
      case 'customers':
        return Icons.people;
      case 'financial':
        return Icons.account_balance;
      default:
        return Icons.description;
    }
  }

  String _getReportTitle() {
    switch (_selectedReportType) {
      case 'sales':
        return 'Sales Reports';
      case 'products':
        return 'Product Reports';
      case 'customers':
        return 'Customer Reports';
      case 'financial':
        return 'Financial Reports';
      default:
        return 'Reports';
    }
  }

  String _getReportDescription() {
    switch (_selectedReportType) {
      case 'sales':
        return 'Detailed analysis of sales performance, revenue trends, and transaction insights';
      case 'products':
        return 'Inventory levels, product performance metrics, and stock movement analysis';
      case 'customers':
        return 'Customer behavior patterns, demographics, and retention analytics';
      case 'financial':
        return 'Comprehensive financial overview including profit/loss, expenses, and forecasts';
      default:
        return 'Advanced reporting and analytics tools';
    }
  }
}
