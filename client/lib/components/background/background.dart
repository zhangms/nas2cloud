import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/components/uploader/auto_uploader.dart';
import 'package:workmanager/workmanager.dart';

const String autoUploadTaskName = "autoupload";

@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print("Native called background task: $task");
      switch (task) {
        case autoUploadTaskName:
          var enqueuedCount = await AutoUploader().executeAutoupload();
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

  Future<void> initialize() async {
    if (kIsWeb) {
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
    var n = DateTime.now();
    var key = "${n.year}-${n.month}-${n.day} ${n.hour}:${n.minute}";
    await Workmanager().registerOneOffTask(
      "${AppConfig.appId}_upload_$key",
      autoUploadTaskName,
      initialDelay: Duration(seconds: 10),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      inputData: {"type": "once:$key"},
      tag: autoUploadTaskName,
    );
    print("once auto upload task registed");
  }
}
