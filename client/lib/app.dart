import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/login_response/data.dart' as logintoken;

import 'utils/spu.dart';

class AppState extends ChangeNotifier {
  init() async {
    await spu.init();
    notifyListeners();
  }

  void saveHostAddress(String address) async {
    await spu.saveHostAddress(address);
    notifyListeners();
  }

  void onLoginSuccess(logintoken.Data data) async {
    await spu.saveLoginToken(data.toJson());
    notifyListeners();
  }
}
