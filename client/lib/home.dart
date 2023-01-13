import 'package:flutter/material.dart';
import 'package:nas2cloud/config.dart';
import 'package:nas2cloud/login.dart';
import 'package:provider/provider.dart';

import 'app.dart';

class HomePage extends StatelessWidget {
  getPage(AppState appState) {
    appState.init();
    if (!appState.preferenceComplete) {
      return Text("loading...");
    }
    if (!appState.isHostAddressConfiged()) {
      return ConfigPage();
    }
    return LoginPage();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    appState.init();
    return Scaffold(
      body: getPage(appState),
    );
  }
}
