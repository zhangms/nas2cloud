import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../api/api.dart';
import '../../api/app_config.dart';
import '../../utils/file_helper.dart';
import '../../utils/spu.dart';
import '../background/background.dart';
import 'auto_upload_config.dart';
import 'file_uploader.dart';
import 'upload_entry.dart';
import 'upload_repo.dart';

class AutoUploader {
  static const String _configKey = "app.autoupload.config";
  static const _wlanConfigKey = "app.autoupload.wlan";

  static AutoUploader _instance = AutoUploader._private();

  factory AutoUploader() => _instance;

  AutoUploader._private();

  Future<void> initialize() async {
    await BackgroundProcessor().registerAutoUploadTask();
  }

  static Future<String?> _wrapConfigKey(String key) async {
    var userName = await AppConfig.getLoginUserName();
    if (userName == null) {
      return null;
    }
    return "$key.$userName";
  }

  Future<bool> saveConfig(AutoUploadConfig config) async {
    var key = await _wrapConfigKey(_configKey);
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

  Future<void> clearConfig() async {
    var key = await _wrapConfigKey(_configKey);
    if (key == null) {
      return;
    }
    await Spu().remove(key);
  }

  Future<List<AutoUploadConfig>> getConfigList() async {
    var key = await _wrapConfigKey(_configKey);
    if (key == null) {
      return [];
    }
    var list = (await Spu().getStringList(key)) ?? [];
    return Stream<String>.fromIterable(list)
        .map((event) => AutoUploadConfig.fromJson(event))
        .toList();
  }

  static Future<bool> getAutouploadWlanSetting() async {
    var key = await _wrapConfigKey(_wlanConfigKey);
    if (key == null) {
      return true;
    }
    return (await Spu().getBool(_wlanConfigKey)) ?? true;
  }

  static Future<bool> setAutouploadWlanSetting(bool wlan) async {
    var key = await _wrapConfigKey(_wlanConfigKey);
    if (key == null) {
      return false;
    }
    return (await Spu().setBool(key, wlan));
  }

  Future<int> executeAutoupload() async {
    if (kIsWeb) {
      return -1;
    }
    var autouploadWlan = await getAutouploadWlanSetting();
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
    DateTime start = DateTime.now();
    List<UploadEntry> waiting = await _getWillUploadEntries(config);
    var escape = DateTime.now().difference(start).inMilliseconds;
    await Api().postTraceLog(
        "willUpload:${config.path}, length:${waiting.length},escape: $escape");

    var enqueued = await _enqueue(waiting);
    escape = DateTime.now().difference(start).inMilliseconds;
    await Api().postTraceLog(
        "enqueueUploadComplete:${config.path},enqueued:$enqueued,escape: $escape");

    return enqueued;
  }

  Future<List<UploadEntry>> _getWillUploadEntries(
      AutoUploadConfig config) async {
    var directory = Directory(config.path);
    List<UploadEntry> waiting = [];
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
      var saved = await UploadRepository.platform.saveIfNotExists(entry);
      if (saved.uploadTaskId == "none") {
        waiting.add(saved);
        if (waiting.length >= 2048) {
          break;
        }
      }
    }
    return waiting;
  }

  Future<int> _enqueue(List<UploadEntry> waiting) async {
    int enqueued = 0;
    for (var entry in waiting) {
      if (await FileUploader.platform.enqueue(entry)) {
        enqueued++;
      }
    }
    return enqueued;
  }
}
