import 'package:nas2cloud/api/dto/file_upload_record.dart';
import 'package:nas2cloud/api/dto/file_upload_status_enum.dart';
import 'package:nas2cloud/api/uploader/file_uploder.dart';

class UnsupportUploader extends FileUploader {
  @override
  Future<bool> fireStreamUploadEvent(
      {required String dest,
      required String fileName,
      required int size,
      required Stream<List<int>> stream}) {
    return Future.value(false);
  }

  @override
  int getCount() {
    return 0;
  }

  @override
  FileUploadRecord? getRecord(int index) {
    return null;
  }

  @override
  void clearRecordByState(List<FileUploadStatus> filters) {}
}
