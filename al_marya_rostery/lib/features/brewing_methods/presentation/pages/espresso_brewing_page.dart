import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class EspressoBrewingPage extends StatelessWidget {
  const EspressoBrewingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        title: const Text('Espresso'),
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryBrown.withValues(alpha: 0.8),
                    AppTheme.primaryLightBrown,
                  ],
                ),
              ),
              child: const Center(
                child: Icon(Icons.coffee, size: 80, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),

            // Title and Description
            Text(
              'Espresso Method',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'High-pressure brewing method that creates a concentrated, intense coffee shot with rich crema.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMedium),
            ),
            const SizedBox(height: 24),

            // Equipment Needed
            _buildSection(context, 'Equipment Needed', Icons.build, [
              'Espresso machine with pump',
              'Coffee grinder (burr grinder preferred)',
              'Tamper',
              'Portafilter and basket',
              'Espresso cups (2-3 oz)',
              'Scale for dosing',
            ]),

            const SizedBox(height: 24),

            // Coffee Dose
            _buildInfoCard(
              context,
              'Coffee Dose',
              '18-20g',
              'Standard double shot dose',
              Icons.balance,
            ),

            const SizedBox(height: 16),

            // Extraction Time
            _buildInfoCard(
              context,
              'Extraction Time',
              '25-30 seconds',
              'Optimal extraction for double shot',
              Icons.timer,
            ),

            const SizedBox(height: 16),

            // Water Temperature
            _buildInfoCard(
              context,
              'Water Temperature',
              '190°F - 196°F',
              '88°C - 91°C for best extraction',
              Icons.thermostat,
            ),

            const SizedBox(height: 16),

            // Pressure
            _buildInfoCard(
              context,
              'Pressure',
              '9 bars',
              'Standard brewing pressure',
              Icons.compress,
            ),

            const SizedBox(height: 24),

            // Brewing Steps
            _buildSection(context, 'Brewing Steps', Icons.list_alt, [
              'Dose 18-20g of finely ground coffee',
              'Level and distribute grounds evenly',
              'Tamp with 30lbs of pressure',
              'Lock portafilter into group head',
              'Start extraction immediately',
              'Stop at 25-30 seconds for 36-40ml output',
              'Serve immediately while crema is fresh',
              'Clean portafilter and group head',
            ]),

            const SizedBox(height: 24),

            // Grind Size Guide
            _buildGrindGuide(context),

            const SizedBox(height: 24),

            // Crema Guide
            _buildCremaGuide(context),

            const SizedBox(height: 24),

            // Tips Section
            _buildTipsSection(context),

            const SizedBox(height: 24),

            // Recommended Products Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/category-browse',
                    arguments: 'Espresso',
                  );
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Shop Espresso Products'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryBrown),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBrown,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
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
                  child: Text(
                    entry.value,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppTheme.textDark),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    String description,
    IconData icon,
  ) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryBrown),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.textMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrindGuide(BuildContext context) {
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
              Icon(Icons.grain, color: AppTheme.primaryBrown),
              const SizedBox(width: 8),
              Text(
                'Grind Size Guide',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Espresso requires a FINE grind - similar to table salt or powdered sugar. The grind should be fine enough to create resistance but not so fine as to cause channeling.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildCremaGuide(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bubble_chart, color: AppTheme.accentAmber),
              const SizedBox(width: 8),
              Text(
                'Perfect Crema',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Good crema should be:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildCremaPoint('Golden-brown in color'),
          _buildCremaPoint('2-3mm thick layer'),
          _buildCremaPoint('Smooth and even texture'),
          _buildCremaPoint('Persists for 2-3 minutes'),
        ],
      ),
    );
  }

  Widget _buildCremaPoint(String point) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentAmber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              point,
              style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLightBrown.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryLightBrown.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppTheme.primaryBrown),
              const SizedBox(width: 8),
              Text(
                'Pro Tips',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('Use freshly roasted beans (5-14 days post-roast)'),
          _buildTip('Maintain consistent tamping pressure'),
          _buildTip('Start extraction immediately after tamping'),
          _buildTip('Watch for even extraction from both spouts'),
          _buildTip('Clean machine regularly for best taste'),
          _buildTip('Adjust grind size if extraction is too fast/slow'),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
