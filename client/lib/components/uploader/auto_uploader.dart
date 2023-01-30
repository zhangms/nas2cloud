import 'dart:async';
import 'dart:io';

import 'package:nas2cloud/components/background/background.dart';
import 'package:nas2cloud/components/uploader/auto_upload_config.dart';
import 'package:nas2cloud/components/uploader/upload_entry.dart';
import 'package:nas2cloud/components/uploader/upload_repo.dart';
import 'package:nas2cloud/components/uploader/upload_status.dart';
import 'package:nas2cloud/utils/file_helper.dart';
import 'package:nas2cloud/utils/spu.dart';
import 'package:path/path.dart' as p;

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
    await for (final file in directory
        .list(recursive: true, followLinks: true)
        .where((file) => !FileHelper.isHidden(file.path))
        .where((file) => !FileSystemEntity.isDirectorySync(file.path))) {
      await saveToUpload(
          file: file,
          relativeFrom: config.basepath,
          remote: config.remote!,
          group: config.group);
    }
    print(
        "saveToUpload:${config.path}, escape: ${DateTime.now().difference(start).inMilliseconds}");
    return true;
  }

  Future<void> saveToUpload(
      {required FileSystemEntity file,
      required String group,
      required String relativeFrom,
      required String remote}) async {
    var parent = file.parent.path;
    var dest = p.join(remote, p.relative(parent, from: relativeFrom));
    var stat = file.statSync();
    var entry = UploadEntry(
        uploadGroupId: group,
        src: file.path,
        dest: dest,
        size: stat.size,
        lastModified: stat.modified.millisecondsSinceEpoch,
        createTime: DateTime.now().millisecondsSinceEpoch,
        beginUploadTime: 0,
        endUploadTime: 9,
        status: UploadStatus.waiting.name,
        message: UploadStatus.waiting.name);
    int count = await UploadRepo.platform.saveIfNotExists(entry);
    print("saveToUpload ${file.path}, $count");
  }
}
