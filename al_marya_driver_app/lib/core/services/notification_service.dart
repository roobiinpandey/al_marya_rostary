import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _isEnabled = true;

  bool get isEnabled => _isEnabled;

  // Initialize notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load notification preference
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(AppConstants.notificationsEnabledKey) ?? true;

      const initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;

      // Request permissions for iOS
      await _requestPermissions();
    } catch (e) {
      print('Error initializing notification service: $e');
      _isInitialized = false;
      _isEnabled = false;
    }
  }

  Future<void> _requestPermissions() async {
    final bool? granted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    print('iOS notification permissions granted: $granted');
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle notification tap - navigate to relevant screen
  }

  // Enable/Disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.notificationsEnabledKey, enabled);

    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  // Show notification for new available delivery
  Future<void> showNewDeliveryNotification({
    required String orderId,
    required String customerName,
    required double amount,
    required String address,
  }) async {
    if (!_isEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      'deliveries_channel',
      'Delivery Notifications',
      channelDescription: 'Notifications for new delivery orders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      orderId.hashCode, // Use order ID hash as notification ID
      '🚚 New Delivery Available',
      'Order for $customerName - AED ${amount.toStringAsFixed(2)}\n$address',
      notificationDetails,
      payload: orderId,
    );
  }

  // Show notification for delivery reminder
  Future<void> showDeliveryReminderNotification({
    required String orderId,
    required String customerName,
  }) async {
    if (!_isEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Delivery Reminders',
      channelDescription: 'Reminders for assigned deliveries',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      orderId.hashCode,
      '⏰ Delivery Reminder',
      'Pending delivery for $customerName',
      notificationDetails,
      payload: orderId,
    );
  }

  // Show notification for multiple available deliveries
  Future<void> showMultipleDeliveriesNotification(int count) async {
    if (!_isEnabled || count == 0) return;

    const androidDetails = AndroidNotificationDetails(
      'deliveries_channel',
      'Delivery Notifications',
      channelDescription: 'Notifications for new delivery orders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      0, // Use 0 for general notifications
      '🚚 Available Deliveries',
      '$count new ${count == 1 ? 'delivery' : 'deliveries'} waiting for pickup!',
      notificationDetails,
    );
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
