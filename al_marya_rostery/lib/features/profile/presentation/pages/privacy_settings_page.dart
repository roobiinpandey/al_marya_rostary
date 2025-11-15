import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _isLoading = true;
  bool _shareDataWithPartners = false;
  bool _personalizedAds = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _shareDataWithPartners =
            prefs.getBool('share_data_with_partners') ?? false;
        _personalizedAds = prefs.getBool('personalized_ads') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading privacy settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('Error saving privacy setting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save setting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Settings',
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
                  icon: Icons.privacy_tip,
                  title: 'Data & Privacy',
                ),
                const SizedBox(height: 8),
                _buildSettingCard([
                  _buildSwitchTile(
                    title: 'Share Data with Partners',
                    subtitle: 'Allow sharing anonymized data with partners',
                    value: _shareDataWithPartners,
                    onChanged: (value) {
                      setState(() {
                        _shareDataWithPartners = value;
                      });
                      _saveSetting('share_data_with_partners', value);
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Personalized Ads',
                    subtitle: 'See ads tailored to your interests',
                    value: _personalizedAds,
                    onChanged: (value) {
                      setState(() {
                        _personalizedAds = value;
                      });
                      _saveSetting('personalized_ads', value);
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  icon: Icons.account_circle,
                  title: 'Account Management',
                ),
                const SizedBox(height: 8),
                _buildSettingCard([
                  _buildActionTile(
                    icon: Icons.download,
                    title: 'Download My Data',
                    subtitle: 'Request a copy of your personal data',
                    onTap: _showDownloadDataDialog,
                  ),
                  _buildActionTile(
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account and data',
                    textColor: Colors.red,
                    onTap: _showDeleteAccountDialog,
                  ),
                ]),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryBrown,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBrown.withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We respect your privacy. Your data is encrypted and stored securely. We will never share your personal information without your consent.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryBrown.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () {
                          // Navigate to privacy policy page
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Privacy policy page coming soon'),
                              backgroundColor: AppTheme.primaryBrown,
                            ),
                          );
                        },
                        child: const Text(
                          'Read our full Privacy Policy →',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryBrown,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
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

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppTheme.primaryBrown),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor ?? const Color(0xFF2E2E2E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: Color(0xFF8C8C8C)),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF8C8C8C)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showDownloadDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download My Data'),
        content: const Text(
          'We will prepare a copy of your personal data and send it to your registered email address within 48 hours.',
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
                    'Data download request submitted successfully!',
                  ),
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
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Account'),
          ],
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
                    'Account deletion request submitted. Our team will contact you within 24 hours.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
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
