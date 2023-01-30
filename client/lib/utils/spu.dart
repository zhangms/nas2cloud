import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _namespace = "nas2cloud.";

class Spu {
  static Spu _instance = Spu._private();

  factory Spu() => _instance;

  Spu._private();

  SharedPreferences? _prefs;

  Future<bool> initSharedPreferences() async {
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
        print("initSharedPreferences complete");
      }
      return true;
    } catch (e) {
      print("initSharedPreferences error $e");
      return false;
    }
  }

  String _wrap(String key) {
    return "$_namespace$key";
  }

  Future<String?> getString(String key) async {
    if (await initSharedPreferences()) {
      return _prefs!.getString(_wrap(key));
    }
    throw ErrorDescription("initSharedPreferences error");
  }

  Future<bool> containsKey(String key) async {
    if (await initSharedPreferences()) {
      return _prefs!.containsKey(_wrap(key));
    }
    throw ErrorDescription("initSharedPreferences error");
  }

  Future<Set<String>> getKeys() async {
    if (await initSharedPreferences()) {
      Set<String> ret = {};
      var keys = _prefs!.getKeys();
      for (var key in keys) {
        if (key.startsWith(_namespace)) {
          ret.add(key.substring(_namespace.length));
        }
      }
      return ret;
    }
    throw ErrorDescription("initSharedPreferences error");
  }

  Future<List<String>?> getStringList(String key) async {
    if (await initSharedPreferences()) {
      return _prefs!.getStringList(key);
    }
    throw ErrorDescription("initSharedPreferences error");
  }

  Future<bool> setString(String key, String value) async {
    if (await initSharedPreferences()) {
      return await _prefs!.setString(_wrap(key), value);
    }
    throw ErrorDescription("initSharedPreferences error");
  }

  Future<bool> setStringList(String key, List<String> value) async {
    if (await initSharedPreferences()) {
      return _prefs!.setStringList(key, value);
    }
    throw ErrorDescription("initSharedPreferences error");
  }

  Future<bool> setInt(String key, int value) async {
    if (await initSharedPreferences()) {
      return await _prefs!.setInt(_wrap(key), value);
    }
    throw ErrorDescription("initSharedPreferences error");
  }

  Future<int?> getInt(String key) async {
    if (await initSharedPreferences()) {
      return _prefs!.getInt(_wrap(key));
    }
    throw ErrorDescription("initSharedPreferences error");
  }

  Future<bool> remove(String key) async {
    if (await initSharedPreferences()) {
      return await _prefs!.remove(_wrap(key));
    }
    throw ErrorDescription("initSharedPreferences error");
  }
}
