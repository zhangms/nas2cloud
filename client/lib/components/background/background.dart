import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/components/uploader/auto_uploader.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundProcessor {
  static const String autoUploadTaskName = "autoupload";

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      print("Native called background task: $task");
      switch (task) {
        case autoUploadTaskName:
          return await AutoUploader().executeAutoupload();
        default:
          return true;
      }
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
      autoUploadTaskName,
      initialDelay: Duration(seconds: 10),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      inputData: {"hello": "world"},
    );
  }
}
