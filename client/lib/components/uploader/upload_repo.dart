import 'package:flutter/foundation.dart';
import 'package:nas2cloud/components/uploader/upload_entry.dart';
import 'package:nas2cloud/components/uploader/upload_repo_sp.dart';
import 'package:nas2cloud/components/uploader/upload_repo_sqflite.dart';

abstract class UploadRepo {
  static UploadRepo _instance = UploadRepo._private();

  static UploadRepo get platform => _instance;

  factory UploadRepo._private() {
    if (kIsWeb) {
      return UploadRepoSP();
    }
    return UploadRepoSqflite();
  }

  UploadRepo();

  Future<int> saveIfNotExists(UploadEntry entry);
}
