import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../../../../data/models/user_model.dart';

/// User Detail Dialog
/// Shows comprehensive user information and allows editing
class UserDetailDialog extends StatefulWidget {
  final UserModel user;

  const UserDetailDialog({Key? key, required this.user}) : super(key: key);

  @override
  State<UserDetailDialog> createState() => _UserDetailDialogState();
}

class _UserDetailDialogState extends State<UserDetailDialog> {
  late UserModel _user;
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _pointsController;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _nameController = TextEditingController(text: _user.name);
    _emailController = TextEditingController(text: _user.email);
    _phoneController = TextEditingController(text: _user.phone ?? '');
    _pointsController = TextEditingController(
      text: _user.loyaltyProgram.points.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserInfo(),
                    const SizedBox(height: 24),
                    _buildLoyaltyInfo(),
                    const SizedBox(height: 24),
                    _buildStatistics(),
                    const SizedBox(height: 24),
                    _buildPreferences(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ==================== HEADER ====================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF6D4C3D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              _user.name[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF6D4C3D),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user.email,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _isEditing = !_isEditing),
            tooltip: _isEditing ? 'Cancel Edit' : 'Edit User',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ==================== USER INFO ====================

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('User Information'),
        const SizedBox(height: 12),
        _buildInfoRow('ID', _user.id),
        if (_isEditing)
          Column(
            children: [
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: _inputDecoration('Name', Icons.person),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: _inputDecoration('Email', Icons.email),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: _inputDecoration('Phone', Icons.phone),
              ),
            ],
          )
        else
          Column(
            children: [
              _buildInfoRow('Name', _user.name),
              _buildInfoRow('Email', _user.email),
              if (_user.phone != null) _buildInfoRow('Phone', _user.phone!),
            ],
          ),
        _buildInfoRow('Roles', _user.roles.join(', ')),
        _buildInfoRow('Status', _user.accountStatus),
        _buildInfoRow(
          'Email Verified',
          _user.isEmailVerified ? 'Yes' : 'No',
          valueColor: _user.isEmailVerified ? Colors.green : Colors.orange,
        ),
        _buildInfoRow('Auth Provider', _user.authProvider ?? 'Email'),
        _buildInfoRow('Firebase Sync', _user.syncStatusDisplay),
        if (_user.firebaseSyncError != null)
          _buildInfoRow(
            'Sync Error',
            _user.firebaseSyncError!,
            valueColor: Colors.red,
          ),
        _buildInfoRow('Joined', _user.formattedCreatedAt),
        _buildInfoRow('Last Login', _user.formattedLastLogin),
      ],
    );
  }

  // ==================== LOYALTY INFO ====================

  Widget _buildLoyaltyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Loyalty Program'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildLoyaltyCard(
                      'Points',
                      _user.loyaltyProgram.points.toString(),
                      Icons.stars,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLoyaltyCard(
                      'Tier',
                      _user.loyaltyProgram.tier,
                      Icons.military_tech,
                      _getTierColor(_user.loyaltyProgram.tier),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildLoyaltyCard(
                'Total Spent',
                '${_user.loyaltyProgram.totalSpent.toStringAsFixed(2)} AED',
                Icons.attach_money,
                Colors.green,
              ),
              if (_isEditing) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _pointsController,
                  decoration: _inputDecoration('Adjust Points', Icons.edit),
                  keyboardType: TextInputType.number,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoyaltyCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STATISTICS ====================

  Widget _buildStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Statistics'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Orders',
                _user.statistics.totalOrders.toString(),
                Icons.shopping_cart,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Spent',
                _user.statistics.formattedTotalSpent,
                Icons.payments,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Average Order Value',
          _user.statistics.formattedAverageOrderValue,
          Icons.analytics,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PREFERENCES ====================

  Widget _buildPreferences() {
    final notif = _user.preferences.notifications;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Preferences'),
        const SizedBox(height: 12),
        _buildInfoRow('Language', _user.preferences.language.toUpperCase()),
        _buildInfoRow('Currency', _user.preferences.currency),
        const SizedBox(height: 8),
        Text(
          'Notifications',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        _buildNotificationRow('Email', notif.email),
        _buildNotificationRow('Push', notif.push),
        _buildNotificationRow('SMS', notif.sms),
        _buildNotificationRow('Order Updates', notif.orderUpdates),
        _buildNotificationRow('Promotions', notif.promotions),
        _buildNotificationRow('Newsletter', notif.newsletter),
      ],
    );
  }

  Widget _buildNotificationRow(String label, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: enabled ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  // ==================== FOOTER ====================

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildFooterButton(
                'Toggle Status',
                _user.isActive ? Icons.block : Icons.check_circle,
                _user.isActive ? Colors.orange : Colors.green,
                _toggleStatus,
              ),
              const SizedBox(width: 12),
              _buildFooterButton(
                'View Orders',
                Icons.shopping_bag,
                Colors.blue,
                _viewOrders,
              ),
            ],
          ),
          if (_isEditing)
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D4C3D),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooterButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // ==================== HELPERS ====================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6D4C3D),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      default:
        return Colors.grey;
    }
  }

  // ==================== ACTIONS ====================

  void _toggleStatus() async {
    final provider = context.read<UserProvider>();
    final success = await provider.toggleActiveStatus(
      _user.id,
      !_user.isActive,
    );

    if (success && mounted) {
      setState(() {
        _user = _user.copyWith(isActive: !_user.isActive);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User ${_user.isActive ? 'activated' : 'deactivated'}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _saveChanges() async {
    final provider = context.read<UserProvider>();

    final pointsDelta =
        int.tryParse(_pointsController.text) ?? _user.loyaltyProgram.points;

    final success = await provider.updateUser(
      id: _user.id,
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
    );

    // Update points if changed
    if (pointsDelta != _user.loyaltyProgram.points) {
      await provider.updateLoyaltyPoints(
        id: _user.id,
        points: pointsDelta,
        reason: 'Admin adjustment',
      );
    }

    if (success && mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh user data
      await provider.fetchUserDetails(_user.id);
      if (mounted) {
        setState(() {
          _user = provider.selectedUser ?? _user;
        });
      }
    }
  }

  void _viewOrders() async {
    try {
      final provider = context.read<UserProvider>();

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Loading orders...'),
              ],
            ),
          );
        },
      );

      // Fetch user orders
      final orders = await provider.fetchUserOrders(_user.id);

      // Close loading dialog
      Navigator.of(context).pop();

      if (!mounted) return;

      if (orders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No orders found for this user')),
        );
        return;
      }

      // Show orders dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6D4C3D),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shopping_bag,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order History',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${orders.length} order${orders.length != 1 ? 's' : ''} found',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Orders List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final orderNumber = order['orderNumber'] ?? 'N/A';
                        final status = order['status'] ?? 'unknown';
                        final total =
                            order['total'] ?? order['totalAmount'] ?? 0;
                        final createdAt = order['createdAt'] ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(
                              Icons.receipt,
                              color: _getStatusColor(status),
                            ),
                            title: Text(
                              'Order #$orderNumber',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Status: $status',
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Date: $createdAt',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            trailing: Text(
                              'AED ${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            onTap: () {
                              // Could implement order detail view here
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Order Details - $orderNumber (Coming Soon)',
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load orders: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Get color for order status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
