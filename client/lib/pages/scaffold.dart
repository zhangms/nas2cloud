import 'package:flutter/material.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/pages/app/file_home.dart';
import 'package:nas2cloud/pages/config.dart';
import 'package:nas2cloud/pages/login.dart';
import 'package:provider/provider.dart';

class ScaffoldPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    appState.init();

    if (!appStorage.isInitComplete()) {
      return Scaffold(
        body: Center(
          child: Text("Loading..."),
        ),
      );
    }
    if (!appStorage.isHostAddressConfiged()) {
      return ConfigPage();
    }
    if (!appStorage.isUserLogged()) {
      return LoginPage();
    }
    return FileHomePage();
  }
}
