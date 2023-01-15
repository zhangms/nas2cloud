import 'package:flutter/material.dart';
import 'package:nas2cloud/pages/app/home.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import 'config.dart';
import 'login.dart';

class ScaffoldPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    appState.init();

    if (!appStorage.isInitComplete()) {
      return Scaffold(
        body: Text("Loading..."),
      );
    }
    if (!appStorage.isHostAddressConfiged()) {
      return ConfigPage();
    }
    if (!appStorage.isUserLogged()) {
      return LoginPage();
    }
    return HomePage();
  }
}
