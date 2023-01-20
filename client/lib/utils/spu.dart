import 'package:shared_preferences/shared_preferences.dart';

class _Spu {
  late SharedPreferences _prefs;
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

  SharedPreferences get() {
    return _prefs;
  }

  isComplete() {
    return _complete;
  }
}

var spu = _Spu();
