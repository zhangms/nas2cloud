import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/dto/file_upload_record.dart';
import 'package:nas2cloud/api/dto/file_upload_status_enum.dart';
import 'package:nas2cloud/api/dto/result.dart';
import 'package:nas2cloud/components/notification/notification.dart';
import 'package:nas2cloud/components/uploader/file_uploder.dart';
import 'package:nas2cloud/utils/spu.dart';
import 'package:path/path.dart' as p;

const String _uploadKeyPrefix = "app.upload.task";
const String _uploadCounterKey = "app.upload._task_counter_";

String _uploadKey(String taskId) {
  return "$_uploadKeyPrefix$taskId";
}

Future<int> _uploadCounter() async {
  var count = spu.getInt(_uploadCounterKey) ?? 0;
  count++;
  await spu.setInt(_uploadCounterKey, count);
  return count;
}

@pragma('vm:entry-point')
void _flutterUploaderBackgroudHandler() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterUploader uploader = FlutterUploader();
  uploader.progress.listen(_onUploadTaskProgress);
  uploader.result.listen(_onUploadTaskResponse);
}

void _onUploadTaskResponse(UploadTaskResponse result) {
  print("upload result : $result");
  var record = _getUploadRecord(result.taskId);
  if (record == null || record.endUploadTime > 0) {
    return;
  }
  if (result.status == null) {
    LocalNotification.get().clear(id: int.parse(record.id));
    return;
  }
  if (result.status!.description == "Failed") {
    String errMsg = "ERROR";
    if (result.response != null) {
      var ret = Result.fromJson(result.response!);
      errMsg = ret.message ?? "ERROR";
    }
    record.message = errMsg;
    record.endUploadTime = DateTime.now().millisecondsSinceEpoch;
    record.status = FileUploadStatus.failed.name;
    spu.setString(_uploadKey(result.taskId), record.toJson());
    FileUploader.get().notifyListeners(record);
    LocalNotification.get().send(
        id: int.parse(record.id), title: record.fileName, body: "上传失败：$errMsg");
    return;
  }
  if (result.status!.description == "Completed") {
    record.message = "Completed";
    record.endUploadTime = DateTime.now().millisecondsSinceEpoch;
    record.status = FileUploadStatus.success.name;
    spu.setString(_uploadKey(result.taskId), record.toJson());
    FileUploader.get().notifyListeners(record);
    LocalNotification.get()
        .send(id: int.parse(record.id), title: record.fileName, body: "上传完成");
    return;
  }
}

void _onUploadTaskProgress(UploadTaskProgress progress) {
  print("upload progress : $progress");
  var record = _getUploadRecord(progress.taskId);
  if (record == null || record.endUploadTime > 0) {
    return;
  }
  record.progress = progress.progress ?? 0;
  spu.setString(_uploadKey(progress.taskId), record.toJson());
  LocalNotification.get().progress(
      id: int.parse(record.id),
      title: record.fileName,
      body: "上传中：${progress.progress}%",
      progress: progress.progress ?? 0);
}

FileUploadRecord? _getUploadRecord(String taskId) {
  if (!spu.isComplete()) {
    return null;
  }
  var content = spu.getString(_uploadKey(taskId));
  if (content == null) {
    return null;
  }
  return FileUploadRecord.fromJson(content);
}

class PathUploader extends FileUploader {
  static bool _inited = false;
  @override
  Future<bool> init() {
    if (!_inited) {
      _inited = true;
      _flutterUploaderBackgroudHandler();
      FlutterUploader().setBackgroundHandler(_flutterUploaderBackgroudHandler);
      print("FlutterUploader init complete");
    }
    return Future.value(_inited);
  }

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
    FlutterUploader().clearUploads();
    var fileName = p.basename(src);
    var counter = await _uploadCounter();
    if (!await _checkAndNotifyUploadAble(dest, fileName, counter)) {
      return false;
    }
    var file = File(src);
    var taskId = await _enqueue(file, dest);
    var record = await saveUploadRecord(file, dest, taskId, counter);
    notifyListeners(record);
    return true;
  }

  Future<bool> _checkAndNotifyUploadAble(
      String dest, String fileName, int counter) async {
    Result exists = await Api.getFileExists(Api.paths(dest, fileName));
    if (!exists.success) {
      LocalNotification.get()
          .send(id: counter, title: fileName, body: "上传错误：${exists.message}");
      return false;
    }
    if (exists.message == "true") {
      LocalNotification.get().send(id: counter, title: fileName, body: "文件已存在");
      return false;
    }
    return true;
  }

  Future<String> _enqueue(File src, String dest) async {
    var fileName = p.basename(src.path);
    var lastModified = await src.lastModified();
    return await FlutterUploader().enqueue(
      MultipartFormDataUpload(
        url: Api.getApiUrl(Api.paths("/api/store/upload", dest)),
        files: [FileItem(path: src.path, field: "file")],
        method: UploadMethod.POST,
        headers: Api.httpHeaders(),
        data: {"lastModified": "${lastModified.millisecondsSinceEpoch}"},
        tag: fileName,
      ),
    );
  }

  Future<FileUploadRecord> saveUploadRecord(
      File src, String dest, String taskId, int counter) async {
    var stat = await src.stat();
    var fileName = p.basename(src.path);
    var record = FileUploadRecord(
        id: "$counter",
        fileName: fileName,
        filePath: src.path,
        size: stat.size,
        beginUploadTime: DateTime.now().millisecondsSinceEpoch,
        endUploadTime: -1,
        fileLastModTime: DateTime.now().millisecondsSinceEpoch,
        dest: dest,
        status: FileUploadStatus.uploading.name,
        progress: 0,
        message: FileUploadStatus.uploading.name);
    await spu.setString(_uploadKey(taskId), record.toJson());
    return record;
  }

  @override
  void clearRecordByState(List<FileUploadStatus> filters) {
    FlutterUploader().clearUploads();
    var records = _getUploadRecords();
    for (var record in records) {
      if (FileUploadStatus.isAny(record.status, filters)) {
        spu.remove(record.id);
      }
    }
  }

  List<FileUploadRecord>? _records;

  @override
  int getCount() {
    _records = _getUploadRecords();
    return _records!.length;
  }

  @override
  FileUploadRecord? getRecord(int index) {
    if (_records == null || _records!.length < index) {
      return null;
    }
    return _records![index];
  }

  List<FileUploadRecord> _getUploadRecords() {
    List<FileUploadRecord> list = [];
    var keys = spu.getKeys();
    for (var key in keys) {
      if (!key.startsWith(_uploadKeyPrefix)) {
        continue;
      }
      String? str = spu.getString(key);
      if (str == null) {
        continue;
      }
      var record = FileUploadRecord.fromJson(str);
      if (record.endUploadTime > 0 &&
          DateTime.now().millisecondsSinceEpoch - record.endUploadTime >
              Duration(minutes: 10).inMilliseconds) {
        spu.remove(key);
        continue;
      }
      record.id = key;
      list.add(record);
    }
    list.sort(((a, b) {
      return a.beginUploadTime > b.beginUploadTime ? 0 : 1;
    }));
    return list;
  }
}
