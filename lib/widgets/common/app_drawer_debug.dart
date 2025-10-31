import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_logger.dart';

/// DEBUG VERSION: AppDrawer with extensive debugging
class AppDrawerDebug extends StatelessWidget {
  const AppDrawerDebug({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFA89A6A), // Almaryah olive gold
              Color(0xFFCBBE8C), // Almaryah light gold
            ],
          ),
        ),
        child: Column(
          children: [
            _buildUserProfileHeader(context),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // DEBUG: Add visible indicator at top
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.red.withValues(alpha: 0.3),
                      child: const Text(
                        'DEBUG: Navigation Section Should Start Here',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: Colors.red),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildNavigationSection(context),
                      ),
                    ),
                    _buildBottomSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Debug logging in debug mode only
        assert(() {
          AppLogger.debug(
            'DEBUG: Building header - isAuthenticated: ${authProvider.isAuthenticated}',
          );
          return true;
        }());

        if (!authProvider.isAuthenticated) {
          return _buildGuestHeader(context);
        }

        final user = authProvider.user;
        // Debug logging in debug mode only
        assert(() {
          AppLogger.debug('DEBUG: User: ${user?.name}, Email: ${user?.email}');
          return true;
        }());

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
          child: Column(
            children: [
              // Profile Picture with Edit Button
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: user?.avatar?.isNotEmpty == true
                        ? CachedNetworkImageProvider(user!.avatar!)
                        : null,
                    child: user?.avatar?.isEmpty != false
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/main-navigation',
                        arguments: {'initialIndex': 3}, // Profile tab
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFA000), // accentAmber
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // User Name
              Text(
                user?.name ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              // User Email
              if (user?.email != null && user!.email.isNotEmpty)
                Text(
                  user.email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),

              // User Role Badge
              if (user?.roles.isNotEmpty == true)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user!.roles.first.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    // Debug logging in debug mode only
    assert(() {
      AppLogger.debug('DEBUG: Building guest header');
      return true;
    }());

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person_outline,
              size: 50,
              color: Color(0xFFA89A6A), // Almaryah olive gold
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome Guest!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFA89A6A), // Almaryah olive gold
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Debug logging in debug mode only
        assert(() {
          AppLogger.debug(
            'DEBUG: Building navigation section - isAuthenticated: ${authProvider.isAuthenticated}',
          );
          AppLogger.debug('DEBUG: User: ${authProvider.user?.name}');
          return true;
        }());

        return Column(
          children: [
            // DEBUG: Profile visibility indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.green.withValues(alpha: 0.3),
              child: Text(
                'DEBUG: Profile should be visible here (Auth: ${authProvider.isAuthenticated})',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.green),
              ),
            ),

            // Profile at the TOP - Always visible
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(
                  alpha: 0.2,
                ), // DEBUG: Make it RED for visibility
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red,
                  width: 3, // DEBUG: Thick border
                ),
              ),
              child: _buildNavItem(
                context,
                icon: Icons.person,
                title: '🔴 PROFILE (DEBUG)',
                subtitle: authProvider.isAuthenticated
                    ? 'Manage your account (LOGGED IN)'
                    : 'Create your profile (GUEST)',
                onTap: () => _navigateTo(context, '/profile'),
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),

            // Coffee & Shopping Section
            _buildSectionHeader('Coffee & Shopping'),
            _buildNavItem(
              context,
              icon: Icons.home,
              title: 'Home',
              subtitle: 'Browse coffee collection',
              onTap: () => _navigateTo(context, '/home'),
            ),
            _buildNavItem(
              context,
              icon: Icons.local_cafe,
              title: 'Coffee Menu',
              subtitle: 'Explore our varieties',
              onTap: () => _navigateTo(context, '/coffee'),
            ),
            _buildNavItem(
              context,
              icon: Icons.shopping_cart,
              title: 'Cart',
              subtitle: 'View cart items',
              onTap: () => Navigator.of(context).pushNamed(
                '/main-navigation',
                arguments: {'initialIndex': 2}, // Cart tab
              ),
            ),
            if (authProvider.isAuthenticated) ...[
              _buildNavItem(
                context,
                icon: Icons.favorite,
                title: 'Favorites',
                subtitle: 'Your favorite items',
                onTap: () => _navigateTo(context, '/favorites'),
              ),
              _buildNavItem(
                context,
                icon: Icons.stars,
                title: 'Reward Points',
                subtitle: 'Earn and redeem points',
                onTap: () => Navigator.of(context).pushNamed(
                  '/main-navigation',
                  arguments: {'initialIndex': 1}, // Rewards tab
                ),
              ),
            ],

            const Divider(height: 1),

            // Account Section (for other account items)
            if (authProvider.isAuthenticated) ...[
              _buildSectionHeader('Account'),
              _buildNavItem(
                context,
                icon: Icons.receipt_long,
                title: 'Order History',
                subtitle: 'Track your orders',
                onTap: () => _navigateTo(context, '/orders'),
              ),
              _buildNavItem(
                context,
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'App preferences',
                onTap: () => _navigateTo(context, '/settings'),
              ),
            ],

            // Admin Section
            if (authProvider.user?.roles.contains('admin') ?? false) ...[
              const Divider(height: 1),
              _buildSectionHeader('Admin'),
              _buildNavItem(
                context,
                icon: Icons.dashboard,
                title: 'Admin Dashboard',
                subtitle: 'Manage the app',
                onTap: () => _navigateTo(context, '/admin'),
              ),
              _buildNavItem(
                context,
                icon: Icons.people,
                title: 'User Management',
                subtitle: 'Manage users',
                onTap: () => _navigateTo(context, '/admin/users'),
              ),
            ],

            // Support Section
            const Divider(height: 1),
            _buildSectionHeader('Support'),
            _buildNavItem(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get assistance',
              onTap: () => _navigateTo(context, '/help-support'),
            ),
            _buildNavItem(
              context,
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'App information',
              onTap: () => _navigateTo(context, '/about'),
            ),

            // DEBUG: End marker
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.blue.withValues(alpha: 0.3),
              child: const Text(
                'DEBUG: Navigation Section Ends Here',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF5D5D5D), // textMedium
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showBadge = false,
    String? badgeText,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(
            0xFFA89A6A,
          ).withValues(alpha: 0.1), // Almaryah olive gold
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFFA89A6A),
          size: 24,
        ), // Almaryah olive gold
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
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
      trailing: showBadge && badgeText != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA000), // accentAmber
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : const Icon(
              Icons.chevron_right,
              color: Color(0xFF8C8C8C), // textLight
            ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (authProvider.isAuthenticated) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, authProvider),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/login');
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Sign In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBrown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'AlMaryah Rostery v1.0.0 (DEBUG)',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF8C8C8C).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateTo(BuildContext context, String route) {
    // Debug logging in debug mode only
    assert(() {
      AppLogger.debug('DEBUG: Navigating to: $route');
      return true;
    }());
    Navigator.pop(context); // Close drawer
    Navigator.pushNamed(context, route);
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          Flexible(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', overflow: TextOverflow.ellipsis),
            ),
          ),
          Flexible(
            child: ElevatedButton(
              onPressed: () async {
                // Get navigator before async operations
                final navigator = Navigator.of(context);
                final rootNavigator = Navigator.of(
                  context,
                  rootNavigator: true,
                );

                // Close dialog and drawer
                navigator.pop(); // Close dialog
                navigator.pop(); // Close drawer

                // Wait a frame for UI to settle
                await Future.delayed(const Duration(milliseconds: 100));

                // Perform logout
                await authProvider.logout();

                // Wait for logout to complete fully
                await Future.delayed(const Duration(milliseconds: 100));

                // Navigate to login (use root navigator to clear everything)
                if (context.mounted) {
                  rootNavigator.pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign Out', overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}
