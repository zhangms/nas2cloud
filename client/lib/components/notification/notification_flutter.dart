import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../api/app_config.dart';
import 'notification.dart';

class NotificationFlutter extends LocalNotification {
  static final FlutterLocalNotificationsPlugin _notifier =
      FlutterLocalNotificationsPlugin();

  static bool _inited = false;

  @override
  Future<void> initialize() async {
    if (_inited) {
      return;
    }
    _inited = true;
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings("@mipmap/ic_launcher");

    const DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
      macOS: darwinInitializationSettings,
    );
    await _notifier.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: receiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    print("FlutterLocalNotificationsPlugin init complete");
  }

  static void receiveNotificationResponse(NotificationResponse response) {}

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {}

  @override
  Future<void> send(
      {required int id, required String title, required String body}) async {
    var androidDetail = AndroidNotificationDetails(
      AppConfig.appId,
      await AppConfig.getAppName(),
      importance: Importance.max,
      priority: Priority.high,
    );
    var darwin = DarwinNotificationDetails();
    var detail =
        NotificationDetails(android: androidDetail, iOS: darwin, macOS: darwin);
    await _notifier.show(id, title, body, detail);
  }

  @override
  Future<void> progress(
      {required int id,
      required String title,
      required String body,
      required int progress}) async {
    Future.sync(() => AppConfig.getAppName());

    var androidDetail = AndroidNotificationDetails(
      AppConfig.appId,
      await AppConfig.getAppName(),
      importance: Importance.max,
      priority: Priority.high,
      showProgress: true,
      progress: progress,
      maxProgress: 100,
    );
    var darwin = DarwinNotificationDetails();
    var detail =
        NotificationDetails(android: androidDetail, iOS: darwin, macOS: darwin);
    await _notifier.show(id, title, body, detail);
  }

  @override
  Future<void> clear({required int id}) async {
    await _notifier.cancel(id);
  }
}
