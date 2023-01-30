import 'dart:io';

import 'package:flutter/foundation.dart';
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

  Future<bool> initialize();

  Future<bool> uploadStream({
    required String dest,
    required String fileName,
    required int fileSize,
    required Stream<List<int>> stream,
  });

  Future<bool> uploadEntryStream(
      {required UploadEntry entry, required Stream<List<int>> stream});

  Future<bool> uploadPath({required String src, required String dest});

  Future<bool> uploadEntry({required UploadEntry entry});

  static Future<UploadEntry> saveToUpload({
    required String channel,
    required String filepath,
    required String relativeFrom,
    required String remote,
  }) async {
    var file = File(filepath);
    var dest = p.normalize(
        p.join(remote, p.relative(file.parent.path, from: relativeFrom)));
    var stat = file.statSync();
    var entry = UploadEntry(
        channel: channel,
        src: file.path,
        dest: dest,
        size: stat.size,
        lastModified: stat.modified.millisecondsSinceEpoch,
        createTime: DateTime.now().millisecondsSinceEpoch,
        beginUploadTime: 0,
        endUploadTime: 9,
        uploadTaskId: "none",
        status: UploadStatus.waiting.name,
        message: UploadStatus.waiting.name);
    return await UploadRepo.platform.saveIfNotExists(entry);
  }
}
