import 'package:nas2cloud/components/uploader/upload_repo.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

const String _initDbSQL = '''
CREATE TABLE t_upload_entry (
    id INTEGER PRIMARY KEY,
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
''';

class UploadRepoSqflite extends UploadRepo {
  static UploadRepoSqflite _instance = UploadRepoSqflite._private();

  factory UploadRepoSqflite() => _instance;

  UploadRepoSqflite._private();

  Database? database;

  @override
  Future<bool> open() async {
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

  @override
  Future<void> close() async {
    if (database != null) {
      await database!.close();
    }
  }
}
