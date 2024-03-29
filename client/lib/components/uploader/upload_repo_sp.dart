import '../../dto/page_data.dart';
import '../../dto/upload_entry.dart';
import '../../utils/pair.dart';
import '../../utils/spu.dart';
import 'upload_repo.dart';

class UploadRepoSP extends UploadRepository {
  static const _keyPrefix = "app.upload.entry";

  String _getKey(String taskId) {
    return "${_keyPrefix}_$taskId";
  }

  String _getTaskId(UploadEntry entry) {
    return _getTaskIdBySrcDest(entry.src, entry.dest);
  }

  String _getTaskIdBySrcDest(String src, String dest) {
    return "$src:$dest";
  }

  @override
  Future<Pair<UploadEntry, bool>> saveIfNotExists(UploadEntry entry) async {
    var key = _getKey(_getTaskId(entry));
    var value = await Spu().getString(key);
    if (value != null) {
      return Pair<UploadEntry, bool>(
          left: UploadEntry.fromJson(value), right: false);
    }
    await Spu().setString(key, entry.toJson());
    return Pair<UploadEntry, bool>(left: entry, right: false);
  }

  @override
  Future<int> deleteBySrcDest(String src, String dest) async {
    var key = _getKey(_getTaskIdBySrcDest(src, dest));
    var deleted = await Spu().remove(key);
    return deleted ? 1 : 0;
  }

  @override
  Future<int> update(UploadEntry entry) async {
    var key = _getKey(_getTaskId(entry));
    await Spu().setString(key, entry.toJson());
    return 1;
  }

  @override
  Future<UploadEntry?> findByTaskId(String taskId) async {
    var key = _getKey(taskId);
    var value = await Spu().getString(key);
    if (value != null) {
      return UploadEntry.fromJson(value);
    }
    return null;
  }

  @override
  Future<int> clearAll() async {
    var list = await Stream.fromIterable(await Spu().getKeys())
        .where((event) => event.startsWith(_keyPrefix))
        .toList();
    for (var key in list) {
      await Spu().remove(key);
    }
    return list.length;
  }

  @override
  Future<int> getTotal() async {
    var keys = await Spu().getKeys();
    return await Stream.fromIterable(keys)
        .where((event) => event.startsWith(_keyPrefix))
        .length;
  }

  @override
  Future<PageData<UploadEntry>> findByStatus(
      {required String status,
      required int page,
      required int pageSize}) async {
    var keys = await Stream.fromIterable(await Spu().getKeys())
        .where((event) => event.startsWith(_keyPrefix))
        .toList();

    List<UploadEntry> list = [];
    for (var key in keys) {
      var value = await Spu().getString(key);
      if (value != null) {
        var entry = UploadEntry.fromJson(value);
        if (entry.status == status) {
          list.add(entry);
        }
      }
    }
    return PageData(page, keys.length, list);
  }

  @override
  Future<int> deleteByStatus(String status) async {
    var keys = await Stream.fromIterable(await Spu().getKeys())
        .where((event) => event.startsWith(_keyPrefix))
        .toList();
    int deleteCount = 0;
    for (var key in keys) {
      var json = await Spu().getString(key);
      if (json != null) {
        var entry = UploadEntry.fromJson(json);
        if (entry.status == status) {
          await Spu().remove(key);
          deleteCount++;
        }
      }
    }
    return deleteCount;
  }

  @override
  Future<int> countByChannel({required String channel, List<String>? status}) {
    throw UnimplementedError();
  }

  @override
  Future<int> countByStatus(List<String> status) {
    return Future.value(0);
  }
}
