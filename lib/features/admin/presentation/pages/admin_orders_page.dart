import 'package:flutter/material.dart';
import 'package:qahwat_al_emarat/models/order.dart';
import 'package:qahwat_al_emarat/core/theme/theme_extensions.dart';

/// AdminOrdersPage displays all orders for admin management
class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  OrderStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Replace with actual API call to fetch all orders
      // For now, using mock data
      await Future.delayed(const Duration(seconds: 1));

      // Mock orders for demonstration
      _orders = [];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Order> get _filteredOrders {
    if (_filterStatus == null) {
      return _orders;
    }
    return _orders.where((order) => order.status == _filterStatus).toList();
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.grey;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    try {
      // TODO: Replace with actual API call to update order status
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        final index = _orders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          _orders[index] = order.copyWith(status: newStatus);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order #${order.id} updated to ${_getStatusLabel(newStatus)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOrderDetails(Order order) {
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Order status
              _buildDetailRow(
                'Status',
                _getStatusLabel(order.status),
                color: _getStatusColor(order.status),
              ),
              _buildDetailRow('Total', '\$${order.total.toStringAsFixed(2)}'),
              _buildDetailRow('Created', _formatDateTime(order.createdAt)),
              if (order.updatedAt != null)
                _buildDetailRow('Updated', _formatDateTime(order.updatedAt!)),

              const SizedBox(height: 16),

              // Customer info
              Text(
                'Customer Information',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('User ID', order.userId),
              if (order.deliveryAddress != null) ...[
                _buildDetailRow(
                  'Name',
                  order.deliveryAddress!['name'] ?? 'N/A',
                ),
                _buildDetailRow(
                  'Email',
                  order.deliveryAddress!['email'] ?? 'N/A',
                ),
                _buildDetailRow(
                  'Phone',
                  order.deliveryAddress!['phone'] ?? 'N/A',
                ),
                _buildDetailRow(
                  'Address',
                  order.deliveryAddress!['address'] ?? 'N/A',
                ),
                _buildDetailRow(
                  'City',
                  order.deliveryAddress!['city'] ?? 'N/A',
                ),
                _buildDetailRow(
                  'Emirate',
                  order.deliveryAddress!['emirate'] ?? 'N/A',
                ),
              ],

              const SizedBox(height: 16),

              // Order items
              Text(
                'Order Items (${order.items.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...order.items.map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.coffeeName),
                    subtitle: Text('${item.size} - Quantity: ${item.quantity}'),
                    trailing: Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
              ),

              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(order.notes!),
              ],

              const SizedBox(height: 24),

              // Status update buttons
              Text(
                'Update Status',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: OrderStatus.values
                    .where((status) => status != order.status)
                    .map(
                      (status) => ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateOrderStatus(order, status);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getStatusColor(status),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_getStatusLabel(status)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: color != null ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Orders'),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Refresh orders',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filterStatus == null,
                    onSelected: (selected) {
                      setState(() {
                        _filterStatus = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ...OrderStatus.values.map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_getStatusLabel(status)),
                        selected: _filterStatus == status,
                        backgroundColor: _getStatusColor(
                          status,
                        ).withValues(alpha: 0.2),
                        selectedColor: _getStatusColor(status).withValues(alpha: 0.4),
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = selected ? status : null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Orders list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: colors.error,
                        ),
                        const SizedBox(height: 16),
                        Text('Error: $_error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadOrders,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filterStatus == null
                              ? 'No orders yet'
                              : 'No ${_getStatusLabel(_filterStatus!).toLowerCase()} orders',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadOrders,
                    child: ListView.builder(
                      itemCount: _filteredOrders.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final order = _filteredOrders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(order.status),
                              child: Text(
                                order.items.length.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              'Order #${order.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total: \$${order.total.toStringAsFixed(2)}',
                                ),
                                Text(
                                  _getStatusLabel(order.status),
                                  style: TextStyle(
                                    color: _getStatusColor(order.status),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _formatDateTime(order.createdAt),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () => _showOrderDetails(order),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
