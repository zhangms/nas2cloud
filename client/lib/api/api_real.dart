import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:pointycastle/asymmetric/api.dart';

import 'api.dart';
import 'app_config.dart';
import 'dto/file_walk_request.dart';
import 'dto/file_walk_response/file_walk_response.dart';
import 'dto/login_response/login_response.dart';
import 'dto/result.dart';
import 'dto/state_response/state_response.dart';

class ApiReal extends Api {
  ApiReal() : super.internal();

  static const _exception = {"success": false, "message": "服务器不可用"};

  static final RSAKeyParser _rsaKeyParser = RSAKeyParser();

  static String? _rsaPublicKeyContent;

  static Encrypter? _encryptor;

  static var _defaultHttpHeaders = {
    "X-DEVICE": kIsWeb
        ? "flutter-app-web,${AppConfig.currentAppVersion}"
        : "${Platform.operatingSystem},${Platform.operatingSystemVersion},${Platform.version},${AppConfig.currentAppVersion}",
    "Content-Type": "application/json;charset=UTF-8",
  };

  static Future<Encrypter?> _getEncryptor() async {
    String? content = (await AppConfig.getServerStatus())?.publicKey;
    if (content == null || content.isEmpty) {
      return null;
    }
    if (content != _rsaPublicKeyContent) {
      _rsaPublicKeyContent = content;
      var publicKey = _rsaKeyParser.parse(content) as RSAPublicKey;
      _encryptor = Encrypter(RSA(publicKey: publicKey));
    }
    return _encryptor;
  }

