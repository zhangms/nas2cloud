import 'package:flutter/foundation.dart';

import '../../dto/page_data.dart';
import '../../dto/upload_entry.dart';
import '../../utils/pair.dart';
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
  Future<Pair<UploadEntry, bool>> saveIfNotExists(UploadEntry entry);

  Future<int> deleteBySrcDest(String src, String dest);

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
