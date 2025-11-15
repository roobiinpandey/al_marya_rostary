import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../subscriptions/presentation/providers/subscriptions_provider.dart';
import '../../../../data/models/subscription_model.dart';
import '../../../../core/theme/app_theme.dart';

class SubscriptionManagementPage extends StatefulWidget {
  const SubscriptionManagementPage({super.key});

  @override
  State<SubscriptionManagementPage> createState() =>
      _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState
    extends State<SubscriptionManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubscriptionData();
    });
  }

  Future<void> _loadSubscriptionData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final subscriptionsProvider = Provider.of<SubscriptionsProvider>(
      context,
      listen: false,
    );

    if (authProvider.user != null) {
      await subscriptionsProvider.loadUserSubscriptions(authProvider.user!.id);
      await subscriptionsProvider.loadSubscriptionPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isGuest) {
      return _buildGuestMessage();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Subscriptions'),
        elevation: 0,
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SubscriptionsProvider>(
        builder: (context, subscriptionsProvider, child) {
          if (subscriptionsProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBrown),
            );
          }

          if (subscriptionsProvider.hasError) {
            return _buildErrorState(subscriptionsProvider.error!);
          }

          return RefreshIndicator(
            onRefresh: _loadSubscriptionData,
            color: AppTheme.primaryBrown,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Benefits Card
                _buildBenefitsCard(),
                const SizedBox(height: 24),

                // Active Subscriptions Section
                _buildActiveSubscriptionsSection(subscriptionsProvider),
                const SizedBox(height: 24),

                // Available Plans Section
                _buildAvailablePlansSection(subscriptionsProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Unable to load subscriptions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSubscriptionData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              'Get up to 15% off with automatic deliveries in AED',
              style: TextStyle(
                color: Colors.white.withAlpha(230),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBenefitIcon(Icons.local_shipping, 'Free\nDelivery'),
                _buildBenefitIcon(Icons.discount, 'Best\nPrices'),
                _buildBenefitIcon(Icons.pause_circle, 'Flexible\nPlans'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(51),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActiveSubscriptionsSection(SubscriptionsProvider provider) {
    if (provider.userSubscriptions.isEmpty) {
      return _buildNoSubscriptionsCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Active Subscriptions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryBrown,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${provider.userSubscriptions.length}',
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
        ...provider.userSubscriptions.map((subscriptionData) {
          final subscription = SubscriptionModel.fromJson(subscriptionData);
          return _buildSubscriptionCard(subscription, provider);
        }),
      ],
    );
  }

  Widget _buildNoSubscriptionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.coffee_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Active Subscriptions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to your favorite coffee and save up to 15% with regular deliveries',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/coffee'),
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Browse Coffee'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(
    SubscriptionModel subscription,
    SubscriptionsProvider provider,
  ) {
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
                    color: AppTheme.primaryBrown.withAlpha(51),
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
                        subscription.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${subscription.productSize} • ${subscription.frequencyDisplay}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      if (subscription.discountPercentage > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              subscription.formattedOriginalPrice,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(51),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${subscription.discountPercentage.toStringAsFixed(0)}% OFF',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      subscription.formattedPrice,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                    if (subscription.discountPercentage > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Save ${subscription.currency} ${subscription.totalSavings.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: subscription.isActive
                    ? Colors.green.withAlpha(25)
                    : subscription.isPaused
                    ? Colors.orange.withAlpha(25)
                    : Colors.red.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    subscription.isActive
                        ? Icons.local_shipping
                        : subscription.isPaused
                        ? Icons.pause_circle
                        : Icons.cancel,
                    size: 20,
                    color: subscription.isActive
                        ? Colors.green.shade700
                        : subscription.isPaused
                        ? Colors.orange.shade700
                        : Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subscription.isActive
                          ? subscription.daysUntilNextDelivery > 0
                                ? 'Next delivery in ${subscription.daysUntilNextDelivery} days'
                                : 'Delivery scheduled for today'
                          : subscription.isPaused
                          ? 'Subscription paused'
                          : 'Subscription cancelled',
                      style: TextStyle(
                        color: subscription.isActive
                            ? Colors.green.shade700
                            : subscription.isPaused
                            ? Colors.orange.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
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
                    onPressed: subscription.isActive
                        ? () => _pauseSubscription(subscription, provider)
                        : subscription.isPaused
                        ? () => _resumeSubscription(subscription, provider)
                        : null,
                    icon: Icon(
                      subscription.isActive ? Icons.pause : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(subscription.isActive ? 'Pause' : 'Resume'),
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
                    onPressed: () =>
                        _cancelSubscription(subscription, provider),
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

  Widget _buildAvailablePlansSection(SubscriptionsProvider provider) {
    if (provider.availablePlans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subscription Plans',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...provider.availablePlans.map((planData) {
          final plan = SubscriptionPlanModel.fromJson(planData);
          return _buildPlanCard(plan);
        }),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/coffee'),
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Browse Coffee Collection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlanModel plan) {
    IconData planIcon;
    Color planColor;

    switch (plan.frequency.toLowerCase()) {
      case 'weekly':
        planIcon = Icons.local_cafe;
        planColor = AppTheme.primaryBrown;
        break;
      case 'bi-weekly':
        planIcon = Icons.coffee;
        planColor = AppTheme.primaryBrown;
        break;
      case 'monthly':
        planIcon = Icons.coffee_maker;
        planColor = AppTheme.primaryLightBrown;
        break;
      default:
        planIcon = Icons.schedule;
        planColor = AppTheme.primaryBrown;
    }

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
                  color: planColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(planIcon, color: planColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (plan.discountPercentage > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(51),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Save ${plan.formattedDiscount}',
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
                      plan.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Delivery: ${plan.frequency}',
                      style: TextStyle(
                        color: planColor,
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

  Widget _buildGuestMessage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Subscriptions'),
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
      ),
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
                'Create an account to subscribe and save up to 15% on fresh coffee deliveries in AED',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                icon: const Icon(Icons.login),
                label: const Text('Sign In'),
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

  Future<void> _pauseSubscription(
    SubscriptionModel subscription,
    SubscriptionsProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause Subscription'),
        content: Text(
          'Pause "${subscription.productName}" subscription?\n\nYou can resume it anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pause'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.pauseSubscription(subscription.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription paused successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        _loadSubscriptionData(); // Refresh data
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to pause subscription: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _resumeSubscription(
    SubscriptionModel subscription,
    SubscriptionsProvider provider,
  ) async {
    try {
      await provider.resumeSubscription(subscription.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription resumed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadSubscriptionData(); // Refresh data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resume subscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelSubscription(
    SubscriptionModel subscription,
    SubscriptionsProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: Text(
          'Are you sure you want to cancel "${subscription.productName}"?\n\nYou\'ll lose your subscription discount of ${subscription.discountPercentage.toStringAsFixed(0)}%.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Subscription'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.cancelSubscription(subscription.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription cancelled successfully'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _loadSubscriptionData(); // Refresh data
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel subscription: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _modifySubscription(SubscriptionModel subscription) {
    // Navigate to coffee page with subscription context
    Navigator.pushNamed(
      context,
      '/coffee',
      arguments: {'subscriptionId': subscription.id},
    );
  }

  void _selectPlan(SubscriptionPlanModel plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plan.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.description),
            const SizedBox(height: 16),
            Text('Delivery: ${plan.frequency}'),
            Text('Discount: ${plan.formattedDiscount}'),
            Text('Currency: ${plan.currency}'),
            if (plan.features.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...plan.features.map((feature) => Text('• $feature')),
            ],
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
              Navigator.pushNamed(
                context,
                '/coffee',
                arguments: {'planId': plan.id},
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
            ),
            child: const Text('Browse Coffee'),
          ),
        ],
      ),
    );
  }
}
