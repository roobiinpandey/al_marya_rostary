import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// OrderTrackingPage displays real-time order tracking information
class OrderTrackingPage extends StatefulWidget {
  final String orderNumber;

  const OrderTrackingPage({super.key, required this.orderNumber});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  // Mock order tracking data - in real app, this would come from API
  final List<OrderStatus> _orderStatuses = [
    OrderStatus(
      title: 'Order Confirmed',
      description: 'Your order has been confirmed and is being processed.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isCompleted: true,
      icon: Icons.check_circle,
    ),
    OrderStatus(
      title: 'Preparing',
      description: 'We\'re carefully roasting and packaging your coffee.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isCompleted: true,
      icon: Icons.coffee_maker,
    ),
    OrderStatus(
      title: 'Ready for Pickup',
      description:
          'Your order is ready and will be picked up by our delivery partner.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      isCompleted: true,
      icon: Icons.inventory,
    ),
    OrderStatus(
      title: 'Out for Delivery',
      description: 'Your order is on the way to your address.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isCompleted: true,
      icon: Icons.local_shipping,
    ),
    OrderStatus(
      title: 'Delivered',
      description:
          'Your order has been successfully delivered. Enjoy your coffee!',
      timestamp: null,
      isCompleted: false,
      icon: Icons.home,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Track Order',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            _buildOrderHeader(),

            const SizedBox(height: 24),

            // Estimated Delivery
            _buildEstimatedDelivery(),

            const SizedBox(height: 24),

            // Order Progress
            _buildOrderProgress(),

            const SizedBox(height: 24),

            // Delivery Details
            _buildDeliveryDetails(),

            const SizedBox(height: 24),

            // Contact Support
            _buildContactSupport(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ${widget.orderNumber}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'In Transit',
                    style: TextStyle(
                      color: AppTheme.accentAmber,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Placed on ${_formatDate(DateTime.now().subtract(const Duration(hours: 2)))}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMedium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimatedDelivery() {
    final estimatedTime = DateTime.now().add(const Duration(minutes: 45));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBrown, AppTheme.primaryLightBrown],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.access_time, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated Delivery',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${estimatedTime.hour}:${estimatedTime.minute.toString().padLeft(2, '0')} - ${(estimatedTime.hour + 1) % 24}:${estimatedTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Today • 45 minutes',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Open live tracking map
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Live tracking will be available soon!'),
                ),
              );
            },
            icon: const Icon(Icons.map, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderProgress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 20),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _orderStatuses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final status = _orderStatuses[index];
                final isLast = index == _orderStatuses.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: status.isCompleted
                                ? AppTheme.primaryBrown
                                : AppTheme.textLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            status.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 40,
                            color: status.isCompleted
                                ? AppTheme.primaryBrown
                                : AppTheme.textLight,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: status.isCompleted
                                  ? AppTheme.textDark
                                  : AppTheme.textMedium,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status.description,
                            style: TextStyle(
                              color: AppTheme.textMedium,
                              fontSize: 14,
                            ),
                          ),
                          if (status.timestamp != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(status.timestamp!),
                              style: TextStyle(
                                color: AppTheme.textLight,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),

            // Delivery Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppTheme.primaryBrown,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'John Doe',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Text('123 Sheikh Zayed Road'),
                      const Text('Dubai Marina, Dubai'),
                      const Text('+971 50 123 4567'),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Delivery Instructions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.note, color: AppTheme.primaryBrown, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Instructions',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Please call when you arrive. Building entrance is from the back.',
                        style: TextStyle(color: AppTheme.textMedium),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSupport() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need Help?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'If you have any questions about your order, we\'re here to help.',
              style: TextStyle(color: AppTheme.textMedium),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Open chat support
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chat support will be available soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat Support'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryBrown),
                      foregroundColor: AppTheme.primaryBrown,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Call support
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Call +971 4 123 4567 for support'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Us'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryBrown),
                      foregroundColor: AppTheme.primaryBrown,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class OrderStatus {
  final String title;
  final String description;
  final DateTime? timestamp;
  final bool isCompleted;
  final IconData icon;

  OrderStatus({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isCompleted,
    required this.icon,
  });
}
