import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/app_storage.dart';
import 'package:nas2cloud/api/dto/login_response/data.dart' as logindto;
import 'package:nas2cloud/api/dto/state_response/data.dart' as statedto;

class AppState extends ChangeNotifier {
  updateHostState(String address, statedto.Data data) async {
    await AppStorage.saveHostAddress(address);
    await AppStorage.saveHostState(data);
    notifyListeners();
  }

  clearHostAddress() async {
    await AppStorage.clearHostAddress();
    notifyListeners();
  }

  login(logindto.Data data) async {
    await AppStorage.saveUserLoginInfo(data);
    notifyListeners();
  }

  Future<void> logout() async {
    await AppStorage.clearUserLogin();
    notifyListeners();
  }
}
