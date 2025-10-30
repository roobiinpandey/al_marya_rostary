import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/common/app_drawer.dart';

class BrewingGuidePage extends StatelessWidget {
  const BrewingGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        title: const Text(
          'Brewing Guide',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.menu_book,
                      size: 32,
                      color: AppTheme.primaryBrown,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perfect Brewing Guide',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Master the art of coffee brewing with our expert tips',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Brewing Methods',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMethodCard(
              context,
              'Drip Coffee',
              Icons.water_drop,
              'Clean, smooth taste with excellent clarity',
              '/brewing/drip',
            ),
            const SizedBox(height: 12),
            _buildMethodCard(
              context,
              'French Press',
              Icons.coffee_maker,
              'Full-bodied and rich with deep flavors',
              '/brewing/french-press',
            ),
            const SizedBox(height: 12),
            _buildMethodCard(
              context,
              'Espresso',
              Icons.local_cafe,
              'Concentrated and intense coffee experience',
              '/brewing/espresso',
            ),
            const SizedBox(height: 24),
            const Text(
              'General Tips',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTip('Use fresh, cold water for best taste'),
                    _buildTip('Grind beans just before brewing'),
                    _buildTip('Maintain proper water temperature (195-205°F)'),
                    _buildTip('Use the right coffee-to-water ratio'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    String route,
  ) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryBrown.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryBrown, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(description, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to specific brewing method
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $title guide'),
              backgroundColor: AppTheme.primaryBrown,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
