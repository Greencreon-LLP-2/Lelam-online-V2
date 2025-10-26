// lib/core/service/awesome_notification_service.dart
import 'package:awesome_notifications/awesome_notifications.dart';

class AwesomeNotificationService {
  static final AwesomeNotificationService _instance = AwesomeNotificationService._internal();
  factory AwesomeNotificationService() => _instance;
  AwesomeNotificationService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await AwesomeNotifications().initialize(
        null, // Use default app icon
        [
          NotificationChannel(
            channelKey: 'basic_channel',
            channelName: 'Basic Notifications',
            channelDescription: 'Notification channel for basic alerts',
            // defaultColor: const Color(0xFF9D50DD),
            // ledColor: Colors.white,
            importance: NotificationImportance.High,
          ),
          NotificationChannel(
            channelKey: 'auction_channel',
            channelName: 'Auction Notifications',
            channelDescription: 'Notification channel for auction updates',
            // defaultColor: const Color(0xFF2196F3),
            // ledColor: Colors.blue,
            importance: NotificationImportance.High,
          ),
        ],
        debug: true,
      );

      // Set up notification listeners
      _setupNotificationListeners();

      _isInitialized = true;
      print('AwesomeNotifications initialized successfully');
    } catch (e) {
      print('Error initializing AwesomeNotifications: $e');
    }
  }

  void _setupNotificationListeners() {
    // Handle notification taps
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod: _onNotificationCreatedMethod,
      onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
    );
  }

  static Future<void> _onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Handle notification tap
    final payload = receivedAction.payload;
    
    if (payload != null) {
      print('Notification tapped with payload: $payload');
      
      final String? type = payload['type'];
      final String? id = payload['id'];
      
      // Handle navigation based on payload
      _handleNavigation(type, id);
    }
  }

  static Future<void> _onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // Notification was created
    print('Notification created: ${receivedNotification.body}');
  }

  static Future<void> _onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // Notification was displayed
    print('Notification displayed: ${receivedNotification.body}');
  }

  static Future<void> _onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Notification was dismissed
    print('Notification dismissed');
  }

  static void _handleNavigation(String? type, String? id) {
    switch (type) {
      case 'auction':
        // Navigate to auction detail
        print('Navigate to auction: $id');
        break;
      case 'product':
        // Navigate to product detail
        print('Navigate to product: $id');
        break;
      case 'order':
        // Navigate to order detail
        print('Navigate to order: $id');
        break;
      default:
        // Navigate to notifications screen
        print('Navigate to notifications');
        break;
    }
  }

  // Create a notification
  Future<void> createNotification({
    required String title,
    required String body,
    Map<String, String>? payload,
    String channelKey = 'basic_channel',
    int? id,
  }) async {
    if (!_isInitialized) return;

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: channelKey,
          title: title,
          body: body,
          payload: payload,
        ),
      );
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Request notification permissions
  Future<bool> requestNotificationPermission() async {
    try {
      return await AwesomeNotifications().requestPermissionToSendNotifications();
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      return await AwesomeNotifications().isNotificationAllowed();
    } catch (e) {
      print('Error checking notification permission: $e');
      return false;
    }
  }
}