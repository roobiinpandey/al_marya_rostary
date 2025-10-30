import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/common/app_drawer.dart';

class AccessoriesPage extends StatelessWidget {
  const AccessoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.settings, color: Colors.grey, size: 20),
            SizedBox(width: 8),
            Text(
              'Coffee Accessories',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                  colors: [Colors.grey.shade200, Colors.grey.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: Colors.grey, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Coffee Equipment',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Everything you need to brew the perfect cup at home. Professional-grade equipment and accessories.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Categories',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildAccessoryCard(
              context,
              'Brewing Equipment',
              'French press, pour-over, espresso machines',
              Icons.coffee_maker,
              Colors.brown,
            ),
            const SizedBox(height: 12),
            _buildAccessoryCard(
              context,
              'Grinders',
              'Manual and electric coffee grinders',
              Icons.grain,
              Colors.amber,
            ),
            const SizedBox(height: 12),
            _buildAccessoryCard(
              context,
              'Filters & Papers',
              'Coffee filters for all brewing methods',
              Icons.filter_alt,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildAccessoryCard(
              context,
              'Scales & Measuring',
              'Precision scales and measuring tools',
              Icons.balance,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildAccessoryCard(
              context,
              'Storage Solutions',
              'Airtight containers and storage jars',
              Icons.inventory_2,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildAccessoryCard(
              context,
              'Mugs & Cups',
              'Premium coffee mugs and cups',
              Icons.local_cafe,
              Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              'Featured Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildFeaturedProductCard(
              context,
              'Al Marya Premium French Press',
              'Glass and stainless steel construction',
              'AED 149',
              Icons.coffee_maker,
            ),
            const SizedBox(height: 12),
            _buildFeaturedProductCard(
              context,
              'Precision Coffee Scale',
              'Digital scale with 0.1g accuracy',
              'AED 89',
              Icons.balance,
            ),
            const SizedBox(height: 12),
            _buildFeaturedProductCard(
              context,
              'Ceramic Pour-Over Dripper',
              'V60 style ceramic dripper',
              'AED 65',
              Icons.filter_alt,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/shop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Shop All Accessories',
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

  Widget _buildAccessoryCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(description, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $title'),
              backgroundColor: AppTheme.primaryBrown,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedProductCard(
    BuildContext context,
    String title,
    String description,
    String price,
    IconData icon,
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
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.grey.shade700, size: 24),
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
                    price,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryBrown,
                      fontWeight: FontWeight.bold,
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
              icon: const Icon(Icons.add_shopping_cart, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
