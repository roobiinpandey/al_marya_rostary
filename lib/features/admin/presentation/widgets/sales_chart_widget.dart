import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

/// Sales chart widget showing monthly sales data
class SalesChartWidget extends StatelessWidget {
  const SalesChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final salesData = adminProvider.salesData;

        if (salesData.isEmpty) {
          return const Center(
            child: Text('No sales data available'),
          );
        }

        // Find max value for scaling
        final maxSales = salesData
            .map((data) => data['sales'] as int)
            .reduce((a, b) => a > b ? a : b);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Monthly Sales',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Last 6 Months',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.accentAmber,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Chart
            SizedBox(
              height: 180, // Fixed height for chart bars
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: salesData.map((data) {
                  final month = data['month'] as String;
                  final sales = data['sales'] as int;
                  final percentage = sales / maxSales;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Value label
                          Text(
                            '${AppConstants.currencySymbol}${(sales / 1000).toStringAsFixed(0)}k',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textMedium,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),

                          const SizedBox(height: 8),

                          // Bar
                          Container(
                            width: double.infinity,
                            height: 150 * percentage, // Fixed max height
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBrown,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBrown.withValues(alpha:0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Month label
                          Text(
                            month,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textLight,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryLightBrown.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Sales',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMedium,
                            ),
                      ),
                      Text(
                        '${AppConstants.currencySymbol}${salesData.fold<int>(0, (sum, data) => sum + (data['sales'] as int)).toString()}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.primaryBrown,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Growth',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMedium,
                            ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.trending_up,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+18.5%',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
