import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscriptions_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SubscriptionsPageEnhanced extends StatefulWidget {
  const SubscriptionsPageEnhanced({Key? key}) : super(key: key);

  @override
  State<SubscriptionsPageEnhanced> createState() =>
      _SubscriptionsPageEnhancedState();
}

class _SubscriptionsPageEnhancedState extends State<SubscriptionsPageEnhanced>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Brand colors - Olive Gold theme
  static const Color primaryColor = Color(
    0xFFA89A6A,
  ); // Olive Gold (brand primary)
  static const Color accentColor = Color(
    0xFFCBBE8C,
  ); // Light Gold (brand secondary)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load subscriptions data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final subscriptionsProvider = Provider.of<SubscriptionsProvider>(
        context,
        listen: false,
      );

      // Get the actual logged-in user ID
      final userId = authProvider.user?.id;
      if (userId != null) {
        subscriptionsProvider.loadUserSubscriptions(userId);
        subscriptionsProvider.loadSubscriptionPlans();
      } else {
        debugPrint('⚠️ No user logged in, cannot load subscriptions');
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Subscriptions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'All Plans'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveSubscriptionsTab(),
          _buildSubscriptionPlansTab(),
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSubscriptionSheet(),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Subscription'),
      ),
    );
  }

  Widget _buildActiveSubscriptionsTab() {
    return Consumer<SubscriptionsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          );
        }

        if (provider.userSubscriptions.isEmpty) {
          return _buildEmptyState(
            'No Subscriptions Yet',
            'Start your coffee subscription journey today!',
            Icons.coffee_outlined,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Card
              _buildOverviewCard(provider),
              const SizedBox(height: 24),

              // Active Subscriptions
              if (provider.activeSubscriptions.isNotEmpty) ...[
                const Text(
                  'Active Subscriptions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...provider.activeSubscriptions
                    .map(
                      (subscription) =>
                          _buildSubscriptionCard(subscription, isActive: true),
                    )
                    .toList(),
                const SizedBox(height: 24),
              ],

              // Paused Subscriptions
              if (provider.pausedSubscriptions.isNotEmpty) ...[
                const Text(
                  'Paused Subscriptions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...provider.pausedSubscriptions
                    .map(
                      (subscription) =>
                          _buildSubscriptionCard(subscription, isActive: false),
                    )
                    .toList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionPlansTab() {
    return Consumer<SubscriptionsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          );
        }

        if (provider.availablePlans.isEmpty) {
          return _buildEmptyState(
            'No Plans Available',
            'Check back later for subscription plans!',
            Icons.inventory_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.availablePlans.length,
          itemBuilder: (context, index) {
            final plan = provider.availablePlans[index];
            return _buildPlanCard(plan);
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<SubscriptionsProvider>(
      builder: (context, provider, child) {
        if (provider.subscriptionHistory.isEmpty) {
          return _buildEmptyState(
            'No History Yet',
            'Your subscription delivery history will appear here.',
            Icons.history_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.subscriptionHistory.length,
          itemBuilder: (context, index) {
            final delivery = provider.subscriptionHistory[index];
            return _buildHistoryCard(delivery);
          },
        );
      },
    );
  }

  Widget _buildOverviewCard(SubscriptionsProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Subscriptions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${provider.activeSubscriptionsCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.coffee,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Spend',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AED ${provider.totalMonthlySpend.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (provider.pausedSubscriptionsCount > 0)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Paused',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.pausedSubscriptionsCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(
    Map<String, dynamic> subscription, {
    required bool isActive,
  }) {
    final nextDelivery = DateTime.tryParse(subscription['nextDelivery'] ?? '');
    final status = subscription['status'] ?? 'unknown';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription['planName'] ?? 'Unknown Plan',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${subscription['frequency'] ?? 'Unknown'} • AED ${subscription['price'] ?? 0}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Next Delivery Info
            if (isActive && nextDelivery != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_shipping,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Next Delivery',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatDate(nextDelivery),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Preferences
            if (subscription['preferences'] != null) ...[
              const Text(
                'Preferences',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: (subscription['preferences'] as Map<String, dynamic>)
                    .entries
                    .map(
                      (entry) => Chip(
                        label: Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.grey[100],
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              children: [
                if (isActive) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _skipDelivery(subscription),
                      icon: const Icon(Icons.skip_next, size: 18),
                      label: const Text('Skip Next'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pauseSubscription(subscription),
                      icon: const Icon(Icons.pause, size: 18),
                      label: const Text('Pause'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _resumeSubscription(subscription),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Resume'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleSubscriptionAction(subscription, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'history',
                      child: ListTile(
                        leading: Icon(Icons.history),
                        title: Text('View History'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'cancel',
                      child: ListTile(
                        leading: Icon(Icons.cancel, color: Colors.red),
                        title: Text('Cancel'),
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.more_vert),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isPopular = plan['isPopular'] == true;

    return Card(
      elevation: isPopular ? 6 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPopular
            ? const BorderSide(color: accentColor, width: 2)
            : BorderSide.none,
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: const BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan['name'] ?? 'Unknown Plan',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan['description'] ?? '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'AED ${plan['price'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/ ${plan['frequency'] ?? 'month'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (plan['features'] != null) ...[
                  const Text(
                    'Features:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...(plan['features'] as List)
                      .map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature.toString(),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  const SizedBox(height: 20),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _subscribeToPlan(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? accentColor : primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Subscribe Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> delivery) {
    final deliveryDate = DateTime.tryParse(delivery['date'] ?? '');
    final status = delivery['status'] ?? 'unknown';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getStatusColor(status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
            size: 20,
          ),
        ),
        title: Text(
          delivery['items']?.first ?? 'Unknown Item',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deliveryDate != null ? _formatDate(deliveryDate) : 'Unknown Date',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (delivery['trackingNumber'] != null)
              Text(
                'Tracking: ${delivery['trackingNumber']}',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(status),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'delivered':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'delivered':
        return Icons.check_circle;
      case 'paused':
        return Icons.pause_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.hourglass_empty;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference < 7 && difference > 0) {
      return '$difference days ago';
    } else if (difference < 0 && difference > -7) {
      return 'In ${-difference} days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Action methods
  void _skipDelivery(Map<String, dynamic> subscription) async {
    final provider = Provider.of<SubscriptionsProvider>(context, listen: false);
    final success = await provider.skipNextDelivery(
      subscription['_id'],
      reason: 'User requested skip',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Next delivery skipped' : 'Failed to skip delivery',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _pauseSubscription(Map<String, dynamic> subscription) async {
    final provider = Provider.of<SubscriptionsProvider>(context, listen: false);
    final success = await provider.pauseSubscription(subscription['_id']);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Subscription paused' : 'Failed to pause subscription',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _resumeSubscription(Map<String, dynamic> subscription) async {
    final provider = Provider.of<SubscriptionsProvider>(context, listen: false);
    final success = await provider.resumeSubscription(subscription['_id']);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Subscription resumed' : 'Failed to resume subscription',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _handleSubscriptionAction(
    Map<String, dynamic> subscription,
    String action,
  ) {
    switch (action) {
      case 'edit':
        _editSubscription(subscription);
        break;
      case 'history':
        _viewSubscriptionHistory(subscription);
        break;
      case 'cancel':
        _cancelSubscription(subscription);
        break;
    }
  }

  void _editSubscription(Map<String, dynamic> subscription) {
    // Note: Implement edit subscription functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit subscription feature coming soon!')),
    );
  }

  void _viewSubscriptionHistory(Map<String, dynamic> subscription) {
    final provider = Provider.of<SubscriptionsProvider>(context, listen: false);
    provider.loadSubscriptionHistory(subscription['_id']);
    _tabController.animateTo(2); // Switch to history tab
  }

  void _cancelSubscription(Map<String, dynamic> subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel this subscription?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<SubscriptionsProvider>(
        context,
        listen: false,
      );
      final success = await provider.cancelSubscription(
        subscription['_id'],
        reason: 'User requested cancellation',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Subscription cancelled'
                : 'Failed to cancel subscription',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _subscribeToPlan(Map<String, dynamic> plan) {
    // Note: Implement subscription creation flow
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subscription creation feature coming soon!'),
      ),
    );
  }

  void _showCreateSubscriptionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Create New Subscription',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: const Column(
                    children: [
                      Text(
                        'Subscription creation form will be implemented here',
                      ),
                      // Note: Add subscription creation form
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
}
