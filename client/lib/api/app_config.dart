import 'package:nas2cloud/api/dto/login_response/data.dart' as logindto;
import 'package:nas2cloud/api/dto/state_response/data.dart' as statedto;
import 'package:nas2cloud/utils/spu.dart';

class AppConfig {
  static const appId = "com.zms.nas2cloud";
  static const _hostAddressKey = "app.host.address";
  static const _hostStateKey = "app.host.state";
  static const _loginTokenKey = "app.login.token";

  static Future<bool> saveHostAddress(String address) async {
    return await Spu().setString(_hostAddressKey, address);
  }

  static Future<String> getHostAddress() async {
    return await Spu().getString(_hostAddressKey) ?? "";
  }

  static Future<bool> isHostAddressConfiged() async {
    return (await Spu().getString(_hostAddressKey)) != null;
  }

  static Future<bool> saveHostState(statedto.Data state) async {
    return await Spu().setString(_hostStateKey, state.toJson());
  }

  static Future<statedto.Data?> getHostState() async {
    final String? str = await Spu().getString(_hostStateKey);
    return str == null ? null : statedto.Data.fromJson(str);
  }

  static statedto.Data? getHostStateSync() {
    statedto.Data? ret;
    Future.value(getHostState()).then((value) => ret = value);
    return ret;
  }

  static Future<String> getAppName() async {
    return (await getHostState())?.appName ?? "Nas2cloud";
  }

  static String getAppNameSync() {
    String? ret;
    Future.value(getAppName()).then((value) => ret = value);
    return ret!;
  }

  static Future<bool> saveUserLoginInfo(logindto.Data data) async {
    return await Spu().setString(_loginTokenKey, data.toJson());
  }

  static Future<bool> deleteUserLoginInfo() async {
    return await Spu().remove(_loginTokenKey);
  }

  static Future<bool> isUserLogged() async {
    final String? tokenData = await Spu().getString(_loginTokenKey);
    return tokenData != null;
  }

  static Future<logindto.Data?> getUserLoginInfo() async {
    final String? tokenData = await Spu().getString(_loginTokenKey);
    if (tokenData != null) {
      return logindto.Data.fromJson(tokenData);
    }
    return null;
  }

  static Future<void> clearHostAddress() async {
    await Spu().remove(_hostStateKey);
    await Spu().remove(_hostAddressKey);
  }

  static clearUserLogin() async {
    await Spu().remove(_loginTokenKey);
    var keys = await Spu().getKeys();
    for (var key in keys) {
      if (key != _hostAddressKey) {
        await Spu().remove(key);
      }
    }
  }
}
