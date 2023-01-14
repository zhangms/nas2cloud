import 'package:shared_preferences/shared_preferences.dart';

class _Spu {
  static const _hostAddressKey = "hostAddress";

  late SharedPreferences _prefs;
  bool _complete = false;

  init() async {
    if (!_complete) {
      _prefs = await SharedPreferences.getInstance();
      _complete = true;
    }
  }

  isComplete() {
    return _complete;
  }

  bool isHostAddressConfiged() {
    return _prefs.getString(_hostAddressKey) != null;
  }

  Future<bool> saveHostAddress(String address) {
    return _prefs.setString(_hostAddressKey, address);
  }

  String? getHostAddress() {
    return _prefs.getString(_hostAddressKey);
  }
}

var spu = _Spu();
