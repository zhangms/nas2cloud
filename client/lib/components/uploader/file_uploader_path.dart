import 'package:nas2cloud/components/uploader/file_uploder.dart';
import 'package:nas2cloud/components/uploader/upload_entry.dart';

class PathUploader extends FileUploader {
  @override
  Future<bool> enqueue(UploadEntry entry) {
    // TODO: implement enqueue
    throw UnimplementedError();
  }

  @override
  Future<bool> initialize() async {
    return true;
  }

  @override
  Future<bool> uploadEntryStream(
      {required UploadEntry entry, required Stream<List<int>> stream}) {
    // TODO: implement uploadEntryStream
    throw UnimplementedError();
  }

  @override
  Future<bool> uploadPath({required String src, required String dest}) {
    // TODO: implement uploadPath
    throw UnimplementedError();
  }

  @override
  Future<bool> uploadStream(
      {required String dest,
      required String fileName,
      required int fileSize,
      required Stream<List<int>> stream}) {
    // TODO: implement uploadStream
    throw UnimplementedError();
  }
}

// class PathUploader extends FileUploader {
//   static bool _initialized = false;

//   @override
//   Future<bool> initialize() async {
//     if (!_initialized) {
//       _initialized = true;
//       // flutterUploaderBackgroudHandler();
//       // FlutterUploader().setBackgroundHandler(flutterUploaderBackgroudHandler);
//       print("FlutterUploader init complete");
//     }
//     return _initialized;
//   }

//   @override
//   Future<bool> uploadPath({required String src, required String dest}) {
//     throw UnimplementedError();
//   }

//   @override
//   Future<bool> enqueue(UploadEntry entry) async {
//     FlutterUploader().clearUploads();
//     var savedEntry = await UploadRepository.platform.saveIfNotExists(entry);
//     if (!UploadStatus.match(savedEntry.status, UploadStatus.waiting)) {
//       return false;
//     }
//     var fileName = p.basename(savedEntry.src);
//     Result checkResult =
//         await Api.getFileExists(Api.joinPath(savedEntry.dest, fileName));
//     if (!checkResult.success) {
//       UploadRepository.platform.update(savedEntry.copyWith(
//         status: UploadStatus.failed.name,
//         message: "ERROR:${checkResult.message}",
//         beginUploadTime: DateTime.now().millisecondsSinceEpoch,
//         endUploadTime: DateTime.now().millisecondsSinceEpoch,
//       ));
//       return false;
//     }
//     if (checkResult.message == "true") {
//       UploadRepository.platform.update(savedEntry.copyWith(
//         status: UploadStatus.successed.name,
//         message: "remoteExists",
//         beginUploadTime: DateTime.now().millisecondsSinceEpoch,
//         endUploadTime: DateTime.now().millisecondsSinceEpoch,
//       ));
//       return false;
//     }
//     var url =
//         await Api.getApiUrl(Api.joinPath("/api/store/upload", savedEntry.dest));
//     var headers = await Api.httpHeaders();
//     var taskId = await FlutterUploader().enqueue(
//       MultipartFormDataUpload(
//         url: url,
//         files: [FileItem(path: savedEntry.src, field: "file")],
//         method: UploadMethod.POST,
//         headers: headers,
//         data: {"lastModified": "${savedEntry.lastModified}"},
//         tag: fileName,
//       ),
//     );
//     UploadRepository.platform.update(savedEntry.copyWith(
//       status: UploadStatus.uploading.name,
//       message: "remoteExists",
//       beginUploadTime: DateTime.now().millisecondsSinceEpoch,
//       endUploadTime: 0,
//       uploadTaskId: taskId,
//     ));
//     return true;
//   }

//   @override
//   Future<bool> uploadEntryStream(
//       {required UploadEntry entry, required Stream<List<int>> stream}) {
//     throw UnimplementedError("use uploadPath");
//   }

//   @override
//   Future<bool> uploadStream(
//       {required String dest,
//       required String fileName,
//       required int fileSize,
//       required Stream<List<int>> stream}) {
//     throw UnsupportedError("use uploadPath");
//   }
// }

// @pragma('vm:entry-point')
// void flutterUploaderBackgroudHandler() {
//   WidgetsFlutterBinding.ensureInitialized();
//   FlutterUploader uploader = FlutterUploader();
//   uploader.clearUploads();
//   uploader.result.listen(flutterUploaderTaskResponse);
//   uploader.progress.listen(flutterUploaderTaskProgress);
// }

// void flutterUploaderTaskProgress(UploadTaskProgress progress) {
//   var process = progress.progress ?? 0;
//   if (process > 0 &&
//       process < 100 &&
//       progress.status.description == "Running") {
//     UploadRepository.platform.findByTaskId(progress.taskId).then((value) {
//       if (value != null) {
//         LocalNotification.platform.progress(
//             id: value.id ?? 0,
//             title: p.basename(value.src),
//             body: "",
//             progress: process);
//       }
//     });
//   }
// }

// void flutterUploaderTaskResponse(UploadTaskResponse result) {
//   print("upload result : $result");
//   if (result.status != null) {
//     return;
//   }
//   final String? message = result.response;
//   final String statusName = result.status!.description;
//   if (statusName == "Completed" || statusName == "Failed") {
//     UploadRepository.platform.findByTaskId(result.taskId).then((value) {
//       if (value == null) {
//         return;
//       }
//       switch (statusName) {
//         case "Completed":
//           UploadRepository.platform.update(value.copyWith(
//             status: UploadStatus.successed.name,
//             endUploadTime: DateTime.now().millisecondsSinceEpoch,
//             message: message,
//           ));
//           LocalNotification.platform.clear(id: value.id ?? 0);
//           break;
//         case "Failed":
//           UploadRepository.platform.update(value.copyWith(
//             status: UploadStatus.failed.name,
//             endUploadTime: DateTime.now().millisecondsSinceEpoch,
//             message: message,
//           ));
//           LocalNotification.platform.send(
//               id: value.id ?? 0,
//               title: p.basename(value.src),
//               body: "上传失败：$message");
//           break;
//         default:
//           break;
//       }
//     });
//   }
// }
