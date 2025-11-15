import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ShippingAddressWidget extends StatelessWidget {
  final String name;
  final String phone;
  final String address;
  final String city;
  final String emirate;
  final VoidCallback? onEdit;

  const ShippingAddressWidget({
    super.key,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.emirate,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
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
                  'Shipping Address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                if (onEdit != null)
                  TextButton(
                    onPressed: onEdit,
                    child: const Text(
                      'Edit',
                      style: TextStyle(color: AppTheme.primaryBrown),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAddressRow(Icons.person, name),
            const SizedBox(height: 8),
            _buildAddressRow(Icons.phone, phone),
            const SizedBox(height: 8),
            _buildAddressRow(Icons.location_on, address),
            const SizedBox(height: 8),
            _buildAddressRow(Icons.location_city, '$city, $emirate'),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryBrown),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
