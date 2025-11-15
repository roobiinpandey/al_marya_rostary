import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class DripBrewingPage extends StatelessWidget {
  const DripBrewingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        title: const Text('Drip Brewing'),
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
                child: Icon(Icons.local_cafe, size: 80, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),

            // Title and Description
            Text(
              'Drip Brewing Method',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pour-over coffee brewing method that allows water to drip through coffee grounds slowly.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMedium),
            ),
            const SizedBox(height: 24),

            // Equipment Needed
            _buildSection(context, 'Equipment Needed', Icons.build, [
              'V60 dripper or similar pour-over device',
              'Paper filters',
              'Gooseneck kettle',
              'Digital scale',
              'Coffee grinder',
              'Timer',
            ]),

            const SizedBox(height: 24),

            // Coffee to Water Ratio
            _buildInfoCard(
              context,
              'Coffee to Water Ratio',
              '1:15 to 1:17',
              'For every 1g of coffee, use 15-17g of water',
              Icons.balance,
            ),

            const SizedBox(height: 16),

            // Water Temperature
            _buildInfoCard(
              context,
              'Water Temperature',
              '195°F - 205°F',
              '90°C - 96°C for optimal extraction',
              Icons.thermostat,
            ),

            const SizedBox(height: 24),

            // Brewing Steps
            _buildSection(context, 'Brewing Steps', Icons.list_alt, [
              'Heat water to 195-205°F (90-96°C)',
              'Rinse the paper filter with hot water',
              'Add 20-25g of medium-fine ground coffee',
              'Start timer and pour 40-50g water for blooming (30s)',
              'Continue pouring in slow, circular motions',
              'Total brew time: 4-6 minutes',
              'Enjoy your perfectly brewed drip coffee!',
            ]),

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
                    arguments: 'Drip Coffee',
                  );
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Shop Drip Coffee Products'),
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

  Widget _buildTipsSection(BuildContext context) {
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
              Icon(Icons.lightbulb, color: AppTheme.accentAmber),
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
          _buildTip('Use freshly roasted beans (within 2-4 weeks)'),
          _buildTip('Grind coffee just before brewing'),
          _buildTip('Pour in slow, circular motions'),
          _buildTip('Maintain consistent water temperature'),
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
              color: AppTheme.accentAmber,
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
