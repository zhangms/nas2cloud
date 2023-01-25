import 'package:flutter/foundation.dart';
import 'package:nas2cloud/components/notification/notification_flutter.dart';
import 'package:nas2cloud/components/notification/notification_unsupport.dart';

abstract class LocalNotification {
  static late LocalNotification _instance;

  factory LocalNotification.get() {
    if (kIsWeb) {
      _instance = UnsupportNotification();
    } else {
      _instance = NotificationFlutter();
    }
    return _instance;
  }

  LocalNotification();

  Future<bool> init();

  void send({required int id, required String title, required String body});

  void progress(
      {required int id,
      required String title,
      required String body,
      required int progress});

  void clear({required int id});
}
