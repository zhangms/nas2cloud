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
  Future<void> cancelAllRunning() async {
    await FlutterUploader().cancelAll();
    await FlutterUploader().clearUploads();
    await UploadRepository.platform.deleteByStatus(UploadStatus.waiting.name);
    await UploadRepository.platform.deleteByStatus(UploadStatus.uploading.name);
    FileUploader.notifyListeners(null);
  }

  @override
  Future<void> clearTask(UploadStatus status) async {
    await FlutterUploader().clearUploads();
    await UploadRepository.platform.deleteByStatus(status.name);
    FileUploader.notifyListeners(null);
  }

  void _syncTaskState() async {
    var uploader = FlutterUploader();
    await for (var progress in uploader.progress) {
      await _handleUploadTaskStatus(
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
  uploader.result.listen(_flutterUploaderTaskResponse);
  uploader.progress.listen(_flutterUploaderTaskProgress);
}

void _flutterUploaderTaskProgress(UploadTaskProgress progress) async {
  await _handleUploadTaskStatus(
    taskId: progress.taskId,
    status: progress.status,
    progress: progress.progress,
  );
}

void _flutterUploaderTaskResponse(UploadTaskResponse result) async {
  await _handleUploadTaskStatus(
    taskId: result.taskId,
    status: result.status,
    message: result.response,
  );
}

Future<void> _handleUploadTaskStatus(
    {required String taskId,
    UploadTaskStatus? status,
    int? progress,
    String? message}) async {
  var statusName = status?.description ?? "NONE";
  var entry = await UploadRepository.platform.findByTaskId(taskId);
  if (entry == null) {
    return;
  }
  var entryStatus = UploadStatus.valueOf(entry.status);
  if (entryStatus == null) {
    return;
  }
  switch (statusName) {
    case "Enqueued":
    case "Paused":
      await _handleWaiting(entry, entryStatus, statusName);
      return;
    case "Running":
      await _handleRunning(entry, entryStatus, statusName, progress);
      return;
    case "Completed":
      await _handleComplete(entry, entryStatus, statusName, message);
      return;
    case "Failed":
    case "Cancelled":
      await _handleFailed(entry, entryStatus, statusName, message);
      return;
  }
}

Future<void> _handleFailed(UploadEntry entry, UploadStatus entryStatus,
    String statusName, String? message) async {
  if (entryStatus.groupIndex >= UploadStatus.failed.groupIndex) {
    return;
  }
  var result = entry.copyWith(
    status: UploadStatus.failed.name,
    endUploadTime: DateTime.now().millisecondsSinceEpoch,
    message: "$statusName:$message",
  );
  await UploadRepository.platform.update(result);
  FileUploader.notifyListeners(result);
  LocalNotification.platform.send(
      id: entry.id ?? 0, title: p.basename(entry.src), body: "上传失败：$message");
}

Future<void> _handleComplete(UploadEntry entry, UploadStatus entryStatus,
    String statusName, String? message) async {
  LocalNotification.platform.clear(id: entry.id ?? 0);
  if (entryStatus.groupIndex >= UploadStatus.successed.groupIndex) {
    return;
  }
  var result = entry.copyWith(
    status: UploadStatus.successed.name,
    endUploadTime: DateTime.now().millisecondsSinceEpoch,
    message: "$statusName:$message",
  );
  await UploadRepository.platform.update(result);
  FileUploader.notifyListeners(result);
}

Future<void> _handleRunning(UploadEntry entry, UploadStatus entryStatus,
    String statusName, int? progress) async {
  if (progress != null) {
    if (progress < 100) {
      LocalNotification.platform.progress(
          id: entry.id ?? 0,
          title: p.basename(entry.src),
          body: "",
          progress: progress);
    } else {
      LocalNotification.platform.clear(id: entry.id ?? 0);
    }
  }
  if (entryStatus.groupIndex >= UploadStatus.uploading.groupIndex) {
    return;
  }
  var result = entry.copyWith(
    status: UploadStatus.uploading.name,
    beginUploadTime: DateTime.now().millisecondsSinceEpoch,
    message: "$statusName:$progress",
  );
  await UploadRepository.platform.update(result);
  return;
}

Future<void> _handleWaiting(
    UploadEntry entry, UploadStatus entryStatus, String statusName) async {
  LocalNotification.platform.clear(id: entry.id ?? 0);
  if (entryStatus.groupIndex >= UploadStatus.waiting.groupIndex) {
    return;
  }
  var result = entry.copyWith(
    status: UploadStatus.waiting.name,
    message: statusName,
  );
  await UploadRepository.platform.update(result);
}
