import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

class LoyaltyRewardsPage extends StatefulWidget {
  const LoyaltyRewardsPage({super.key});

  @override
  State<LoyaltyRewardsPage> createState() => _LoyaltyRewardsPageState();
}

class _LoyaltyRewardsPageState extends State<LoyaltyRewardsPage> {
  // Mock user points data
  int _totalPoints = 1250;
  final int _pointsToNextReward = 250;
  final String _membershipTier = 'Gold';

  final List<Map<String, dynamic>> _pointsHistory = [
    {
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'description': 'Purchase - Ethiopian Yirgacheffe',
      'points': 150,
      'type': 'earned',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'description': 'Redeemed - Free 250g Coffee',
      'points': -500,
      'type': 'redeemed',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 10)),
      'description': 'Purchase - Colombian Supremo',
      'points': 200,
      'type': 'earned',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 15)),
      'description': 'Birthday Bonus',
      'points': 100,
      'type': 'bonus',
    },
  ];

  final List<Map<String, dynamic>> _availableRewards = [
    {
      'title': 'Free 250g Coffee',
      'points': 500,
      'description': 'Choose any 250g coffee blend',
      'icon': Icons.coffee,
      'color': AppTheme.primaryBrown,
    },
    {
      'title': '10% Off Next Purchase',
      'points': 300,
      'description': 'Valid for 30 days',
      'icon': Icons.discount,
      'color': Colors.green.shade700,
    },
    {
      'title': 'Free Shipping',
      'points': 200,
      'description': 'On your next order',
      'icon': Icons.local_shipping,
      'color': Colors.blue.shade700,
    },
    {
      'title': 'Premium Tasting Set',
      'points': 1000,
      'description': '5 premium coffee samples',
      'icon': Icons.card_giftcard,
      'color': Colors.purple.shade700,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final progress = (_totalPoints % 1500) / 1500;

    if (authProvider.isGuest) {
      return _buildGuestMessage();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty & Rewards'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Points Overview Card
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
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.7),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Points',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _totalPoints.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.stars,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _membershipTier,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$_pointsToNextReward points to next reward',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.amber,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // How to Earn Points
          _buildSection(
            'How to Earn Points',
            Column(
              children: [
                _buildEarnPointsItem(
                  Icons.shopping_bag,
                  'Shop',
                  'Earn 10 points for every \$1 spent',
                  Colors.green,
                ),
                _buildEarnPointsItem(
                  Icons.share,
                  'Refer Friends',
                  'Get 500 points for each referral',
                  Colors.blue,
                ),
                _buildEarnPointsItem(
                  Icons.cake,
                  'Birthday',
                  'Receive 100 bonus points',
                  Colors.purple,
                ),
                _buildEarnPointsItem(
                  Icons.rate_review,
                  'Review',
                  'Earn 50 points per product review',
                  Colors.orange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Available Rewards
          _buildSection(
            'Redeem Rewards',
            Column(
              children: _availableRewards.map((reward) {
                return _buildRewardCard(reward);
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Points History
          _buildSection(
            'Points History',
            Column(
              children: _pointsHistory.map((transaction) {
                return _buildHistoryItem(transaction);
              }).toList(),
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

  Widget _buildEarnPointsItem(
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

  Widget _buildRewardCard(Map<String, dynamic> reward) {
    final canRedeem = _totalPoints >= (reward['points'] as int);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (reward['color'] as Color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            reward['icon'] as IconData,
            color: reward['color'] as Color,
          ),
        ),
        title: Text(
          reward['title'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(reward['description'] as String),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.stars, size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 4),
                Text(
                  '${reward['points']} points',
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: canRedeem ? () => _redeemReward(reward) : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Text(canRedeem ? 'Redeem' : 'Locked'),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> transaction) {
    final isEarned =
        transaction['type'] == 'earned' || transaction['type'] == 'bonus';
    final points = transaction['points'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isEarned
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
          child: Icon(
            isEarned ? Icons.add : Icons.remove,
            color: isEarned ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          transaction['description'] as String,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          _formatDate(transaction['date'] as DateTime),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Text(
          '${isEarned ? '+' : ''}$points',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isEarned ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildGuestMessage() {
    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty & Rewards')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.card_giftcard, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 24),
              const Text(
                'Sign in to view rewards',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Create an account to start earning points and unlock exclusive rewards',
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

  void _redeemReward(Map<String, dynamic> reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem Reward'),
        content: Text(
          'Redeem "${reward['title']}" for ${reward['points']} points?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _totalPoints -= reward['points'] as int;
                _pointsHistory.insert(0, {
                  'date': DateTime.now(),
                  'description': 'Redeemed - ${reward['title']}',
                  'points': -(reward['points'] as int),
                  'type': 'redeemed',
                });
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${reward['title']} redeemed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }
}
