import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class PushNotificationPermissionHandler {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Singleton pattern
  static final PushNotificationPermissionHandler _instance =
  PushNotificationPermissionHandler._internal();

  factory PushNotificationPermissionHandler() {
    return _instance;
  }

  PushNotificationPermissionHandler._internal();

  /// Initialize notifications plugins
  Future<void> initialize() async {
    // Setup Flutter Local Notifications
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Set up Firebase Messaging handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Request permissions for push notifications
  Future<bool> requestPermissions() async {
    bool permissionGranted = false;

    if (Platform.isIOS) {
      // iOS-specific permission request
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      permissionGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      // Request iOS local notification permissions
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      // Android-specific permission request
      // For Android 13+ (API level 33+), we need to request the notification permission
      if (await _isAndroid13OrHigher()) {
        permissionGranted = await Permission.notification.request().isGranted;
      } else {
        // For lower Android versions, permissions are granted by default
        permissionGranted = true;
      }
    }

    // If permissions granted, get the FCM token
    if (permissionGranted) {
      await getToken();
    }

    return permissionGranted;
  }

  /// Check if device is running Android 13 or higher
  Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      return await Permission.notification.request().isGranted;
    }
    return false;
  }

  /// Get the FCM token for this device
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Check if notifications are permitted
  Future<bool> areNotificationsPermitted() async {
    if (Platform.isIOS) {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } else if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        return await Permission.notification.isGranted;
      } else {
        return true; // Pre-Android 13 default permission
      }
    }
    return false;
  }

  /// Open app settings to allow the user to enable permissions manually
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    // You can customize this method to show a local notification
    // when a message is received while the app is in the foreground
    if (message.notification != null) {
      _showLocalNotification(
        id: message.hashCode,
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Show a local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'push_notification_channel',
      'Push Notifications',
      channelDescription: 'Channel for push notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
