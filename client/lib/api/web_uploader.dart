import 'dart:math';

import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/dto/file_upload_record.dart';
import 'package:nas2cloud/api/dto/file_upload_status_enum.dart';
import 'package:nas2cloud/utils/spu.dart';

class _WebUploader {
  static const String _uploadKey = "app.fileupload.";

  Future<bool> addToUpload(
      {required String dest,
      required int size,
      required String name,
      Stream<List<int>>? readStream}) async {
    if (readStream == null || size <= 0 || dest == "/" || dest.isEmpty) {
      return false;
    }
    var id = "$dest/$name";
    var key = "$_uploadKey$id";
    var stateValue = spu.getString(key);
    if (stateValue != null) {
      var r = FileUploadRecord.fromJson(stateValue);
      if (FileUploadStatus.isAny(
          r.status, [FileUploadStatus.uploading, FileUploadStatus.success])) {
        return false;
      }
    }

    var record = FileUploadRecord(
        id: id,
        fileName: name,
        filePath: name,
        size: size,
        uploadTime: DateTime.now().millisecondsSinceEpoch,
        fileLastModTime: DateTime.now().millisecondsSinceEpoch,
        dest: dest,
        status: FileUploadStatus.uploading.name,
        progress: 0,
        message: FileUploadStatus.uploading.name);

    if (!await spu.setString(key, record.toJson())) {
      return false;
    }
    api
        .webUpload(
            dest: dest, stream: readStream, contentLength: size, fileName: name)
        .then((value) {
      if (value.success) {
        _callback(key, true, "OK");
      } else {
        _callback(key, false, value.message ?? "ERROR");
      }
    }).onError(((error, stackTrace) {
      print(e);
      _callback(key, false, error.toString());
    }));
    return true;
  }

  _callback(String uploadKey, bool success, String message) async {
    var record = FileUploadRecord.fromJson(spu.getString(uploadKey)!);
    record.status =
        success ? FileUploadStatus.success.name : FileUploadStatus.error.name;
    record.message = message;
    await spu.setString(uploadKey, record.toJson());
  }
}

var webUploader = _WebUploader();
