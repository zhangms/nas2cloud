import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/dto/file_walk_request.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file_walk_response.dart';
import 'package:nas2cloud/api/dto/login_response/login_response.dart';
import 'package:nas2cloud/api/dto/result.dart';
import 'package:nas2cloud/api/dto/state_response/state_response.dart';

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
    return path;
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
  Future<FileWalkResponse> postFileWalk(FileWalkRequest reqeust) async {
    return FileWalkResponse.fromMap({
      "success": true,
      "message": "OK",
      "data": {
        "currentStart": 0,
        "currentStop": 0,
        "currentPage": 0,
        "currentPath": reqeust.path,
        "total": 0,
        "nav": [],
        "files": []
      },
    });
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
      "message": "no uploads",
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
}
