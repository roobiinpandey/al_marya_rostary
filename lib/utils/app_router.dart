import 'package:flutter/material.dart';
import '../pages/settings_page.dart';
import '../features/wishlist/presentation/pages/wishlist_page.dart';
import '../pages/orders_page.dart';
import '../pages/profile_page.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/screens/email_verification_screen.dart';
import '../core/guards/email_verification_guard.dart';

class AppRouter {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String favorites = '/favorites';
  static const String orders = '/orders';
  static const String coffee = '/coffee';
  static const String cart = '/cart';
  static const String admin = '/admin';
  static const String adminUsers = '/admin/users';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _buildRoute(
          const EmailVerificationGuard(child: HomePage()),
          settings: settings,
        );

      case '/home':
        return _buildRoute(
          const EmailVerificationGuard(child: HomePage()),
          settings: settings,
        );

      case '/login':
        return _buildRoute(const LoginPage(), settings: settings);

      case '/register':
        return _buildRoute(const RegisterPage(), settings: settings);

      case '/forgot-password':
        return _buildRoute(const ForgotPasswordPage(), settings: settings);

      case '/email-verification':
        return _buildRoute(const EmailVerificationScreen(), settings: settings);

      case '/profile':
        return _buildRoute(
          const EmailVerificationGuard(child: ProfilePage()),
          settings: settings,
        );

      case '/settings':
        return _buildRoute(const SettingsPage(), settings: settings);

      case '/favorites':
        return _buildRoute(const WishlistPage(), settings: settings);

      case '/orders':
        return _buildRoute(
          const EmailVerificationGuard(child: OrdersPage()),
          settings: settings,
        );

      case '/coffee':
        return _buildRoute(
          _buildPlaceholderPage('Coffee Menu'),
          settings: settings,
        );

      case '/cart':
        return _buildRoute(
          _buildPlaceholderPage('Shopping Cart'),
          settings: settings,
        );

      case '/admin':
        return _buildRoute(
          _buildPlaceholderPage('Admin Dashboard'),
          settings: settings,
        );

      case '/admin/users':
        return _buildRoute(
          _buildPlaceholderPage('User Management'),
          settings: settings,
        );

      default:
        return _buildRoute(_buildNotFoundPage(), settings: settings);
    }
  }

  static MaterialPageRoute<dynamic> _buildRoute(
    Widget child, {
    required RouteSettings settings,
  }) {
    return MaterialPageRoute<dynamic>(
      builder: (BuildContext context) => child,
      settings: settings,
    );
  }

  static Widget _buildPlaceholderPage(String pageName) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          pageName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.construction,
                size: 80,
                color: Color(0xFF8C8C8C),
              ),
              const SizedBox(height: 24),
              Text(
                pageName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Coming Soon!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5D5D5D),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This page is under development and will be available soon.',
                style: TextStyle(fontSize: 14, color: Color(0xFF8C8C8C)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildNotFoundPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Page Not Found',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Color(0xFF8C8C8C)),
              SizedBox(height: 24),
              Text(
                '404',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Page Not Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5D5D5D),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'The page you are looking for does not exist.',
                style: TextStyle(fontSize: 14, color: Color(0xFF8C8C8C)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigation helper methods
  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, home, (route) => false);
  }

  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamed(context, login);
  }

  static void navigateToRegister(BuildContext context) {
    Navigator.pushNamed(context, register);
  }

  static void navigateToForgotPassword(BuildContext context) {
    Navigator.pushNamed(context, forgotPassword);
  }

  static void navigateToEmailVerification(BuildContext context) {
    Navigator.pushNamed(context, emailVerification);
  }

  static void navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, profile);
  }

  static void navigateToSettings(BuildContext context) {
    Navigator.pushNamed(context, settings);
  }

  static void navigateToFavorites(BuildContext context) {
    Navigator.pushNamed(context, favorites);
  }

  static void navigateToOrders(BuildContext context) {
    Navigator.pushNamed(context, orders);
  }

  static void navigateToCoffee(BuildContext context) {
    Navigator.pushNamed(context, coffee);
  }

  static void navigateToCart(BuildContext context) {
    Navigator.pushNamed(context, cart);
  }

  static void navigateToAdmin(BuildContext context) {
    Navigator.pushNamed(context, admin);
  }

  static void navigateToAdminUsers(BuildContext context) {
    Navigator.pushNamed(context, adminUsers);
  }

  static void goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      navigateToHome(context);
    }
  }

  /// Check if current route is a specific route
  static bool isCurrentRoute(BuildContext context, String routeName) {
    return ModalRoute.of(context)?.settings.name == routeName;
  }

  /// Get current route name
  static String? getCurrentRoute(BuildContext context) {
    return ModalRoute.of(context)?.settings.name;
  }
}
