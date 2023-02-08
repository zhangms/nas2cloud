import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../api/api.dart';
import '../../api/dto/result.dart';
import '../../event/bus.dart';
import 'event_fileupload.dart';
import 'file_uploader_path.dart';
import 'file_uploader_web.dart';
import 'upload_entry.dart';
import 'upload_repo.dart';
import 'upload_status.dart';

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

  Future<void> cancelAllRunning();

  static void fireEvent(UploadEntry? entry) {
    eventBus.fire(EventFileUpload(entry));
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
