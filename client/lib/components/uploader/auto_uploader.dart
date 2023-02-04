import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/components/background/background.dart';
import 'package:nas2cloud/components/uploader/auto_upload_config.dart';
import 'package:nas2cloud/components/uploader/file_uploder.dart';
import 'package:nas2cloud/utils/file_helper.dart';
import 'package:nas2cloud/utils/spu.dart';
import 'package:permission_handler/permission_handler.dart';

class AutoUploader {
  static const String _key = "app.autoupload.config";

  static AutoUploader _instance = AutoUploader._private();

  factory AutoUploader() => _instance;

  AutoUploader._private();

  Future<void> initialize() async {
    await BackgroundProcessor().registerAutoUploadTask();
  }

  Future<String?> _getKey() async {
    var userName = await AppConfig.getLoginUserName();
    if (userName == null) {
      return null;
    }
    return "$_key.$userName";
  }

  Future<bool> saveConfig(AutoUploadConfig config) async {
    var key = await _getKey();
    if (key == null) {
      return false;
    }
    List<String> ret = [];
    List<String> configs = await Spu().getStringList(key) ?? [];
    bool configExists = false;
    for (var c in configs) {
      var cfg = AutoUploadConfig.fromJson(c);
      if (cfg.path == config.path) {
        ret.add(config.toJson());
        configExists = true;
      } else {
        ret.add(c);
      }
    }
    if (!configExists) {
      ret.add(config.toJson());
    }
    return await Spu().setStringList(key, ret);
  }

  Future<List<AutoUploadConfig>> getConfigList() async {
    var key = await _getKey();
    if (key == null) {
      return [];
    }
    var list = (await Spu().getStringList(key)) ?? [];
    return Stream<String>.fromIterable(list)
        .map((event) => AutoUploadConfig.fromJson(event))
        .toList();
  }

  Future<void> clearConfig() async {
    var key = await _getKey();
    if (key == null) {
      return;
    }
    await Spu().remove(key);
  }

  Future<int> executeAutoupload() async {
    if (kIsWeb) {
      return -1;
    }
    var autouploadWlan = await AppConfig.getAutouploadWlanSetting();
    if (autouploadWlan) {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.wifi) {
        print("auto upload skip because not wifi");
        return -1;
      }
    }
    if (!await Permission.manageExternalStorage.isGranted) {
      print("auto upload skip because manageExternalStorage is not granted");
      return -1;
    }
    List<AutoUploadConfig> configs = await getConfigList();
    var enqueuedCount = 0;
    for (var config in configs) {
      if (config.autoupload) {
        enqueuedCount += (await _executeAutoupload(config));
      }
    }
    return enqueuedCount;
  }

  Future<int> _executeAutoupload(AutoUploadConfig config) async {
    var start = DateTime.now();
    var directory = Directory(config.path);
    var enqueuedCount = 0;
    await for (final file in directory
        .list(recursive: true, followLinks: true)
        .map((file) => file.path)
        .where((file) => !FileHelper.isHidden(file))
        .where((file) => !FileSystemEntity.isDirectorySync(file))) {
      var entry = FileUploader.createEntryByFilepath(
        channel: config.uploadChannel,
        filepath: file,
        relativeFrom: config.basepath,
        remote: config.remote!,
      );
      var begin = DateTime.now();
      var enqueued = await FileUploader.platform.enqueue(entry);
      var timeEscape = DateTime.now().difference(begin).inMilliseconds;
      if (enqueued) {
        enqueuedCount++;
        var log =
            "enqueue auto upload : ${entry.src}, ${entry.dest}, $enqueuedCount, $timeEscape(ms)";
        print(log);
        await Api().postTraceLog(log);
      }
    }
    var log =
        "enqueueUploadComplete:${config.path}, escape: ${DateTime.now().difference(start).inMilliseconds}";
    print(log);
    await Api().postTraceLog(log);
    return enqueuedCount;
  }
}
