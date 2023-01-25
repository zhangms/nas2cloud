import 'package:nas2cloud/api/dto/login_response/data.dart' as logindto;
import 'package:nas2cloud/api/dto/state_response/data.dart' as statedto;
import 'package:nas2cloud/utils/spu.dart';

class AppStorage {
  static const _hostAddressKey = "app.host.address";
  static const _hostStateKey = "app.host.state";
  static const _loginTokenKey = "app.login.token";

  static Future<bool> saveHostAddress(String address) async {
    return await spu.setString(_hostAddressKey, address);
  }

  static String getHostAddress() {
    return spu.getString(_hostAddressKey) ?? "";
  }

  static bool isHostAddressConfiged() {
    return spu.getString(_hostAddressKey) != null;
  }

  static Future<bool> saveHostState(statedto.Data state) async {
    return await spu.setString(_hostStateKey, state.toJson());
  }

  static statedto.Data? getHostState() {
    final String? str = spu.getString(_hostStateKey);
    return str == null ? null : statedto.Data.fromJson(str);
  }

  static Future<bool> saveUserLoginInfo(logindto.Data data) async {
    return await spu.setString(_loginTokenKey, data.toJson());
  }

  static Future<bool> deleteUserLoginInfo() async {
    return await spu.remove(_loginTokenKey);
  }

  static bool isUserLogged() {
    final String? tokenData = spu.getString(_loginTokenKey);
    return tokenData != null;
  }

  static logindto.Data? getUserLoginInfo() {
    final String? tokenData = spu.getString(_loginTokenKey);
    if (tokenData != null) {
      return logindto.Data.fromJson(tokenData);
    }
    return null;
  }

  static Future<void> clearHostAddress() async {
    await spu.remove(_hostStateKey);
    await spu.remove(_hostAddressKey);
  }

  static clearUserLogin() async {
    await spu.remove(_loginTokenKey);
    var keys = spu.getKeys();
    for (var key in keys) {
      if (key != _hostAddressKey) {
        await spu.remove(key);
      }
    }
  }
}
