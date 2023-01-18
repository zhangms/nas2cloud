import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:nas2cloud/api/file_walk_request.dart';
import 'package:nas2cloud/api/file_walk_response/file_walk_response.dart';
import 'package:nas2cloud/api/login_response/login_response.dart';
import 'package:nas2cloud/api/result.dart';
import 'package:nas2cloud/api/state_response/state_response.dart';
import 'package:nas2cloud/app.dart';

const _exception = {"success": false, "message": "服务器不可用"};

const _defaultHttpHeaders = {
  "X-DEVICE": "web",
  "Content-Type": "application/json;charset=UTF-8",
};

class _Api {
  const _Api();

  Map<String, String> httpHeaders() {
    var header = {..._defaultHttpHeaders};
    if (appStorage.isUserLogged()) {
      var data = appStorage.getUserInfo()!;
      header["X-AUTH-TOKEN"] = "${data.username}-${data.token}";
    }
    return header;
  }

  Future<StateResponse> getHostState(String address) async {
    try {
      var url = Uri.http(address, "api/state");
      Response resp = await http.get(url, headers: httpHeaders());
      return StateResponse.fromJson(utf8.decode(resp.bodyBytes));
    } catch (e) {
      print(e);
      return StateResponse.fromMap(_exception);
    }
  }

  Future<LoginResponse> postLogin(
      {required String username, required String password}) async {
    try {
      var url = Uri.http(appStorage.getHostAddress(), "/api/user/login");
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

  Future<FileWalkResponse> postFileWalk(FileWalkRequest reqeust) async {
    try {
      var url = Uri.http(appStorage.getHostAddress(), "/api/store/walk");
      Response resp =
          await http.post(url, headers: httpHeaders(), body: reqeust.toJson());
      return FileWalkResponse.fromJson(utf8.decode(resp.bodyBytes));
    } catch (e) {
      print(e);
      return FileWalkResponse.fromMap(_exception);
    }
  }

  Future<Result> postCreateFolder(String path, String folderName) async {
    var url = Uri.http(appStorage.getHostAddress(), "/api/store/createFolder");
    Response resp = await http.post(url,
        headers: httpHeaders(),
        body: jsonEncode({
          "path": path,
          "folderName": folderName,
        }));
    return Result.fromJson(utf8.decode(resp.bodyBytes));
  }

  Future<Result> postDeleteFile(String fullPath) async {
    var url = Uri.http(appStorage.getHostAddress(), "/api/store/deleteFiles");
    Response resp = await http.post(url,
        headers: httpHeaders(),
        body: jsonEncode({
          "paths": [fullPath],
        }));
    return Result.fromJson(utf8.decode(resp.bodyBytes));
  }
}

const api = _Api();
