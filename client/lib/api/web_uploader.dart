import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/dto/file_upload_record.dart';
import 'package:nas2cloud/utils/spu.dart';

class _WebUploader {
  static const String _uploadKey = "app.fileupload.";

  bool addToUpload(
      {required String dest,
      required int size,
      required String name,
      Stream<List<int>>? readStream}) {
    if (readStream == null || size <= 0 || dest == "/" || dest.isEmpty) {
      return false;
    }

    FileUploadRecord record = FileUploadRecord(
        id: "$dest/$name",
        fileName: name,
        filePath: name,
        size: size,
        uploadTime: DateTime.now().millisecondsSinceEpoch,
        fileLastModTime: DateTime.now().millisecondsSinceEpoch,
        dest: dest,
        status: "uploading",
        progress: 0);

    var key = "$_uploadKey${record.id}";
    if (spu.containsKey(key) ?? true) {
      return false;
    }
    spu.setString(key, record.toJson());
    api.webUpload(path: dest, stream: readStream, contentLength: size)
        .then((value) => {print("------->$value")});

    return true;
  }
}

var webUploader = _WebUploader();
