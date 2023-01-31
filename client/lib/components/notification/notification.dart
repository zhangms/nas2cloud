import 'package:flutter/foundation.dart';
import 'package:nas2cloud/components/notification/notification_flutter.dart';
import 'package:nas2cloud/components/notification/notification_unsupport.dart';

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

  void initialize();

  void send({required int id, required String title, required String body});

  void progress(
      {required int id,
      required String title,
      required String body,
      required int progress});

  void clear({required int id});
}
