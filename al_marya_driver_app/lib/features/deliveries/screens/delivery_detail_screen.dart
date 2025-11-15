import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/order_model.dart';
import '../services/deliveries_service.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final Order order;

  const DeliveryDetailScreen({super.key, required this.order});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  final _deliveriesService = DeliveriesService();
  final _locationService = LocationService();
  late Order _order;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  Future<void> _openNavigation() async {
    if (_order.deliveryAddress == null ||
        _order.deliveryAddress!.latitude == null ||
        _order.deliveryAddress!.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No coordinates available for navigation'),
        ),
      );
      return;
    }

    final lat = _order.deliveryAddress!.latitude;
    final lng = _order.deliveryAddress!.longitude;

    // Google Maps URL
    final Uri mapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open navigation')),
        );
      }
    }
  }

  Future<void> _handleAccept() async {
    setState(() => _isLoading = true);

    final result = await _deliveriesService.acceptDelivery(_order.id);

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        setState(() {
          _order = result['order'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppTheme.statusCompleted,
          ),
        );
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

  Future<void> _handleStart() async {
    setState(() => _isLoading = true);

    final result = await _deliveriesService.startDelivery(_order.id);

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        setState(() {
          _order = result['order'];
        });

        // Update driver status to on_delivery and ensure tracking is active
        await _locationService.updateDriverStatus(
          AppConstants.statusOnDelivery,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppTheme.statusCompleted,
          ),
        );
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

  Future<void> _handleComplete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Delivery'),
        content: const Text('Have you delivered the order to the customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      final result = await _deliveriesService.completeDelivery(_order.id);

      setState(() => _isLoading = false);

      if (mounted) {
        if (result['success']) {
          // Set driver status back to available after completing delivery
          await _locationService.updateDriverStatus(
            AppConstants.statusAvailable,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppTheme.statusCompleted,
            ),
          );
          Navigator.of(context).pop();
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
  }

  Color _getStatusColor() {
    switch (_order.status) {
      case 'ready':
        return AppTheme.statusPending;
      case 'out-for-delivery':
        return AppTheme.statusInProgress;
      case 'completed':
        return AppTheme.statusCompleted;
      default:
        return AppTheme.textMedium;
    }
  }

  String _getStatusText() {
    switch (_order.status) {
      case 'ready':
        return 'Ready for Pickup';
      case 'out-for-delivery':
        return 'Out for Delivery';
      case 'completed':
        return 'Completed';
      default:
        return _order.status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #${_order.orderNumber}')),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(color: _getStatusColor(), width: 3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _order.status == 'completed'
                            ? Icons.check_circle
                            : Icons.local_shipping,
                        color: _getStatusColor(),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStatusText(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(),
                              ),
                            ),
                            Text(
                              'Order placed ${DateFormat('MMM d, h:mm a').format(_order.createdAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Customer Information
                _buildSection(
                  title: 'Customer Information',
                  icon: Icons.person,
                  child: Column(
                    children: [
                      _buildInfoRow(
                        'Name',
                        _order.customer.name,
                        Icons.person_outline,
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                              'Phone',
                              _order.customer.phone,
                              Icons.phone_outlined,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _makePhoneCall(_order.customer.phone),
                            icon: const Icon(Icons.call, size: 18),
                            label: const Text('Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.statusInProgress,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Delivery Address
                if (_order.deliveryAddress != null)
                  _buildSection(
                    title: 'Delivery Address',
                    icon: Icons.location_on,
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Address',
                          _order.deliveryAddress!.fullAddress,
                          Icons.location_on_outlined,
                        ),
                        if (_order.deliveryAddress!.instructions != null &&
                            _order
                                .deliveryAddress!
                                .instructions!
                                .isNotEmpty) ...[
                          const Divider(height: 24),
                          _buildInfoRow(
                            'Instructions',
                            _order.deliveryAddress!.instructions!,
                            Icons.info_outline,
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openNavigation,
                            icon: const Icon(Icons.navigation),
                            label: const Text('Start Navigation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryOliveGold,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Order Items
                _buildSection(
                  title: 'Order Items',
                  icon: Icons.shopping_bag,
                  child: Column(
                    children: [
                      ..._order.items.map((item) => _buildOrderItem(item)),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'AED ${_order.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryOliveGold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryOliveGold),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.textMedium),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMedium,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16, color: AppTheme.textDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryOliveGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${item.quantity}x',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryOliveGold,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.size != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Size: ${item.size}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
                if (item.addons != null && item.addons!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Add-ons: ${item.addons!.join(', ')}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Note: ${item.notes}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            'AED ${item.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomActions() {
    if (_order.status == 'ready' && _order.driverId == null) {
      // Available delivery - show accept button
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleAccept,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Accept Delivery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOliveGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      );
    } else if (_order.status == 'ready' && _order.driverId != null) {
      // Accepted but not started - show start button
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleStart,
            icon: const Icon(Icons.directions_car),
            label: const Text('Start Delivery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusInProgress,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      );
    } else if (_order.status == 'out-for-delivery') {
      // Out for delivery - show complete button
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleComplete,
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Delivery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusCompleted,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      );
    }

    return null; // No actions for completed orders
  }
}
