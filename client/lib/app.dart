import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/login_response/data.dart' as logindto;
import 'package:nas2cloud/api/state_response/data.dart' as statedto;
import 'package:nas2cloud/utils/spu.dart';

class _AppStorage {
  static const _hostAddressKey = "hostAddress";
  static const _hostStateKey = "hostState";
  static const _loginTokenKey = "loginToken";

  Future<bool> init() async {
    return await spu.initSharedPreferences();
  }

  Future<bool> saveHostAddress(String address) async {
    return await spu.get().setString(_hostAddressKey, address);
  }

  String getHostAddress() {
    return spu.get().getString(_hostAddressKey) ?? "";
  }

  bool isHostAddressConfiged() {
    return spu.get().getString(_hostAddressKey) != null;
  }

  Future<bool> saveHostState(statedto.Data state) async {
    return await spu.get().setString(_hostStateKey, state.toJson());
  }

  statedto.Data? getHostState() {
    final String? str = spu.get().getString(_hostStateKey);
    return str == null ? null : statedto.Data.fromJson(str);
  }

  Future<bool> saveUserLoginInfo(logindto.Data data) async {
    return await spu.get().setString(_loginTokenKey, data.toJson());
  }

  Future<bool> deleteUserLoginInfo() async {
    return await spu.get().remove(_loginTokenKey);
  }

  bool isUserLogged() {
    final String? tokenData = spu.get().getString(_loginTokenKey);
    return tokenData != null;
  }

  logindto.Data? getUserInfo() {
    final String? tokenData = spu.get().getString(_loginTokenKey);
    if (tokenData != null) {
      return logindto.Data.fromJson(tokenData);
    }
    return null;
  }
}

var appStorage = _AppStorage();

class AppState extends ChangeNotifier {
  updateHostState(String address, statedto.Data data) async {
    await appStorage.saveHostAddress(address);
    await appStorage.saveHostState(data);
    notifyListeners();
  }

  updateLoginInfo(logindto.Data data) async {
    await appStorage.saveUserLoginInfo(data);
    notifyListeners();
  }
}
