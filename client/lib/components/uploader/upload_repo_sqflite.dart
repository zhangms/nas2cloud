import 'package:flutter/material.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/api/dto/page_data.dart';
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

  Map<String, Database> databases = {};

  Future<Database> _open() async {
    var username = await AppConfig.getLoginUserName();
    if (username == null) {
      throw ErrorDescription("Db Open Error");
    }
    var dbname = "nas2cloud_uploader_$username.db";
    if (databases.isNotEmpty && databases[dbname] == null) {
      await _close();
    }
    var database = databases[dbname];
    if (database != null) {
      return database;
    }
    var sqls = await Stream.fromIterable(_initDbSQL.split(";"))
        .map((sql) => sql.trim())
        .where((sql) => sql.isNotEmpty)
        .toList();
    var path = await getDatabasesPath();
    var datapath = p.join(path, dbname);
    database = await openDatabase(
      datapath,
      version: 1,
      onCreate: (Database db, int version) async {
        for (var sql in sqls) {
          await db.execute(sql);
        }
      },
    );
    print("sqflite $dbname opened");
    databases[dbname] = database;
    return database;
  }

  Future<void> _close() async {
    for (var e in databases.entries) {
      await e.value.close();
    }
    databases.clear();
  }

  @override
  Future<UploadEntry> saveIfNotExists(UploadEntry entry) async {
    var database = await _open();
    var list = await database.rawQuery(
        "select * from t_upload_entry where src=? and dest=?",
        [entry.src, entry.dest]);
    if (list.isNotEmpty) {
      return UploadEntry.fromMap(list[0]);
    }
    var id = await database.insert("t_upload_entry", entry.toMap());
    return entry.copyWith(id: id);
  }

  @override
  Future<int> getWaitingCount(String channel) async {
    var database = await _open();
    return Sqflite.firstIntValue(await database.rawQuery(
            "select count(1) from t_upload_entry where uploadGroupId=? and status=?",
            [channel, UploadStatus.waiting.name])) ??
        0;
  }

  @override
  Future<int> update(UploadEntry entry) async {
    var database = await _open();
    return await database.update("t_upload_entry", entry.toMap(),
        where: "id=?", whereArgs: [entry.id]);
  }

  @override
  Future<UploadEntry?> findByTaskId(String taskId) async {
    var database = await _open();
    var list = await database.query("t_upload_entry",
        where: "uploadTaskId=?", whereArgs: [taskId], limit: 1);
    if (list.isNotEmpty) {
      return UploadEntry.fromMap(list[0]);
    }
    return null;
  }

  @override
  Future<int> clearAll() async {
    var database = await _open();
    return await database.delete("t_upload_entry", where: "id>0");
  }

  @override
  Future<int> getTotal() async {
    var database = await _open();
    var ret = await database.rawQuery("select count(1) from t_upload_entry");
    var count = Sqflite.firstIntValue(ret) ?? 0;
    return count;
  }

  @override
  Future<PageData<UploadEntry>> findByStatus(
      {required String status,
      required int page,
      required int pageSize}) async {
    var database = await _open();
    var total = Sqflite.firstIntValue(await database.rawQuery(
            "select count(1) from t_upload_entry where status=?", [status])) ??
        0;
    var resultSet = await database.query("t_upload_entry",
        where: "status=?",
        whereArgs: [status],
        orderBy: "id desc",
        offset: page * pageSize,
        limit: pageSize);
    var list = await Stream.fromIterable(resultSet)
        .map((map) => UploadEntry.fromMap(map))
        .toList();
    return PageData<UploadEntry>(page, total, list);
  }

  @override
  Future<int> deleteByStatus(String status) async {
    var database = await _open();
    return await database
        .delete("t_upload_entry", where: "status=?", whereArgs: [status]);
  }

  @override
  Future<int> findCountByChannel(
      {required String channel, List<String>? status}) async {
    var database = await _open();
    var sql = "select count(1) from t_upload_entry where channel=?";
    var args = [];
    args.add(channel);
    if (status != null && status.isNotEmpty) {
      sql +=
          " and status in(${List.generate(status.length, (index) => "?").join(",")})";
      args.addAll(status);
    }
    var ret = await database.rawQuery(sql, args);
    return Sqflite.firstIntValue(ret) ?? 0;
  }
}
