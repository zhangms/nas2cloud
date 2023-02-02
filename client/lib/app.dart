import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/app_config.dart';

class AppState extends ChangeNotifier {
  Future<void> changeTheme(int theme) async {
    await AppConfig.setThemeSetting(theme);
    notifyListeners();
  }
}
