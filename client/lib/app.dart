import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/app_storage.dart';
import 'package:nas2cloud/api/dto/login_response/data.dart' as logindto;
import 'package:nas2cloud/api/dto/state_response/data.dart' as statedto;

class AppState extends ChangeNotifier {
  updateHostState(String address, statedto.Data data) async {
    await appStorage.saveHostAddress(address);
    await appStorage.saveHostState(data);
    notifyListeners();
  }

  clearHostAddress() async {
    appStorage.clearHostAddress();
    notifyListeners();
  }

  updateLoginInfo(logindto.Data data) async {
    await appStorage.saveUserLoginInfo(data);
    notifyListeners();
  }
}
