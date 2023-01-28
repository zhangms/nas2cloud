import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/api/dto/file_walk_request.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file_walk_response.dart';
import 'package:nas2cloud/api/dto/login_response/login_response.dart';
import 'package:nas2cloud/api/dto/result.dart';
import 'package:nas2cloud/api/dto/state_response/state_response.dart';
import 'package:pointycastle/asymmetric/api.dart';

class Api {
  static const _exception = {"success": false, "message": "服务器不可用"};

  static final RSAKeyParser _rsaKeyParser = RSAKeyParser();

  static String? _rsaPublicKeyContent;

  static Encrypter? _encrypter;

  static var _defaultHttpHeaders = {
    "X-DEVICE": kIsWeb
        ? "flutter-app-web"
        : "${Platform.operatingSystem},${Platform.operatingSystemVersion},${Platform.version}",
    "Content-Type": "application/json;charset=UTF-8",
  };

  static Encrypter? _getEncrypter() {
    String? content = AppConfig.getHostState()?.publicKey;
    if (content == null || content.isEmpty) {
      return null;
    }
    if (content != _rsaPublicKeyContent) {
      _rsaPublicKeyContent = content;
      var publicKey = _rsaKeyParser.parse(content) as RSAPublicKey;
      _encrypter = Encrypter(RSA(publicKey: publicKey));
    }
    return _encrypter;
  }

  static String encrypt(String data) {
    var encrypter = _getEncrypter();
    if (encrypter == null) {
      throw StateError("encrypter is null");
    }
    try {
      final encrypted = encrypter.encrypt(data);
      return Base64Codec.urlSafe().encode(encrypted.bytes);
    } catch (e) {
      print(e);
      return "";
    }
  }

  static Map<String, String> httpHeaders() {
    var header = {..._defaultHttpHeaders};
    if (AppConfig.isUserLogged()) {
      var data = AppConfig.getUserLoginInfo()!;
      header["X-AUTH-TOKEN"] = "${data.username}-${data.token}";
    }
    return header;
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

  static String getApiUrl(String path) {
    if (!AppConfig.isHostAddressConfiged()) {
      return path;
    }
    String address = AppConfig.getHostAddress();
    return Uri.http(address, path).toString();
  }

  static String getStaticFileUrl(String path) {
    if (!AppConfig.isHostAddressConfiged()) {
      return path;
    }
    String address =
        AppConfig.getHostState()?.staticAddress ?? AppConfig.getHostAddress();
    return Uri.http(address, path).toString();
  }

  static String signUrl(String url) {
    var now = DateTime.now().millisecondsSinceEpoch;
    String str = "$now ${jsonEncode(httpHeaders())}";
    String sign = encrypt(str);
    return "$url?_sign=$sign";
  }

  static Future<StateResponse> getHostStateIfConfiged() async {
    if (!AppConfig.isHostAddressConfiged()) {
      return Future.value(StateResponse.fromMap({
        "success": true,
        "message": "HOST_NOT_CONFIGED",
      }));
    }
    var state = await getHostState(AppConfig.getHostAddress());
    if (state.success) {
      await AppConfig.saveHostState(state.data!);
    }
    return state;
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
      var url = Uri.http(AppConfig.getHostAddress(), "/api/user/login");
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
      var url = Uri.http(AppConfig.getHostAddress(), "/api/store/walk");
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
      var url = Uri.http(AppConfig.getHostAddress(), "/api/store/createFolder");
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
      var url = Uri.http(AppConfig.getHostAddress(), "/api/store/deleteFiles");
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

  static Future<Result> getFileExists(String fullPath) async {
    try {
      var url = Uri.http(
          AppConfig.getHostAddress(), paths("/api/store/fileExists", fullPath));
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
          AppConfig.getHostAddress(), paths("/api/store/upload", dest));
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

  static Future<RangeData> rangeGetStatic(
      String path, int start, int end) async {
    try {
      var url = Uri.http(AppConfig.getHostAddress(), path);
      Map<String, String> headers = {"Range": "bytes=$start-$end"};
      headers.addAll(httpHeaders());
      Response resp = await http.get(url, headers: headers);
      return RangeData(resp.headers[HttpHeaders.contentTypeHeader] ?? "UNKNOWN",
          resp.contentLength ?? 0, resp.bodyBytes);
    } catch (e) {
      print(e);
      return RangeData("UNKNOWN", 0, null);
    }
  }
}

class RangeData {
  String contentType;
  int contentLength;
  Uint8List? content;
  RangeData(this.contentType, this.contentLength, this.content);
}
