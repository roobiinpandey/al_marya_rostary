import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';
import 'address_management_page.dart';
import 'payment_methods_page.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _marketingCommunications = true;
  bool _orderUpdates = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryBrown,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ahmed Al Mansouri',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ahmed@example.com',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfilePage(),
                      ),
                    ),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryBrown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account Management Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, 'Account Management'),
                  const SizedBox(height: 16),

                  _buildSettingsCard([
                    _buildSettingsItem(
                      icon: Icons.person_outline,
                      title: 'Personal Information',
                      subtitle: 'Update your name, email, and phone number',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordPage(),
                        ),
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.location_on_outlined,
                      title: 'My Addresses',
                      subtitle: 'Manage delivery addresses',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddressManagementPage(),
                        ),
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.payment_outlined,
                      title: 'Payment Methods',
                      subtitle: 'Manage cards and payment options',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentMethodsPage(),
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Notifications Section
                  _buildSectionHeader(context, 'Notifications'),
                  const SizedBox(height: 16),

                  _buildSettingsCard([
                    _buildNotificationItem(
                      title: 'Order Updates',
                      subtitle: 'Get notified about your order status',
                      value: _orderUpdates,
                      onChanged: (value) {
                        setState(() {
                          _orderUpdates = value;
                        });
                      },
                    ),
                    _buildDivider(),
                    _buildNotificationItem(
                      title: 'Email Notifications',
                      subtitle: 'Receive updates via email',
                      value: _emailNotifications,
                      onChanged: (value) {
                        setState(() {
                          _emailNotifications = value;
                        });
                      },
                    ),
                    _buildDivider(),
                    _buildNotificationItem(
                      title: 'SMS Notifications',
                      subtitle: 'Get SMS updates for important notifications',
                      value: _smsNotifications,
                      onChanged: (value) {
                        setState(() {
                          _smsNotifications = value;
                        });
                      },
                    ),
                    _buildDivider(),
                    _buildNotificationItem(
                      title: 'Marketing Communications',
                      subtitle: 'Receive promotional offers and news',
                      value: _marketingCommunications,
                      onChanged: (value) {
                        setState(() {
                          _marketingCommunications = value;
                        });
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // App Preferences Section
                  _buildSectionHeader(context, 'App Preferences'),
                  const SizedBox(height: 16),

                  _buildSettingsCard([
                    _buildSettingsItem(
                      icon: Icons.language_outlined,
                      title: 'Language',
                      subtitle: 'English (UAE)',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showLanguageDialog();
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.palette_outlined,
                      title: 'Theme',
                      subtitle: 'Light mode',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showThemeDialog();
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.currency_exchange_outlined,
                      title: 'Currency',
                      subtitle: 'AED (د.إ)',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showCurrencyDialog();
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Support Section
                  _buildSectionHeader(context, 'Support & Legal'),
                  const SizedBox(height: 16),

                  _buildSettingsCard([
                    _buildSettingsItem(
                      icon: Icons.help_outline,
                      title: 'Help & FAQ',
                      subtitle: 'Get answers to common questions',
                      onTap: () {
                        // TODO: Navigate to help page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Help & FAQ - Coming Soon'),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.support_agent_outlined,
                      title: 'Contact Support',
                      subtitle: 'Get help from our customer service team',
                      onTap: () {
                        // TODO: Navigate to contact support page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contact Support - Coming Soon'),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'Learn how we protect your data',
                      onTap: () {
                        // TODO: Navigate to privacy policy
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Privacy Policy - Coming Soon'),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      subtitle: 'Read our terms and conditions',
                      onTap: () {
                        // TODO: Navigate to terms of service
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Terms of Service - Coming Soon'),
                          ),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 32),

                  // Logout Section
                  _buildSettingsCard([
                    _buildSettingsItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      titleColor: Colors.red,
                      iconColor: Colors.red,
                      onTap: () {
                        _showLogoutDialog();
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Version Info
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Qahwat Al Emarat',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textLight),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version 1.0.0 (1)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? titleColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primaryBrown).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.primaryBrown, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppTheme.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppTheme.textMedium, fontSize: 12),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildNotificationItem({
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
        child: const Icon(
          Icons.notifications_outlined,
          color: AppTheme.primaryBrown,
          size: 20,
        ),
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

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English', 'English (UAE)', true),
            _buildLanguageOption('العربية', 'Arabic (UAE)', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String title, String subtitle, bool isSelected) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primaryBrown)
          : null,
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Language support coming soon')),
          );
        }
      },
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('Light Mode', Icons.light_mode, true),
            _buildThemeOption('Dark Mode', Icons.dark_mode, false),
            _buildThemeOption('System Default', Icons.auto_mode, false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String title, IconData icon, bool isSelected) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBrown),
      title: Text(title),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primaryBrown)
          : null,
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Theme options coming soon')),
          );
        }
      },
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCurrencyOption('AED', 'UAE Dirham (د.إ)', true),
            _buildCurrencyOption('USD', 'US Dollar (\$)', false),
            _buildCurrencyOption('EUR', 'Euro (€)', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyOption(String code, String name, bool isSelected) {
    return ListTile(
      title: Text(code),
      subtitle: Text(name),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primaryBrown)
          : null,
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Multi-currency support coming soon')),
          );
        }
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout from your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement logout functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
