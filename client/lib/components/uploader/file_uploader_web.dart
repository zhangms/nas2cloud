import '../../api/api.dart';
import '../../api/dto/result.dart';
import 'file_uploader.dart';
import 'upload_entry.dart';
import 'upload_repo.dart';
import 'upload_status.dart';

class WebUploader extends FileUploader {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> uploadPath({required String src, required String dest}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> enqueue(UploadEntry entry) {
    throw UnimplementedError();
  }

  @override
  Future<bool> uploadStream(
      {required String dest,
      required String fileName,
      required int fileSize,
      required Stream<List<int>> stream}) async {
    var entry = UploadEntry(
        channel: "upload",
        src: fileName,
        dest: dest,
        size: fileSize,
        lastModified: DateTime.now().millisecondsSinceEpoch,
        createTime: DateTime.now().millisecondsSinceEpoch,
        beginUploadTime: 0,
        endUploadTime: 0,
        uploadTaskId: "none",
        status: UploadStatus.waiting.name,
        message: UploadStatus.waiting.name);

    var savedEntry = await beforeUploadCheck(entry);
    if (savedEntry == null) {
      return false;
    }
    var taskId = "${entry.src}:${entry.dest}";
    if (savedEntry.size / 1024 / 1024 >= 500) {
      var ret = savedEntry.copyWith(
        uploadTaskId: taskId,
        status: UploadStatus.failed.name,
        message: "文件大小不能超过500MB",
      );
      UploadRepository.platform.update(ret);
      return false;
    }
    savedEntry = savedEntry.copyWith(
      status: UploadStatus.uploading.name,
      uploadTaskId: taskId,
      message: "uploading",
    );
    await UploadRepository.platform.update(savedEntry);
    Api()
        .uploadStream(
          dest: savedEntry.dest,
          fileName: savedEntry.src,
          fileLastModified: savedEntry.lastModified,
          size: savedEntry.size,
          stream: stream,
        )
        .then((value) => onUploadResponse(savedEntry!, value))
        .onError((error, stackTrace) =>
            onUploadError(savedEntry!, error, stackTrace));
    return true;
  }

  onUploadResponse(UploadEntry entry, Result value) async {
    var result = entry.copyWith(
      status: value.success
          ? UploadStatus.successed.name
          : UploadStatus.failed.name,
      message: value.message,
    );
    await UploadRepository.platform.update(result);
    FileUploader.fireEvent(result);
  }

  onUploadError(UploadEntry entry, Object? error, StackTrace stackTrace) async {
    var result = entry.copyWith(
      status: UploadStatus.failed.name,
      message: "ERROR:$error",
    );
    await UploadRepository.platform.update(result);
    FileUploader.fireEvent(result);
  }

  @override
  Future<void> cancelAllRunning() async {
    await UploadRepository.platform.clearAll();
    FileUploader.fireEvent(null);
  }

  @override
  Future<void> clearTask(UploadStatus status) async {
    await UploadRepository.platform.deleteByStatus(status.name);
    FileUploader.fireEvent(null);
  }
}
