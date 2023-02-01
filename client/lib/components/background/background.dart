import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/api.dart';
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
          return await AutoUploader().executeAutoupload();
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
        .initialize(backgroundCallbackDispatcher, isInDebugMode: isInDebugMode);
    print("background processor init complete");
  }

  Future<void> registerAutoUploadTask() async {
    await Workmanager().registerPeriodicTask(
      "${AppConfig.appId}.periodic-autoupload-task",
      autoUploadTaskName,
      initialDelay: Duration(seconds: 10),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      inputData: {"hello": "world"},
      tag: autoUploadTaskName,
    );
    print("auto upload task registed");
  }
}