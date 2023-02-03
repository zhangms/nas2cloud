import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/dto/result.dart';
import 'package:nas2cloud/components/uploader/file_uploader_path.dart';
import 'package:nas2cloud/components/uploader/file_uploader_web.dart';
import 'package:nas2cloud/components/uploader/upload_entry.dart';
import 'package:nas2cloud/components/uploader/upload_repo.dart';
import 'package:nas2cloud/components/uploader/upload_status.dart';
import 'package:path/path.dart' as p;

abstract class FileUploader {
  static FileUploader _instance = FileUploader._platform();

  static FileUploader get platform => _instance;

  static FileUploader _platform() {
    if (kIsWeb) {
      return WebUploader();
    } else {
      return PathUploader();
    }
  }

  FileUploader();

  Future<void> initialize();

  Future<bool> uploadStream({
    required String dest,
    required String fileName,
    required int fileSize,
    required Stream<List<int>> stream,
  });

  Future<bool> uploadPath({required String src, required String dest});

  Future<bool> enqueue(UploadEntry entry);

  static UploadEntry createEntryByFilepath({
    required String channel,
    required String filepath,
    required String relativeFrom,
    required String remote,
  }) {
    var file = File(filepath);
    var dest = p.normalize(
        p.join(remote, p.relative(file.parent.path, from: relativeFrom)));
    var stat = file.statSync();
    return UploadEntry(
        channel: channel,
        src: file.path,
        dest: dest,
        size: stat.size,
        lastModified: stat.modified.millisecondsSinceEpoch,
        createTime: DateTime.now().millisecondsSinceEpoch,
        beginUploadTime: 0,
        endUploadTime: 0,
        uploadTaskId: "none",
        status: UploadStatus.waiting.name,
        message: UploadStatus.waiting.name);
  }

  Future<void> cancelAndClearAll();

  static List<Function(UploadEntry? entry)> _listeners = [];

  static void removeListener(Function(UploadEntry? entry) listener) {
    _listeners.remove(listener);
    print("uploader remove listener : ${_listeners.length}");
  }

  static void addListener(Function(UploadEntry? entry) listener) {
    _listeners.add(listener);
    print("uploader add listener : ${_listeners.length}");
  }

  static void notifyListeners(UploadEntry? entry) {
    for (var listener in _listeners) {
      listener(entry);
    }
  }

  Future<void> clearTask(UploadStatus status);

  @protected
  Future<UploadEntry?> beforeUploadCheck(UploadEntry entry) async {
    var savedEntry = await UploadRepository.platform.saveIfNotExists(entry);
    if (savedEntry.uploadTaskId != "none") {
      return null;
    }
    Result checkResult = await Api().getFileExists(
      Api().joinPath(savedEntry.dest, p.basename(savedEntry.src)),
    );
    if (!checkResult.success) {
      UploadRepository.platform.update(savedEntry.copyWith(
        uploadTaskId: "${savedEntry.src}:${savedEntry.dest}",
        status: UploadStatus.failed.name,
        message: "ERROR:${checkResult.message}",
        beginUploadTime: DateTime.now().millisecondsSinceEpoch,
        endUploadTime: DateTime.now().millisecondsSinceEpoch,
      ));
      return null;
    }
    if (checkResult.message == "true") {
      UploadRepository.platform.update(savedEntry.copyWith(
        uploadTaskId: "${savedEntry.src}:${savedEntry.dest}",
        status: UploadStatus.successed.name,
        message: "remoteExists",
        beginUploadTime: DateTime.now().millisecondsSinceEpoch,
        endUploadTime: DateTime.now().millisecondsSinceEpoch,
      ));
      return null;
    }
    return savedEntry;
  }
}
