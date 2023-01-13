import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _hostAddressKey = "hostAddress";

class AppState extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool preferenceComplete = false;
  String? hostAddress;

  init() async {
    if (!preferenceComplete) {
      _prefs = await SharedPreferences.getInstance();
      _initLoad();
      preferenceComplete = true;
    }
  }

  setHostAddress(String address) async {
    _prefs.setString(_hostAddressKey, address);
    hostAddress = address;
    notifyListeners();
  }

  void _initLoad() {
    hostAddress = _prefs.getString(_hostAddressKey);
    notifyListeners();
  }

  isHostAddressConfiged() {
    return hostAddress != null;
  }
}
