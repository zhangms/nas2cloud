import 'dart:async';

import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/dto/file_upload_record.dart';
import 'package:nas2cloud/api/dto/file_upload_status_enum.dart';
import 'package:nas2cloud/api/uploader/file_uploder.dart';
import 'package:nas2cloud/utils/spu.dart';

const String _keyPrefix = "app.fileupload.";

class WebUploader extends FileUploader {
  @override
  Future<bool> fireStreamUploadEvent(
      {required String dest,
      required String fileName,
      required int size,
      required Stream<List<int>> stream}) async {
    if (size <= 0 || dest == "/" || dest.isEmpty) {
      return false;
    }
    var record = FileUploadRecord(
        id: "$dest/$fileName",
        fileName: fileName,
        filePath: fileName,
        size: size,
        beginUploadTime: DateTime.now().millisecondsSinceEpoch,
        endUploadTime: -1,
        fileLastModTime: DateTime.now().millisecondsSinceEpoch,
        dest: dest,
        status: FileUploadStatus.uploading.name,
        progress: 0,
        message: FileUploadStatus.uploading.name);

    var uploadKey = "$_keyPrefix${record.id}";
    if (spu.containsKey(uploadKey)) {
      return true;
    }
    _clearRecordCache();
    if (!await spu.setString(uploadKey, record.toJson())) {
      return false;
    }
    if (record.size / 1024 / 1024 >= 500) {
      await _chgState(record, FileUploadStatus.reject, "文件大小不能超过500MB");
      return false;
    }
    api
        .uploadStream(
            dest: record.dest,
            fileName: record.fileName,
            fileLastModified: record.fileLastModTime,
            size: record.size,
            stream: stream)
        .then((value) {
      if (value.success) {
        _chgState(record, FileUploadStatus.success, "OK");
      } else {
        _chgState(record, FileUploadStatus.error, value.message ?? "ERROR");
      }
    }).onError(((error, stackTrace) {
      _chgState(record, FileUploadStatus.error, error.toString());
    }));
    return true;
  }

  Future<bool> _chgState(
      FileUploadRecord record, FileUploadStatus status, String message) async {
    record.status = status.name;
    record.message = message;
    switch (status) {
      case FileUploadStatus.error:
      case FileUploadStatus.reject:
      case FileUploadStatus.success:
        record.endUploadTime = DateTime.now().millisecondsSinceEpoch;
        break;
      default:
        break;
    }
    var uploadKey = "$_keyPrefix${record.id}";
    bool ret = await spu.setString(uploadKey, record.toJson());
    _clearRecordCache();
    super.notifyListeners(record);
    return ret;
  }

  List<FileUploadRecord>? records;

  void _clearRecordCache() {
    records = null;
  }

  List<FileUploadRecord> _loadRecordCache() {
    if (records != null) {
      return records!;
    }
    List<FileUploadRecord> list = [];
    var keys = spu.getKeys();
    for (var key in keys) {
      if (!key.startsWith(_keyPrefix)) {
        continue;
      }
      String? str = spu.getString(key);
      if (str == null) {
        continue;
      }
      var record = FileUploadRecord.fromJson(str);
      if (DateTime.now().millisecondsSinceEpoch - record.beginUploadTime >
          Duration(days: 1).inMilliseconds) {
        spu.remove(key);
        continue;
      }
      list.add(record);
    }
    list.sort(((a, b) {
      return a.beginUploadTime > b.beginUploadTime ? 0 : 1;
    }));
    records = list;
    return records!;
  }

  @override
  int getCount() {
    var list = _loadRecordCache();
    return list.length;
  }

  @override
  FileUploadRecord? getRecord(int index) {
    var list = _loadRecordCache();
    if (list.length > index) {
      return list[index];
    }
    return null;
  }

  @override
  void clearRecordByState(List<FileUploadStatus> filters) {
    var records = _loadRecordCache();
    for (var record in records) {
      if (filters.isEmpty || FileUploadStatus.isAny(record.status, filters)) {
        var uploadKey = "$_keyPrefix${record.id}";
        spu.remove(uploadKey);
      }
    }
    _clearRecordCache();
  }
}
