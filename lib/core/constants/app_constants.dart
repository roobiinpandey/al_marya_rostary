/// App-wide constants for Qahwat Al Emarat
class AppConstants {
  // API Endpoints
  static const String baseUrl = 'http://localhost:5001';
  static const String coffeeEndpoint = '/api/coffees';
  static const String categoriesEndpoint = '/api/categories';
  static const String slidersEndpoint = '/api/sliders';
  static const String cartEndpoint = '/cart';
  static const String ordersEndpoint = '/orders';
  static const String authEndpoint = '/api/auth';

  // App Info
  static const String appName = 'Qahwat Al Emarat';
  static const String appVersion = '1.0.0';

  // Currency
  static const String currencySymbol = 'AED'; // UAE Dirham Code
  static const String currencyCode = 'AED';

  // Asset Paths
  static const String logoPath = 'assets/images/logo.png';
  static const String defaultProfilePic = 'assets/images/default_profile.png';

  // Other constants
  static const int defaultTimeout = 30; // seconds
}
