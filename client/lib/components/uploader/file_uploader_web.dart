import 'package:nas2cloud/components/uploader/file_uploder.dart';
import 'package:nas2cloud/components/uploader/upload_entry.dart';

class WebUploader extends FileUploader {
  @override
  void initialize() {
    throw UnimplementedError();
  }

  @override
  Future<bool> enqueue(UploadEntry entry) {
    // TODO: implement uploadEntry
    throw UnimplementedError();
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

  // static const String _keyPrefix = "app.fileupload.";

  // @override
  // Future<bool> uploadStream(
  //     {required String dest,
  //     required String fileName,
  //     required int size,
  //     required Stream<List<int>> stream}) async {
  //   if (size <= 0 || dest == "/" || dest.isEmpty) {
  //     return false;
  //   }
  //   var record = FileUploadRecord(
  //       id: "$dest/$fileName",
  //       fileName: fileName,
  //       filePath: fileName,
  //       size: size,
  //       beginUploadTime: DateTime.now().millisecondsSinceEpoch,
  //       endUploadTime: -1,
  //       fileLastModTime: DateTime.now().millisecondsSinceEpoch,
  //       dest: dest,
  //       status: FileUploadStatus.uploading.name,
  //       progress: 0,
  //       message: FileUploadStatus.uploading.name);

  //   var uploadKey = "$_keyPrefix${record.id}";
  //   if (spu.containsKey(uploadKey)) {
  //     return true;
  //   }
  //   _clearRecordCache();
  //   if (!await spu.setString(uploadKey, record.toJson())) {
  //     return false;
  //   }
  //   if (record.size / 1024 / 1024 >= 500) {
  //     await _chgState(record, FileUploadStatus.failed, "文件大小不能超过500MB");
  //     return false;
  //   }
  //   Api.uploadStream(
  //           dest: record.dest,
  //           fileName: record.fileName,
  //           fileLastModified: record.fileLastModTime,
  //           size: record.size,
  //           stream: stream)
  //       .then((value) {
  //     if (value.success) {
  //       _chgState(record, FileUploadStatus.success, "OK");
  //     } else {
  //       _chgState(record, FileUploadStatus.failed, value.message ?? "ERROR");
  //     }
  //   }).onError(((error, stackTrace) {
  //     _chgState(record, FileUploadStatus.failed, error.toString());
  //   }));
  //   return true;
  // }

  // Future<bool> _chgState(
  //     FileUploadRecord record, FileUploadStatus status, String message) async {
  //   record.status = status.name;
  //   record.message = message;
  //   switch (status) {
  //     case FileUploadStatus.failed:
  //     case FileUploadStatus.success:
  //       record.endUploadTime = DateTime.now().millisecondsSinceEpoch;
  //       break;
  //     default:
  //       break;
  //   }
  //   var uploadKey = "$_keyPrefix${record.id}";
  //   bool ret = await spu.setString(uploadKey, record.toJson());
  //   _clearRecordCache();
  //   super.notifyListeners(record);
  //   return ret;
  // }

  // List<FileUploadRecord>? records;

  // void _clearRecordCache() {
  //   records = null;
  // }

  // List<FileUploadRecord> _loadRecordCache() {
  //   if (records != null) {
  //     return records!;
  //   }
  //   List<FileUploadRecord> list = [];
  //   var keys = spu.getKeys();
  //   for (var key in keys) {
  //     if (!key.startsWith(_keyPrefix)) {
  //       continue;
  //     }
  //     String? str = spu.getString(key);
  //     if (str == null) {
  //       continue;
  //     }
  //     var record = FileUploadRecord.fromJson(str);
  //     if (DateTime.now().millisecondsSinceEpoch - record.beginUploadTime >
  //         Duration(days: 1).inMilliseconds) {
  //       spu.remove(key);
  //       continue;
  //     }
  //     list.add(record);
  //   }
  //   list.sort(((a, b) {
  //     return a.beginUploadTime > b.beginUploadTime ? 0 : 1;
  //   }));
  //   records = list;
  //   return records!;
  // }

  // @override
  // int getCount() {
  //   var list = _loadRecordCache();
  //   return list.length;
  // }

  // @override
  // FileUploadRecord? getRecord(int index) {
  //   var list = _loadRecordCache();
  //   if (list.length > index) {
  //     return list[index];
  //   }
  //   return null;
  // }

  // @override
  // void clearRecordByState(List<FileUploadStatus> filters) {
  //   var records = _loadRecordCache();
  //   for (var record in records) {
  //     if (FileUploadStatus.isAny(record.status, filters)) {
  //       var uploadKey = "$_keyPrefix${record.id}";
  //       spu.remove(uploadKey);
  //     }
  //   }
  //   _clearRecordCache();
  // }

  // @override
  // Future<bool> uploadPath({required String dest, required String src}) {
  //   throw UnsupportedError("unsupported");
  // }
}
