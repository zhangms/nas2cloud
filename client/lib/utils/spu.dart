import 'package:shared_preferences/shared_preferences.dart';

class _Spu {
  SharedPreferences? _prefs;
  bool _complete = false;

  Future<bool> initSharedPreferences() async {
    try {
      if (!_complete) {
        _prefs = await SharedPreferences.getInstance();
        _complete = true;
      }
      return _complete;
    } catch (e) {
      print(e);
      return false;
    }
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  bool? containsKey(String key) {
    return _prefs?.containsKey(key);
  }

  Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  isComplete() {
    return _complete;
  }
}

var spu = _Spu();
