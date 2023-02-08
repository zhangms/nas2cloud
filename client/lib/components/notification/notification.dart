import 'package:flutter/foundation.dart';

import 'notification_flutter.dart';
import 'notification_unsupport.dart';

abstract class LocalNotification {
  static LocalNotification _instance = _platform();

  static LocalNotification get platform => _instance;

  static LocalNotification _platform() {
    if (kIsWeb) {
      return UnsupportNotification();
    } else {
      return NotificationFlutter();
    }
  }

  LocalNotification();

  Future<void> initialize();

  Future<void> send(
      {required int id, required String title, required String body});

  Future<void> progress(
      {required int id,
      required String title,
      required String body,
      required int progress});

  Future<void> clear({required int id});
}
