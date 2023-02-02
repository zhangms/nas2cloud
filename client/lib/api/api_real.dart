import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/api/dto/file_walk_request.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file_walk_response.dart';
import 'package:nas2cloud/api/dto/login_response/login_response.dart';
import 'package:nas2cloud/api/dto/result.dart';
import 'package:nas2cloud/api/dto/state_response/state_response.dart';
import 'package:pointycastle/asymmetric/api.dart';

class ApiReal extends Api {
  ApiReal() : super.internal();

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

  static Future<Encrypter?> _getEncrypter() async {
    String? content = (await AppConfig.getHostState())?.publicKey;
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

  @override
  Future<String> encrypt(String data) async {
    var encrypter = await _getEncrypter();
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
    if (!await AppConfig.isHostAddressConfiged()) {
      return path;
    }
    String address = await AppConfig.getHostAddress();
    return Uri.http(address, path).toString();
  }

  @override
  Future<String> getStaticFileUrl(String path) async {
    if (!await AppConfig.isHostAddressConfiged()) {
      return path;
    }
    var state = await AppConfig.getHostState();
    var hostAddress = await AppConfig.getHostAddress();
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
  Future<StateResponse> getHostStateIfConfiged() async {
    if (!await AppConfig.isHostAddressConfiged()) {
      return StateResponse.fromMap({
        "success": true,
        "message": "HOST_NOT_CONFIGED",
      });
    }
    var state = await getHostState(await AppConfig.getHostAddress());
    if (state.success) {
      await AppConfig.saveHostState(state.data!);
    }
    return state;
  }

  @override
  Future<StateResponse> getHostState(String address) async {
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
      var url = Uri.http(await AppConfig.getHostAddress(), "/api/user/login");
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
  Future<FileWalkResponse> postFileWalk(FileWalkRequest reqeust) async {
    try {
      var url = Uri.http(await AppConfig.getHostAddress(), "/api/store/walk");
      Response resp = await http.post(url,
          headers: await httpHeaders(), body: reqeust.toJson());
      return FileWalkResponse.fromJson(utf8.decode(resp.bodyBytes));
    } catch (e) {
      print(e);
      return FileWalkResponse.fromMap(_exception);
    }
  }

  @override
  Future<Result> postCreateFolder(String path, String folderName) async {
    try {
      var url =
          Uri.http(await AppConfig.getHostAddress(), "/api/store/createFolder");
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
      var url =
          Uri.http(await AppConfig.getHostAddress(), "/api/store/deleteFiles");
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
      var url = Uri.http(await AppConfig.getHostAddress(),
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
      Result exists = await getFileExists(joinPath(dest, fileName));
      if (!exists.success) {
        return exists;
      }
      if (exists.message == "true") {
        return Result(success: false, message: "文件已存在");
      }
      var uri = Uri.http(await AppConfig.getHostAddress(),
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
      var url = Uri.http(await AppConfig.getHostAddress(), path);
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
}