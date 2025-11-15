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
  bool _orderUpdates = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;
  bool _marketingCommunications = true;
  bool _newProductAlerts = false;
  bool _specialOffers = true;
  bool _deliveryUpdates = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orderUpdates = prefs.getBool('notif_order_updates') ?? true;
      _emailNotifications = prefs.getBool('notif_email') ?? true;
      _smsNotifications = prefs.getBool('notif_sms') ?? false;
      _pushNotifications = prefs.getBool('notif_push') ?? true;
      _marketingCommunications = prefs.getBool('notif_marketing') ?? true;
      _newProductAlerts = prefs.getBool('notif_new_products') ?? false;
      _specialOffers = prefs.getBool('notif_special_offers') ?? true;
      _deliveryUpdates = prefs.getBool('notif_delivery') ?? true;
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
          'Notification Settings',
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
                    // Order Notifications Section
                    _buildSectionHeader('Order Notifications'),
                    const SizedBox(height: 8),
                    Text(
                      'Stay updated about your coffee orders',
                      style: TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNotificationCard([
                      _buildNotificationSwitch(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Order Updates',
                        subtitle: 'Get notified about order status changes',
                        value: _orderUpdates,
                        onChanged: (value) {
                          setState(() => _orderUpdates = value);
                          _saveSetting('notif_order_updates', value);
                        },
                      ),
                      _buildDivider(),
                      _buildNotificationSwitch(
                        icon: Icons.local_shipping_outlined,
                        title: 'Delivery Updates',
                        subtitle: 'Track your delivery in real-time',
                        value: _deliveryUpdates,
                        onChanged: (value) {
                          setState(() => _deliveryUpdates = value);
                          _saveSetting('notif_delivery', value);
                        },
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Communication Channels Section
                    _buildSectionHeader('Communication Channels'),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how you want to receive notifications',
                      style: TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNotificationCard([
                      _buildNotificationSwitch(
                        icon: Icons.notifications_outlined,
                        title: 'Push Notifications',
                        subtitle: 'Receive instant updates on your device',
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() => _pushNotifications = value);
                          _saveSetting('notif_push', value);
                        },
                      ),
                      _buildDivider(),
                      _buildNotificationSwitch(
                        icon: Icons.email_outlined,
                        title: 'Email Notifications',
                        subtitle: 'Receive updates via email',
                        value: _emailNotifications,
                        onChanged: (value) {
                          setState(() => _emailNotifications = value);
                          _saveSetting('notif_email', value);
                        },
                      ),
                      _buildDivider(),
                      _buildNotificationSwitch(
                        icon: Icons.sms_outlined,
                        title: 'SMS Notifications',
                        subtitle: 'Get SMS updates for important notifications',
                        value: _smsNotifications,
                        onChanged: (value) {
                          setState(() => _smsNotifications = value);
                          _saveSetting('notif_sms', value);
                        },
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Marketing & Promotions Section
                    _buildSectionHeader('Marketing & Promotions'),
                    const SizedBox(height: 8),
                    Text(
                      'Special offers and new product announcements',
                      style: TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNotificationCard([
                      _buildNotificationSwitch(
                        icon: Icons.campaign_outlined,
                        title: 'Marketing Communications',
                        subtitle: 'Receive promotional offers and news',
                        value: _marketingCommunications,
                        onChanged: (value) {
                          setState(() => _marketingCommunications = value);
                          _saveSetting('notif_marketing', value);
                        },
                      ),
                      _buildDivider(),
                      _buildNotificationSwitch(
                        icon: Icons.local_offer_outlined,
                        title: 'Special Offers',
                        subtitle: 'Get exclusive deals and discounts',
                        value: _specialOffers,
                        onChanged: (value) {
                          setState(() => _specialOffers = value);
                          _saveSetting('notif_special_offers', value);
                        },
                      ),
                      _buildDivider(),
                      _buildNotificationSwitch(
                        icon: Icons.new_releases_outlined,
                        title: 'New Product Alerts',
                        subtitle: 'Be first to know about new coffee arrivals',
                        value: _newProductAlerts,
                        onChanged: (value) {
                          setState(() => _newProductAlerts = value);
                          _saveSetting('notif_new_products', value);
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
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryBrown,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can update these settings anytime. Important order notifications cannot be disabled.',
                              style: TextStyle(
                                color: AppTheme.textDark,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
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

  Widget _buildNotificationCard(List<Widget> children) {
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

  Widget _buildNotificationSwitch({
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

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppTheme.textLight.withValues(alpha: 0.1),
      indent: 16,
      endIndent: 16,
    );
  }
}
