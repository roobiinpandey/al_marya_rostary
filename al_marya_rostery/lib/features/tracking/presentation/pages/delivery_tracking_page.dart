import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/delivery_tracking_model.dart';
import '../../data/services/delivery_tracking_service.dart';
import '../widgets/delivery_map_widget.dart';
import '../widgets/order_status_card.dart';
import '../widgets/delivery_address_widget.dart';
import '../widgets/receiver_details_widget.dart';

/// Noon Food-style delivery tracking screen
class DeliveryTrackingPage extends StatefulWidget {
  final String orderId;
  final String orderNumber;

  const DeliveryTrackingPage({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage> {
  final DeliveryTrackingService _trackingService = DeliveryTrackingService();
  StreamSubscription? _trackingSubscription;

  DeliveryTrackingData? _trackingData;
  bool _isLoading = true;
  String? _error;
  ReceiverDetails? _receiverDetails;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    _trackingSubscription = _trackingService
        .trackOrder(widget.orderId)
        .listen(
          (data) {
            setState(() {
              _trackingData = data;
              _isLoading = false;
              _error = null;
              _receiverDetails = data.receiverDetails;
            });
          },
          onError: (error) {
            setState(() {
              _error = error.toString();
              _isLoading = false;
            });
          },
        );
  }

  void _handleEditInstructions() {
    showDialog(
      context: context,
      builder: (context) => _buildInstructionsDialog(),
    );
  }

  Widget _buildInstructionsDialog() {
    final controller = TextEditingController(
      text: _trackingData?.deliveryAddress.instructions ?? '',
    );

    return AlertDialog(
      title: const Text('Delivery Instructions'),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Enter delivery instructions...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final success = await _trackingService.updateDeliveryInstructions(
              widget.orderId,
              controller.text,
            );

            if (!mounted) return;

            if (success) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Instructions updated successfully'),
                ),
              );
              _startTracking(); // Refresh data
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to update instructions'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _handleReceiverDetailsChanged(ReceiverDetails receiverDetails) async {
    setState(() {
      _receiverDetails = receiverDetails;
    });

    // Save to backend
    await _trackingService.updateReceiverDetails(
      widget.orderId,
      receiverDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Track Order #${widget.orderNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView()
          : _buildTrackingView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Unable to load tracking data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startTracking,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingView() {
    if (_trackingData == null) {
      return const Center(child: Text('No tracking data available'));
    }

    return Stack(
      children: [
        // Google Map (top half)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.4,
          child: DeliveryMapWidget(
            pickupLocation: _trackingData!.pickupLocation,
            deliveryLocation: _trackingData!.deliveryLocation,
            driverLocation: _trackingData!.driverLocation,
            routePolyline: _trackingData!.routePolyline,
          ),
        ),

        // Bottom sheet (scrollable)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.35,
          left: 0,
          right: 0,
          bottom: 0,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Order Status Card
                OrderStatusCard(trackingData: _trackingData!),

                // Delivery Address
                DeliveryAddressWidget(
                  deliveryAddress: _trackingData!.deliveryAddress,
                  restaurantInfo: _trackingData!.restaurantInfo,
                  onEditInstructions: _handleEditInstructions,
                ),

                // Receiver Details
                ReceiverDetailsWidget(
                  initialReceiverDetails: _receiverDetails,
                  onReceiverDetailsChanged: _handleReceiverDetailsChanged,
                  currentUserName: 'Current User', // Get from auth/profile
                ),

                // Bottom padding
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    _trackingService.stopTracking();
    super.dispose();
  }
}
