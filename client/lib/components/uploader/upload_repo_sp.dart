import 'package:nas2cloud/api/dto/page_data.dart';
import 'package:nas2cloud/components/uploader/upload_entry.dart';
import 'package:nas2cloud/components/uploader/upload_repo.dart';

class UploadRepoSP extends UploadRepository {
  @override
  Future<UploadEntry> saveIfNotExists(UploadEntry entry) {
    throw UnimplementedError();
  }

  @override
  Future<int> update(UploadEntry entry) {
    throw UnimplementedError();
  }

  @override
  Future<UploadEntry?> findByTaskId(String taskId) {
    throw UnimplementedError();
  }

  @override
  Future<int> clearAll() {
    throw UnimplementedError();
  }

  @override
  Future<int> getTotal() {
    throw UnimplementedError();
  }

  @override
  Future<PageData<UploadEntry>> findByStatus(
      {required String status, required int page, required int pageSize}) {
    throw UnimplementedError();
  }

  @override
  Future<int> deleteByStatus(String status) {
    throw UnimplementedError();
  }

  @override
  Future<int> findCountByChannel(
      {required String channel, List<String>? status}) {
    // TODO: implement findCountByChannel
    throw UnimplementedError();
  }
}
