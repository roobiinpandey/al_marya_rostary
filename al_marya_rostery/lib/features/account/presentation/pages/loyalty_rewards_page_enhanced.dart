import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/loyalty_provider.dart';
import '../../../../core/theme/app_theme.dart';

class LoyaltyRewardsPageEnhanced extends StatefulWidget {
  const LoyaltyRewardsPageEnhanced({super.key});

  @override
  State<LoyaltyRewardsPageEnhanced> createState() =>
      _LoyaltyRewardsPageEnhancedState();
}

class _LoyaltyRewardsPageEnhancedState extends State<LoyaltyRewardsPageEnhanced>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load loyalty data when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final loyaltyProvider = context.read<LoyaltyProvider>();

      if (!authProvider.isGuest && authProvider.user != null) {
        loyaltyProvider.initializeLoyaltyData(authProvider.user!.id);
      } else {
        loyaltyProvider.initializeLoyaltyData(null);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isGuest) {
      return _buildGuestMessage();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty & Rewards'),
        elevation: 0,
        actions: [
          Consumer<LoyaltyProvider>(
            builder: (context, loyaltyProvider, child) {
              return IconButton(
                icon: loyaltyProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: loyaltyProvider.isLoading
                    ? null
                    : () => loyaltyProvider.refresh(authProvider.user?.id),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Overview'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'Rewards'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.star), text: 'Tiers'),
          ],
        ),
      ),
      body: Consumer<LoyaltyProvider>(
        builder: (context, loyaltyProvider, child) {
          if (loyaltyProvider.isLoading && !loyaltyProvider.hasLoyaltyAccount) {
            return const Center(child: CircularProgressIndicator());
          }

          if (loyaltyProvider.hasError && !loyaltyProvider.hasLoyaltyAccount) {
            return _buildErrorState(
              loyaltyProvider.error!,
              loyaltyProvider,
              authProvider.user?.id,
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(loyaltyProvider),
              _buildRewardsTab(loyaltyProvider, authProvider.user?.id),
              _buildHistoryTab(loyaltyProvider),
              _buildTiersTab(loyaltyProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGuestMessage() {
    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty & Rewards')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Login Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please log in to view your loyalty points and rewards.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                icon: const Icon(Icons.login),
                label: const Text('Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBrown,
                  foregroundColor: Colors.white,
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

  Widget _buildErrorState(
    String error,
    LoyaltyProvider provider,
    String? userId,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load loyalty data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.refresh(userId),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(LoyaltyProvider provider) {
    final points = provider.currentPoints;
    final tier = provider.currentTier;
    final progress = provider.tierProgress;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    AppTheme.primaryBrown,
                    AppTheme.primaryBrown.withValues(alpha: 0.8),
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
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '$points',
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
                        child: Text(
                          tier,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Progress to next tier
                  if (provider.pointsToNextTier > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progress to next tier',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '${provider.pointsToNextTier} points to go',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Lifetime Points',
                  '${provider.lifetimePoints}',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Redemptions',
                  '${provider.loyaltyAccount?['totalRedemptions'] ?? 0}',
                  Icons.redeem,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Activity Preview
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (provider.pointsHistory.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No activity yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start earning points with your first purchase!',
                      style: TextStyle(color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...provider.pointsHistory.take(3).map((transaction) {
              return _buildTransactionItem(transaction);
            }),

          if (provider.pointsHistory.length > 3) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: const Text('View All History'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardsTab(LoyaltyProvider provider, String? userId) {
    return RefreshIndicator(
      onRefresh: () => provider.refresh(userId),
      child: provider.availableRewards.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(32),
              children: [
                Icon(
                  Icons.card_giftcard_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No rewards available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep earning points to unlock exciting rewards!',
                  style: TextStyle(color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.availableRewards.length,
              itemBuilder: (context, index) {
                final reward = provider.availableRewards[index];
                return _buildRewardCard(reward, provider, userId);
              },
            ),
    );
  }

  Widget _buildHistoryTab(LoyaltyProvider provider) {
    return provider.pointsHistory.isEmpty
        ? ListView(
            padding: const EdgeInsets.all(32),
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No history yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your points transactions will appear here',
                style: TextStyle(color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.pointsHistory.length,
            itemBuilder: (context, index) {
              return _buildTransactionItem(provider.pointsHistory[index]);
            },
          );
  }

  Widget _buildTiersTab(LoyaltyProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.loyaltyTiers.length,
      itemBuilder: (context, index) {
        final tier = provider.loyaltyTiers[index];
        final isCurrentTier = tier['name'] == provider.currentTier;
        return _buildTierCard(tier, isCurrentTier);
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final points = transaction['points'] ?? 0;
    final type = transaction['type'] ?? 'earned';
    final description = transaction['description'] ?? 'Transaction';
    final date =
        DateTime.tryParse(transaction['createdAt'] ?? '') ?? DateTime.now();

    Color pointsColor = points > 0 ? Colors.green : Colors.red;
    IconData icon = type == 'earned'
        ? Icons.add_circle
        : type == 'redeemed'
        ? Icons.remove_circle
        : Icons.star_border;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: pointsColor.withValues(alpha: 0.1),
          child: Icon(icon, color: pointsColor),
        ),
        title: Text(description),
        subtitle: Text(_formatDate(date)),
        trailing: Text(
          '${points > 0 ? '+' : ''}$points',
          style: TextStyle(fontWeight: FontWeight.bold, color: pointsColor),
        ),
      ),
    );
  }

  Widget _buildRewardCard(
    Map<String, dynamic> reward,
    LoyaltyProvider provider,
    String? userId,
  ) {
    final title = reward['title'] ?? 'Reward';
    final description = reward['description'] ?? '';
    final pointsRequired = reward['pointsRequired'] ?? 0;
    final canRedeem = provider.currentPoints >= pointsRequired;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    color: AppTheme.primaryBrown,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '$pointsRequired points',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed:
                      canRedeem && !provider.isRedeeming && userId != null
                      ? () => _showRedeemDialog(reward, provider, userId)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canRedeem ? AppTheme.primaryBrown : null,
                    foregroundColor: canRedeem ? Colors.white : null,
                  ),
                  child: provider.isRedeeming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(canRedeem ? 'Redeem' : 'Not enough points'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(Map<String, dynamic> tier, bool isCurrentTier) {
    final name = tier['name'] ?? 'Tier';
    final minPoints = tier['minPoints'] ?? 0;
    final maxPoints = tier['maxPoints'];
    final benefits = List<String>.from(tier['benefits'] ?? []);
    final colorHex = tier['color'] ?? '#CD7F32';
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isCurrentTier ? 8 : 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isCurrentTier ? Border.all(color: color, width: 2) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.star, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            if (isCurrentTier) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Current',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          maxPoints != null
                              ? '$minPoints - $maxPoints points'
                              : '$minPoints+ points',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Benefits:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...benefits.map(
                (benefit) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(benefit)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRedeemDialog(
    Map<String, dynamic> reward,
    LoyaltyProvider provider,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Redeem ${reward['title']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reward['description'] ?? ''),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.stars, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Cost: ${reward['pointsRequired']} points',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Remaining points: ${provider.currentPoints - (reward['pointsRequired'] ?? 0)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await provider.redeemReward(
                  userId: userId,
                  rewardId: reward['_id'] ?? 'mock_reward',
                  pointsRequired: reward['pointsRequired'] ?? 0,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Reward redeemed successfully!'
                            : 'Failed to redeem reward. Please try again.',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                foregroundColor: Colors.white,
              ),
              child: const Text('Redeem'),
            ),
          ],
        );
      },
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
