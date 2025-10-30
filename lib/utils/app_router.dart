import 'package:flutter/material.dart';
import '../pages/settings_page.dart';
import '../features/wishlist/presentation/pages/wishlist_page.dart';
import '../pages/orders_page.dart';
import '../pages/profile_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/auth/presentation/pages/login_page.dart'; // FIXED: Use features-based login page
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/screens/email_verification_screen.dart';
import '../core/guards/email_verification_guard.dart';
import '../debug/auth_debug_page.dart';
import '../features/admin/presentation/pages/admin_login_page.dart';
import '../core/theme/app_theme.dart';
// Import missing pages
import '../features/coffee/presentation/pages/product_detail_page.dart';
import '../features/coffee/presentation/pages/coffee_list_page_wrapper.dart';
import '../features/cart/presentation/pages/cart_page.dart';
import '../features/cart/presentation/pages/guest_checkout_page.dart';
import '../features/checkout/presentation/pages/checkout_page.dart';
import '../features/checkout/presentation/pages/order_confirmation_page.dart';
import '../features/checkout/presentation/pages/order_tracking_page.dart';
import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/admin/presentation/pages/admin_orders_page.dart';
import '../features/admin/presentation/pages/user_management_page.dart';
import '../features/admin/presentation/pages/firebase_users_page.dart';
import '../features/search/presentation/pages/search_results_page.dart';
import '../features/account/presentation/pages/account_settings_page.dart';
import '../features/account/presentation/pages/edit_profile_page.dart';
import '../features/account/presentation/pages/change_password_page.dart';
import '../features/account/presentation/pages/address_management_page.dart';
import '../features/account/presentation/pages/payment_methods_page.dart';
import '../features/coffee/presentation/pages/category_browse_page.dart';
import '../features/coffee/presentation/pages/filter_sort_page.dart';
import '../features/coffee/presentation/pages/reviews_page.dart';
import '../features/coffee/presentation/pages/write_review_page.dart';
import '../features/account/presentation/pages/loyalty_rewards_page.dart';
import '../features/account/presentation/pages/referral_page.dart';
import '../features/account/presentation/pages/subscription_management_page.dart';
// Import new pages
import '../features/admin/presentation/pages/admin_products_page.dart';
import '../features/admin/presentation/pages/admin_analytics_page.dart';
import '../features/admin/presentation/pages/admin_settings_page.dart';
import '../features/admin/presentation/pages/admin_reports_page.dart';
import '../features/common/presentation/pages/help_support_page.dart';
import '../features/common/presentation/pages/about_page.dart';
// Import enhanced navigation pages
import '../features/coffee/presentation/pages/coffee_arabica_page.dart';
import '../features/coffee/presentation/pages/coffee_robusta_page.dart';
import '../features/coffee/presentation/pages/coffee_blends_page.dart';
import '../features/coffee/presentation/pages/brewing_guide_page.dart';
import '../features/coffee/presentation/pages/featured_products_page.dart';
import '../features/coffee/presentation/pages/best_sellers_page.dart';
import '../features/coffee/presentation/pages/new_arrivals_page.dart';
import '../features/coffee/presentation/pages/accessories_page.dart';
import '../features/coffee/presentation/pages/gifts_page.dart';
import '../features/subscription/presentation/pages/subscription_page.dart';

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
  static const String checkout = '/checkout';
  static const String orderConfirmation = '/orderConfirmation';
  static const String orderTracking = '/order-tracking';
  static const String admin = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminOrders = '/admin/orders';
  static const String adminProducts = '/admin/products';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminSettings = '/admin/settings';
  static const String adminReports = '/admin/reports';
  static const String helpSupport = '/help-support';
  static const String about = '/about';
  static const String search = '/search';
  static const String productDetail = '/product';
  static const String accountSettings = '/account-settings';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String addressManagement = '/address-management';
  static const String paymentMethods = '/payment-methods';
  static const String categoryBrowse = '/category-browse';
  static const String filterSort = '/filter-sort';
  static const String reviews = '/reviews';
  static const String writeReview = '/write-review';
  static const String loyaltyRewards = '/loyalty-rewards';
  static const String referral = '/referral';
  static const String subscriptions = '/subscriptions';
  static const String debugAuth = '/debug/auth';
  // Enhanced navigation routes
  static const String coffeeArabica = '/coffee/arabica';
  static const String coffeeRobusta = '/coffee/robusta';
  static const String coffeeBlends = '/coffee/blends';
  static const String brewingGuide = '/brewing-guide';
  static const String featuredProducts = '/featured-products';
  static const String bestSellers = '/best-sellers';
  static const String newArrivals = '/new-arrivals';
  static const String accessories = '/accessories';
  static const String gifts = '/gifts';
  static const String subscription = '/subscription';

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
        return _buildRoute(const CoffeeListPageWrapper(), settings: settings);

      case '/cart':
        return _buildRoute(const CartPage(), settings: settings);

      case '/guest-checkout':
        return _buildRoute(const GuestCheckoutPage(), settings: settings);

      case '/checkout':
        return _buildRoute(
          const EmailVerificationGuard(child: CheckoutPage()),
          settings: settings,
        );

      case '/orderConfirmation':
        final orderData = settings.arguments as Map<String, dynamic>?;
        if (orderData == null) {
          return _buildRoute(
            _buildErrorPage('Order data not found'),
            settings: settings,
          );
        }
        return _buildRoute(
          OrderConfirmationPage(orderData: orderData),
          settings: settings,
        );

      case '/order-tracking':
        final orderNumber = settings.arguments as String?;
        if (orderNumber == null) {
          return _buildRoute(
            _buildErrorPage('Order number not provided'),
            settings: settings,
          );
        }
        return _buildRoute(
          OrderTrackingPage(orderNumber: orderNumber),
          settings: settings,
        );

      case '/product':
        final product = settings.arguments as dynamic;
        if (product == null) {
          return _buildRoute(
            _buildErrorPage('Product not found'),
            settings: settings,
          );
        }
        return _buildRoute(
          ProductDetailPage(product: product),
          settings: settings,
        );

      case '/search':
        final query = settings.arguments as String?;
        return _buildRoute(
          SearchResultsPage(initialQuery: query ?? ''),
          settings: settings,
        );

      case '/admin':
        return _buildRoute(const AdminLoginPage(), settings: settings);

      case '/admin/dashboard':
        return _buildRoute(
          const EmailVerificationGuard(child: AdminDashboardPage()),
          settings: settings,
        );

      case '/admin/users':
        return _buildRoute(
          const EmailVerificationGuard(child: UserManagementPage()),
          settings: settings,
        );

      case '/admin/firebase-users':
        return _buildRoute(
          const EmailVerificationGuard(child: FirebaseUsersPage()),
          settings: settings,
        );

      case '/admin/orders':
        return _buildRoute(const AdminOrdersPage(), settings: settings);

      case '/admin/products':
        return _buildRoute(const AdminProductsPage(), settings: settings);

      case '/admin/analytics':
        return _buildRoute(const AdminAnalyticsPage(), settings: settings);

      case '/admin/settings':
        return _buildRoute(const AdminSettingsPage(), settings: settings);

      case '/admin/reports':
        return _buildRoute(const AdminReportsPage(), settings: settings);

      case '/account-settings':
        return _buildRoute(
          const EmailVerificationGuard(child: AccountSettingsPage()),
          settings: settings,
        );

      case '/edit-profile':
        return _buildRoute(
          const EmailVerificationGuard(child: EditProfilePage()),
          settings: settings,
        );

      case '/change-password':
        return _buildRoute(
          const EmailVerificationGuard(child: ChangePasswordPage()),
          settings: settings,
        );

      case '/address-management':
        return _buildRoute(
          const EmailVerificationGuard(child: AddressManagementPage()),
          settings: settings,
        );

      case '/payment-methods':
        return _buildRoute(
          const EmailVerificationGuard(child: PaymentMethodsPage()),
          settings: settings,
        );

      case '/category-browse':
        final initialCategory = settings.arguments as String?;
        return _buildRoute(
          CategoryBrowsePage(initialCategory: initialCategory),
          settings: settings,
        );

      case '/filter-sort':
        final initialFilters = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          FilterSortPage(initialFilters: initialFilters),
          settings: settings,
        );

      case '/reviews':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null ||
            !args.containsKey('productId') ||
            !args.containsKey('productName')) {
          return _buildRoute(
            _buildErrorPage('Product information not provided'),
            settings: settings,
          );
        }
        return _buildRoute(
          ReviewsPage(
            productId: args['productId'] as String,
            productName: args['productName'] as String,
          ),
          settings: settings,
        );

      case '/write-review':
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          WriteReviewPage(
            productId: args?['productId'] as String?,
            productName: args?['productName'] as String?,
          ),
          settings: settings,
        );

      case '/loyalty-rewards':
        return _buildRoute(
          const EmailVerificationGuard(child: LoyaltyRewardsPage()),
          settings: settings,
        );

      case '/referral':
        return _buildRoute(
          const EmailVerificationGuard(child: ReferralPage()),
          settings: settings,
        );

      case '/subscriptions':
        return _buildRoute(
          const EmailVerificationGuard(child: SubscriptionManagementPage()),
          settings: settings,
        );

      case '/debug/auth':
        return _buildRoute(const AuthDebugPage(), settings: settings);

      case '/help-support':
        return _buildRoute(const HelpSupportPage(), settings: settings);

      case '/about':
        return _buildRoute(const AboutPage(), settings: settings);

      // Enhanced navigation routes
      case '/coffee/arabica':
        return _buildRoute(const CoffeeArabicaPage(), settings: settings);

      case '/coffee/robusta':
        return _buildRoute(const CoffeeRobustaPage(), settings: settings);

      case '/coffee/blends':
        return _buildRoute(const CoffeeBlendsPage(), settings: settings);

      case '/brewing-guide':
        return _buildRoute(const BrewingGuidePage(), settings: settings);

      case '/featured-products':
        return _buildRoute(const FeaturedProductsPage(), settings: settings);

      case '/best-sellers':
        return _buildRoute(const BestSellersPage(), settings: settings);

      case '/new-arrivals':
        return _buildRoute(const NewArrivalsPage(), settings: settings);

      case '/accessories':
        return _buildRoute(const AccessoriesPage(), settings: settings);

      case '/gifts':
        return _buildRoute(const GiftsPage(), settings: settings);

      case '/subscription':
        return _buildRoute(const SubscriptionPage(), settings: settings);

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

  static Widget _buildErrorPage(String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Error',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFA89A6A),
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
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                'Oops!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA89A6A),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 16, color: Color(0xFF5D5D5D)),
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
        backgroundColor: AppTheme.primaryBrown,
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
                  color: AppTheme.primaryBrown,
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
