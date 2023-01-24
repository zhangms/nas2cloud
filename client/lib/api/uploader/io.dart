import 'package:nas2cloud/api/dto/file_upload_record.dart';
import 'package:nas2cloud/api/dto/file_upload_status_enum.dart';
import 'package:nas2cloud/api/uploader/file_uploder.dart';

class IOUploader extends FileUploader {
  @override
  void clearRecordByState(List<FileUploadStatus> filters) {}

  @override
  Future<bool> firePathUploadEvent(
      {required String dest, required String src}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> fireStreamUploadEvent(
      {required String dest,
      required String fileName,
      required int size,
      required Stream<List<int>> stream}) {
    throw UnimplementedError();
  }

  @override
  int getCount() {
    throw UnimplementedError();
  }

  @override
  FileUploadRecord? getRecord(int index) {
    throw UnimplementedError();
  }
}
