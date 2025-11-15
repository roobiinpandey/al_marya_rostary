import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/pin_auth_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/order_model.dart';
import '../services/deliveries_service.dart';
import '../widgets/order_card.dart';
import '../../auth/screens/pin_login_screen.dart';
import 'delivery_detail_screen.dart';

class DeliveriesListScreen extends StatefulWidget {
  const DeliveriesListScreen({super.key});

  @override
  State<DeliveriesListScreen> createState() => _DeliveriesListScreenState();
}

class _DeliveriesListScreenState extends State<DeliveriesListScreen>
    with SingleTickerProviderStateMixin {
  final _authService = PinAuthService();
  final _locationService = LocationService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeLocationTracking();
  }

  Future<void> _initializeLocationTracking() async {
    // Initialize location service and start tracking
    final result = await _locationService.initialize();

    if (result['success']) {
      // Set driver status to available and start tracking
      await _locationService.updateDriverStatus(AppConstants.statusAvailable);
    } else {
      // Show permission dialog if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                // Open app settings (would need app_settings package)
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Stop location tracking and set driver offline
      _locationService.stopTracking();
      await _locationService.updateDriverStatus(AppConstants.statusOffline);

      // Logout
      await _authService.logout();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PinLoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driver = _authService.currentDriver;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Deliveries'),
            Text(
              driver?.name ?? 'Driver',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'My Deliveries'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AvailableDeliveriesTab(onRefresh: () => setState(() {})),
          _MyDeliveriesTab(onRefresh: () => setState(() {})),
          _CompletedDeliveriesTab(onRefresh: () => setState(() {})),
        ],
      ),
    );
  }
}

class _AvailableDeliveriesTab extends StatefulWidget {
  final VoidCallback onRefresh;

  const _AvailableDeliveriesTab({required this.onRefresh});

  @override
  State<_AvailableDeliveriesTab> createState() =>
      _AvailableDeliveriesTabState();
}

class _AvailableDeliveriesTabState extends State<_AvailableDeliveriesTab> {
  final _deliveriesService = DeliveriesService();
  List<Order>? _orders;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await _deliveriesService.fetchAvailableDeliveries();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load deliveries';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAccept(Order order) async {
    final result = await _deliveriesService.acceptDelivery(order.id);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppTheme.statusCompleted,
          ),
        );
        _loadDeliveries();
        widget.onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToDetail(Order order) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => DeliveryDetailScreen(order: order),
          ),
        )
        .then((_) => _loadDeliveries());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDeliveries,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_orders == null || _orders!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delivery_dining, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No available deliveries',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'New deliveries will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDeliveries,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeliveries,
      child: ListView.builder(
        itemCount: _orders!.length,
        itemBuilder: (context, index) {
          final order = _orders![index];
          return OrderCard(
            order: order,
            showAcceptButton: true,
            onTap: () => _navigateToDetail(order),
            onAccept: () => _handleAccept(order),
          );
        },
      ),
    );
  }
}

class _MyDeliveriesTab extends StatefulWidget {
  final VoidCallback onRefresh;

  const _MyDeliveriesTab({required this.onRefresh});

  @override
  State<_MyDeliveriesTab> createState() => _MyDeliveriesTabState();
}

class _MyDeliveriesTabState extends State<_MyDeliveriesTab> {
  final _deliveriesService = DeliveriesService();
  List<Order>? _orders;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await _deliveriesService.fetchMyDeliveries();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load deliveries';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleStart(Order order) async {
    final result = await _deliveriesService.startDelivery(order.id);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppTheme.statusCompleted,
          ),
        );
        _loadDeliveries();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleComplete(Order order) async {
    final result = await _deliveriesService.completeDelivery(order.id);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppTheme.statusCompleted,
          ),
        );
        _loadDeliveries();
        widget.onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToDetail(Order order) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => DeliveryDetailScreen(order: order),
          ),
        )
        .then((_) => _loadDeliveries());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDeliveries,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_orders == null || _orders!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No active deliveries',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Accept a delivery to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDeliveries,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeliveries,
      child: ListView.builder(
        itemCount: _orders!.length,
        itemBuilder: (context, index) {
          final order = _orders![index];
          final bool showStart =
              order.status == 'assigned' || order.status == 'ready';
          final bool showComplete = order.status == 'out-for-delivery';

          return OrderCard(
            order: order,
            showStartButton: showStart,
            showCompleteButton: showComplete,
            onTap: () => _navigateToDetail(order),
            onStart: showStart ? () => _handleStart(order) : null,
            onComplete: showComplete ? () => _handleComplete(order) : null,
          );
        },
      ),
    );
  }
}

class _CompletedDeliveriesTab extends StatefulWidget {
  final VoidCallback onRefresh;

  const _CompletedDeliveriesTab({required this.onRefresh});

  @override
  State<_CompletedDeliveriesTab> createState() =>
      _CompletedDeliveriesTabState();
}

class _CompletedDeliveriesTabState extends State<_CompletedDeliveriesTab> {
  final _deliveriesService = DeliveriesService();
  List<Order>? _orders;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await _deliveriesService.fetchCompletedDeliveries();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load deliveries';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToDetail(Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeliveryDetailScreen(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDeliveries,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_orders == null || _orders!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No completed deliveries',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed deliveries will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDeliveries,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeliveries,
      child: ListView.builder(
        itemCount: _orders!.length,
        itemBuilder: (context, index) {
          final order = _orders![index];
          return OrderCard(order: order, onTap: () => _navigateToDetail(order));
        },
      ),
    );
  }
}
