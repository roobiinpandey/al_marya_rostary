import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../../profile/presentation/pages/profile_page.dart';

/// A reusable widget that displays authentication-related menu options
/// based on the current user's authentication state.
///
/// Shows different options for:
/// - Authenticated non-guest users: Profile, Sign Out
/// - Guest users: Sign In, Sign Up
/// - Unauthenticated users: Sign In, Sign Up
class AuthMenuWidget extends StatelessWidget {
  /// Whether to display as drawer items (vertical list)
  final bool isDrawerStyle;

  /// Optional callback when an action is performed (useful for closing popups/drawers)
  final VoidCallback? onActionPerformed;

  const AuthMenuWidget({
    super.key,
    this.isDrawerStyle = true,
    this.onActionPerformed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          // Authenticated user: show Profile and Sign Out
          return _buildAuthenticatedUserMenu(context, authProvider);
        } else {
          // Unauthenticated: show Sign In and Sign Up
          return _buildGuestUserMenu(context);
        }
      },
    );
  }

  Widget _buildAuthenticatedUserMenu(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final user = authProvider.user;

    if (isDrawerStyle) {
      return Column(
        children: [
          // Profile option
          ListTile(
            leading: Icon(Icons.person, color: AppTheme.primaryBrown),
            title: Text(
              'Profile',
              style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              if (user != null) {
                onActionPerformed?.call();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      userName: user.name,
                      email: user.email,
                      profileImageUrl: user.avatar ?? '',
                    ),
                  ),
                );
              }
            },
          ),
          // Sign Out option
          ListTile(
            leading: Icon(Icons.logout, color: AppTheme.primaryBrown),
            title: Text(
              'Sign Out',
              style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () async {
              // Get navigator before async operations
              final navigator = Navigator.of(context, rootNavigator: true);
              final messenger = ScaffoldMessenger.of(context);

              // Call callback first
              onActionPerformed?.call();

              // Wait a frame for UI to settle
              await Future.delayed(const Duration(milliseconds: 100));

              // Perform logout
              await authProvider.logout();

              // Wait for logout to complete fully
              await Future.delayed(const Duration(milliseconds: 100));

              // Navigate to login (use root navigator to clear everything)
              if (context.mounted) {
                navigator.pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );

                // Show success message
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Signed out successfully'),
                    backgroundColor: AppTheme.primaryBrown,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      );
    } else {
      // Return popup menu items for non-drawer style
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // This will be handled by the parent PopupMenuButton
        ],
      );
    }
  }

  Widget _buildGuestUserMenu(BuildContext context) {
    if (isDrawerStyle) {
      return Column(
        children: [
          // Sign In option
          ListTile(
            leading: Icon(Icons.login, color: AppTheme.primaryBrown),
            title: Text(
              'Sign In',
              style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              onActionPerformed?.call();
              // Replace entire stack with login page for clean navigation
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
            },
          ),
          // Sign Up option
          ListTile(
            leading: Icon(Icons.person_add, color: AppTheme.primaryBrown),
            title: Text(
              'Sign Up',
              style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              onActionPerformed?.call();
              // Replace entire stack with register page for clean navigation
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamedAndRemoveUntil(AppRoutes.register, (route) => false);
            },
          ),
        ],
      );
    } else {
      // Return popup menu items for non-drawer style
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // This will be handled by the parent PopupMenuButton
        ],
      );
    }
  }

  /// Static method to get popup menu items for PopupMenuButton
  static List<PopupMenuEntry<String>> getPopupMenuItems(
    AuthProvider authProvider,
  ) {
    if (authProvider.isAuthenticated) {
      // Authenticated user: show Profile and Sign Out
      return [
        const PopupMenuItem(value: 'profile', child: Text('Profile')),
        const PopupMenuItem(value: 'logout', child: Text('Sign Out')),
      ];
    } else {
      // Unauthenticated: show Sign In and Sign Up
      return [
        const PopupMenuItem(value: 'signin', child: Text('Sign In')),
        const PopupMenuItem(value: 'signup', child: Text('Sign Up')),
      ];
    }
  }

  /// Static method to handle popup menu actions
  static Future<void> handlePopupMenuAction(
    String value,
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    switch (value) {
      case 'profile':
        final user = authProvider.user;
        if (user != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProfilePage(
                userName: user.name,
                email: user.email,
                profileImageUrl: user.avatar ?? '',
              ),
            ),
          );
        }
        break;
      case 'logout':
        // Wait a frame for UI to settle
        await Future.delayed(const Duration(milliseconds: 100));

        // Perform logout
        await authProvider.logout();

        // Wait for logout to complete fully
        await Future.delayed(const Duration(milliseconds: 100));

        // Navigate to login
        if (context.mounted) {
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        }
        break;
      case 'signin':
        // Replace entire stack with login page for clean navigation
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        break;
      case 'signup':
        // Replace entire stack with register page for clean navigation
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil(AppRoutes.register, (route) => false);
        break;
    }
  }
}
