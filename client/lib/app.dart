import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/api/dto/state_response/data.dart' as statedto;
import 'package:nas2cloud/components/uploader/file_uploder.dart';

class AppState extends ChangeNotifier {
  updateHostState(String address, statedto.Data data) async {
    await AppConfig.saveHostAddress(address);
    await AppConfig.saveServerStatus(data);
    notifyListeners();
  }

  Future<void> logout() async {
    await FileUploader.platform.cancelAndClearAll();
    await AppConfig.clearUserLogin();
    notifyListeners();
  }

  Future<void> changeTheme(int theme) async {
    await AppConfig.setThemeSetting(theme);
    notifyListeners();
  }
}
