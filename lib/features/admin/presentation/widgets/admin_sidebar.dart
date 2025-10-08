import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Admin sidebar navigation widget
class AdminSidebar extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;

  const AdminSidebar({super.key, required this.isOpen, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isOpen ? 280 : 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppTheme.primaryBrown),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: AppTheme.primaryBrown,
                    size: 24,
                  ),
                ),
                if (isOpen) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Panel',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Qahwat Al Emarat',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white.withValues(alpha:0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    isOpen ? Icons.chevron_left : Icons.chevron_right,
                    color: Colors.white,
                  ),
                  onPressed: onToggle,
                  iconSize: 20,
                ),
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  context,
                  'Dashboard',
                  Icons.dashboard,
                  isSelected: true,
                  onTap: () {
                    // Already on dashboard
                  },
                ),
                const Divider(height: 1),
                _buildNavItem(
                  context,
                  'Products',
                  Icons.inventory,
                  onTap: () {
                    // TODO: Navigate to products page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Products - Coming Soon')),
                    );
                  },
                ),
                _buildNavItem(
                  context,
                  'Orders',
                  Icons.shopping_cart,
                  onTap: () {
                    // TODO: Navigate to orders page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Orders - Coming Soon')),
                    );
                  },
                ),
                _buildNavItem(
                  context,
                  'User Management',
                  Icons.people,
                  onTap: () {
                    Navigator.pushNamed(context, '/admin/users');
                  },
                ),
                const Divider(height: 1),
                _buildNavItem(
                  context,
                  'Analytics',
                  Icons.analytics,
                  onTap: () {
                    // TODO: Navigate to analytics page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Analytics - Coming Soon')),
                    );
                  },
                ),
                _buildNavItem(
                  context,
                  'Reports',
                  Icons.description,
                  onTap: () {
                    // TODO: Navigate to reports page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reports - Coming Soon')),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildNavItem(
                  context,
                  'Settings',
                  Icons.settings,
                  onTap: () {
                    // TODO: Navigate to settings page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings - Coming Soon')),
                    );
                  },
                ),
                _buildNavItem(
                  context,
                  'Support',
                  Icons.help,
                  onTap: () {
                    // TODO: Navigate to support page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support - Coming Soon')),
                    );
                  },
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey, width: 1)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryLightBrown,
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: AppTheme.primaryBrown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isOpen) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin User',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'admin@qahwatalemarat.com',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, size: 20),
                    onPressed: () async {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      await authProvider.logout();
                      if (context.mounted) {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/login', (route) => false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Signed out successfully'),
                          ),
                        );
                      }
                    },
                    tooltip: 'Logout',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String title,
    IconData icon, {
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? AppTheme.primaryLightBrown.withValues(alpha:0.1) : null,
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppTheme.primaryBrown : AppTheme.textMedium,
            ),
            if (isOpen) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isSelected
                        ? AppTheme.primaryBrown
                        : AppTheme.textDark,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 4,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBrown,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
