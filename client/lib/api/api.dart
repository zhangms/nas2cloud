import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/api_mock.dart';
import 'package:nas2cloud/api/api_real.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/api/dto/file_walk_request.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file_walk_response.dart';
import 'package:nas2cloud/api/dto/login_response/login_response.dart';
import 'package:nas2cloud/api/dto/result.dart';
import 'package:nas2cloud/api/dto/state_response/state_response.dart';
import 'package:path/path.dart' as p;

abstract class Api {
  static Api _real = ApiReal();
  static Api _mock = ApiMock();

  factory Api() {
    if (AppConfig.isUseMockApi()) {
      return _mock;
    } else {
      return _real;
    }
  }

  Api.internal();

  Future<String> encrypt(String data);

  Future<Map<String, String>> httpHeaders();

  String joinPath(String first, String second) {
    return p.normalize(["/", first, second].join("/"));
  }

  Future<String> getApiUrl(String path);

  Future<String> getStaticFileUrl(String path);

  Future<String> signUrl(String url);

  Future<StateResponse> tryGetServerStatus();

  Future<StateResponse> getServerStatus(String address);

  Future<LoginResponse> postLogin(
      {required String username, required String password});

  Future<FileWalkResponse> postFileWalk(FileWalkRequest reqeust);

  Future<Result> postCreateFolder(String path, String folderName);

  Future<Result> postDeleteFile(String fullPath);

  Future<Result> getFileExists(String fullPath);

  Future<Result> uploadStream({
    required String dest,
    required String fileName,
    required int fileLastModified,
    required int size,
    required Stream<List<int>> stream,
  });

  Future<RangeData> rangeGetStatic(String path, int start, int end);
}

class RangeData {
  String contentType;
  int contentLength;
  Uint8List? content;
  RangeData(this.contentType, this.contentLength, this.content);
}
