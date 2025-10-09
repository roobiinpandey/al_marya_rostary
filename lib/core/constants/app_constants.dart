/// App-wide constants for Qahwat Al Emarat
class AppConstants {
  // API Endpoints - Environment Configuration
  // Set _useProduction to true for production MongoDB Atlas backend
  // Set _useProduction to false for local development
  static const bool _useProduction = true; // Change to false for local development
  
  static String get baseUrl => _useProduction 
    ? 'https://***REMOVED***.onrender.com'  // Production backend with MongoDB Atlas
    : 'http://localhost:5001';          // Local backend
    
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
