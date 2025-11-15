import 'package:flutter/material.dart';
import '../../features/coffee/presentation/pages/coffee_list_page.dart';
import '../../features/coffee/presentation/pages/product_detail_page.dart';
import '../../features/coffee/presentation/pages/category_browse_page.dart';
import '../../features/search/presentation/pages/search_results_page.dart';
import '../../features/account/presentation/pages/edit_profile_page.dart';
import '../../features/account/presentation/pages/address_management_page.dart';
import '../../features/account/presentation/pages/payment_methods_page.dart';
import '../../features/account/presentation/pages/account_settings_page.dart';
import '../../features/admin/presentation/pages/admin_orders_page.dart';
import '../../pages/orders_page.dart';
import '../../pages/settings_page.dart';
import '../../pages/profile_page.dart';
import '../../features/wishlist/presentation/pages/wishlist_page.dart';
import '../../data/models/coffee_product_model.dart';
import '../theme/app_theme.dart';

/// Central navigation service for consistent navigation throughout the app
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  BuildContext? get context => navigatorKey.currentContext;

  /// Navigate to a new page
  Future<T?> navigateTo<T>(Widget page) async {
    if (context == null) return null;
    return Navigator.push<T>(context!, MaterialPageRoute(builder: (_) => page));
  }

  /// Navigate and remove all previous routes
  Future<T?> navigateAndRemoveUntil<T>(Widget page) async {
    if (context == null) return null;
    return Navigator.pushAndRemoveUntil<T>(
      context!,
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  /// Navigate with named route
  Future<T?> navigateToNamed<T>(String routeName, {Object? arguments}) async {
    if (context == null) return null;
    return Navigator.pushNamed<T>(context!, routeName, arguments: arguments);
  }

  /// Replace current page
  Future<T?> replaceWith<T>(Widget page) async {
    if (context == null) return null;
    return Navigator.pushReplacement<T, dynamic>(
      context!,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Go back
  void goBack<T>([T? result]) {
    if (context != null && Navigator.canPop(context!)) {
      Navigator.pop(context!, result);
    }
  }

  /// Pop until specific route
  void popUntil(String routeName) {
    if (context == null) return;
    Navigator.popUntil(context!, ModalRoute.withName(routeName));
  }

  /// Show dialog
  Future<T?> showDialogBox<T>(Widget dialog) async {
    if (context == null) return null;
    return showDialog<T>(context: context!, builder: (_) => dialog);
  }

  /// Show bottom sheet
  Future<T?> showBottomSheet<T>(Widget sheet) async {
    if (context == null) return null;
    return showModalBottomSheet<T>(
      context: context!,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => sheet,
    );
  }

  // ============== Feature-specific navigation methods ==============

  /// Navigate to Coffee List Page (requires coffee products list)
  Future<void> navigateToCoffeeList(
    List<CoffeeProductModel> coffeeProducts,
  ) async {
    await navigateTo(CoffeeListPage(coffeeProducts: coffeeProducts));
  }

  /// Navigate to Product Detail Page
  Future<void> navigateToProductDetail(CoffeeProductModel product) async {
    await navigateTo(ProductDetailPage(product: product));
  }

  /// Navigate to Category Browse Page
  Future<void> navigateToCategoryBrowse({String? category}) async {
    await navigateTo(CategoryBrowsePage(initialCategory: category));
  }

  /// Navigate to Subcategory Page
  Future<void> navigateToSubcategory(String subcategoryName) async {
    await navigateTo(CategoryBrowsePage(initialCategory: subcategoryName));
  }

  /// Navigate to Search Results
  Future<void> navigateToSearchResults(String query) async {
    await navigateTo(SearchResultsPage(initialQuery: query));
  }

  /// Navigate to Profile Page
  Future<void> navigateToProfile() async {
    await navigateTo(const ProfilePage());
  }

  /// Navigate to Edit Profile Page
  Future<void> navigateToEditProfile() async {
    await navigateTo(const EditProfilePage());
  }

  /// Navigate to Address Management
  Future<void> navigateToAddressManagement() async {
    await navigateTo(const AddressManagementPage());
  }

  /// Navigate to Payment Methods
  Future<void> navigateToPaymentMethods() async {
    await navigateTo(const PaymentMethodsPage());
  }

  /// Navigate to Account Settings
  Future<void> navigateToAccountSettings() async {
    await navigateTo(const AccountSettingsPage());
  }

  /// Navigate to Orders Page
  Future<void> navigateToOrders() async {
    await navigateTo(const OrdersPage());
  }

  /// Navigate to Admin Orders Page
  Future<void> navigateToAdminOrders() async {
    await navigateTo(const AdminOrdersPage());
  }

  /// Navigate to Wishlist/Favorites
  Future<void> navigateToWishlist() async {
    await navigateTo(const WishlistPage());
  }

  /// Navigate to Settings
  Future<void> navigateToSettings() async {
    await navigateTo(const SettingsPage());
  }

  /// Navigate to Help Page
  Future<void> navigateToHelp() async {
    await navigateTo(_buildPlaceholderPage('Help & Support'));
  }

  /// Navigate to Contact Support
  Future<void> navigateToContactSupport() async {
    await navigateTo(_buildPlaceholderPage('Contact Support'));
  }

  /// Navigate to Privacy Policy
  Future<void> navigateToPrivacyPolicy() async {
    await navigateTo(_buildPlaceholderPage('Privacy Policy'));
  }

  /// Navigate to Terms of Service
  Future<void> navigateToTerms() async {
    await navigateTo(_buildPlaceholderPage('Terms of Service'));
  }

  /// Navigate to All Products Page
  Future<void> navigateToAllProducts() async {
    // Navigate to category browse instead which loads all products
    await navigateToCategoryBrowse();
  }

  /// Show success message
  void showSuccessMessage(String message) {
    if (context == null) return;
    ScaffoldMessenger.of(context!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show error message
  void showErrorMessage(String message) {
    if (context == null) return;
    ScaffoldMessenger.of(context!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show info message
  void showInfoMessage(String message) {
    if (context == null) return;
    ScaffoldMessenger.of(context!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Build placeholder page for unimplemented features
  Widget _buildPlaceholderPage(String pageName) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          pageName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBrown,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
                  color: AppTheme.primaryBrown,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'This feature is coming soon!',
                style: TextStyle(fontSize: 16, color: Color(0xFF8C8C8C)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
