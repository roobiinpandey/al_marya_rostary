import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _shareAnalytics = true;
  bool _sharePersonalizedAds = false;
  bool _shareUsageData = true;
  bool _shareLocation = true;
  bool _showProfilePublicly = false;
  bool _allowFriendRequests = true;
  bool _shareOrderHistory = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shareAnalytics = prefs.getBool('privacy_analytics') ?? true;
      _sharePersonalizedAds = prefs.getBool('privacy_ads') ?? false;
      _shareUsageData = prefs.getBool('privacy_usage') ?? true;
      _shareLocation = prefs.getBool('privacy_location') ?? true;
      _showProfilePublicly = prefs.getBool('privacy_profile_public') ?? false;
      _allowFriendRequests = prefs.getBool('privacy_friend_requests') ?? true;
      _shareOrderHistory = prefs.getBool('privacy_order_history') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBrown),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Data Sharing Section
                    _buildSectionHeader('Data Sharing'),
                    const SizedBox(height: 8),
                    Text(
                      'Control what data you share with us',
                      style: TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacyCard([
                      _buildPrivacySwitch(
                        icon: Icons.analytics_outlined,
                        title: 'Analytics Data',
                        subtitle:
                            'Help us improve by sharing app usage analytics',
                        value: _shareAnalytics,
                        onChanged: (value) {
                          setState(() => _shareAnalytics = value);
                          _saveSetting('privacy_analytics', value);
                        },
                      ),
                      _buildDivider(),
                      _buildPrivacySwitch(
                        icon: Icons.data_usage_outlined,
                        title: 'Usage Data',
                        subtitle: 'Share how you use the app features',
                        value: _shareUsageData,
                        onChanged: (value) {
                          setState(() => _shareUsageData = value);
                          _saveSetting('privacy_usage', value);
                        },
                      ),
                      _buildDivider(),
                      _buildPrivacySwitch(
                        icon: Icons.location_on_outlined,
                        title: 'Location Data',
                        subtitle: 'Share your location for delivery services',
                        value: _shareLocation,
                        onChanged: (value) {
                          setState(() => _shareLocation = value);
                          _saveSetting('privacy_location', value);
                        },
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Advertising Section
                    _buildSectionHeader('Advertising'),
                    const SizedBox(height: 8),
                    Text(
                      'Manage personalized advertising preferences',
                      style: TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacyCard([
                      _buildPrivacySwitch(
                        icon: Icons.ad_units_outlined,
                        title: 'Personalized Ads',
                        subtitle: 'Show ads based on your preferences',
                        value: _sharePersonalizedAds,
                        onChanged: (value) {
                          setState(() => _sharePersonalizedAds = value);
                          _saveSetting('privacy_ads', value);
                        },
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Account Visibility Section
                    _buildSectionHeader('Account Visibility'),
                    const SizedBox(height: 8),
                    Text(
                      'Control who can see your profile and activity',
                      style: TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacyCard([
                      _buildPrivacySwitch(
                        icon: Icons.public_outlined,
                        title: 'Public Profile',
                        subtitle: 'Allow others to see your profile',
                        value: _showProfilePublicly,
                        onChanged: (value) {
                          setState(() => _showProfilePublicly = value);
                          _saveSetting('privacy_profile_public', value);
                        },
                      ),
                      _buildDivider(),
                      _buildPrivacySwitch(
                        icon: Icons.people_outline,
                        title: 'Friend Requests',
                        subtitle: 'Allow others to send you friend requests',
                        value: _allowFriendRequests,
                        onChanged: (value) {
                          setState(() => _allowFriendRequests = value);
                          _saveSetting('privacy_friend_requests', value);
                        },
                      ),
                      _buildDivider(),
                      _buildPrivacySwitch(
                        icon: Icons.history_outlined,
                        title: 'Order History Visibility',
                        subtitle: 'Share your order history with friends',
                        value: _shareOrderHistory,
                        onChanged: (value) {
                          setState(() => _shareOrderHistory = value);
                          _saveSetting('privacy_order_history', value);
                        },
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Data Management Section
                    _buildSectionHeader('Data Management'),
                    const SizedBox(height: 16),
                    _buildPrivacyCard([
                      _buildActionTile(
                        icon: Icons.download_outlined,
                        title: 'Download My Data',
                        subtitle: 'Get a copy of your personal data',
                        onTap: () {
                          _showDownloadDataDialog();
                        },
                      ),
                      _buildDivider(),
                      _buildActionTile(
                        icon: Icons.delete_outline,
                        title: 'Delete My Account',
                        subtitle: 'Permanently delete your account and data',
                        textColor: Colors.red,
                        onTap: () {
                          _showDeleteAccountDialog();
                        },
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryBrown.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.privacy_tip_outlined,
                            color: AppTheme.primaryBrown,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Privacy Matters',
                                  style: TextStyle(
                                    color: AppTheme.textDark,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'We are committed to protecting your privacy. Read our Privacy Policy to learn more.',
                                  style: TextStyle(
                                    color: AppTheme.textDark,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    // Navigate to privacy policy
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Read Privacy Policy →',
                                    style: TextStyle(
                                      color: AppTheme.primaryBrown,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildPrivacyCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildPrivacySwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryBrown.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryBrown, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppTheme.textMedium, fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryBrown,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? AppTheme.primaryBrown).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: textColor ?? AppTheme.primaryBrown, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor ?? AppTheme.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppTheme.textMedium, fontSize: 12),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: textColor ?? AppTheme.textMedium,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppTheme.textLight.withValues(alpha: 0.1),
      indent: 16,
      endIndent: 16,
    );
  }

  void _showDownloadDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Your Data'),
        content: const Text(
          'We will prepare a copy of your data and send it to your registered email address within 48 hours.',
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
                  content: Text('Data export request submitted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
            ),
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
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
                  content: Text(
                    'Please contact support to delete your account',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
