import 'package:flutter/material.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:nas2cloud/components/uploader/file_uploder.dart';
import 'package:nas2cloud/components/uploader/upload_entry.dart';

class PathUploader extends FileUploader {
  static bool _initialized = false;

  @override
  Future<bool> initialize() async {
    if (!_initialized) {
      _initialized = true;
      FlutterUploader().setBackgroundHandler(flutterUploaderBackgroudHandler);
      print("FlutterUploader init complete");
    }
    return _initialized;
  }

  @override
  Future<bool> uploadPath({required String src, required String dest}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> uploadEntry({required UploadEntry entry}) async {
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
}

// class PathUploader extends FileUploader {
//   static bool _inited = false;
//   @override
//   Future<bool> init() {
//     if (!_inited) {
//       _inited = true;
//       flutterUploaderBackgroudHandler();
//       FlutterUploader().setBackgroundHandler(flutterUploaderBackgroudHandler);
//       print("FlutterUploader init complete");
//     }
//     return Future.value(_inited);
//   }

//   @override
//   Future<bool> uploadStream(
//       {required String dest,
//       required String fileName,
//       required int size,
//       required Stream<List<int>> stream}) {
//     throw UnsupportedError("error");
//   }

//   @override
//   Future<bool> uploadPath({required String src, required String dest}) async {
//     FlutterUploader().clearUploads();
//     var fileName = p.basename(src);
//     var counter = await _uploadCounter();
//     if (!await _checkAndNotifyUploadAble(dest, fileName, counter)) {
//       return false;
//     }
//     var file = File(src);
//     var taskId = await _enqueue(file, dest);
//     var record = await saveUploadRecord(file, dest, taskId, counter);
//     notifyListeners(record);
//     return true;
//   }

//   Future<bool> _checkAndNotifyUploadAble(
//       String dest, String fileName, int counter) async {
//     Result exists = await Api.getFileExists(Api.paths(dest, fileName));
//     if (!exists.success) {
//       LocalNotification.get()
//           .send(id: counter, title: fileName, body: "上传错误：${exists.message}");
//       return false;
//     }
//     if (exists.message == "true") {
//       LocalNotification.get().send(id: counter, title: fileName, body: "文件已存在");
//       return false;
//     }
//     return true;
//   }

//   Future<String> _enqueue(File src, String dest) async {
//     var fileName = p.basename(src.path);
//     var lastModified = await src.lastModified();
//     return await FlutterUploader().enqueue(
//       MultipartFormDataUpload(
//         url: Api.getApiUrl(Api.paths("/api/store/upload", dest)),
//         files: [FileItem(path: src.path, field: "file")],
//         method: UploadMethod.POST,
//         headers: Api.httpHeaders(),
//         data: {"lastModified": "${lastModified.millisecondsSinceEpoch}"},
//         tag: fileName,
//       ),
//     );
//   }

//   Future<FileUploadRecord> saveUploadRecord(
//       File src, String dest, String taskId, int counter) async {
//     var stat = await src.stat();
//     var fileName = p.basename(src.path);
//     var record = FileUploadRecord(
//         id: "$counter",
//         fileName: fileName,
//         filePath: src.path,
//         size: stat.size,
//         beginUploadTime: DateTime.now().millisecondsSinceEpoch,
//         endUploadTime: -1,
//         fileLastModTime: DateTime.now().millisecondsSinceEpoch,
//         dest: dest,
//         status: FileUploadStatus.uploading.name,
//         progress: 0,
//         message: FileUploadStatus.uploading.name);
//     await spu.setString(_uploadKey(taskId), record.toJson());
//     return record;
//   }

//   @override
//   void clearRecordByState(List<FileUploadStatus> filters) {
//     FlutterUploader().clearUploads();
//     var records = _getUploadRecords();
//     for (var record in records) {
//       if (FileUploadStatus.isAny(record.status, filters)) {
//         spu.remove(record.id);
//       }
//     }
//   }
//   List<FileUploadRecord>? _records;
// }

@pragma('vm:entry-point')
void flutterUploaderBackgroudHandler() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterUploader uploader = FlutterUploader();
  uploader.result.listen(flutterUploaderTaskResponse);
  uploader.progress.listen(flutterUploaderTaskProgress);
}

void flutterUploaderTaskResponse(UploadTaskResponse result) {
  print("upload result : $result");
}

void flutterUploaderTaskProgress(UploadTaskProgress progress) {
  print("upload progress : $progress");
}
