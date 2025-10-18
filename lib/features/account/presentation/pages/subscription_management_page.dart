import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

class SubscriptionManagementPage extends StatefulWidget {
  const SubscriptionManagementPage({super.key});

  @override
  State<SubscriptionManagementPage> createState() =>
      _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState
    extends State<SubscriptionManagementPage> {
  final List<Map<String, dynamic>> _activeSubscriptions = [
    {
      'id': '1',
      'name': 'Ethiopian Yirgacheffe',
      'size': '500g',
      'frequency': 'Every 2 weeks',
      'nextDelivery': DateTime.now().add(const Duration(days: 8)),
      'price': 24.99,
      'status': 'active',
      'imageUrl': '',
    },
    {
      'id': '2',
      'name': 'Colombian Supremo',
      'size': '1kg',
      'frequency': 'Monthly',
      'nextDelivery': DateTime.now().add(const Duration(days: 15)),
      'price': 42.99,
      'status': 'active',
      'imageUrl': '',
    },
  ];

  final List<Map<String, dynamic>> _availablePlans = [
    {
      'name': 'Weekly Coffee Lover',
      'frequency': 'Weekly',
      'discount': '15%',
      'description': 'Fresh coffee delivered every week',
      'icon': Icons.local_cafe,
      'color': AppTheme.primaryBrown,
    },
    {
      'name': 'Bi-Weekly Enthusiast',
      'frequency': 'Every 2 weeks',
      'discount': '12%',
      'description': 'Perfect for regular coffee drinkers',
      'icon': Icons.coffee,
      'color': AppTheme.primaryBrown,
    },
    {
      'name': 'Monthly Explorer',
      'frequency': 'Monthly',
      'discount': '10%',
      'description': 'Try new blends each month',
      'icon': Icons.coffee_maker,
      'color': AppTheme.primaryLightBrown,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isGuest) {
      return _buildGuestMessage();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Coffee Subscriptions'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Benefits Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryBrown, AppTheme.primaryLightBrown],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome, size: 48, color: Colors.amber),
                  const SizedBox(height: 16),
                  const Text(
                    'Subscribe & Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get up to 15% off with automatic deliveries',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Active Subscriptions
          if (_activeSubscriptions.isNotEmpty) ...[
            _buildSection(
              'Active Subscriptions',
              Column(
                children: _activeSubscriptions.map((subscription) {
                  return _buildSubscriptionCard(subscription);
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Subscription Benefits
          _buildSection(
            'Subscription Benefits',
            Column(
              children: [
                _buildBenefitItem(
                  Icons.local_shipping,
                  'Free Delivery',
                  'Always get free shipping',
                  Colors.blue,
                ),
                _buildBenefitItem(
                  Icons.discount,
                  'Best Prices',
                  'Save up to 15% on every order',
                  Colors.green,
                ),
                _buildBenefitItem(
                  Icons.pause_circle,
                  'Flexible',
                  'Pause or cancel anytime',
                  Colors.orange,
                ),
                _buildBenefitItem(
                  Icons.swap_horiz,
                  'Easy Changes',
                  'Change coffee or delivery frequency',
                  Colors.purple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Available Plans
          _buildSection(
            'Choose Your Plan',
            Column(
              children: _availablePlans.map((plan) {
                return _buildPlanCard(plan);
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // How It Works
          _buildSection(
            'How It Works',
            Column(
              children: [
                _buildStep(
                  1,
                  'Choose Your Coffee',
                  'Select from our premium collection',
                ),
                _buildStep(
                  2,
                  'Pick Your Frequency',
                  'Weekly, bi-weekly, or monthly',
                ),
                _buildStep(
                  3,
                  'Enjoy Fresh Coffee',
                  'Delivered right to your door',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Browse Coffee Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/coffee');
              },
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Browse Coffee Collection'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> subscription) {
    final nextDelivery = subscription['nextDelivery'] as DateTime;
    final daysUntilDelivery = nextDelivery.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.coffee,
                    size: 32,
                    color: AppTheme.primaryBrown,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${subscription['size']} • ${subscription['frequency']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${subscription['price']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    size: 20,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Next delivery in $daysUntilDelivery days',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pauseSubscription(subscription),
                    icon: const Icon(Icons.pause, size: 18),
                    label: const Text('Pause'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _modifySubscription(subscription),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modify'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelSubscription(subscription),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectPlan(plan),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (plan['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  plan['icon'] as IconData,
                  color: plan['color'] as Color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Save ${plan['discount']}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan['description'] as String,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan['frequency'] as String,
                      style: TextStyle(
                        color: plan['color'] as Color,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestMessage() {
    return Scaffold(
      appBar: AppBar(title: const Text('Coffee Subscriptions')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.coffee_maker, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 24),
              const Text(
                'Sign in to manage subscriptions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Create an account to subscribe and save up to 15% on fresh coffee deliveries',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Replace entire stack with login page for clean navigation
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                icon: const Icon(Icons.login),
                label: const Text('Sign In'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pauseSubscription(Map<String, dynamic> subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause Subscription'),
        content: Text(
          'Pause "${subscription['name']}" subscription?\n\nYou can resume it anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription paused'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Pause'),
          ),
        ],
      ),
    );
  }

  void _modifySubscription(Map<String, dynamic> subscription) {
    Navigator.pushNamed(context, '/coffee');
  }

  void _cancelSubscription(Map<String, dynamic> subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: Text(
          'Are you sure you want to cancel "${subscription['name']}"?\n\nYou\'ll lose your subscription discount.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Subscription'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _activeSubscriptions.removeWhere(
                  (s) => s['id'] == subscription['id'],
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription cancelled'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }

  void _selectPlan(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plan['name'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan['description'] as String),
            const SizedBox(height: 16),
            Text('Delivery: ${plan['frequency']}'),
            Text('Discount: ${plan['discount']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/coffee');
            },
            child: const Text('Browse Coffee'),
          ),
        ],
      ),
    );
  }
}
