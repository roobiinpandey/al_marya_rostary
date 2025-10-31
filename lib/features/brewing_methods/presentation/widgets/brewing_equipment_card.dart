import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/brewing_method_model.dart';

class BrewingEquipmentCard extends StatelessWidget {
  final List<BrewingEquipment> equipment;
  final bool isArabic;

  const BrewingEquipmentCard({
    super.key,
    required this.equipment,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'المعدات المطلوبة' : 'Required Equipment',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBrown,
            ),
          ),
          const SizedBox(height: 16),
          ...equipment.map((item) => _buildEquipmentItem(context, item)),
        ],
      ),
    );
  }

  Widget _buildEquipmentItem(BuildContext context, BrewingEquipment item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentAmber.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentAmber.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentAmber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getEquipmentIcon(item.name.en),
              color: AppTheme.accentAmber,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? item.name.ar : item.name.en,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    isArabic ? item.description!.ar : item.description!.en,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!item.required)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isArabic ? 'اختياري' : 'Optional',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getEquipmentIcon(String equipmentName) {
    final name = equipmentName.toLowerCase();
    if (name.contains('espresso') || name.contains('machine')) {
      return Icons.coffee_maker;
    } else if (name.contains('grinder')) {
      return Icons.settings;
    } else if (name.contains('scale')) {
      return Icons.scale;
    } else if (name.contains('kettle')) {
      return Icons.local_drink;
    } else if (name.contains('filter')) {
      return Icons.filter_alt;
    } else if (name.contains('cup') || name.contains('mug')) {
      return Icons.coffee;
    } else if (name.contains('spoon') || name.contains('tamper')) {
      return Icons.dining;
    } else if (name.contains('timer')) {
      return Icons.timer;
    } else if (name.contains('thermometer')) {
      return Icons.thermostat;
    } else {
      return Icons.coffee_maker;
    }
  }
}
