import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final bool showAcceptButton;
  final bool showStartButton;
  final bool showCompleteButton;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onAccept,
    this.onStart,
    this.onComplete,
    this.showAcceptButton = false,
    this.showStartButton = false,
    this.showCompleteButton = false,
  });

  Color _getStatusColor() {
    switch (order.status) {
      case 'ready':
        return AppTheme.statusPending;
      case 'assigned':
        return AppTheme.statusInProgress;
      case 'out-for-delivery':
        return AppTheme.statusInProgress;
      case 'completed':
      case 'delivered':
        return AppTheme.statusCompleted;
      default:
        return AppTheme.textMedium;
    }
  }

  String _getStatusText() {
    switch (order.status) {
      case 'ready':
        return 'Ready for Pickup';
      case 'assigned':
        return 'Assigned to You';
      case 'out-for-delivery':
        return 'Out for Delivery';
      case 'completed':
      case 'delivered':
        return 'Delivered';
      default:
        return order.status
            .replaceAll('-', ' ')
            .split(' ')
            .map(
              (w) => w.isEmpty
                  ? ''
                  : w[0].toUpperCase() + w.substring(1).toLowerCase(),
            )
            .join(' ');
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order Number and Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.orderNumber}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer Info
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 18,
                    color: AppTheme.textMedium,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customer.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Phone Number
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: AppTheme.textMedium,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.customer.phone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Delivery Address
              if (order.deliveryAddress != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppTheme.textMedium,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.deliveryAddress!.fullAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Order Items Count and Time
              Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 18,
                    color: AppTheme.textMedium,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMedium,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color: AppTheme.textMedium,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatTime(order.createdAt),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMedium,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Total Amount
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOliveGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      size: 18,
                      color: AppTheme.primaryOliveGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AED ${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryOliveGold,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              if (showAcceptButton ||
                  showStartButton ||
                  showCompleteButton) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showAcceptButton)
                      ElevatedButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOliveGold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    if (showStartButton)
                      ElevatedButton.icon(
                        onPressed: onStart,
                        icon: const Icon(Icons.directions_car, size: 18),
                        label: const Text('Start Delivery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.statusInProgress,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    if (showCompleteButton)
                      ElevatedButton.icon(
                        onPressed: onComplete,
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.statusCompleted,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
