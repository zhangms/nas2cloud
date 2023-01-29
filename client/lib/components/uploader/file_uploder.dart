import 'package:flutter/foundation.dart';
import 'package:nas2cloud/components/uploader/file_uploader_path.dart';
import 'package:nas2cloud/components/uploader/file_uploader_web.dart';

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

  Future<bool> uploadStream(
      {required String dest,
      required String fileName,
      required int size,
      required Stream<List<int>> stream});

  Future<bool> uploadPath({required String src, required String dest});
}
