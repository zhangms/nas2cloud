import 'package:flutter/foundation.dart';
import 'package:nas2cloud/dto/search_photo_response.dart';
import 'package:path/path.dart' as p;

import '../dto/file_walk_request.dart';
import '../dto/file_walk_response.dart';
import '../dto/login_response.dart';
import '../dto/result.dart';
import '../dto/search_photo_count_response.dart';
import '../dto/state_response.dart';
import 'api_mock.dart';
import 'api_real.dart';
import 'app_config.dart';

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

  Future<String> signData(String data);

  Future<StateResponse> tryGetServerStatus();

  Future<StateResponse> getServerStatus(String address);

  Future<LoginResponse> postLogin(
      {required String username, required String password});

  Future<FileWalkResponse> postFileWalk(FileWalkRequest request);

  Future<Result> postCreateFolder(String path, String folderName);

  Future<Result> postDeleteFile(String fullPath);

  Future<Result> getFileExists(String fullPath);

  Future<Result> getCheckUpdates();

  Future<Result> postTraceLog(String log);

  Future<Result> postToggleFavor(String fullPath, String name);

  Future<Result> uploadStream({
    required String dest,
    required String fileName,
    required int fileLastModified,
    required int size,
    required Stream<List<int>> stream,
  });

  Future<RangeData> rangeGetStatic(String path, int start, int end);

  Future<SearchPhotoResponse> searchPhoto(String time, String searchAfter);

  Future<SearchPhotoCountResponse> searchPhotoCount();
}

class RangeData {
  String contentType;
  int contentLength;
  Uint8List? content;

  RangeData(this.contentType, this.contentLength, this.content);
}
