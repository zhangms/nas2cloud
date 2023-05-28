import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../../api/app_config.dart';
import '../uploader/auto_uploader.dart';

const String autoUploadTaskName = "autoupload";

@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print("Native called background task: $task");
      switch (task) {
        case autoUploadTaskName:
          var enqueuedCount = await AutoUploader().executeAutoUpload();
          return enqueuedCount >= 0;
        default:
          return true;
      }
    } catch (e) {
      print(e);
      return false;
    }
  });
}

class BackgroundProcessor {
  static BackgroundProcessor _instance = BackgroundProcessor._private();

  factory BackgroundProcessor() => _instance;

  BackgroundProcessor._private();

  bool _inited = false;

  bool isNotSupport() {
    return kIsWeb;
  }

  Future<void> initialize() async {
    if (isNotSupport()) {
      return;
    }
    if (_inited) {
      return;
    }
    _inited = true;
    await Workmanager()
        .initialize(backgroundCallbackDispatcher, isInDebugMode: kDebugMode);
    print("background processor init complete");
  }

  Future<void> registerAutoUploadTask() async {
    if (isNotSupport()) {
      return;
    }
    await Workmanager().registerPeriodicTask(
      "${AppConfig.appId}.periodic-autoupload-task",
      autoUploadTaskName,
      initialDelay: Duration(seconds: 10),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      inputData: {"type": "periodic"},
      tag: autoUploadTaskName,
    );
    print("auto upload task registed");
  }

  Future<void> executeOnceAutoUploadTask() async {
    if (isNotSupport()) {
      return;
    }
    var n = DateTime.now();
    await Workmanager().registerOneOffTask(
      "${AppConfig.appId}.once-autoupload-task",
      autoUploadTaskName,
      initialDelay: Duration(seconds: 10),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      inputData: {"type": "once"},
      tag: autoUploadTaskName,
    );
    print("once auto upload task registed: $n");
  }
}
