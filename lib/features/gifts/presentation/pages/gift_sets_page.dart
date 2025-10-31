import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class GiftSetsPage extends StatelessWidget {
  const GiftSetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        title: const Text('Gift Sets'),
        backgroundColor: AppTheme.accentAmber,
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
                    AppTheme.accentAmber.withValues(alpha: 0.8),
                    AppTheme.accentAmber.withValues(alpha: 0.6),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(Icons.card_giftcard, size: 80, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),

            // Title and Description
            Text(
              'Coffee Gift Sets',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Perfect gift sets for coffee lovers, carefully curated to create memorable coffee experiences.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMedium),
            ),
            const SizedBox(height: 24),

            // Gift Set Types
            _buildGiftSetTypes(context),

            const SizedBox(height: 24),

            // Occasions
            _buildOccasionsGuide(context),

            const SizedBox(height: 24),

            // What's Included
            _buildWhatsIncluded(context),

            const SizedBox(height: 24),

            // Gift Tips
            _buildGiftTips(context),

            const SizedBox(height: 24),

            // Shop Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/category-browse',
                    arguments: 'Gift Sets',
                  );
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Shop Gift Sets'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmber,
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

  Widget _buildGiftSetTypes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Types of Gift Sets',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Starter Set
        _buildGiftSetCard(
          context,
          'Coffee Starter Set',
          'Perfect for coffee beginners',
          Icons.play_circle_outline,
          AppTheme.primaryBrown,
          [
            'Premium coffee beans',
            'Basic brewing guide',
            'Coffee mug',
            'Measuring spoon',
          ],
          '25-50',
        ),

        const SizedBox(height: 16),

        // Brewing Set
        _buildGiftSetCard(
          context,
          'Brewing Enthusiast Set',
          'For the home brewing enthusiast',
          Icons.local_cafe,
          AppTheme.accentAmber,
          [
            'V60 dripper & filters',
            'Specialty coffee beans',
            'Digital scale',
            'Gooseneck kettle',
          ],
          '75-150',
        ),

        const SizedBox(height: 16),

        // Premium Set
        _buildGiftSetCard(
          context,
          'Premium Coffee Set',
          'Luxury gift for coffee connoisseurs',
          Icons.diamond,
          AppTheme.primaryLightBrown,
          [
            'Rare coffee selection',
            'Premium accessories',
            'Gift packaging',
            'Tasting notes',
          ],
          '150-300',
        ),

        const SizedBox(height: 16),

        // Office Set
        _buildGiftSetCard(
          context,
          'Office Coffee Set',
          'Perfect for workplace coffee lovers',
          Icons.business,
          AppTheme.textDark,
          [
            'Travel mug',
            'Instant coffee packets',
            'Desk accessories',
            'Corporate packaging',
          ],
          '30-75',
        ),
      ],
    );
  }

  Widget _buildGiftSetCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    List<String> features,
    String priceRange,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
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
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '\$${priceRange}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Typically includes:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: features.map((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  feature,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOccasionsGuide(BuildContext context) {
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
              Icon(Icons.celebration, color: AppTheme.accentAmber),
              const SizedBox(width: 8),
              Text(
                'Perfect Gift Occasions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOccasionRow('Birthday', 'Personalized coffee experience'),
          _buildOccasionRow('Holiday', 'Seasonal coffee blends'),
          _buildOccasionRow('Corporate', 'Professional gift sets'),
          _buildOccasionRow('Housewarming', 'Home brewing essentials'),
          _buildOccasionRow('Thank You', 'Appreciation gift sets'),
          _buildOccasionRow('Anniversary', 'Premium luxury sets'),
        ],
      ),
    );
  }

  Widget _buildOccasionRow(String occasion, String suggestion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              occasion,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              suggestion,
              style: const TextStyle(color: AppTheme.textMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsIncluded(BuildContext context) {
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
              Icon(Icons.inventory, color: AppTheme.accentAmber),
              const SizedBox(width: 8),
              Text(
                'What\'s Included in Our Gift Sets',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildIncludedPoint('Premium coffee beans from Al Marya Rostery'),
          _buildIncludedPoint('High-quality brewing accessories'),
          _buildIncludedPoint('Beautiful gift packaging'),
          _buildIncludedPoint('Brewing guides and instructions'),
          _buildIncludedPoint('Personalized gift message option'),
          _buildIncludedPoint('Quality guarantee on all items'),
        ],
      ),
    );
  }

  Widget _buildIncludedPoint(String point) {
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
              point,
              style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftTips(BuildContext context) {
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
                'Gift Giving Tips',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('Consider the recipient\'s coffee experience level'),
          _buildTip('Include a personalized message for extra touch'),
          _buildTip('Choose gift wrapping for special occasions'),
          _buildTip('Add brewing instructions for beginners'),
          _buildTip('Consider pairing with our coffee subscription'),
          _buildTip('Order early for holiday and special occasions'),
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
