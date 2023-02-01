import 'package:flutter/cupertino.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/dto/result.dart';
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
    var entry = FileUploader.toUploadEntry(
        channel: "uploadPath",
        filepath: src,
        relativeFrom: p.dirname(src),
        remote: dest);
    return await enqueue(entry);
  }

  @override
  Future<bool> enqueue(UploadEntry entry) async {
    _syncTaskState();

    var savedEntry = await UploadRepository.platform.saveIfNotExists(entry);
    if (savedEntry.uploadTaskId != "none") {
      return false;
    }
    var fileName = p.basename(savedEntry.src);
    Result checkResult =
        await Api().getFileExists(Api().joinPath(savedEntry.dest, fileName));
    if (!checkResult.success) {
      UploadRepository.platform.update(savedEntry.copyWith(
        status: UploadStatus.failed.name,
        message: "ERROR:${checkResult.message}",
        beginUploadTime: DateTime.now().millisecondsSinceEpoch,
        endUploadTime: DateTime.now().millisecondsSinceEpoch,
      ));
      return false;
    }
    if (checkResult.message == "true") {
      UploadRepository.platform.update(savedEntry.copyWith(
        status: UploadStatus.successed.name,
        message: "remoteExists",
        beginUploadTime: DateTime.now().millisecondsSinceEpoch,
        endUploadTime: DateTime.now().millisecondsSinceEpoch,
      ));
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
        tag: fileName,
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
  Future<bool> uploadEntryStream(
      {required UploadEntry entry, required Stream<List<int>> stream}) {
    throw UnimplementedError("use uploadPath");
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
      var result = entry.copyWith(
        status: UploadStatus.waiting.name,
        message: "$statusName:$message",
      );
      await UploadRepository.platform.update(result);
      LocalNotification.platform.clear(id: entry.id ?? 0);
      break;
    case "Running":
      var result = entry.copyWith(
        status: UploadStatus.uploading.name,
        message: "$statusName:$message,$progress",
      );
      await UploadRepository.platform.update(result);
      if (progress != null) {
        LocalNotification.platform.progress(
            id: entry.id ?? 0,
            title: p.basename(entry.src),
            body: "",
            progress: progress);
      }
      break;
    case "Completed":
      var result = entry.copyWith(
        status: UploadStatus.successed.name,
        endUploadTime: DateTime.now().millisecondsSinceEpoch,
        message: "$statusName:$message,$progress",
      );
      await UploadRepository.platform.update(result);
      FileUploader.notifyListeners(result);
      LocalNotification.platform.clear(id: entry.id ?? 0);
      break;
    case "Failed":
    case "Cancelled":
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
