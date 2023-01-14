import 'package:shared_preferences/shared_preferences.dart';

class _Spu {
  late SharedPreferences _prefs;
  bool _complete = false;

  initSharedPreferences() async {
    if (!_complete) {
      _prefs = await SharedPreferences.getInstance();
      _complete = true;
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
