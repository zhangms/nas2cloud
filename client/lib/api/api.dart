import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:nas2cloud/api/app_storage.dart';
import 'package:nas2cloud/api/dto/file_walk_request.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file_walk_response.dart';
import 'package:nas2cloud/api/dto/login_response/login_response.dart';
import 'package:nas2cloud/api/dto/result.dart';
import 'package:nas2cloud/api/dto/state_response/state_response.dart';

class Api {
  static const _exception = {"success": false, "message": "服务器不可用"};

  static var _defaultHttpHeaders = {
    "X-DEVICE": kIsWeb
        ? "flutter-app-web"
        : "${Platform.operatingSystem},${Platform.operatingSystemVersion},${Platform.version}",
    "Content-Type": "application/json;charset=UTF-8",
  };

  static Map<String, String> httpHeaders() {
    var header = {..._defaultHttpHeaders};
    if (AppStorage.isUserLogged()) {
      var data = AppStorage.getUserLoginInfo()!;
      header["X-AUTH-TOKEN"] = "${data.username}-${data.token}";
    }
    return header;
  }

  static String getApiUrl(String path) {
    if (!AppStorage.isHostAddressConfiged()) {
      return path;
    }
    String address = AppStorage.getHostAddress();
    if (address.endsWith("/")) {
      address = address.substring(0, address.length - 1);
    }
    if (path.startsWith("/")) {
      return "http://$address$path";
    }
    return "http://$address/$path";
  }

  static String getStaticFileUrl(String path) {
    if (!AppStorage.isHostAddressConfiged()) {
      return path;
    }
    String address =
        AppStorage.getHostState()?.staticAddress ?? AppStorage.getHostAddress();
    if (address.endsWith("/")) {
      address = address.substring(0, address.length - 1);
    }
    if (path.startsWith("/")) {
      return "http://$address$path";
    }
    return "http://$address/$path";
  }

  static String signUrl(String url) {
    String str =
        "${DateTime.now().millisecondsSinceEpoch}|${jsonEncode(httpHeaders())}";
    var sign = Base64Encoder.urlSafe().convert(str.codeUnits);
    return "$url?_sign=$sign";
  }

  static Future<StateResponse> getHostState(String address) async {
    try {
      var url = Uri.http(address, "api/state");
      Response resp = await http.get(url, headers: httpHeaders());
      return StateResponse.fromJson(utf8.decode(resp.bodyBytes));
    } catch (e) {
      print(e);
      return StateResponse.fromMap(_exception);
    }
  }

  static Future<LoginResponse> postLogin(
      {required String username, required String password}) async {
    try {
      var url = Uri.http(AppStorage.getHostAddress(), "/api/user/login");
      Response resp = await http.post(url,
          headers: _defaultHttpHeaders,
          body: jsonEncode({
            "username": username,
            "password": password,
          }));
      return LoginResponse.fromJson(utf8.decode(resp.bodyBytes));
    } catch (e) {
      print(e);
      return LoginResponse.fromMap(_exception);
    }
  }

  static Future<FileWalkResponse> postFileWalk(FileWalkRequest reqeust) async {
    try {
      var url = Uri.http(AppStorage.getHostAddress(), "/api/store/walk");
      Response resp =
          await http.post(url, headers: httpHeaders(), body: reqeust.toJson());
      return FileWalkResponse.fromJson(utf8.decode(resp.bodyBytes));
    } catch (e) {
      print(e);
      return FileWalkResponse.fromMap(_exception);
    }
  }

  static Future<Result> postCreateFolder(String path, String folderName) async {
    try {
      var url =
          Uri.http(AppStorage.getHostAddress(), "/api/store/createFolder");
      Response resp = await http.post(url,
          headers: httpHeaders(),
          body: jsonEncode({
            "path": path,
            "folderName": folderName,
          }));
      return Result.fromJson(utf8.decode(resp.bodyBytes));
    } catch (e) {
      print(e);
      return Result.fromMap(_exception);
    }
  }

  static Future<Result> postDeleteFile(String fullPath) async {
    try {
      var url = Uri.http(AppStorage.getHostAddress(), "/api/store/deleteFiles");
      Response resp = await http.post(url,
          headers: httpHeaders(),
          body: jsonEncode({
            "paths": [fullPath],
          }));
      return Result.fromJson(utf8.decode(resp.bodyBytes));
    } catch (e) {
      print(e);
      return Result.fromMap(_exception);
    }
  }

  static String paths(String first, String second) {
    var base = first;
    if (!base.startsWith("/")) {
      base = "/$base";
    }
    if (base.endsWith("/")) {
      base = base.substring(0, base.length - 1);
    }

    var path = second;
    if (path.startsWith("/")) {
      path = path.substring(1);
    }
    if (path.endsWith("/")) {
      path = path.substring(0, path.length - 1);
    }
    return "$base/$path";
  }

  static Future<Result> getFileExists(String fullPath) async {
    try {
      var url = Uri.http(AppStorage.getHostAddress(),
          paths("/api/store/fileExists", fullPath));
      Response resp = await http.get(url, headers: httpHeaders());
      return Result.fromJson(utf8.decode(resp.bodyBytes));
    } catch (e) {
      print(e);
      return Result.fromMap(_exception);
    }
  }

  static Future<Result> uploadStream({
    required String dest,
    required String fileName,
    required int fileLastModified,
    required int size,
    required Stream<List<int>> stream,
  }) async {
    try {
      Result exists = await getFileExists(paths(dest, fileName));
      if (!exists.success) {
        return exists;
      }
      if (exists.message == "true") {
        return Result(success: false, message: "文件已存在");
      }
      var uri = Uri.http(
          AppStorage.getHostAddress(), paths("/api/store/upload", dest));
      var request = http.MultipartRequest("POST", uri)
        ..headers.addAll(httpHeaders())
        ..fields["lastModified"] = "$fileLastModified"
        ..files.add(MultipartFile("file", stream, size, filename: fileName));
      var resp = await request.send();
      var ret = await resp.stream.bytesToString();
      return Result.fromJson(ret);
    } catch (e) {
      print(e);
      return Result.fromMap(_exception);
    }
  }
}
