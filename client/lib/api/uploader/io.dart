import 'dart:io';

import 'package:nas2cloud/api/dto/file_upload_record.dart';
import 'package:nas2cloud/api/dto/file_upload_status_enum.dart';
import 'package:nas2cloud/api/uploader/file_uploder.dart';

class IOUploader extends FileUploader {
  @override
  Future<bool> uploadStream(
      {required String dest,
      required String fileName,
      required int size,
      required Stream<List<int>> stream}) {
    throw UnsupportedError("error");
  }

  @override
  Future<bool> uploadPath({required String src, required String dest}) {
    var file = File(src);
    print(file.lastModifiedSync());
    print(file.path);
    return Future.value(false);
  }

  @override
  void clearRecordByState(List<FileUploadStatus> filters) {}

  @override
  int getCount() {
    return 0;
  }

  @override
  FileUploadRecord? getRecord(int index) {
    return null;
  }
}
