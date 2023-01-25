import 'dart:io';

import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:nas2cloud/api/api.dart';
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
  Future<bool> uploadPath({required String src, required String dest}) async {
    var url = "/api/store/upload/$dest";
    if (dest.startsWith("/")) {
      url = "/api/store/upload$dest";
    }
    var file = File(src);
    var lastModified = await file.lastModified();
    final taskId = await FlutterUploader().enqueue(
      MultipartFormDataUpload(
        url: Api.getApiUrl(url),
        files: [FileItem(path: src, field: "file")],
        method: UploadMethod.POST,
        headers: Api.httpHeaders(),
        data: {"lastModified": "${lastModified.millisecondsSinceEpoch}"},
      ),
    );
    print(taskId);
    return true;
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
