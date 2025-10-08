import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _darkModeEnabled = false;
  bool _soundEnabled = true;
  double _fontSize = 16.0;
  String _language = 'English';
  String _currency = 'AED';

  final List<String> _languages = ['English', 'Arabic', 'French', 'Spanish'];
  final List<String> _currencies = ['AED', 'USD', 'EUR', 'GBP'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8B4513), // primaryBrown
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5), // backgroundLight
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionCard('Account', [
              _buildListTile(
                icon: Icons.person,
                title: 'Profile',
                subtitle: 'Manage your profile information',
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
              _buildListTile(
                icon: Icons.security,
                title: 'Privacy & Security',
                subtitle: 'Password and security settings',
                onTap: () => _showComingSoon(context, 'Privacy & Security'),
              ),
              _buildListTile(
                icon: Icons.payment,
                title: 'Payment Methods',
                subtitle: 'Manage payment and billing',
                onTap: () => _showComingSoon(context, 'Payment Methods'),
              ),
            ]),

            const SizedBox(height: 16),

            // Notifications Section
            _buildSectionCard('Notifications', [
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: Color(0xFF8B4513),
                  ),
                ),
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive all notifications'),
                value: _notificationsEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _notificationsEnabled = value;
                    if (!value) {
                      _emailNotifications = false;
                      _pushNotifications = false;
                    }
                  });
                },
              ),
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.email, color: Color(0xFF8B4513)),
                ),
                title: const Text('Email Notifications'),
                subtitle: const Text('Order updates and promotions'),
                value: _emailNotifications && _notificationsEnabled,
                onChanged: _notificationsEnabled
                    ? (bool value) {
                        setState(() {
                          _emailNotifications = value;
                        });
                      }
                    : null,
              ),
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.push_pin, color: Color(0xFF8B4513)),
                ),
                title: const Text('Push Notifications'),
                subtitle: const Text('Real-time app notifications'),
                value: _pushNotifications && _notificationsEnabled,
                onChanged: _notificationsEnabled
                    ? (bool value) {
                        setState(() {
                          _pushNotifications = value;
                        });
                      }
                    : null,
              ),
            ]),

            const SizedBox(height: 16),

            // Appearance Section
            _buildSectionCard('Appearance', [
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _darkModeEnabled ? Icons.dark_mode : Icons.light_mode,
                    color: const Color(0xFF8B4513),
                  ),
                ),
                title: const Text('Dark Mode'),
                subtitle: Text(
                  _darkModeEnabled
                      ? 'Dark theme enabled'
                      : 'Light theme enabled',
                ),
                value: _darkModeEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _darkModeEnabled = value;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B4513).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.text_fields,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Font Size',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2E2E2E), // textDark
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text(
                                '12px',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF8C8C8C),
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _fontSize,
                                  min: 12.0,
                                  max: 20.0,
                                  divisions: 4,
                                  activeColor: const Color(0xFF8B4513),
                                  onChanged: (double value) {
                                    setState(() {
                                      _fontSize = value;
                                    });
                                  },
                                ),
                              ),
                              const Text(
                                '20px',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF8C8C8C),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Current: ${_fontSize.toInt()}px',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8C8C8C), // textLight
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // Language & Region Section
            _buildSectionCard('Language & Region', [
              _buildDropdownTile(
                icon: Icons.language,
                title: 'Language',
                value: _language,
                items: _languages,
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _language = value;
                    });
                  }
                },
              ),
              _buildDropdownTile(
                icon: Icons.attach_money,
                title: 'Currency',
                value: _currency,
                items: _currencies,
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _currency = value;
                    });
                  }
                },
              ),
            ]),

            const SizedBox(height: 16),

            // App Section
            _buildSectionCard('App', [
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.volume_up, color: Color(0xFF8B4513)),
                ),
                title: const Text('Sound Effects'),
                subtitle: const Text('Enable app sounds'),
                value: _soundEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _soundEnabled = value;
                  });
                },
              ),
              _buildListTile(
                icon: Icons.storage,
                title: 'Storage & Cache',
                subtitle: 'Manage app storage',
                onTap: () => _showCacheDialog(context),
              ),
              _buildListTile(
                icon: Icons.update,
                title: 'App Version',
                subtitle: 'Version 1.0.0',
                onTap: () => _showComingSoon(context, 'Update Check'),
              ),
            ]),

            const SizedBox(height: 16),

            // Support Section
            _buildSectionCard('Support', [
              _buildListTile(
                icon: Icons.help,
                title: 'Help & FAQ',
                subtitle: 'Get help with the app',
                onTap: () => _showComingSoon(context, 'Help & FAQ'),
              ),
              _buildListTile(
                icon: Icons.feedback,
                title: 'Send Feedback',
                subtitle: 'Share your thoughts',
                onTap: () => _showFeedbackDialog(context),
              ),
              _buildListTile(
                icon: Icons.rate_review,
                title: 'Rate App',
                subtitle: 'Rate us on the App Store',
                onTap: () => _showComingSoon(context, 'App Rating'),
              ),
              _buildListTile(
                icon: Icons.info,
                title: 'About',
                subtitle: 'App information',
                onTap: () => _showAboutDialog(context),
              ),
            ]),

            const SizedBox(height: 32),

            // Save Settings Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _saveSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E2E2E), // textDark
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF8B4513).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF8B4513)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF2E2E2E), // textDark
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF8C8C8C), // textLight
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFF8C8C8C), // textLight
      ),
      onTap: onTap,
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF8B4513).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF8B4513)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF2E2E2E), // textDark
        ),
      ),
      trailing: SizedBox(
        width: 120, // Constrain dropdown width
        child: DropdownButton<String>(
          value: value,
          underline: Container(),
          isExpanded: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _saveSettings() {
    // TODO: Implement settings persistence
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Color(0xFF4CAF50), // success green
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: const Color(0xFFFFA000),
      ),
    );
  }

  void _showCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached data including images and temporary files. This action cannot be undone.',
        ),
        actions: [
          Flexible(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', overflow: TextOverflow.ellipsis),
            ),
          ),
          Flexible(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared successfully!'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Cache', overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'We\'d love to hear from you! Share your thoughts and suggestions.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter your feedback here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          Flexible(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', overflow: TextOverflow.ellipsis),
            ),
          ),
          Flexible(
            child: ElevatedButton(
              onPressed: () {
                if (feedbackController.text.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Feedback sent! Thank you for your input.'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
              ),
              child: const Text('Send', overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Qahwat Al Emarat',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.coffee,
        size: 48,
        color: Color(0xFF8B4513),
      ),
      children: const [
        Text('Premium Coffee Experience'),
        Text('Authentic Emirati Coffee Culture'),
        Text('Made with ❤️ in UAE'),
        SizedBox(height: 16),
        Text('© 2024 Qahwat Al Emarat. All rights reserved.'),
      ],
    );
  }
}
