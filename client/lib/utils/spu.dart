import 'package:shared_preferences/shared_preferences.dart';

const _namespace = "nas2cloud.";

class _Spu {
  late final SharedPreferences _prefs;
  bool _complete = false;

  Future<bool> initSharedPreferences() async {
    try {
      if (!_complete) {
        _prefs = await SharedPreferences.getInstance();
        _complete = true;
      }
      print("initSharedPreferences complete");
      return _complete;
    } catch (e) {
      print("initSharedPreferences error $e");
      return false;
    }
  }

  String _wrap(String key) {
    return "$_namespace$key";
  }

  String? getString(String key) {
    return _prefs.getString(_wrap(key));
  }

  bool containsKey(String key) {
    return _prefs.containsKey(_wrap(key));
  }

  Set<String> getKeys() {
    Set<String> ret = {};
    var keys = _prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith(_namespace)) {
        ret.add(key.substring(_namespace.length));
      }
    }
    return ret;
  }

  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(_wrap(key), value);
  }

  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(_wrap(key), value);
  }

  int? getInt(String key) {
    return _prefs.getInt(_wrap(key));
  }

  Future<bool> remove(String key) async {
    return await _prefs.remove(_wrap(key));
  }

  isComplete() {
    return _complete;
  }
}

var spu = _Spu();
