import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/common/app_drawer.dart';

class BestSellersPage extends StatelessWidget {
  const BestSellersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.trending_up, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text('Best Sellers', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        elevation: 2,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade100, Colors.green.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Customer Favorites',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Our most popular products loved by thousands of coffee enthusiasts worldwide.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Top Performers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBestSellerCard(
              context,
              '#1 Al Marya House Blend',
              'Our signature coffee blend',
              '4.9 ⭐ (2,847 reviews)',
              Icons.local_cafe,
              Colors.amber,
            ),
            const SizedBox(height: 12),
            _buildBestSellerCard(
              context,
              '#2 Ethiopian Yirgacheffe',
              'Single origin premium coffee',
              '4.8 ⭐ (1,923 reviews)',
              Icons.public,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildBestSellerCard(
              context,
              '#3 French Roast Dark',
              'Bold and intense flavor',
              '4.7 ⭐ (1,654 reviews)',
              Icons.local_fire_department,
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildBestSellerCard(
              context,
              '#4 Espresso Supreme',
              'Perfect for espresso lovers',
              '4.8 ⭐ (1,445 reviews)',
              Icons.coffee,
              Colors.brown,
            ),
            const SizedBox(height: 12),
            _buildBestSellerCard(
              context,
              '#5 Morning Breakfast Blend',
              'Light and smooth start',
              '4.6 ⭐ (1,234 reviews)',
              Icons.wb_sunny,
              Colors.yellow,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/coffee'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Shop Best Sellers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSellerCard(
    BuildContext context,
    String title,
    String description,
    String rating,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rating,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added $title to cart'),
                    backgroundColor: AppTheme.primaryBrown,
                  ),
                );
              },
              icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
