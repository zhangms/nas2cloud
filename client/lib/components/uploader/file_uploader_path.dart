import 'package:flutter/cupertino.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/components/notification/notification.dart';
import 'package:nas2cloud/components/uploader/file_uploder.dart';
import 'package:nas2cloud/components/uploader/upload_entry.dart';
import 'package:nas2cloud/components/uploader/upload_repo.dart';
import 'package:nas2cloud/components/uploader/upload_status.dart';
import 'package:path/path.dart' as p;

class PathUploader extends FileUploader {
  static bool _initialized = false;

  @override
  Future<bool> initialize() async {
    if (!_initialized) {
      _initialized = true;
      flutterUploaderProcessHandler();
      FlutterUploader().setBackgroundHandler(flutterUploaderProcessHandler);
      print("FlutterUploader init complete");
    }
    return _initialized;
  }

  @override
  Future<bool> uploadPath({required String src, required String dest}) async {
    var entry = FileUploader.createEntryByFilepath(
        channel: "upload",
        filepath: src,
        relativeFrom: p.dirname(src),
        remote: dest);
    return await enqueue(entry);
  }

  @override
  Future<bool> enqueue(UploadEntry entry) async {
    _syncTaskState();
    var savedEntry = await beforeUploadCheck(entry);
    if (savedEntry == null) {
      return false;
    }
    var url = await Api()
        .getApiUrl(Api().joinPath("/api/store/upload", savedEntry.dest));
    var headers = await Api().httpHeaders();
    var taskId = await FlutterUploader().enqueue(
      MultipartFormDataUpload(
        url: url,
        files: [FileItem(path: savedEntry.src, field: "file")],
        method: UploadMethod.POST,
        headers: headers,
        data: {"lastModified": "${savedEntry.lastModified}"},
        tag: p.basename(savedEntry.src),
      ),
    );
    UploadRepository.platform.update(savedEntry.copyWith(
      status: UploadStatus.waiting.name,
      message: "enqueued",
      beginUploadTime: 0,
      endUploadTime: 0,
      uploadTaskId: taskId,
    ));
    return true;
  }

  @override
  Future<bool> uploadStream(
      {required String dest,
      required String fileName,
      required int fileSize,
      required Stream<List<int>> stream}) {
    throw UnsupportedError("use uploadPath");
  }

  @override
  Future<void> cancelAndClearAll() async {
    await FlutterUploader().cancelAll();
    await FlutterUploader().clearUploads();
    await UploadRepository.platform.clearAll();
  }

  @override
  Future<void> clearTask(UploadStatus status) async {
    await FlutterUploader().clearUploads();
    await UploadRepository.platform.deleteByStatus(status.name);
  }

  void _syncTaskState() async {
    var uploader = FlutterUploader();
    await for (var progress in uploader.progress) {
      handleUploadTaskStatus(
          taskId: progress.taskId,
          status: progress.status,
          progress: progress.progress);
    }
    await uploader.clearUploads();
  }
}

@pragma('vm:entry-point')
void flutterUploaderProcessHandler() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterUploader uploader = FlutterUploader();
  uploader.clearUploads();
  uploader.result.listen(flutterUploaderTaskResponse);
  uploader.progress.listen(flutterUploaderTaskProgress);
}

void flutterUploaderTaskProgress(UploadTaskProgress progress) async {
  await handleUploadTaskStatus(
      taskId: progress.taskId,
      status: progress.status,
      progress: progress.progress);
}

void flutterUploaderTaskResponse(UploadTaskResponse result) async {
  await handleUploadTaskStatus(taskId: result.taskId, status: result.status);
}

Future<void> handleUploadTaskStatus({
  required String taskId,
  UploadTaskStatus? status,
  int? progress,
  String? message,
}) async {
  var entry = await UploadRepository.platform.findByTaskId(taskId);
  if (entry == null) {
    return;
  }
  var statusName = status?.description ?? "NONE";
  switch (statusName) {
    case "Enqueued":
    case "Paused":
      LocalNotification.platform.clear(id: entry.id ?? 0);
      if (UploadStatus.match(entry.status, UploadStatus.waiting)) {
        return;
      }
      var result = entry.copyWith(
        status: UploadStatus.waiting.name,
        message: "$statusName:$message",
      );
      await UploadRepository.platform.update(result);
      break;
    case "Running":
      if (progress != null) {
        LocalNotification.platform.progress(
            id: entry.id ?? 0,
            title: p.basename(entry.src),
            body: "",
            progress: progress);
      }
      if (UploadStatus.match(entry.status, UploadStatus.uploading)) {
        return;
      }
      var result = entry.copyWith(
        status: UploadStatus.uploading.name,
        message: "$statusName:$message,$progress",
      );
      await UploadRepository.platform.update(result);
      break;
    case "Completed":
      LocalNotification.platform.clear(id: entry.id ?? 0);
      if (UploadStatus.match(entry.status, UploadStatus.successed)) {
        return;
      }
      var result = entry.copyWith(
        status: UploadStatus.successed.name,
        endUploadTime: DateTime.now().millisecondsSinceEpoch,
        message: "$statusName:$message,$progress",
      );
      await UploadRepository.platform.update(result);
      FileUploader.notifyListeners(result);
      break;
    case "Failed":
    case "Cancelled":
      if (UploadStatus.match(entry.status, UploadStatus.failed)) {
        return;
      }
      var result = entry.copyWith(
        status: UploadStatus.failed.name,
        endUploadTime: DateTime.now().millisecondsSinceEpoch,
        message: "$statusName:$message,$progress",
      );
      await UploadRepository.platform.update(result);
      FileUploader.notifyListeners(result);
      LocalNotification.platform.send(
          id: entry.id ?? 0,
          title: p.basename(entry.src),
          body: "上传失败：$message");
      break;
  }
}
