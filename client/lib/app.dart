import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/login_response/data.dart' as logindto;
import 'package:nas2cloud/api/state_response/data.dart' as statedto;
import 'package:nas2cloud/api/state_response/state_response.dart';

import 'utils/spu.dart';

class _AppStorage {
  static const _hostAddressKey = "hostAddress";
  static const _hostStateKey = "hostState";
  static const _loginTokenKey = "loginToken";

  Future<void> init() async {
    if (!spu.isComplete()) {
      await spu.initSharedPreferences();
    }
  }

  bool isInitComplete() {
    return spu.isComplete();
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

  bool isUserLogged() {
    final String? tokenData = spu.get().getString(_loginTokenKey);
    return tokenData != null;
  }
}

var appStorage = _AppStorage();

class AppState extends ChangeNotifier {
  Future<void> init() async {
    if (appStorage.isInitComplete()) {
      return;
    }
    await appStorage.init();
    if (appStorage.isHostAddressConfiged()) {
      StateResponse resp = await api.getHostState(appStorage.getHostAddress());
      if (resp.success) {
        appStorage.saveHostState(resp.data!);
      }
    }
    notifyListeners();
  }

  void updateHostState(String address, statedto.Data data) async {
    await appStorage.saveHostAddress(address);
    await appStorage.saveHostState(data);
    notifyListeners();
  }

  void updateLoginInfo(logindto.Data data) async {
    await appStorage.saveUserLoginInfo(data);
    notifyListeners();
  }
}
