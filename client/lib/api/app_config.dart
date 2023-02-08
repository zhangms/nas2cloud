import 'package:flutter/material.dart';

import '../components/background/background.dart';
import '../components/downloader/downloader.dart';
import '../components/notification/notification.dart';
import '../components/uploader/auto_uploader.dart';
import '../components/uploader/file_uploder.dart';
import '../utils/spu.dart';
import 'dto/login_response/data.dart' as logindto;
import 'dto/state_response/data.dart' as statedto;

class AppConfig {
  static const currentAppVersion = "v2.9.5";

  static const defaultAppName = "Nas2cloud";

  static const themeFollowSystem = 0;
  static const themeLight = 1;
  static const themeDark = 2;

  static const appId = "com.zms.nas2cloud";
  static const _themeKey = "app.theme";
  static const _serverAddressKey = "app.server.address";
  static const _serverStatusKey = "app.server.status";
  static const _loginTokenKey = "app.login.token";
  static const _useMockApiKey = "app.usemockapi";

  static bool _useMockApi = false;

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Spu().initSharedPreferences();
    await BackgroundProcessor().initialize();
    await LocalNotification.platform.initialize();
    await Downloader.platform.initialize();
    await FileUploader.platform.initialize();
    await AutoUploader().initialize();
    _useMockApi = (await Spu().getBool(_useMockApiKey)) ?? false;
  }

  static Future<void> useMockApi(bool mock) async {
    _useMockApi = mock;
    if (mock) {
      await Spu().setBool(_useMockApiKey, mock);
    } else {
      await Spu().remove(_useMockApiKey);
    }
  }

  static bool isUseMockApi() {
    return _useMockApi;
  }

  static Future<bool> saveServerAddress(String address) async {
    return await Spu().setString(_serverAddressKey, address);
  }

  static Future<String> getServerAddress() async {
    return await Spu().getString(_serverAddressKey) ?? "";
  }

  static Future<bool> isServerAddressConfiged() async {
    return (await Spu().getString(_serverAddressKey)) != null;
  }

  static Future<bool> saveServerStatus(statedto.Data state) async {
    return await Spu().setString(_serverStatusKey, state.toJson());
  }

  static Future<statedto.Data?> getServerStatus() async {
    final String? str = await Spu().getString(_serverStatusKey);
    return str == null ? null : statedto.Data.fromJson(str);
  }

  static Future<String> getAppName() async {
    return (await getServerStatus())?.appName ?? defaultAppName;
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

  static Future<String?> getLoginUserName() async {
    var info = await getUserLoginInfo();
    return info?.username;
  }

  static Future<void> clearServerAddress() async {
    await clearServerStatus();
    await clearUserLogin();
    await Spu().remove(_serverAddressKey);
  }

  static Future<void> clearServerStatus() async {
    await Spu().remove(_serverStatusKey);
  }

  static Future<void> clearUserLogin() async {
    await Spu().remove(_useMockApiKey);
    await Spu().remove(_themeKey);
    await Spu().remove(_serverStatusKey);
    await Spu().remove(_loginTokenKey);
  }

  static Future<int> getThemeSetting() async {
    return (await Spu().getInt(_themeKey)) ?? themeFollowSystem;
  }

  static Future<bool> setThemeSetting(int theme) async {
    return await Spu().setInt(_themeKey, theme);
  }
}
