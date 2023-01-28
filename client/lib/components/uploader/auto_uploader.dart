import 'dart:async';

import 'package:nas2cloud/components/background/background.dart';
import 'package:nas2cloud/components/uploader/auto_upload_config.dart';
import 'package:nas2cloud/utils/spu.dart';

class AutoUploader {
  static const String key = "app.autoupload.config";

  static void init() {
    BackgroundProcessor.registerAutoUploadTask();
    executeAutouploadAsync();
  }

  static Future<bool> saveConfig(AutoUploadConfig config) async {
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

  static Future<List<AutoUploadConfig>> getConfigList() {
    return Stream<String>.fromIterable(spu.getStringList(key) ?? [])
        .map((event) => AutoUploadConfig.fromJson(event))
        .toList();
  }

  static void executeAutouploadSync() {
    print("execute autoupload");
  }

  static void executeAutouploadAsync() {
    Future.delayed(Duration(seconds: 10), executeAutouploadSync);
  }
}
