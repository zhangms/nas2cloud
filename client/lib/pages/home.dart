import 'package:flutter/material.dart';
import 'package:nas2cloud/utils/spu.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import 'config.dart';
import 'login.dart';


class HomePage extends StatelessWidget {
  getPage(AppState appState) {
    appState.init();
    if (!spu.isComplete()) {
      return Text("loading...");
    }
    if (!spu.isHostAddressConfiged()) {
      return ConfigPage();
    }
    if (!spu.isUserLogged()) {
      return LoginPage();
    }
    return Placeholder();
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
