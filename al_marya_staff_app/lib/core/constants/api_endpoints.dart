/// API Endpoints Configuration
/// For production, update baseUrl to production server URL
class ApiEndpoints {
  // Production URL (Render.com)
  static const String baseUrl = 'https://almaryarostary.onrender.com';

  // Local Development URL (uncomment for development)
  // static const String baseUrl = 'http://localhost:5001';

  // Staff Authentication Endpoints
  static const String staffLogin = '$baseUrl/api/staff/login';
  static const String staffRegister = '$baseUrl/api/staff/register';
  static const String updateFcmToken = '$baseUrl/api/staff/fcm-token';

  // Staff Profile Endpoints
  static const String getProfile = '$baseUrl/api/staff/profile';
  static const String updateStatus = '$baseUrl/api/staff/status';
  static const String getStats = '$baseUrl/api/staff/stats';

  // Order Management Endpoints
  static const String getOrders = '$baseUrl/api/staff/orders';
  static String getOrderDetails(String orderId) =>
      '$baseUrl/api/staff/orders/$orderId';
  static String acceptOrder(String orderId) =>
      '$baseUrl/api/staff/orders/$orderId/accept';
  static String startPreparation(String orderId) =>
      '$baseUrl/api/staff/orders/$orderId/start';
  static String markOrderReady(String orderId) =>
      '$baseUrl/api/staff/orders/$orderId/ready';

  // Health Check
  static const String health = '$baseUrl/api/health';
}
