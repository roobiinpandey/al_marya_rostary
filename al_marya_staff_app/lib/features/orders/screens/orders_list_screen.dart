import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/pin_auth_service.dart';
import '../../../core/services/orders_service.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  final OrdersService _ordersService = OrdersService();
  final PinAuthService _authService = PinAuthService();
  List<dynamic> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _filterStatus = 'all'; // 'all', 'pending', 'assigned'
  String _staffName = '';
  String _staffRole = '';

  // Olive gold theme color
  static const Color oliveGold = Color(0xFFA89A6A);

  @override
  void initState() {
    super.initState();
    _loadStaffInfo();
    _loadOrders();
  }

  Future<void> _loadStaffInfo() async {
    try {
      print('🔍 Loading staff info...');
      final staffData = await _authService.getStaffData();
      print('📊 Staff data: $staffData');

      if (staffData != null && mounted) {
        final name = staffData['name'];
        final role = staffData['role'];

        print('✅ Name: $name');
        print('✅ Role: $role');

        setState(() {
          _staffName = name?.toString() ?? '';
          _staffRole = (role?.toString() ?? '').toUpperCase();
        });

        print('✅ State updated - Name: $_staffName, Role: $_staffRole');
      } else {
        print('❌ Staff data is null or widget not mounted');
      }
    } catch (e) {
      print('❌ Error loading staff info: $e');
      // Don't crash, just use empty values
      if (mounted) {
        setState(() {
          _staffName = '';
          _staffRole = '';
        });
      }
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _ordersService.getOrders(
        status: _filterStatus == 'all' ? null : _filterStatus,
      );

      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _orders = result['orders'] ?? [];
        } else {
          _errorMessage = result['error'] ?? 'Failed to load orders';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Image.asset(
                'assets/images/common/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.coffee, color: Colors.brown);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Orders',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_staffName.isNotEmpty)
                    Text(
                      'Welcome, $_staffName',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Staff info badge
          if (_staffRole.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _staffRole,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.inventory_2),
            onPressed: () {
              Navigator.pushNamed(context, '/products');
            },
            tooltip: 'Product Management',
          ),
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () {
              Navigator.pushNamed(context, '/change-pin');
            },
            tooltip: 'Change PIN',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = PinAuthService();
              await authService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[100],
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadOrders,
                  color: oliveGold,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(oliveGold),
                    ),
                  )
                : _errorMessage != null
                ? _buildErrorState()
                : _orders.isEmpty
                ? _buildEmptyState()
                : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filterStatus = value;
          });
          _loadOrders();
        }
      },
      selectedColor: oliveGold.withOpacity(0.3),
      checkmarkColor: oliveGold,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? oliveGold : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error Loading Orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: oliveGold,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Orders',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterStatus == 'pending'
                ? 'No pending orders available'
                : _filterStatus == 'completed'
                ? 'No completed orders yet'
                : _filterStatus == 'assigned'
                ? 'No orders assigned to you'
                : 'No orders at the moment',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: oliveGold,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: oliveGold,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final orderNumber = order['orderNumber'] ?? 'N/A';
    final status = order['status'] ?? 'pending';
    final totalAmount = order['totalAmount']?.toString() ?? '0';
    final items = order['items'] as List? ?? [];
    final isAssignedToMe = order['isAssignedToMe'] ?? false;
    final createdAt = order['createdAt'] != null
        ? DateTime.parse(order['createdAt'])
        : DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: oliveGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: oliveGold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#$orderNumber',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _formatDateTime(createdAt),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(status),
                ],
              ),

              const SizedBox(height: 12),

              // Items summary
              Text(
                '${items.length} item${items.length != 1 ? 's' : ''}',
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 8),

              // Total amount and assigned badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Total: AED $totalAmount',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: oliveGold,
                      ),
                    ),
                  ),
                  if (isAssignedToMe)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          'Assigned',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Quick action buttons
              const SizedBox(height: 12),
              _buildQuickActions(order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(dynamic order) {
    final status = order['status']?.toString().toLowerCase() ?? 'pending';
    final orderId = order['id']?.toString() ?? '';

    // Debug logging
    print('🔍 Order ${order['orderNumber']}: status=$status, id=$orderId');
    print('🔍 Raw order data: $order');

    // 1. NEW ORDER: Show Accept/Reject/Hold buttons
    if (status == 'pending' || status == 'confirmed') {
      return Row(
        children: [
          // Reject button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _rejectOrder(orderId),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Hold button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _holdOrder(orderId),
              icon: const Icon(Icons.pause, size: 16),
              label: const Text('Hold'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Accept button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _acceptOrder(orderId),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 2. ACCEPTED: Auto-start processing
    if (status == 'accepted' || status == 'preparing') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _markAsReady(orderId),
          icon: const Icon(Icons.check_circle, size: 18),
          label: const Text('Mark as Ready'),
          style: ElevatedButton.styleFrom(
            backgroundColor: oliveGold,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    // 3. READY: Hand to Driver OR Complete directly
    if (status == 'ready') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handToDriver(orderId),
              icon: const Icon(Icons.local_shipping, size: 18),
              label: const Text('Hand to Driver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _completeOrder(orderId),
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 4. OUT FOR DELIVERY: Just mark as completed
    if (status == 'out-for-delivery') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _completeOrder(orderId),
          icon: const Icon(Icons.done_all, size: 18),
          label: const Text('Mark as Completed'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    // On Hold: Show Resume
    if (status == 'on-hold' || status == 'hold') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _resumeOrder(orderId),
          icon: const Icon(Icons.play_arrow, size: 18),
          label: const Text('Resume Order'),
          style: ElevatedButton.styleFrom(
            backgroundColor: oliveGold,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    // Completed/Delivered: Show view details
    if (status == 'completed' ||
        status == 'delivered' ||
        status == 'out-for-delivery') {
      return TextButton.icon(
        onPressed: () => _showOrderDetails(order),
        icon: const Icon(Icons.visibility, size: 16),
        label: const Text('View Details'),
        style: TextButton.styleFrom(foregroundColor: oliveGold),
      );
    }

    // Default: Just show view details button
    return TextButton.icon(
      onPressed: () => _showOrderDetails(order),
      icon: const Icon(Icons.info_outline, size: 16),
      label: const Text('View Details'),
      style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'accepted':
        color = Colors.blue;
        label = 'Accepted';
        break;
      case 'preparing':
        color = Colors.purple;
        label = 'Preparing';
        break;
      case 'ready':
        color = Colors.green;
        label = 'Ready';
        break;
      case 'completed':
        color = Colors.teal;
        label = 'Completed';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withOpacity(1.0),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
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

  void _showOrderDetails(dynamic order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: oliveGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long, color: oliveGold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order['orderNumber']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          order['status'] ?? 'pending',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Order details
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Items
                  const Text(
                    'Items',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...((order['items'] as List?) ?? []).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            '${item['quantity']}x',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['coffee']?['name'] ?? 'Item',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            'AED ${item['price']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: oliveGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'AED ${order['totalAmount']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: oliveGold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Delivery info
                  if (order['deliveryMethod'] != null) ...[
                    const Text(
                      'Delivery',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order['deliveryMethod'] == 'pickup'
                          ? 'Pickup'
                          : 'Delivery',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Order Notes
                  if (order['notes'] != null &&
                      order['notes'].toString().isNotEmpty) ...[
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order['notes'].toString(),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: _buildOrderActionButtons(order),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderActionButtons(dynamic order) {
    final status = order['status']?.toString().toLowerCase() ?? 'pending';
    final orderId = order['id']?.toString() ?? '';

    // Pending: Accept or Reject
    if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _rejectOrder(orderId),
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _acceptOrder(orderId),
              icon: const Icon(Icons.check),
              label: const Text('Accept Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    }

    // Accepted: Start Preparing or Hold
    if (status == 'accepted') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _holdOrder(orderId),
              icon: const Icon(Icons.pause),
              label: const Text('Hold'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _startPreparing(orderId),
              icon: const Icon(Icons.restaurant),
              label: const Text('Start Preparing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: oliveGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    }

    // Preparing: Mark as Ready
    if (status == 'preparing') {
      return ElevatedButton.icon(
        onPressed: () => _markAsReady(orderId),
        icon: const Icon(Icons.check_circle),
        label: const Text('Mark as Ready'),
        style: ElevatedButton.styleFrom(
          backgroundColor: oliveGold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(double.infinity, 48),
        ),
      );
    }

    // Ready: Hand to Driver or Complete
    if (status == 'ready') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handToDriver(orderId),
              icon: const Icon(Icons.local_shipping),
              label: const Text('Hand to Driver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _completeOrder(orderId),
              icon: const Icon(Icons.done_all),
              label: const Text('Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    }

    // On Hold: Resume
    if (status == 'on-hold' || status == 'hold') {
      return ElevatedButton.icon(
        onPressed: () => _resumeOrder(orderId),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Resume Order'),
        style: ElevatedButton.styleFrom(
          backgroundColor: oliveGold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(double.infinity, 48),
        ),
      );
    }

    // Default: No actions
    return const SizedBox.shrink();
  }

  // Order action methods
  Future<void> _acceptOrder(String orderId) async {
    setState(() => _isLoading = true);

    final result = await _ordersService.acceptOrder(orderId);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to accept order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order?'),
        content: const Text('Are you sure you want to reject this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final result = await _ordersService.updateOrderStatus(orderId, 'rejected');

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order rejected'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to reject order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startPreparing(String orderId) async {
    setState(() => _isLoading = true);

    final result = await _ordersService.updateOrderStatus(orderId, 'preparing');

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Started preparing order'),
          backgroundColor: Colors.purple,
        ),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to update order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAsReady(String orderId) async {
    setState(() => _isLoading = true);

    final result = await _ordersService.updateOrderStatus(orderId, 'ready');

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as ready!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to update order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _holdOrder(String orderId) async {
    setState(() => _isLoading = true);

    final result = await _ordersService.updateOrderStatus(orderId, 'on-hold');

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order put on hold'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to hold order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resumeOrder(String orderId) async {
    setState(() => _isLoading = true);

    final result = await _ordersService.updateOrderStatus(orderId, 'accepted');

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order resumed'),
          backgroundColor: Colors.green,
        ),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to resume order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handToDriver(String orderId) async {
    setState(() => _isLoading = true);

    final result = await _ordersService.updateOrderStatus(
      orderId,
      'out-for-delivery',
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order handed to driver'),
          backgroundColor: Colors.blue,
        ),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to update order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeOrder(String orderId) async {
    setState(() => _isLoading = true);

    final result = await _ordersService.updateOrderStatus(orderId, 'completed');

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order completed!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to complete order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
