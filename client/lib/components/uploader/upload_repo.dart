import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/dto/page_data.dart';

import 'upload_entry.dart';
import 'upload_repo_sp.dart';
import 'upload_repo_sqflite.dart';

abstract class UploadRepository {
  static UploadRepository _instance = UploadRepository._private();

  static UploadRepository get platform => _instance;

  factory UploadRepository._private() {
    if (kIsWeb) {
      return UploadRepoSP();
    }
    return UploadRepoSqflite();
  }

  UploadRepository();

/*
 * return id
 */
  Future<UploadEntry> saveIfNotExists(UploadEntry entry);

  Future<int> update(UploadEntry entry);

  Future<UploadEntry?> findByTaskId(String taskId);

  Future<int> clearAll();

  Future<int> getTotal();

  Future<PageData<UploadEntry>> findByStatus(
      {required String status, required int page, required int pageSize});

  Future<int> deleteByStatus(String status);

  Future<int> countByChannel({required String channel, List<String>? status});

  Future<int> countByStatus(List<String> status);
}