  @override
  Future<String> encrypt(String data) async {
    var encrypter = await _getEncryptor();
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

  @override
  Future<Map<String, String>> httpHeaders() async {
    var header = {..._defaultHttpHeaders};
    var loginInfo = await AppConfig.getUserLoginInfo();
    if (loginInfo != null) {
      header["X-AUTH-TOKEN"] = "${loginInfo.username}-${loginInfo.token}";
    }
    return header;
  }

  @override
  Future<String> getApiUrl(String path) async {
    if (!await AppConfig.isServerAddressConfig()) {
      return path;
    }
    String address = await AppConfig.getServerAddress();
    return Uri.http(address, path).toString();
  }

  @override
  Future<String> getStaticFileUrl(String path) async {
    if (!await AppConfig.isServerAddressConfig()) {
      return path;
    }
    var state = await AppConfig.getServerStatus();
    var hostAddress = await AppConfig.getServerAddress();
    String address = state?.staticAddress ?? hostAddress;
    return Uri.http(address, path).toString();
  }

  @override
  Future<String> signUrl(String url) async {
    var now = DateTime.now().millisecondsSinceEpoch;
    var headers = await httpHeaders();
    String str = "$now ${jsonEncode(headers)}";
    String sign = await encrypt(str);
    return "$url?_sign=$sign";
  }

  @override
  Future<StateResponse> tryGetServerStatus() async {
    if (!await AppConfig.isServerAddressConfig()) {
      return StateResponse.fromMap({
        "success": true,
        "message": "SERVER_ADDRESS_NOT_CONFIG",
      });
    }
    var state = await getServerStatus(await AppConfig.getServerAddress());
    if (state.success) {
      await AppConfig.saveServerStatus(state.data!);
    }
    return state;
  }

  @override
  Future<StateResponse> getServerStatus(String address) async {
    try {
      var url = Uri.http(address, "api/state");
      var headers = await httpHeaders();
      Response resp = await http.get(url, headers: headers);
      return StateResponse.fromJson(utf8.decode(resp.bodyBytes));
    } catch (e) {
      print(e);
      return StateResponse.fromMap(_exception);
    }
  }

  @override
  Future<LoginResponse> postLogin(
      {required String username, required String password}) async {
    try {
      var url = Uri.http(await AppConfig.getServerAddress(), "/api/user/login");
      var headers = await httpHeaders();
      Response resp = await http.post(url,
          headers: headers,
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

  @override
  Future<FileWalkResponse> postFileWalk(FileWalkRequest request) async {
    try {
      var url = Uri.http(await AppConfig.getServerAddress(), "/api/store/walk");
      Response resp = await http.post(url,
          headers: await httpHeaders(), body: request.toJson());
      return FileWalkResponse.fromJson(utf8.decode(resp.bodyBytes));
    } catch (e) {
      print(e);
      return FileWalkResponse.fromMap(_exception);
    }
  }

  @override
  Future<Result> postCreateFolder(String path, String folderName) async {
    try {
      var url = Uri.http(
          await AppConfig.getServerAddress(), "/api/store/createFolder");
      Response resp = await http.post(url,
          headers: await httpHeaders(),
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

  @override
  Future<Result> postDeleteFile(String fullPath) async {
    try {
      var url = Uri.http(
          await AppConfig.getServerAddress(), "/api/store/deleteFiles");
      Response resp = await http.post(url,
          headers: await httpHeaders(),
          body: jsonEncode({
            "paths": [fullPath],
          }));
      return Result.fromJson(utf8.decode(resp.bodyBytes));
    } catch (e) {
      print(e);
      return Result.fromMap(_exception);
    }
  }

  @override
  Future<Result> getFileExists(String fullPath) async {
    try {
      var url = Uri.http(await AppConfig.getServerAddress(),
          joinPath("/api/store/fileExists", fullPath));
      Response resp = await http.get(url, headers: await httpHeaders());
      return Result.fromJson(utf8.decode(resp.bodyBytes));
    } catch (e) {
      print(e);
      return Result.fromMap(_exception);
    }
  }

  @override
  Future<Result> uploadStream({
    required String dest,
    required String fileName,
    required int fileLastModified,
    required int size,
    required Stream<List<int>> stream,
  }) async {
    try {
      var uri = Uri.http(await AppConfig.getServerAddress(),
          joinPath("/api/store/upload", dest));
      var request = http.MultipartRequest("POST", uri)
        ..headers.addAll(await httpHeaders())
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

  @override
  Future<RangeData> rangeGetStatic(String path, int start, int end) async {
    try {
      var url = Uri.http(await AppConfig.getServerAddress(), path);
      Map<String, String> headers = {"Range": "bytes=$start-$end"};
      var authHeader = await httpHeaders();
      headers.addAll(authHeader);
      Response resp = await http.get(url, headers: headers);
      return RangeData(resp.headers[HttpHeaders.contentTypeHeader] ?? "UNKNOWN",
          resp.contentLength ?? 0, resp.bodyBytes);
    } catch (e) {
      print(e);
      return RangeData("UNKNOWN", 0, null);
    }
  }

  @override
  Future<Result> getCheckUpdates() async {
    try {
      var url =
          Uri.http(await AppConfig.getServerAddress(), "/api/checkupdates");
      Response resp = await http.get(url, headers: await httpHeaders());
      return Result.fromJson(utf8.decode(resp.bodyBytes));
    } catch (e) {
      print(e);
      return Result.fromMap(_exception);
    }
  }

  @override
  Future<Result> postTraceLog(String log) async {
    try {
      var url = Uri.http(await AppConfig.getServerAddress(), "/api/traceLog");
      var platform = platformName();
      var appVersion = AppConfig.currentAppVersion;
      var userName = await AppConfig.getLoginUserName() ?? "_";
      Response resp = await http.post(url,
          headers: await httpHeaders(),
          body: jsonEncode({
            "log": "$platform|$appVersion|$userName|$log",
          }));
      return Result.fromJson(utf8.decode(resp.bodyBytes));
    } catch (e) {
      print(e);
      return Result.fromMap(_exception);
    }
  }

  @override
  Future<Result> postToggleFavor(String fullPath, String name) async {
    try {
      var url = Uri.http(
          await AppConfig.getServerAddress(), "/api/store/toggleFavorite");
      Response resp = await http.post(url,
          headers: await httpHeaders(),
          body: jsonEncode({
            "name": name,
            "path": fullPath,
          }));
      return Result.fromJson(utf8.decode(resp.bodyBytes));
    } catch (e) {
      print(e);
      return Result.fromMap(_exception);
    }
  }

  String platformName() {
    if (kIsWeb) {
      return "web";
    }
    return "${Platform.operatingSystem},${Platform.operatingSystemVersion}";
  }
}
