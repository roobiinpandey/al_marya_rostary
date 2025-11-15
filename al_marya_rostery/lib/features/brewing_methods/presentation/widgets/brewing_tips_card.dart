import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/brewing_method_model.dart';

class BrewingTipsCard extends StatelessWidget {
  final List<BilingualText> tips;
  final bool isArabic;

  const BrewingTipsCard({
    super.key,
    required this.tips,
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.accentAmber,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'نصائح للتحضير' : 'Brewing Tips',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.asMap().entries.map((entry) {
            final index = entry.key;
            final tip = entry.value;
            return _buildTipItem(context, tip, index + 1);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, BilingualText tip, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.accentAmber,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentAmber.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                isArabic ? tip.ar : tip.en,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textDark,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
