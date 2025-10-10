import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import 'order_tracking_page.dart';

/// OrderConfirmationPage displays successful order confirmation
class OrderConfirmationPage extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderConfirmationPage({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    // Clear cart after successful order
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false).clearCart();
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        title: Text(
          'Order Confirmed',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Success Animation/Icon
            _buildSuccessHeader(),

            const SizedBox(height: 32),

            // Order Details Card
            _buildOrderDetailsCard(),

            const SizedBox(height: 20),

            // Items Summary
            _buildItemsSummary(),

            const SizedBox(height: 20),

            // Delivery Information
            _buildDeliveryInfo(),

            const SizedBox(height: 20),

            // Payment Information
            _buildPaymentInfo(),

            const SizedBox(height: 32),

            // Action Buttons
            _buildActionButtons(context),

            const SizedBox(height: 20),

            // Additional Info
            _buildAdditionalInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBrown.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Order Confirmed!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thank you for your order. We\'ll start preparing your coffee right away!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppTheme.textMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    final orderNumber = orderData['orderNumber'] as String;
    final createdAt = DateTime.parse(orderData['createdAt'] as String);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),

            _buildDetailRow('Order Number', orderNumber),
            _buildDetailRow('Date', _formatDateTime(createdAt)),
            _buildDetailRow('Status', 'Confirmed'),
            _buildDetailRow('Estimated Delivery', _getEstimatedDelivery()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMedium)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSummary() {
    final items = orderData['items'] as List;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Order (${items.length} items)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                return Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.primaryLightBrown.withValues(
                          alpha: 0.2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.coffee,
                              color: AppTheme.primaryBrown,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Qty: ${item.quantity}${item.selectedSize != null ? ' • ${item.selectedSize}' : ''}',
                            style: const TextStyle(
                              color: AppTheme.textMedium,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      '${AppConstants.currencySymbol}${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),
            const Divider(),

            // Order Total
            _buildTotalRow('Subtotal', orderData['subtotal'] as double),
            if ((orderData['deliveryFee'] as double) > 0)
              _buildTotalRow(
                'Delivery Fee',
                orderData['deliveryFee'] as double,
              ),
            if (orderData['paymentMethod'] == 'cash')
              _buildTotalRow('COD Fee', 5.0),

            const SizedBox(height: 8),
            _buildTotalRow('Total', _calculateFinalTotal(), isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppTheme.textDark : AppTheme.textMedium,
            ),
          ),
          Text(
            '${AppConstants.currencySymbol}${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppTheme.primaryBrown : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    final delivery = orderData['delivery'] as Map<String, dynamic>;
    final shippingAddress =
        orderData['shippingAddress'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppTheme.primaryBrown,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shippingAddress['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(shippingAddress['address'] as String),
                      Text(
                        '${shippingAddress['city']}, ${shippingAddress['emirate']}',
                      ),
                      Text(shippingAddress['phone'] as String),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(
                  Icons.local_shipping,
                  color: AppTheme.primaryBrown,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDeliveryMethodText(delivery['method'] as String),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (delivery['date'] != null)
                        Text(
                          'Date: ${_formatDate(delivery['date'] as DateTime)}',
                        ),
                      if (delivery['time'] != null)
                        Text('Time: ${delivery['time']}'),
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

  Widget _buildPaymentInfo() {
    final paymentMethod = orderData['paymentMethod'] as String;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Icon(
                  _getPaymentIcon(paymentMethod),
                  color: AppTheme.primaryBrown,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPaymentMethodText(paymentMethod),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (paymentMethod == 'card' &&
                          orderData['cardLast4'] != null)
                        Text('•••• •••• •••• ${orderData['cardLast4']}'),
                      if (paymentMethod == 'cash')
                        const Text('Pay when your order arrives'),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Confirmed',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
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

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Track Order Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OrderTrackingPage(
                    orderNumber: orderData['orderNumber'] as String,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Track Your Order',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Continue Shopping Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/home', (route) => false);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryBrown),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue Shopping',
              style: TextStyle(
                color: AppTheme.primaryBrown,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLightBrown.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.primaryBrown,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'What happens next?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text('• We\'ll roast your coffee beans to perfection'),
          const Text('• You\'ll receive updates via SMS and email'),
          const Text('• Our delivery partner will contact you before delivery'),
          const Text('• Rate your experience after delivery'),
        ],
      ),
    );
  }

  // Helper methods
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getEstimatedDelivery() {
    final delivery = orderData['delivery'] as Map<String, dynamic>;
    final method = delivery['method'] as String;

    switch (method) {
      case 'same_day':
        return 'Today';
      case 'express':
        return '1-2 business days';
      default:
        return '3-5 business days';
    }
  }

  String _getDeliveryMethodText(String method) {
    switch (method) {
      case 'express':
        return 'Express Delivery';
      case 'same_day':
        return 'Same Day Delivery';
      default:
        return 'Standard Delivery';
    }
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'card':
        return 'Credit/Debit Card';
      case 'cash':
        return 'Cash on Delivery';
      case 'apple_pay':
        return 'Apple Pay';
      case 'google_pay':
        return 'Google Pay';
      default:
        return 'Payment Method';
    }
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'card':
        return Icons.credit_card;
      case 'cash':
        return Icons.money;
      case 'apple_pay':
        return Icons.apple;
      case 'google_pay':
        return Icons.android;
      default:
        return Icons.payment;
    }
  }

  double _calculateFinalTotal() {
    double total = orderData['total'] as double;
    if (orderData['paymentMethod'] == 'cash') {
      total += 5.0; // COD fee
    }
    return total;
  }
}
