import 'dart:async';
import 'dart:io';

import 'package:nas2cloud/components/background/background.dart';
import 'package:nas2cloud/components/uploader/auto_upload_config.dart';
import 'package:nas2cloud/components/uploader/file_uploder.dart';
import 'package:nas2cloud/components/uploader/upload_repo.dart';
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
    var start = DateTime.now();
    await _syncToUpload(config);
    print(
        "saveToUploadComplete:${config.path}, escape: ${DateTime.now().difference(start).inMilliseconds}");
    await loopExecuteUpload(config.uploadChannel);
    return true;
  }

  Future<void> _syncToUpload(AutoUploadConfig config) async {
    var directory = Directory(config.path);
    await for (final file in directory
        .list(recursive: true, followLinks: true)
        .map((file) => file.path)
        .where((file) => !FileHelper.isHidden(file))
        .where((file) => !FileSystemEntity.isDirectorySync(file))) {
      await FileUploader.saveToUpload(
        channel: config.uploadChannel,
        filepath: file,
        relativeFrom: config.basepath,
        remote: config.remote!,
      );
    }
  }

  Future<void> loopExecuteUpload(String group) async {
    while (true) {
      var entry = await UploadRepo.platform.findFirstWaitingUploadEntry(group);
      if (entry == null) {
        break;
      }
      // var copy = entry.copyWith(
      //     status: UploadStatus.uploading.name,
      //     message: "uploading",
      //     beginUploadTime: DateTime.now().millisecondsSinceEpoch);
      // UploadRepo.platform.update(copy);
      break;
    }
  }
}
