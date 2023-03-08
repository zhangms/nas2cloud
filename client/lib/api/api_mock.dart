import 'package:nas2cloud/dto/search_photo_count_response.dart';
import 'package:nas2cloud/dto/search_photo_response.dart';

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

  @override
  Future<SearchPhotoResponse> searchPhoto(String time, String searchAfter) {
    return Future.value(SearchPhotoResponse.fromJson('''

{
  "success": true,
  "message": "OK",
  "data": {
    "searchAfter": "---",
    "files": [
      {
        "name": "world map3.jpg",
        "path": "/Pic/world map3.jpg",
        "thumbnail": "",
        "type": "FILE",
        "size": "551KB",
        "modTime": "2019-03-11 23:06",
        "ext": ".JPG",
        "favor": false,
        "favorName": ""
      },
      {
        "name": "world map2.jpg",
        "path": "/Pic/world map2.jpg",
        "thumbnail": "",
        "type": "FILE",
        "size": "3.47MB",
        "modTime": "2019-03-11 23:04",
        "ext": ".JPG",
        "favor": false,
        "favorName": ""
      },
      {
        "name": "world map.jpg",
        "path": "/Pic/world map.jpg",
        "thumbnail": "",
        "type": "FILE",
        "size": "3.35MB",
        "modTime": "2019-03-11 23:03",
        "ext": ".JPG",
        "favor": false,
        "favorName": ""
      }
    ]
  }
}

'''));
  }

  @override
  Future<SearchPhotoCountResponse> searchPhotoCount() {
    return Future.value(SearchPhotoCountResponse.fromJson('''
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "key": "2023-02",
      "value": 2
    },
    {
      "key": "2023-03",
      "value": 323
    },
    {
      "key": "2023-04",
      "value": 750
    },
    {
      "key": "2023-05",
      "value": 538
    },
    {
      "key": "2023-06",
      "value": 30
    },
    {
      "key": "2023-07",
      "value": 31
    },
    {
      "key": "2023-08",
      "value": 31
    },
    {
      "key": "2023-09",
      "value": 30
    },
    {
      "key": "2023-10",
      "value": 31
    },
    {
      "key": "2023-11",
      "value": 30
    },
    {
      "key": "2023-12",
      "value": 31
    },
    {
      "key": "2024-01",
      "value": 31
    },
    {
      "key": "2024-02",
      "value": 29
    },
    {
      "key": "2024-03",
      "value": 31
    },
    {
      "key": "2024-04",
      "value": 4
    }
  ]
}
'''));
  }

  @override
  Future<String> signData(String data) async {
    return data;
  }
}
