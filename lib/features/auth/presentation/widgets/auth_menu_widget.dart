import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
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
                      userName: user.name ?? 'User',
                      email: user.email ?? 'No email',
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
              onActionPerformed?.call();
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signed out successfully'),
                    backgroundColor: AppTheme.primaryBrown,
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
              Navigator.pushNamed(context, AppRoutes.login);
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
              Navigator.pushNamed(context, AppRoutes.register);
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
                userName: user.name ?? 'User',
                email: user.email ?? 'No email',
                profileImageUrl: user.avatar ?? '',
              ),
            ),
          );
        }
        break;
      case 'logout':
        await authProvider.logout();
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        }
        break;
      case 'signin':
        Navigator.of(context).pushNamed(AppRoutes.login);
        break;
      case 'signup':
        Navigator.of(context).pushNamed(AppRoutes.register);
        break;
    }
  }
}
