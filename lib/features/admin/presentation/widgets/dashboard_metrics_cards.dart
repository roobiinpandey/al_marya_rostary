import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

/// Dashboard metrics cards showing key business indicators
class DashboardMetricsCards extends StatelessWidget {
  const DashboardMetricsCards({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (isMobile) {
          // Mobile layout: Column of cards
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: _buildMetricCard(
                  context,
                  'Total Orders',
                  adminProvider.totalOrders.toString(),
                  Icons.shopping_cart,
                  AppTheme.primaryBrown,
                  '+${adminProvider.getOrdersChange().toStringAsFixed(1)}%',
                  true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _buildMetricCard(
                  context,
                  'Total Revenue',
                  '${AppConstants.currencySymbol}${adminProvider.totalRevenue.toStringAsFixed(0)}',
                  Icons.attach_money,
                  AppTheme.accentAmber,
                  '+${adminProvider.getRevenueChange().toStringAsFixed(1)}%',
                  true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _buildMetricCard(
                  context,
                  'Total Products',
                  adminProvider.totalProducts.toString(),
                  Icons.inventory,
                  Colors.blue,
                  'Active',
                  false,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _buildMetricCard(
                  context,
                  'Total Users',
                  adminProvider.totalUsers.toString(),
                  Icons.people,
                  Colors.green,
                  '+${adminProvider.getUsersChange().toStringAsFixed(1)}%',
                  true,
                ),
              ),
            ],
          );
        } else {
          // Desktop layout: Row of cards
          return Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Total Orders',
                  adminProvider.totalOrders.toString(),
                  Icons.shopping_cart,
                  AppTheme.primaryBrown,
                  '+${adminProvider.getOrdersChange().toStringAsFixed(1)}%',
                  true,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Total Revenue',
                  '${AppConstants.currencySymbol}${adminProvider.totalRevenue.toStringAsFixed(0)}',
                  Icons.attach_money,
                  AppTheme.accentAmber,
                  '+${adminProvider.getRevenueChange().toStringAsFixed(1)}%',
                  true,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Total Products',
                  adminProvider.totalProducts.toString(),
                  Icons.inventory,
                  Colors.blue,
                  'Active',
                  false,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Total Users',
                  adminProvider.totalUsers.toString(),
                  Icons.people,
                  Colors.green,
                  '+${adminProvider.getUsersChange().toStringAsFixed(1)}%',
                  true,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
    bool showChange,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Title Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Value
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          // Change Indicator
          if (showChange)
            Row(
              children: [
                Icon(
                  change.startsWith('+')
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 16,
                  color: change.startsWith('+') ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  change,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            change.startsWith('+') ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  'vs last month',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                change,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
