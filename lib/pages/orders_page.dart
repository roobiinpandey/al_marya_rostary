import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadOrders() {
    // TODO: Load orders from API
    // Mock data for now
    setState(() {
      _orders = [
        OrderModel(
          id: 'ORD-001',
          items: [
            OrderItem(
              id: '1',
              name: 'Emirati Qahwa',
              quantity: 2,
              price: 25.00,
              imageUrl:
                  'https://via.placeholder.com/100x100/8B4513/FFFFFF?text=Qahwa',
            ),
            OrderItem(
              id: '2',
              name: 'Arabic Dates',
              quantity: 1,
              price: 15.00,
              imageUrl:
                  'https://via.placeholder.com/100x100/8B4513/FFFFFF?text=Dates',
            ),
          ],
          status: OrderStatus.delivered,
          orderDate: DateTime.now().subtract(const Duration(days: 3)),
          deliveryDate: DateTime.now().subtract(const Duration(days: 2)),
          total: 65.00,
          deliveryAddress: 'Dubai Marina, Dubai, UAE',
          trackingNumber: 'TRK123456789',
        ),
        OrderModel(
          id: 'ORD-002',
          items: [
            OrderItem(
              id: '3',
              name: 'Cold Brew',
              quantity: 1,
              price: 18.00,
              imageUrl:
                  'https://via.placeholder.com/100x100/8B4513/FFFFFF?text=Cold+Brew',
            ),
          ],
          status: OrderStatus.inProgress,
          orderDate: DateTime.now().subtract(const Duration(hours: 6)),
          deliveryDate: null,
          total: 18.00,
          deliveryAddress: 'Business Bay, Dubai, UAE',
          trackingNumber: 'TRK987654321',
        ),
        OrderModel(
          id: 'ORD-003',
          items: [
            OrderItem(
              id: '4',
              name: 'Arabic Mocha',
              quantity: 3,
              price: 22.00,
              imageUrl:
                  'https://via.placeholder.com/100x100/8B4513/FFFFFF?text=Mocha',
            ),
          ],
          status: OrderStatus.pending,
          orderDate: DateTime.now().subtract(const Duration(minutes: 30)),
          deliveryDate: null,
          total: 66.00,
          deliveryAddress: 'Downtown Dubai, UAE',
          trackingNumber: null,
        ),
        OrderModel(
          id: 'ORD-004',
          items: [
            OrderItem(
              id: '5',
              name: 'Turkish Coffee',
              quantity: 1,
              price: 20.00,
              imageUrl:
                  'https://via.placeholder.com/100x100/8B4513/FFFFFF?text=Turkish',
            ),
          ],
          status: OrderStatus.cancelled,
          orderDate: DateTime.now().subtract(const Duration(days: 7)),
          deliveryDate: null,
          total: 20.00,
          deliveryAddress: 'Jumeirah, Dubai, UAE',
          trackingNumber: null,
        ),
      ];
      _isLoading = false;
    });
  }

  List<OrderModel> get _filteredOrders {
    switch (_tabController.index) {
      case 0: // All
        return _orders;
      case 1: // Pending
        return _orders
            .where((order) => order.status == OrderStatus.pending)
            .toList();
      case 2: // In Progress
        return _orders
            .where((order) => order.status == OrderStatus.inProgress)
            .toList();
      case 3: // Delivered
        return _orders
            .where(
              (order) =>
                  order.status == OrderStatus.delivered ||
                  order.status == OrderStatus.cancelled,
            )
            .toList();
      default:
        return _orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8B4513), // primaryBrown
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (index) {
            setState(() {}); // Refresh to update filtered orders
          },
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5), // backgroundLight
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B4513)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(),
                _buildOrdersList(),
                _buildOrdersList(),
                _buildOrdersList(),
              ],
            ),
    );
  }

  Widget _buildOrdersList() {
    final filteredOrders = _filteredOrders;

    if (filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(filteredOrders[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    String message = 'No orders found';
    String subtitle = 'Start browsing our coffee collection';
    IconData icon = Icons.receipt_long;

    switch (_tabController.index) {
      case 1:
        message = 'No pending orders';
        subtitle = 'All caught up! No pending orders at the moment.';
        icon = Icons.pending_actions;
        break;
      case 2:
        message = 'No orders in progress';
        subtitle = 'No orders are currently being prepared.';
        icon = Icons.hourglass_empty;
        break;
      case 3:
        message = 'No completed orders';
        subtitle = 'Your completed orders will appear here.';
        icon = Icons.check_circle_outline;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: const Color(0xFF8C8C8C), // textLight
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5D5D5D), // textMedium
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8C8C8C), // textLight
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/coffee');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Browse Coffee'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E2E2E), // textDark
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(order.orderDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8C8C8C), // textLight
                        ),
                      ),
                    ],
                  ),
                  _buildStatusChip(order.status),
                ],
              ),

              const SizedBox(height: 16),

              // Order Items Preview
              ...order.items.take(2).map((item) => _buildOrderItemRow(item)),

              if (order.items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+${order.items.length - 2} more items',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B4513),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Order Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8C8C8C), // textLight
                        ),
                      ),
                      Text(
                        '${order.total.toStringAsFixed(2)} AED',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513), // primaryBrown
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (order.status == OrderStatus.inProgress &&
                          order.trackingNumber != null)
                        TextButton(
                          onPressed: () => _trackOrder(order),
                          child: const Text('Track Order'),
                        ),
                      if (order.status == OrderStatus.delivered)
                        TextButton(
                          onPressed: () => _reorder(order),
                          child: const Text('Reorder'),
                        ),
                      if (order.status == OrderStatus.pending)
                        TextButton(
                          onPressed: () => _cancelOrder(order),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Cancel'),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 40,
                height: 40,
                color: const Color(0xFFF0F0F0),
                child: const Icon(
                  Icons.coffee,
                  color: Color(0xFF8B4513),
                  size: 20,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 40,
                height: 40,
                color: const Color(0xFFF0F0F0),
                child: const Icon(
                  Icons.coffee,
                  color: Color(0xFF8B4513),
                  size: 20,
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
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2E2E2E), // textDark
                  ),
                ),
                Text(
                  'Qty: ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8C8C8C), // textLight
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(item.price * item.quantity).toStringAsFixed(2)} AED',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5D5D5D), // textMedium
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        label = 'Pending';
        icon = Icons.pending;
        break;
      case OrderStatus.inProgress:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        label = 'In Progress';
        icon = Icons.hourglass_empty;
        break;
      case OrderStatus.delivered:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        label = 'Delivered';
        icon = Icons.check_circle;
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        label = 'Cancelled';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildOrderDetailsSheet(order),
    );
  }

  Widget _buildOrderDetailsSheet(OrderModel order) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),

              const SizedBox(height: 20),

              // Order Details
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection(
                        'Order Date',
                        _formatDate(order.orderDate),
                      ),
                      if (order.deliveryDate != null)
                        _buildDetailSection(
                          'Delivery Date',
                          _formatDate(order.deliveryDate!),
                        ),
                      if (order.trackingNumber != null)
                        _buildDetailSection(
                          'Tracking Number',
                          order.trackingNumber!,
                        ),
                      _buildDetailSection(
                        'Delivery Address',
                        order.deliveryAddress,
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E2E2E),
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...order.items.map((item) => _buildDetailOrderItem(item)),

                      const Divider(height: 32),

                      _buildDetailSection(
                        'Total',
                        '${order.total.toStringAsFixed(2)} AED',
                        isTotal: true,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    if (order.status == OrderStatus.pending ||
                        order.status == OrderStatus.inProgress) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _trackOrder(order);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4513),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Track Order',
                            style: TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (order.status == OrderStatus.delivered) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _reorder(order);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4513),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Reorder Items',
                            style: TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        if (order.status == OrderStatus.pending) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _cancelOrder(order);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel Order',
                                style: TextStyle(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF8C8C8C),
                              side: const BorderSide(color: Color(0xFF8C8C8C)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(
    String title,
    String value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                color: const Color(0xFF8C8C8C),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal
                    ? const Color(0xFF8B4513)
                    : const Color(0xFF2E2E2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailOrderItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 50,
                height: 50,
                color: const Color(0xFFF0F0F0),
                child: const Icon(Icons.coffee, color: Color(0xFF8B4513)),
              ),
              errorWidget: (context, url, error) => Container(
                width: 50,
                height: 50,
                color: const Color(0xFFF0F0F0),
                child: const Icon(Icons.coffee, color: Color(0xFF8B4513)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
                Text(
                  'Quantity: ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8C8C8C),
                  ),
                ),
                Text(
                  'Unit Price: ${item.price.toStringAsFixed(2)} AED',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8C8C8C),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(item.price * item.quantity).toStringAsFixed(2)} AED',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B4513),
            ),
          ),
        ],
      ),
    );
  }

  void _trackOrder(OrderModel order) {
    // TODO: Implement order tracking
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tracking order #${order.id}...'),
        backgroundColor: const Color(0xFF8B4513),
      ),
    );
  }

  void _reorder(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reorder Items'),
        content: Text('Add all items from order #${order.id} to your cart?'),
        actions: [
          Flexible(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', overflow: TextOverflow.ellipsis),
            ),
          ),
          Flexible(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Items added to cart!'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add to Cart', overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelOrder(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text('Are you sure you want to cancel order #${order.id}?'),
        actions: [
          Flexible(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Order', overflow: TextOverflow.ellipsis),
            ),
          ),
          Flexible(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  final index = _orders.indexWhere((o) => o.id == order.id);
                  if (index != -1) {
                    _orders[index] = order.copyWith(
                      status: OrderStatus.cancelled,
                    );
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order cancelled successfully'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Cancel Order',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Data Models
enum OrderStatus { pending, inProgress, delivered, cancelled }

class OrderModel {
  final String id;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final double total;
  final String deliveryAddress;
  final String? trackingNumber;

  OrderModel({
    required this.id,
    required this.items,
    required this.status,
    required this.orderDate,
    this.deliveryDate,
    required this.total,
    required this.deliveryAddress,
    this.trackingNumber,
  });

  OrderModel copyWith({
    String? id,
    List<OrderItem>? items,
    OrderStatus? status,
    DateTime? orderDate,
    DateTime? deliveryDate,
    double? total,
    String? deliveryAddress,
    String? trackingNumber,
  }) {
    return OrderModel(
      id: id ?? this.id,
      items: items ?? this.items,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      total: total ?? this.total,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      trackingNumber: trackingNumber ?? this.trackingNumber,
    );
  }
}

class OrderItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String imageUrl;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.imageUrl,
  });
}
