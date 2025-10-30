import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  // Track expanded sections
  final Map<String, bool> _expandedSections = {
    'coffee_beans': false,
    'brewing_methods': false,
    'accessories': false,
    'gifts': false,
  };

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
        if (!authProvider.isAuthenticated) {
          return _buildGuestHeader(context);
        }

        final user = authProvider.user;
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
                      onTap: () => Navigator.pushNamed(context, '/profile'),
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
        return Column(
          children: [
            // Profile at the TOP - Always visible
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFA89A6A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFA89A6A).withValues(alpha: 0.3),
                ),
              ),
              child: _buildNavItem(
                context,
                icon: Icons.person,
                title: 'Profile',
                subtitle: authProvider.isAuthenticated
                    ? 'Manage your account'
                    : 'Create your profile',
                onTap: () => _navigateTo(context, '/profile'),
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),

            // Coffee & Product Categories
            _buildSectionHeader('Coffee & Products'),

            // Coffee Beans - Expandable
            _buildExpandableSection(
              context,
              'coffee_beans',
              Icons.coffee_outlined,
              'Coffee Beans',
              'Premium coffee varieties',
              [
                {'title': 'Arabica', 'route': '/coffee/arabica'},
                {'title': 'Robusta', 'route': '/coffee/robusta'},
                {'title': 'Blends', 'route': '/coffee/blends'},
              ],
            ),

            // Brewing Methods - Expandable
            _buildExpandableSection(
              context,
              'brewing_methods',
              Icons.local_cafe_outlined,
              'Brewing Methods',
              'Perfect brewing techniques',
              [
                {'title': 'Drip', 'route': '/brewing/drip'},
                {'title': 'French Press', 'route': '/brewing/french-press'},
                {'title': 'Espresso', 'route': '/brewing/espresso'},
              ],
            ),

            // Accessories - Expandable
            _buildExpandableSection(
              context,
              'accessories',
              Icons.build_outlined,
              'Accessories',
              'Coffee making tools',
              [
                {'title': 'Grinders', 'route': '/accessories/grinders'},
                {'title': 'Mugs', 'route': '/accessories/mugs'},
                {'title': 'Filters', 'route': '/accessories/filters'},
              ],
            ),

            // Gifts - Expandable
            _buildExpandableSection(
              context,
              'gifts',
              Icons.card_giftcard_outlined,
              'Gifts',
              'Perfect coffee gifts',
              [
                {'title': 'Gift Sets', 'route': '/gifts/sets'},
                {
                  'title': 'Subscriptions',
                  'route': '/subscription',
                  'isSpecial': true,
                },
              ],
            ),

            const Divider(height: 1),

            // Featured Sections
            _buildSectionHeader('Featured'),
            _buildNavItem(
              context,
              icon: Icons.star_outline,
              title: 'Featured Products',
              subtitle: 'Highlighted coffee selections',
              onTap: () => _navigateTo(context, '/featured'),
            ),
            _buildNavItem(
              context,
              icon: Icons.trending_up_outlined,
              title: 'Best Sellers',
              subtitle: 'Popular items',
              onTap: () => _navigateTo(context, '/bestsellers'),
            ),
            _buildNavItem(
              context,
              icon: Icons.new_releases_outlined,
              title: 'New Arrivals',
              subtitle: 'Latest coffee products',
              onTap: () => _navigateTo(context, '/new-arrivals'),
            ),

            const Divider(height: 1),

            // Quick Actions
            _buildSectionHeader('Quick Actions'),
            _buildNavItem(
              context,
              icon: Icons.menu_book_outlined,
              title: 'Brewing Guide',
              subtitle: 'Coffee preparation instructions',
              onTap: () => _navigateTo(context, '/brewing-guide'),
            ),
            _buildNavItem(
              context,
              icon: Icons.repeat_outlined,
              title: 'Subscription',
              subtitle: 'Coffee subscription service',
              isSpecial: true,
              onTap: () => _navigateTo(context, '/subscription'),
            ),
            _buildNavItem(
              context,
              icon: Icons.contact_support_outlined,
              title: 'Contact Us',
              subtitle: 'Customer support',
              onTap: () => _navigateTo(context, '/contact'),
            ),

            const Divider(height: 1),

            // Essential Navigation
            _buildSectionHeader('Navigation'),
            _buildNavItem(
              context,
              icon: Icons.home_outlined,
              title: 'Home',
              subtitle: 'Browse coffee collection',
              onTap: () => _navigateTo(context, '/home'),
            ),
            _buildNavItem(
              context,
              icon: Icons.shopping_cart_outlined,
              title: 'Cart',
              subtitle: 'View cart items',
              onTap: () => _navigateTo(context, '/cart'),
            ),
            if (authProvider.isAuthenticated) ...[
              _buildNavItem(
                context,
                icon: Icons.favorite_outline,
                title: 'Favorites',
                subtitle: 'Your favorite items',
                onTap: () => _navigateTo(context, '/favorites'),
              ),
            ],

            // Account Section (for authenticated users)
            if (authProvider.isAuthenticated) ...[
              const Divider(height: 1),
              _buildSectionHeader('Account'),
              _buildNavItem(
                context,
                icon: Icons.receipt_long_outlined,
                title: 'Order History',
                subtitle: 'Track your orders',
                onTap: () => _navigateTo(context, '/orders'),
              ),
              _buildNavItem(
                context,
                icon: Icons.settings_outlined,
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
                icon: Icons.dashboard_outlined,
                title: 'Admin Dashboard',
                subtitle: 'Manage the app',
                onTap: () => _navigateTo(context, '/admin'),
              ),
              _buildNavItem(
                context,
                icon: Icons.people_outline,
                title: 'User Management',
                subtitle: 'Manage users',
                onTap: () => _navigateTo(context, '/admin/users'),
              ),
            ],
          ],
        );
      },
    );
  }

  // New method for expandable sections
  Widget _buildExpandableSection(
    BuildContext context,
    String sectionKey,
    IconData icon,
    String title,
    String subtitle,
    List<Map<String, dynamic>> items,
  ) {
    final isExpanded = _expandedSections[sectionKey] ?? false;

    return Column(
      children: [
        _buildNavItem(
          context,
          icon: icon,
          title: title,
          subtitle: subtitle,
          trailing: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            color: const Color(0xFF8C8C8C),
          ),
          onTap: () {
            setState(() {
              _expandedSections[sectionKey] = !isExpanded;
            });
          },
        ),
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(left: 56, right: 16),
            child: Column(
              children: items.map((item) {
                final isSpecial = item['isSpecial'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    leading: isSpecial
                        ? const Icon(
                            Icons.star,
                            color: Color(0xFFFFA000),
                            size: 16,
                          )
                        : Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFA89A6A,
                              ).withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                          ),
                    title: Text(
                      item['title'],
                      style: TextStyle(
                        fontSize: 14,
                        color: isSpecial
                            ? const Color(0xFFFFA000)
                            : const Color(0xFF2E2E2E),
                        fontWeight: isSpecial
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: isSpecial
                        ? const Icon(
                            Icons.star_outlined,
                            color: Color(0xFFFFA000),
                            size: 16,
                          )
                        : const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF8C8C8C),
                            size: 16,
                          ),
                    onTap: () => _navigateTo(context, item['route']),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    dense: true,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
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
    bool isSpecial = false,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSpecial
              ? const Color(0xFFFFA000).withValues(alpha: 0.1)
              : const Color(0xFFA89A6A).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSpecial ? const Color(0xFFFFA000) : const Color(0xFFA89A6A),
          size: 24,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSpecial
                    ? const Color(0xFFFFA000)
                    : const Color(0xFF2E2E2E),
              ),
            ),
          ),
          if (isSpecial)
            const Icon(Icons.star, size: 16, color: Color(0xFFFFA000)),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isSpecial
              ? const Color(0xFFFFA000).withValues(alpha: 0.8)
              : const Color(0xFF8C8C8C),
        ),
      ),
      trailing:
          trailing ??
          (showBadge && badgeText != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA000),
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
              : const Icon(Icons.chevron_right, color: Color(0xFF8C8C8C))),
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
                'AlMaryah Rostery v1.0.0',
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
