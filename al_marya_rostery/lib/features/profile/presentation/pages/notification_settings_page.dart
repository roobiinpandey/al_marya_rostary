import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _isLoading = true;

  // Notification toggles
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  // Order notifications
  bool _orderConfirmation = true;
  bool _orderShipped = true;
  bool _orderDelivered = true;
  bool _orderCancelled = true;

  // Marketing notifications
  bool _promotionalOffers = true;
  bool _newProducts = false;
  bool _weeklyNewsletter = false;

  // Account notifications
  bool _rewardPoints = true;
  bool _accountActivity = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _pushNotifications = prefs.getBool('notif_push') ?? true;
        _emailNotifications = prefs.getBool('notif_email') ?? true;
        _smsNotifications = prefs.getBool('notif_sms') ?? false;

        _orderConfirmation = prefs.getBool('notif_order_confirmation') ?? true;
        _orderShipped = prefs.getBool('notif_order_shipped') ?? true;
        _orderDelivered = prefs.getBool('notif_order_delivered') ?? true;
        _orderCancelled = prefs.getBool('notif_order_cancelled') ?? true;

        _promotionalOffers = prefs.getBool('notif_promotional') ?? true;
        _newProducts = prefs.getBool('notif_new_products') ?? false;
        _weeklyNewsletter = prefs.getBool('notif_newsletter') ?? false;

        _rewardPoints = prefs.getBool('notif_reward_points') ?? true;
        _accountActivity = prefs.getBool('notif_account_activity') ?? true;

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('Error saving notification setting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBrown),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader(
                  icon: Icons.notifications_active,
                  title: 'Notification Channels',
                ),
                const SizedBox(height: 8),
                _buildSettingCard([
                  _buildSwitchTile(
                    title: 'Push Notifications',
                    subtitle: 'Receive notifications on your device',
                    value: _pushNotifications,
                    onChanged: (value) {
                      setState(() => _pushNotifications = value);
                      _saveSetting('notif_push', value);
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Email Notifications',
                    subtitle: 'Receive notifications via email',
                    value: _emailNotifications,
                    onChanged: (value) {
                      setState(() => _emailNotifications = value);
                      _saveSetting('notif_email', value);
                    },
                  ),
                  _buildSwitchTile(
                    title: 'SMS Notifications',
                    subtitle: 'Receive SMS for important updates',
                    value: _smsNotifications,
                    onChanged: (value) {
                      setState(() => _smsNotifications = value);
                      _saveSetting('notif_sms', value);
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  icon: Icons.shopping_bag,
                  title: 'Order Updates',
                ),
                const SizedBox(height: 8),
                _buildSettingCard([
                  _buildSwitchTile(
                    title: 'Order Confirmation',
                    subtitle: 'When your order is confirmed',
                    value: _orderConfirmation,
                    onChanged: (value) {
                      setState(() => _orderConfirmation = value);
                      _saveSetting('notif_order_confirmation', value);
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Order Shipped',
                    subtitle: 'When your order is shipped',
                    value: _orderShipped,
                    onChanged: (value) {
                      setState(() => _orderShipped = value);
                      _saveSetting('notif_order_shipped', value);
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Order Delivered',
                    subtitle: 'When your order is delivered',
                    value: _orderDelivered,
                    onChanged: (value) {
                      setState(() => _orderDelivered = value);
                      _saveSetting('notif_order_delivered', value);
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Order Cancelled',
                    subtitle: 'When an order is cancelled',
                    value: _orderCancelled,
                    onChanged: (value) {
                      setState(() => _orderCancelled = value);
                      _saveSetting('notif_order_cancelled', value);
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  icon: Icons.local_offer,
                  title: 'Marketing & Promotions',
                ),
                const SizedBox(height: 8),
                _buildSettingCard([
                  _buildSwitchTile(
                    title: 'Promotional Offers',
                    subtitle: 'Special deals and discounts',
                    value: _promotionalOffers,
                    onChanged: (value) {
                      setState(() => _promotionalOffers = value);
                      _saveSetting('notif_promotional', value);
                    },
                  ),
                  _buildSwitchTile(
                    title: 'New Products',
                    subtitle: 'Be the first to know about new arrivals',
                    value: _newProducts,
                    onChanged: (value) {
                      setState(() => _newProducts = value);
                      _saveSetting('notif_new_products', value);
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Weekly Newsletter',
                    subtitle: 'Coffee tips and brewing guides',
                    value: _weeklyNewsletter,
                    onChanged: (value) {
                      setState(() => _weeklyNewsletter = value);
                      _saveSetting('notif_newsletter', value);
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  icon: Icons.account_circle,
                  title: 'Account Activity',
                ),
                const SizedBox(height: 8),
                _buildSettingCard([
                  _buildSwitchTile(
                    title: 'Reward Points',
                    subtitle: 'When you earn or redeem points',
                    value: _rewardPoints,
                    onChanged: (value) {
                      setState(() => _rewardPoints = value);
                      _saveSetting('notif_reward_points', value);
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Account Activity',
                    subtitle: 'Login alerts and security updates',
                    value: _accountActivity,
                    onChanged: (value) {
                      setState(() => _accountActivity = value);
                      _saveSetting('notif_account_activity', value);
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryBrown,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You can adjust notification permissions in your device settings. Some critical notifications (like order confirmations) may still be sent for your convenience.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryBrown.withValues(alpha: 0.8),
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

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryBrown, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E2E2E),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2E2E2E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: Color(0xFF8C8C8C)),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryBrown,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
