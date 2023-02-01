import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/api/dto/login_response/data.dart' as logindto;
import 'package:nas2cloud/api/dto/state_response/data.dart' as statedto;
import 'package:nas2cloud/components/uploader/file_uploder.dart';

class AppState extends ChangeNotifier {
  updateHostState(String address, statedto.Data data) async {
    await AppConfig.saveHostAddress(address);
    await AppConfig.saveHostState(data);
    notifyListeners();
  }

  clearHostAddress() async {
    await AppConfig.clearHostAddress();
    notifyListeners();
  }

  login(logindto.Data data) async {
    await AppConfig.saveUserLoginInfo(data);
    notifyListeners();
  }

  Future<void> logout() async {
    await FileUploader.platform.cancelAndClearAll();
    await AppConfig.clearUserLogin();
    notifyListeners();
  }
}
