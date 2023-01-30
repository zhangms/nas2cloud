import 'package:nas2cloud/components/uploader/upload_entry.dart';
import 'package:nas2cloud/components/uploader/upload_repo.dart';

class UploadRepoSP extends UploadRepo {
  @override
  Future<UploadEntry> saveIfNotExists(UploadEntry entry) {
    throw UnimplementedError();
  }

  @override
  Future<int> getWaitingCount(String channel) {
    throw UnimplementedError();
  }

  @override
  Future<UploadEntry?> findFirstWaitingUploadEntry(String channel) {
    throw UnimplementedError();
  }

  @override
  Future<int> update(UploadEntry entry) {
    throw UnimplementedError();
  }
}
