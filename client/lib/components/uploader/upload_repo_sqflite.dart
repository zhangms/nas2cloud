import 'package:nas2cloud/components/uploader/upload_entry.dart';
import 'package:nas2cloud/components/uploader/upload_repo.dart';
import 'package:nas2cloud/components/uploader/upload_status.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

const String _initDbSQL = '''
CREATE TABLE t_upload_entry (
    id INTEGER PRIMARY KEY,
    channel TEXT,
    src TEXT,
    dest TEXT,
    size INTEGER,
    lastModified INTEGER,
    createTime INTEGER,
    beginUploadTime INTEGER,
    endUploadTime INTEGER,
    uploadTaskId TEXT,
    status TEXT,
    message TEXT
);

CREATE UNIQUE INDEX t_upload_entry_index1 on t_upload_entry (src);

CREATE UNIQUE INDEX t_upload_entry_index2 on t_upload_entry (src, dest);

CREATE INDEX t_upload_entry_index3 on t_upload_entry (channel);

CREATE INDEX t_upload_entry_index4 on t_upload_entry (uploadTaskId);

''';

class UploadRepoSqflite extends UploadRepository {
  static UploadRepoSqflite _instance = UploadRepoSqflite._private();

  factory UploadRepoSqflite() => _instance;

  UploadRepoSqflite._private();

  Database? database;

  Future<bool> _open() async {
    if (database != null && database!.isOpen) {
      return true;
    }
    var sqls = await Stream.fromIterable(_initDbSQL.split(";"))
        .map((sql) => sql.trim())
        .where((sql) => sql.isNotEmpty)
        .toList();
    var path = await getDatabasesPath();
    var datapath = p.join(path, "nas2cloud_uploader.db");
    database = await openDatabase(
      datapath,
      version: 1,
      onCreate: (Database db, int version) async {
        for (var sql in sqls) {
          await db.execute(sql);
        }
      },
    );
    print("sqflite nas2cloud_uploader.db opened");
    return true;
  }

  Future<void> close() async {
    if (database != null) {
      await database!.close();
      database = null;
    }
  }

  @override
  Future<UploadEntry> saveIfNotExists(UploadEntry entry) async {
    await _open();
    var list = await database!.rawQuery(
        "select * from t_upload_entry where src=? and dest=?",
        [entry.src, entry.dest]);
    if (list.isNotEmpty) {
      return UploadEntry.fromMap(list[0]);
    }
    var id = await database!.insert("t_upload_entry", entry.toMap());
    return entry.copyWith(id: id);
  }

  @override
  Future<int> getWaitingCount(String channel) async {
    await _open();
    return Sqflite.firstIntValue(await database!.rawQuery(
            "select count(1) from t_upload_entry where uploadGroupId=? and status=?",
            [channel, UploadStatus.waiting.name])) ??
        0;
  }

  @override
  Future<int> update(UploadEntry entry) async {
    await _open();
    return await database!.update("t_upload_entry", entry.toMap(),
        where: "id=?", whereArgs: [entry.id]);
  }

  @override
  Future<UploadEntry?> findByTaskId(String taskId) async {
    await _open();
    var list = await database!.query("t_upload_entry",
        where: "uploadTaskId=?", whereArgs: [taskId], limit: 1);
    if (list.isNotEmpty) {
      return UploadEntry.fromMap(list[0]);
    }
    return null;
  }

  @override
  Future<int> clearAll() async {
    await _open();
    return await database!.delete("t_upload_entry", where: "id>0");
  }
}
