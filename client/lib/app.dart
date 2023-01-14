import 'package:flutter/foundation.dart';

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
}
