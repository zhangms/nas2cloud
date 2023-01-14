import 'package:flutter/material.dart';
import 'package:nas2cloud/pages/app/app.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import 'config.dart';
import 'login.dart';

class ScaffoldPage extends StatelessWidget {
  getPage(AppState appState) {
    if (!appState.isInited()) {
      return Text("");
    }
    if (!appStorage.isHostAddressConfiged()) {
      return ConfigPage();
    }

    if (!appStorage.isUserLogged()) {
      return LoginPage();
    }
    return AppPage();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    appState.init();
    return getPage(appState);
  }
}
