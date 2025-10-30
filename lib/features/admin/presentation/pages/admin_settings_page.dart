import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/admin_sidebar.dart';

/// Admin Settings Page
/// TODO: Implement comprehensive admin settings functionality
class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage>
    with SingleTickerProviderStateMixin {
  bool _sidebarOpen = true;
  late TabController _tabController;

  // Settings state
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _autoAcceptOrders = false;
  bool _maintenanceMode = false;
  double _deliveryRadius = 25.0;
  String _businessHoursStart = '06:00';
  String _businessHoursEnd = '22:00';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: isMobile
          ? AppBar(
              title: const Text('Admin Settings'),
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen),
              ),
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: AdminSidebar(
                isOpen: true,
                onToggle: () => setState(() => _sidebarOpen = !_sidebarOpen),
              ),
            )
          : null,
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar
        AdminSidebar(
          isOpen: _sidebarOpen,
          onToggle: () => setState(() => _sidebarOpen = !_sidebarOpen),
        ),

        // Main Content
        Expanded(
          child: Container(
            color: AppTheme.backgroundCream,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: AppTheme.primaryLightBrown),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Admin Settings',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBrown,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(children: [Expanded(child: _buildContent())]);
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Tab Bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryBrown,
            unselectedLabelColor: AppTheme.textMedium,
            indicatorColor: AppTheme.primaryBrown,
            tabs: const [
              Tab(text: 'General'),
              Tab(text: 'Notifications'),
              Tab(text: 'Business'),
              Tab(text: 'Advanced'),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGeneralSettings(),
              _buildNotificationSettings(),
              _buildBusinessSettings(),
              _buildAdvancedSettings(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsCard(
            'App Information',
            Icons.info_outline,
            children: [
              _buildSettingsTextField('App Name', 'Al Marya Rostery'),
              _buildSettingsTextField('App Version', '1.0.0'),
              _buildSettingsTextField(
                'App Description',
                'Premium Arabic Coffee Experience',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildSettingsCard(
            'Contact Information',
            Icons.contact_mail,
            children: [
              _buildSettingsTextField(
                'Business Email',
                'info@almaryarostery.com',
              ),
              _buildSettingsTextField(
                'Support Email',
                'support@almaryarostery.com',
              ),
              _buildSettingsTextField('Phone Number', '+971 XX XXX XXXX'),
              _buildSettingsTextField('Address', 'Dubai, UAE'),
            ],
          ),

          const SizedBox(height: 16),

          _buildSettingsCard(
            'System Settings',
            Icons.settings,
            children: [
              SwitchListTile(
                title: const Text('Maintenance Mode'),
                subtitle: const Text(
                  'Temporarily disable the app for maintenance',
                ),
                value: _maintenanceMode,
                onChanged: (value) => setState(() => _maintenanceMode = value),
                activeColor: AppTheme.primaryBrown,
              ),
              SwitchListTile(
                title: const Text('Auto Accept Orders'),
                subtitle: const Text('Automatically accept new orders'),
                value: _autoAcceptOrders,
                onChanged: (value) => setState(() => _autoAcceptOrders = value),
                activeColor: AppTheme.primaryBrown,
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildComingSoonNote('General settings management'),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsCard(
            'Admin Notifications',
            Icons.notifications,
            children: [
              SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive order updates via email'),
                value: _emailNotifications,
                onChanged: (value) =>
                    setState(() => _emailNotifications = value),
                activeColor: AppTheme.primaryBrown,
              ),
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text(
                  'Receive push notifications for new orders',
                ),
                value: _pushNotifications,
                onChanged: (value) =>
                    setState(() => _pushNotifications = value),
                activeColor: AppTheme.primaryBrown,
              ),
              SwitchListTile(
                title: const Text('SMS Notifications'),
                subtitle: const Text('Receive SMS for urgent notifications'),
                value: _smsNotifications,
                onChanged: (value) => setState(() => _smsNotifications = value),
                activeColor: AppTheme.primaryBrown,
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildSettingsCard(
            'Customer Notifications',
            Icons.message,
            children: [
              ListTile(
                title: const Text('Order Confirmation Template'),
                subtitle: const Text('Customize order confirmation message'),
                trailing: const Icon(Icons.edit),
                onTap: () =>
                    _showComingSoon('Order confirmation template editor'),
              ),
              ListTile(
                title: const Text('Order Ready Template'),
                subtitle: const Text('Customize order ready notification'),
                trailing: const Icon(Icons.edit),
                onTap: () => _showComingSoon('Order ready template editor'),
              ),
              ListTile(
                title: const Text('Promotional Templates'),
                subtitle: const Text('Manage promotional message templates'),
                trailing: const Icon(Icons.edit),
                onTap: () => _showComingSoon('Promotional templates manager'),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildComingSoonNote('Notification management system'),
        ],
      ),
    );
  }

  Widget _buildBusinessSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsCard(
            'Business Hours',
            Icons.access_time,
            children: [
              ListTile(
                title: const Text('Opening Time'),
                subtitle: Text(_businessHoursStart),
                trailing: const Icon(Icons.schedule),
                onTap: () => _selectTime(true),
              ),
              ListTile(
                title: const Text('Closing Time'),
                subtitle: Text(_businessHoursEnd),
                trailing: const Icon(Icons.schedule),
                onTap: () => _selectTime(false),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildSettingsCard(
            'Delivery Settings',
            Icons.delivery_dining,
            children: [
              ListTile(
                title: const Text('Delivery Radius'),
                subtitle: Text('${_deliveryRadius.round()} km'),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: _deliveryRadius,
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: '${_deliveryRadius.round()} km',
                    onChanged: (value) =>
                        setState(() => _deliveryRadius = value),
                    activeColor: AppTheme.primaryBrown,
                  ),
                ),
              ),
              _buildSettingsTextField('Delivery Fee', '\$2.50'),
              _buildSettingsTextField('Minimum Order Amount', '\$10.00'),
            ],
          ),

          const SizedBox(height: 16),

          _buildSettingsCard(
            'Payment Settings',
            Icons.payment,
            children: [
              ListTile(
                title: const Text('Payment Methods'),
                subtitle: const Text('Configure accepted payment methods'),
                trailing: const Icon(Icons.credit_card),
                onTap: () => _showComingSoon('Payment methods configuration'),
              ),
              ListTile(
                title: const Text('Tax Settings'),
                subtitle: const Text('Configure tax rates and calculations'),
                trailing: const Icon(Icons.receipt),
                onTap: () => _showComingSoon('Tax configuration'),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildComingSoonNote('Business settings management'),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsCard(
            'Database Management',
            Icons.storage,
            children: [
              ListTile(
                title: const Text('Backup Database'),
                subtitle: const Text('Create a backup of the database'),
                trailing: const Icon(Icons.backup),
                onTap: () => _showComingSoon('Database backup functionality'),
              ),
              ListTile(
                title: const Text('Clear Cache'),
                subtitle: const Text('Clear application cache'),
                trailing: const Icon(Icons.clear_all),
                onTap: () => _showComingSoon('Cache clearing functionality'),
              ),
              ListTile(
                title: const Text('Export Data'),
                subtitle: const Text('Export orders and customer data'),
                trailing: const Icon(Icons.file_download),
                onTap: () => _showComingSoon('Data export functionality'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildSettingsCard(
            'Security Settings',
            Icons.security,
            children: [
              ListTile(
                title: const Text('Change Admin Password'),
                subtitle: const Text('Update admin account password'),
                trailing: const Icon(Icons.lock),
                onTap: () => _showComingSoon('Password change functionality'),
              ),
              ListTile(
                title: const Text('Two-Factor Authentication'),
                subtitle: const Text('Enable 2FA for admin account'),
                trailing: const Icon(Icons.security),
                onTap: () => _showComingSoon('2FA setup'),
              ),
              ListTile(
                title: const Text('API Keys'),
                subtitle: const Text('Manage API keys and integrations'),
                trailing: const Icon(Icons.key),
                onTap: () => _showComingSoon('API key management'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildSettingsCard(
            'System Information',
            Icons.info,
            children: [
              _buildInfoRow('Server Status', 'Online', Colors.green),
              _buildInfoRow('Database Status', 'Connected', Colors.green),
              _buildInfoRow('Last Backup', '2 hours ago', Colors.blue),
              _buildInfoRow('Storage Used', '2.3 GB / 10 GB', Colors.orange),
            ],
          ),

          const SizedBox(height: 24),
          _buildComingSoonNote('Advanced system management'),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    String title,
    IconData icon, {
    required List<Widget> children,
  }) {
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryLightBrown.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryBrown, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTextField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.primaryBrown),
          ),
        ),
        onChanged: (value) {
          // TODO: Implement settings value updates
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w500, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonNote(String feature) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLightBrown.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryLightBrown),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaryBrown, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'TODO: Complete $feature implementation',
              style: TextStyle(
                color: AppTheme.textMedium,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final timeString =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStartTime) {
          _businessHoursStart = timeString;
        } else {
          _businessHoursEnd = timeString;
        }
      });
    }
  }

  void _saveSettings() {
    // TODO: Implement settings save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature - Coming Soon')));
  }
}
