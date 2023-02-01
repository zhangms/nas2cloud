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

  Future<SharedPreferences> _get() async {
    if (await initSharedPreferences()) {
      return _prefs!;
    }
    throw ErrorDescription("initSharedPreferences error");
  }

  String _wrap(String key) {
    return "$_namespace$key";
  }

  Future<String?> getString(String key) async {
    var prefs = await _get();
    return prefs.getString(_wrap(key));
  }

  Future<bool> containsKey(String key) async {
    var prefs = await _get();
    return prefs.containsKey(_wrap(key));
  }

  Future<Set<String>> getKeys() async {
    var prefs = await _get();
    Set<String> ret = {};
    var keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith(_namespace)) {
        ret.add(key.substring(_namespace.length));
      }
    }
    return ret;
  }

  Future<List<String>?> getStringList(String key) async {
    var prefs = await _get();
    return prefs.getStringList(key);
  }

  Future<bool> setString(String key, String value) async {
    var prefs = await _get();
    return await prefs.setString(_wrap(key), value);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    var prefs = await _get();
    return prefs.setStringList(key, value);
  }

  Future<bool> setInt(String key, int value) async {
    var prefs = await _get();
    return await prefs.setInt(_wrap(key), value);
  }

  Future<int?> getInt(String key) async {
    var prefs = await _get();
    return prefs.getInt(_wrap(key));
  }

  Future<bool> setBool(String key, bool value) async {
    var prefs = await _get();
    return await prefs.setBool(_wrap(key), value);
  }

  Future<bool?> getBool(String key) async {
    var prefs = await _get();
    return prefs.getBool(_wrap(key));
  }

  Future<bool> remove(String key) async {
    var prefs = await _get();
    return await prefs.remove(_wrap(key));
  }
}
