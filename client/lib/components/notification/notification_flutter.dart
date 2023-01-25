import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nas2cloud/components/notification/notification.dart';

class NotificationFlutter extends LocalNotification {
  static final FlutterLocalNotificationsPlugin _notifier =
      FlutterLocalNotificationsPlugin();

  static bool _inited = false;

  @override
  Future<bool> init() async {
    if (_inited) {
      return true;
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
    return true;
  }

  static void receiveNotificationResponse(NotificationResponse response) {}

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {}

  @override
  void send({required int id, required String title, required String body}) {
    var androidDetail = AndroidNotificationDetails(
      "com.zms.nas2cloud",
      "Nas2cloud",
      importance: Importance.max,
      priority: Priority.high,
    );
    var darwin = DarwinNotificationDetails();
    var detail =
        NotificationDetails(android: androidDetail, iOS: darwin, macOS: darwin);
    _notifier.show(id, title, body, detail);
  }

  @override
  void progress(
      {required int id,
      required String title,
      required String body,
      required int progress}) {
    var androidDetail = AndroidNotificationDetails(
      "com.zms.nas2cloud",
      "Nas2cloud",
      importance: Importance.max,
      priority: Priority.high,
      showProgress: true,
      progress: progress,
      maxProgress: 100,
    );
    var darwin = DarwinNotificationDetails();
    var detail =
        NotificationDetails(android: androidDetail, iOS: darwin, macOS: darwin);
    _notifier.show(id, title, body, detail);
  }

  @override
  void clear({required int id}) {
    _notifier.cancel(id);
  }
}
