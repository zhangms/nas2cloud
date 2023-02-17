import '../dto/file_walk_request.dart';
import '../dto/file_walk_response.dart';
import '../dto/login_response.dart';
import '../dto/result.dart';
import '../dto/state_response.dart';
import 'api.dart';

class ApiMock extends Api {
  ApiMock() : super.internal();

  @override
  Future<String> encrypt(String data) async {
    return data;
  }

  @override
  Future<String> getApiUrl(String path) async {
    return path;
  }

  @override
  Future<Result> getFileExists(String fullPath) async {
    return Result.fromMap({
      "success": true,
      "message": "false",
    });
  }

  @override
  Future<StateResponse> getServerStatus(String address) async {
    return StateResponse.fromMap({
      "success": true,
      "message": "OK",
      "data": {
        "appName": "hello",
        "publicKey": "",
        "userName": "zms",
      },
    });
  }

  @override
  Future<StateResponse> tryGetServerStatus() async {
    return await getServerStatus("xxx");
  }

  @override
  Future<String> getStaticFileUrl(String path) async {
    if (path.startsWith("http")) {
      return path;
    }
    return "http://192.168.31.99:8168/$path";
  }

  @override
  Future<Map<String, String>> httpHeaders() async {
    return {
      "AA": "BB",
    };
  }

  @override
  Future<Result> postCreateFolder(String path, String folderName) async {
    return Result.fromMap({
      "success": true,
      "message": "OK",
    });
  }

  @override
  Future<Result> postDeleteFile(String fullPath) async {
    return Result.fromMap({
      "success": true,
      "message": "OK",
    });
  }

  @override
  Future<FileWalkResponse> postFileWalk(FileWalkRequest request) {
    const total = 10000;
    var start = request.pageNo * request.pageSize;
    var end = (request.pageNo + 1) * request.pageSize;
    List<Map<String, dynamic>> files = [];
    for (var i = start; i < end; i++) {
      if (i >= 0 && i < total) {
        if (i % 5 == 0) {
          files.add({
            "name": "file:$i",
            "type": "FILE",
            "path": "path:$i",
            "size": "123MB",
            "modTime": "2022-02-02 22:22:22",
            "favor": i < 3 ? true : false,
          });
        } else if (i % 6 == 0) {
          files.add({
            "name": "file:$i",
            "type": "FILE",
            "path": "path:$i",
            "size": "123MB",
            "modTime": "2022-02-02 22:22:22",
            "favor": i < 3 ? true : false,
            "ext": ".MP4",
            "thumbnail": "/thumb/a.jpg",
          });
        } else {
          files.add({
            "name": "file:$i",
            "type": "DIR",
            "path": "path:$i",
            "size": "123MB",
            "modTime": "2022-02-02 22:22:22",
            "favor": i < 3 ? true : false,
          });
        }
      } else if (i >= total) {
        break;
      }
    }
    return Future.delayed(
        Duration(milliseconds: 10),
        () => FileWalkResponse.fromMap({
              "success": true,
              "message": "OK",
              "data": {
                "currentStart": start,
                "currentStop": end,
                "currentPage": request.pageNo,
                "currentPath": request.path,
                "total": total,
                "nav": [],
                "files": files
              },
            }));
  }

  @override
  Future<LoginResponse> postLogin(
      {required String username, required String password}) async {
    return LoginResponse.fromMap({
      "success": true,
      "message": "OK",
      "data": {
        'username': "FF",
        'token': "FF",
        'createTime': "FF",
      },
    });
  }

  @override
  Future<RangeData> rangeGetStatic(String path, int start, int end) async {
    return RangeData("text", 10, null);
  }

  @override
  Future<String> signUrl(String url) async {
    return url;
  }

  @override
  Future<Result> uploadStream(
      {required String dest,
      required String fileName,
      required int fileLastModified,
      required int size,
      required Stream<List<int>> stream}) async {
    return Result.fromMap({
      "success": true,
      "message": "OK",
    });
  }

  @override
  Future<Result> getCheckUpdates() async {
    return Result.fromMap({
      "success": true,
      "message": "client/nas2cloud-v2.9.7.apk;2.9.8",
    });
  }

  @override
  Future<Result> postTraceLog(String log) async {
    print("client:$log");
    return Result.fromMap({
      "success": true,
      "message": "OK",
    });
  }

  @override
  Future<Result> postToggleFavor(String fullPath, String name) async {
    return Result.fromMap({
      "success": true,
      "message": "true",
    });
  }
}
