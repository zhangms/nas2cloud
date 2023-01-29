import 'dart:async';
import 'dart:io';

import 'package:nas2cloud/components/background/background.dart';
import 'package:nas2cloud/components/uploader/auto_upload_config.dart';
import 'package:nas2cloud/utils/file_helper.dart';
import 'package:nas2cloud/utils/spu.dart';

class AutoUploader {
  static const String key = "app.autoupload.config";

  static AutoUploader _instance = AutoUploader._private();

  factory AutoUploader() => _instance;

  AutoUploader._private();

  void initialize() {
    BackgroundProcessor().registerAutoUploadTask();
  }

  Future<bool> saveConfig(AutoUploadConfig config) async {
    List<String> ret = [];
    List<String> configs = spu.getStringList(key) ?? [];

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
    return await spu.setStringList(key, ret);
  }

  Future<List<AutoUploadConfig>> getConfigList() {
    return Stream<String>.fromIterable(spu.getStringList(key) ?? [])
        .map((event) => AutoUploadConfig.fromJson(event))
        .toList();
  }

  Future<bool> executeAutoupload() async {
    List<AutoUploadConfig> configs = await getConfigList();
    for (var config in configs) {
      if (config.autoupload) {
        await _executeAutoupload(config);
      }
    }
    return true;
  }

  Future<bool> _executeAutoupload(AutoUploadConfig config) async {
    var directory = Directory(config.path);

    var start = DateTime.now();

    await directory
        .list(recursive: true)
        .map((file) => file.path)
        .where((path) => !FileHelper.isHidden(path))
        .forEach((element) {
      print(element);
    });

    print(
        "${DateTime.now().millisecondsSinceEpoch - start.millisecondsSinceEpoch}");

    return true;
  }
}
