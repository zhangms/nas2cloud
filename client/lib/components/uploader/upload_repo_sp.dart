import 'package:nas2cloud/components/uploader/upload_entry.dart';
import 'package:nas2cloud/components/uploader/upload_repo.dart';

class UploadRepoSP extends UploadRepo {
  @override
  Future<int> saveIfNotExists(UploadEntry entry) {
    throw UnimplementedError();
  }
}
