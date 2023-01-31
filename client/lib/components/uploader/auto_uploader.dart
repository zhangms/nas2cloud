import 'dart:async';
import 'dart:io';

import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/components/background/background.dart';
import 'package:nas2cloud/components/uploader/auto_upload_config.dart';
import 'package:nas2cloud/components/uploader/file_uploder.dart';
import 'package:nas2cloud/utils/file_helper.dart';
import 'package:nas2cloud/utils/spu.dart';

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

  Future<bool> executeAutoupload() async {
    if (await AppConfig.isUserLogged()) {
      List<AutoUploadConfig> configs = await getConfigList();
      for (var config in configs) {
        if (config.autoupload) {
          await _executeAutoupload(config);
        }
      }
      return true;
    }
    return false;
  }

  Future<bool> _executeAutoupload(AutoUploadConfig config) async {
    var start = DateTime.now();

    var directory = Directory(config.path);
    await for (final file in directory
        .list(recursive: true, followLinks: true)
        .map((file) => file.path)
        .where((file) => !FileHelper.isHidden(file))
        .where((file) => !FileSystemEntity.isDirectorySync(file))) {
      var entry = FileUploader.toUploadEntry(
        channel: config.uploadChannel,
        filepath: file,
        relativeFrom: config.basepath,
        remote: config.remote!,
      );
      var enqueued = await FileUploader.platform.enqueue(entry);
      if (enqueued) {
        print("enqueue auto upload : ${entry.src}, ${entry.dest}");
      }
    }
    print(
        "enqueueUploadComplete:${config.path}, escape: ${DateTime.now().difference(start).inMilliseconds}");
    return true;
  }
}
