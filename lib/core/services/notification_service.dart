import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notification service for design updates
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> init() async {
    if (_isInitialized) return;

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to design detail
    // This can be enhanced with deep linking
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    final iOS = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iOS != null) {
      final granted = await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    
    return true; // Android auto-grants
  }

  /// Show design completed notification
  Future<void> showDesignCompleted({
    required String styleName,
    required String designId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'design_channel',
      'Design Updates',
      channelDescription: 'Notifications for design completion',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      designId.hashCode,
      '✨ Design Complete!',
      'Your $styleName transformation is ready to view.',
      details,
      payload: designId,
    );
  }

  /// Show design processing notification
  Future<void> showDesignProcessing({required String styleName}) async {
    const androidDetails = AndroidNotificationDetails(
      'design_channel',
      'Design Updates',
      channelDescription: 'Notifications for design progress',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/ic_launcher',
      ongoing: true,
      showProgress: true,
      maxProgress: 100,
      indeterminate: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: true,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'Creating your design...',
      'Transforming to $styleName style',
      details,
    );
  }

  /// Cancel processing notification
  Future<void> cancelProcessingNotification() async {
    await _notifications.cancel(0);
  }

  /// Show welcome bonus notification
  Future<void> showWelcomeBonus() async {
    const androidDetails = AndroidNotificationDetails(
      'promo_channel',
      'Promotions',
      channelDescription: 'Promotional notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      '🎁 Welcome Gift!',
      "You've received 2 free tokens to start designing!",
      details,
    );
  }

  /// Show design failed notification
  Future<void> showDesignFailed({required String designId}) async {
    const androidDetails = AndroidNotificationDetails(
      'design_channel',
      'Design Updates',
      channelDescription: 'Notifications for design updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      designId.hashCode,
      '⚠️ Design Issue',
      'Something went wrong. Tap to retry.',
      details,
      payload: designId,
    );
  }

  /// Schedule a reminder notification
  Future<void> scheduleReminder({
    required Duration delay,
    required String title,
    required String body,
  }) async {
    // For scheduled notifications, we'd use zonedSchedule
    // Simplified version using Future.delayed for demo
    Future.delayed(delay, () {
      _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Reminder notifications',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
      );
    });
  }
}

