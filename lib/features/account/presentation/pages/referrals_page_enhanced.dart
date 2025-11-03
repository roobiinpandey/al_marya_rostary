import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/referrals_provider.dart';

class ReferralsPageEnhanced extends StatefulWidget {
  const ReferralsPageEnhanced({Key? key}) : super(key: key);

  @override
  State<ReferralsPageEnhanced> createState() => _ReferralsPageEnhancedState();
}

class _ReferralsPageEnhancedState extends State<ReferralsPageEnhanced>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Define primary color here since AppConstants doesn't have it
  static const Color primaryColor = Color(0xFF8B4513); // Brown coffee color

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load referrals data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ReferralsProvider>(context, listen: false);
      provider.loadUserReferrals('current_user_id'); // Note: Get actual user ID
      provider.loadReferralStats('current_user_id'); // Note: Get actual user ID
      provider.loadProgramInfo();
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
          'Referral Program',
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
            Tab(text: 'Overview'),
            Tab(text: 'My Referrals'),
            Tab(text: 'Earnings'),
            Tab(text: 'How it Works'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildReferralsTab(),
          _buildEarningsTab(),
          _buildHowItWorksTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<ReferralsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Referrals',
                      provider.totalReferrals.toString(),
                      Icons.people,
                      primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Points Earned',
                      provider.totalPointsEarned.toString(),
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Referral Code Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Referral Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white38),
                              ),
                              child: Text(
                                provider.referralCodeForSharing,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => _copyReferralCode(
                              provider.referralCodeForSharing,
                            ),
                            icon: const Icon(Icons.copy, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _shareReferralCode(
                                provider.referralCodeForSharing,
                              ),
                              icon: const Icon(Icons.share),
                              label: const Text('Share Code'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Recent Referrals
              const Text(
                'Recent Referrals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildRecentReferralsList(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReferralsTab() {
    return Consumer<ReferralsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          );
        }

        if (provider.userReferrals.isEmpty) {
          return _buildEmptyState(
            'No Referrals Yet',
            'Share your referral code with friends to start earning rewards!',
            Icons.people_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.userReferrals.length,
          itemBuilder: (context, index) {
            final referral = provider.userReferrals[index];
            return _buildReferralCard(referral);
          },
        );
      },
    );
  }

  Widget _buildEarningsTab() {
    return Consumer<ReferralsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Earnings Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'Total Points Earned',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.totalPointsEarned.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Earnings Breakdown
              const Text(
                'Earnings Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildEarningsBreakdown(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHowItWorksTab() {
    return Consumer<ReferralsProvider>(
      builder: (context, provider, child) {
        final programInfo = provider.programInfo;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How It Works',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Steps
              _buildStepCard(
                1,
                'Share Your Code',
                'Share your unique referral code with friends and family.',
                Icons.share,
              ),
              const SizedBox(height: 16),
              _buildStepCard(
                2,
                'Friend Signs Up',
                'When they sign up using your code, both of you get rewarded!',
                Icons.person_add,
              ),
              const SizedBox(height: 16),
              _buildStepCard(
                3,
                'Earn Rewards',
                'You earn ${programInfo?['pointsPerReferral'] ?? 100} points for each successful referral.',
                Icons.star,
              ),
              const SizedBox(height: 24),

              // Terms
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        programInfo?['description'] ??
                            'Refer friends and earn rewards! Terms apply.',
                        style: TextStyle(color: Colors.grey[600], height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReferralsList(ReferralsProvider provider) {
    final recentReferrals = provider.userReferrals.take(3).toList();

    if (recentReferrals.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No referrals yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your code to get started!',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: recentReferrals
          .map((referral) => _buildReferralCard(referral, isCompact: true))
          .toList(),
    );
  }

  Widget _buildReferralCard(
    Map<String, dynamic> referral, {
    bool isCompact = false,
  }) {
    final status = referral['status'] ?? 'pending';
    final createdAt =
        DateTime.tryParse(referral['createdAt'] ?? '') ?? DateTime.now();

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    referral['referredUserEmail'] ?? 'Unknown User',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Joined ${_formatDate(createdAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                  ],
                ],
              ),
            ),
            if (referral['pointsEarned'] != null &&
                referral['pointsEarned'] > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${referral['pointsEarned']}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsBreakdown(ReferralsProvider provider) {
    final referrals = provider.userReferrals;
    final successfulReferrals = referrals
        .where((r) => r['status'] == 'completed')
        .toList();

    if (successfulReferrals.isEmpty) {
      return _buildEmptyState(
        'No Earnings Yet',
        'Complete referrals to start earning points!',
        Icons.star_outline,
      );
    }

    return Column(
      children: successfulReferrals.map((referral) {
        final pointsEarned = referral['pointsEarned'] ?? 0;
        final createdAt =
            DateTime.tryParse(referral['createdAt'] ?? '') ?? DateTime.now();

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.star, color: Colors.amber, size: 20),
            ),
            title: Text(
              '+$pointsEarned points',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.amber,
              ),
            ),
            subtitle: Text(
              'From ${referral['referredUserEmail'] ?? 'Unknown User'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: Text(
              _formatDate(createdAt),
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStepCard(
    int step,
    String title,
    String description,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  step.toString(),
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(icon, color: primaryColor, size: 24),
          ],
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      case 'cancelled':
        return Icons.cancel;
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
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _copyReferralCode(String code) {
    if (code.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: code));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral code copied to clipboard!'),
          duration: Duration(seconds: 2),
          backgroundColor: primaryColor,
        ),
      );
    }
  }

  void _shareReferralCode(String code) {
    if (code.isNotEmpty) {
      // Note: Implement proper sharing functionality
      // For now, just copy to clipboard
      _copyReferralCode(code);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral code ready to share!'),
          duration: Duration(seconds: 2),
          backgroundColor: primaryColor,
        ),
      );
    }
  }
}
