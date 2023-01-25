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

String _uploadKey(String taskId) {
  return "$_uploadKeyPrefix$taskId";
}

Future<int> _uploadCounter() async {
  var key = _uploadKey("_id_counter_");
  var count = spu.getInt(key) ?? 0;
  count++;
  await spu.setInt(key, count);
  return count;
}

void flutterUploaderBackgroudHandler() {
  WidgetsFlutterBinding.ensureInitialized();
  // Needed so that plugin communication works.
  // This uploader instance works within the isolate only.
  FlutterUploader uploader = FlutterUploader();

  // You have now access to:
  uploader.progress.listen((UploadTaskProgress progress) {
    print("upload progress : $progress");
    if (!spu.isComplete()) {
      return;
    }
    var content = spu.getString(_uploadKey(progress.taskId));
    if (content == null) {
      return;
    }
    var record = FileUploadRecord.fromJson(content);
    LocalNotification.get().progress(
        id: int.parse(record.id),
        title: record.fileName,
        body: "上传中：${progress.progress}%",
        progress: progress.progress ?? 0);
  });

  uploader.result.listen((UploadTaskResponse result) {
    print("upload result : $result");
    if (!spu.isComplete()) {
      return;
    }
    var content = spu.getString(_uploadKey(result.taskId));
    if (content == null) {
      return;
    }
    var record = FileUploadRecord.fromJson(content);
    spu.remove(_uploadKey(result.taskId));
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
      LocalNotification.get().send(
        id: int.parse(record.id),
        title: record.fileName,
        body: "上传失败：$errMsg",
      );
    } else if (result.status!.description == "Completed") {
      LocalNotification.get().send(
        id: int.parse(record.id),
        title: record.fileName,
        body: "上传完成",
      );
    }
  });
}

class PathUploader extends FileUploader {
  static bool _inited = false;
  @override
  Future<bool> init() {
    if (!_inited) {
      _inited = true;
      flutterUploaderBackgroudHandler();
      FlutterUploader().setBackgroundHandler(flutterUploaderBackgroudHandler);
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
    var file = File(src);
    var fileName = p.basename(src);
    var counter = await _uploadCounter();
    Result exists = await Api.getFileExists(Api.paths(dest, fileName));
    if (!exists.success) {
      LocalNotification.get().send(
        id: counter,
        title: fileName,
        body: "上传错误：${exists.message}",
      );
      return false;
    }
    if (exists.message == "true") {
      LocalNotification.get().send(
        id: counter,
        title: fileName,
        body: "文件已存在",
      );
      return false;
    }

    var lastModified = await file.lastModified();
    final taskId = await FlutterUploader().enqueue(
      MultipartFormDataUpload(
        url: Api.getApiUrl(Api.paths("/api/store/upload", dest)),
        files: [FileItem(path: src, field: "file")],
        method: UploadMethod.POST,
        headers: Api.httpHeaders(),
        data: {"lastModified": "${lastModified.millisecondsSinceEpoch}"},
        tag: fileName,
      ),
    );
    var record = FileUploadRecord(
        id: "$counter",
        fileName: fileName,
        filePath: src,
        size: -1,
        beginUploadTime: DateTime.now().millisecondsSinceEpoch,
        endUploadTime: -1,
        fileLastModTime: DateTime.now().millisecondsSinceEpoch,
        dest: dest,
        status: FileUploadStatus.uploading.name,
        progress: 0,
        message: FileUploadStatus.uploading.name);
    await spu.setString(_uploadKey(taskId), record.toJson());
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
