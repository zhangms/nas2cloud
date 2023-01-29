import 'package:flutter/foundation.dart';
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

  Future<bool> open() {
    return Future.value(true);
  }

  Future<void> close() async {}
}
