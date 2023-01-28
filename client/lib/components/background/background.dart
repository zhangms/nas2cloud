import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundProcessor {
  @pragma('vm:entry-point')
  static void _callbackDispatcher() {
    Workmanager().executeTask((task, inputData) {
      print("Native called background task: $task");
      return Future.value(true);
    });
  }

  static bool _inited = false;

  static void init() {
    if (kIsWeb) {
      return;
    }
    if (_inited) {
      return;
    }
    _inited = true;
    Workmanager().initialize(_callbackDispatcher, isInDebugMode: isInDebugMode);
  }

  static void registerAutoUploadTask() {
    Workmanager().registerPeriodicTask(
      "periodic-autoupload-task",
      "autoupload",
      frequency: Duration(minutes: 5),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }
}
