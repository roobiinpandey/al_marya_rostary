import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/brewing_method_model.dart';

class BrewingParametersCard extends StatelessWidget {
  final BrewingParameters parameters;

  const BrewingParametersCard({super.key, required this.parameters});

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
            'Brewing Parameters',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBrown,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildParameterItem(
                  context,
                  'Water Temp',
                  '${parameters.waterTemperature}°C',
                  Icons.thermostat,
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildParameterItem(
                  context,
                  'Coffee Ratio',
                  parameters.coffeeToWaterRatio,
                  Icons.scale,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildParameterItem(
                  context,
                  'Grind Size',
                  parameters.grindSize,
                  Icons.grain,
                  Colors.brown,
                ),
              ),
              Expanded(
                child: _buildParameterItem(
                  context,
                  'Brew Time',
                  '${parameters.brewTime.minutes ?? 0} min',
                  Icons.timer,
                  Colors.blue,
                ),
              ),
            ],
          ),
          // No pressure field in the model, so we'll skip this for now
        ],
      ),
    );
  }

  Widget _buildParameterItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
