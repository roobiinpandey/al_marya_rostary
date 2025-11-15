class AppConstants {
  // App Info
  static const String appName = 'Al Marya Driver';
  static const String appVersion = '1.0.0';

  // API Configuration - Production
  static const String baseUrl = 'https://almaryarostary.onrender.com';

  // Local Development URL (uncomment for development)
  // Use 127.0.0.1 for iOS Simulator (localhost doesn't work on simulator)
  // For real device testing, replace with your Mac's IP (e.g., 192.168.1.x)
  // static const String baseUrl = 'http://127.0.0.1:5001';

  static const String apiUrl = '$baseUrl/api';

  // Driver Endpoints
  static const String driverAuthUrl = '$apiUrl/driver/auth';
  static const String driverOrdersUrl = '$apiUrl/driver/orders';
  static const String driverLocationUrl = '$apiUrl/driver/location';
  static const String driverStatusUrl = '$apiUrl/driver/status';
  static const String driverStatsUrl = '$apiUrl/driver/stats';

  // Authentication Endpoints
  static const String pinLoginEndpoint = '$driverAuthUrl/pin-login';
  static const String qrLoginEndpoint = '$driverAuthUrl/qr-login';
  static const String changePinEndpoint = '$driverAuthUrl/change-pin';
  static const String validateTokenEndpoint = '$driverAuthUrl/validate-token';

  // Delivery Endpoints
  static const String availableDeliveriesEndpoint =
      '$driverOrdersUrl/available';
  static const String myDeliveriesEndpoint = '$driverOrdersUrl/my-deliveries';
  static const String completedDeliveriesEndpoint =
      '$driverOrdersUrl/completed';
  static const String acceptDeliveryEndpoint =
      '$driverOrdersUrl/accept'; // POST /:id/accept
  static const String startDeliveryEndpoint =
      '$driverOrdersUrl/start'; // POST /:id/start
  static const String completeDeliveryEndpoint =
      '$driverOrdersUrl/complete'; // POST /:id/complete

  // Location Endpoints
  static const String updateLocationEndpoint =
      driverLocationUrl; // POST /api/driver/location

  // Status Endpoints
  static const String updateStatusEndpoint =
      driverStatusUrl; // POST /api/driver/status

  // SharedPreferences Keys
  static const String authTokenKey = 'auth_token';
  static const String driverDataKey = 'driver_data';
  static const String rememberMeKey = 'remember_me';
  static const String pinKey = 'saved_pin';
  static const String notificationsEnabledKey = 'notifications_enabled';

  // Location Settings
  static const double locationUpdateInterval = 30.0; // seconds
  static const double minDistanceForUpdate = 50.0; // meters

  // Map Settings
  static const double defaultZoom = 15.0;
  static const double deliveryZoom = 17.0;

  // Driver Status Values
  static const String statusAvailable = 'available';
  static const String statusOnDelivery = 'on_delivery';
  static const String statusOffline = 'offline';
  static const String statusOnBreak = 'on_break';

  // Order Status Values
  static const String orderPending = 'pending';
  static const String orderAccepted = 'accepted';
  static const String orderPreparing = 'preparing';
  static const String orderReady = 'ready';
  static const String orderOutForDelivery = 'out-for-delivery';
  static const String orderCompleted = 'completed';
  static const String orderCancelled = 'cancelled';

  // Notification Settings
  static const String notificationChannelId = 'al_marya_driver_notifications';
  static const String notificationChannelName = 'Driver Notifications';
  static const String notificationChannelDescription =
      'Notifications for new deliveries and updates';

  // Timeouts
  static const int apiTimeout = 30; // seconds
  static const int locationTimeout = 10; // seconds
}
