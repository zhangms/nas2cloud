import 'package:nas2cloud/components/uploader/upload_entry.dart';
import 'package:nas2cloud/components/uploader/upload_repo.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

const String _initDbSQL = '''
CREATE TABLE t_upload_entry (
    id INTEGER PRIMARY KEY,
    uploadGroupId TEXT,
    src TEXT,
    dest TEXT,
    size INTEGER,
    lastModified INTEGER,
    createTime INTEGER,
    beginUploadTime INTEGER,
    endUploadTime INTEGER,
    status TEXT,
    message TEXT
);

CREATE UNIQUE INDEX t_upload_entry_index1 on t_upload_entry (src);

CREATE UNIQUE INDEX t_upload_entry_index2 on t_upload_entry (src, dest);

CREATE INDEX t_upload_entry_index3 on t_upload_entry (uploadGroupId);
''';

class UploadRepoSqflite extends UploadRepo {
  static UploadRepoSqflite _instance = UploadRepoSqflite._private();

  factory UploadRepoSqflite() => _instance;

  UploadRepoSqflite._private();

  Database? database;

  Future<bool> _open() async {
    if (database != null) {
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
    return true;
  }

  Future<void> close() async {
    if (database != null) {
      await database!.close();
      database = null;
    }
  }

  @override
  Future<int> saveIfNotExists(UploadEntry entry) async {
    await _open();
    var count = Sqflite.firstIntValue(await database!.rawQuery(
            "select count(1) from t_upload_entry where src=? and dest=?",
            [entry.src, entry.dest])) ??
        0;
    if (count > 0) {
      return 0;
    }
    return await database!.insert("t_upload_entry", entry.toMap());
  }
}
