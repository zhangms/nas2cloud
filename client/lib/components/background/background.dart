import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/components/uploader/auto_uploader.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundProcessor {
  static const String AUTO_UPLOAD_TASK = "autoupload";

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) {
      print("Native called background task: $task");
      if (task == AUTO_UPLOAD_TASK) {
        AutoUploader.executeAutouploadSync();
      }
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
    Workmanager().initialize(callbackDispatcher, isInDebugMode: isInDebugMode);
    print("background processor init complete");
  }

  static void registerAutoUploadTask() {
    Workmanager().registerPeriodicTask(
      "${AppConfig.appId}.periodic-autoupload-task",
      AUTO_UPLOAD_TASK,
      initialDelay: Duration(seconds: 10),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }
}
