/// App-wide constants for Al Marya Rostery Staff App

class AppConstants {
  // App Info
  static const String appName = 'Al Marya Staff';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String staffIdKey = 'staff_id';
  static const String staffEmailKey = 'staff_email';
  static const String staffNameKey = 'staff_name';
  static const String staffRoleKey = 'staff_role';
  static const String fcmTokenKey = 'fcm_token';

  // Order Status
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusPreparing = 'preparing';
  static const String statusReady = 'ready';
  static const String statusPickedUp = 'picked_up';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';

  // Staff Status
  static const String staffStatusActive = 'active';
  static const String staffStatusOnBreak = 'on_break';
  static const String staffStatusInactive = 'inactive';

  // Staff Roles
  static const String roleBarista = 'barista';
  static const String roleManager = 'manager';
  static const String roleCashier = 'cashier';

  // Notification Channel
  static const String notificationChannelId = 'staff_orders_channel';
  static const String notificationChannelName = 'Order Notifications';
  static const String notificationChannelDescription =
      'Notifications for new orders and updates';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;

  // API Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
