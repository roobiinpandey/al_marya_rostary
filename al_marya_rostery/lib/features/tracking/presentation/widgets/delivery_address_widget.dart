import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/delivery_tracking_model.dart';

/// Widget displaying delivery address with edit and call options
class DeliveryAddressWidget extends StatelessWidget {
  final DeliveryAddress deliveryAddress;
  final RestaurantInfo restaurantInfo;
  final VoidCallback? onEditInstructions;

  const DeliveryAddressWidget({
    super.key,
    required this.deliveryAddress,
    required this.restaurantInfo,
    this.onEditInstructions,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              if (onEditInstructions != null)
                TextButton.icon(
                  onPressed: onEditInstructions,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryBrown,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, color: AppTheme.primaryBrown, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  deliveryAddress.fullAddress,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textDark,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),

          // Delivery Instructions
          if (deliveryAddress.instructions != null &&
              deliveryAddress.instructions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Instructions',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deliveryAddress.instructions!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Call buttons
          Row(
            children: [
              // Call Restaurant
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _makePhoneCall(restaurantInfo.phone),
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Call Restaurant'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBrown,
                    side: const BorderSide(color: AppTheme.primaryBrown),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Call Support
              if (restaurantInfo.supportPhone != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _makePhoneCall(restaurantInfo.supportPhone!),
                    icon: const Icon(Icons.support_agent, size: 18),
                    label: const Text('Support'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
