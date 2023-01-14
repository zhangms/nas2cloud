import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/login_response/data.dart' as logintoken;
import 'package:nas2cloud/api/state_response/data.dart' as hoststate;
import 'package:nas2cloud/api/state_response/state_response.dart';

import 'utils/spu.dart';

class _AppStorage {
  static const _hostAddressKey = "hostAddress";
  static const _hostStateKey = "hostState";
  static const _loginTokenKey = "loginToken";

  String getHostAddress() {
    return spu.get().getString(_hostAddressKey) ?? "";
  }

  bool isHostAddressConfiged() {
    return spu.get().getString(_hostAddressKey) != null;
  }

  bool isUserLogged() {
    final String? tokenData = spu.get().getString(_loginTokenKey);
    return tokenData != null;
  }

  Future<bool> saveHostAddress(String address) async {
    return await spu.get().setString(_hostAddressKey, address);
  }

  Future<bool> saveLoginData(logintoken.Data data) async {
    return await spu.get().setString(_loginTokenKey, data.toJson());
  }

  Future<bool> updateHostState(StateResponse state) async {
    if (state.success && state.data != null) {
      return await spu.get().setString(_hostStateKey, state.data!.toJson());
    }
    return false;
  }

  hoststate.Data? getHostState() {
    final String? str = spu.get().getString(_hostStateKey);
    return str == null ? null : hoststate.Data.fromJson(str);
  }
}

var appStorage = _AppStorage();

class AppState extends ChangeNotifier {
  init() async {
    if (!spu.isComplete()) {
      await spu.initSharedPreferences();
      if (appStorage.isHostAddressConfiged()) {
        var state = await api.getHostState(appStorage.getHostAddress());
        await appStorage.updateHostState(state);
      }
      notifyListeners();
    }
  }

  bool isInited() {
    return spu.isComplete();
  }

  void saveHostAddress(String address) async {
    await appStorage.saveHostAddress(address);
    notifyListeners();
  }

  void onLoginSuccess(logintoken.Data data) async {
    await appStorage.saveLoginData(data);
    notifyListeners();
  }
}
