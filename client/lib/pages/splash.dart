import 'package:flutter/material.dart';
import '../api/app_config.dart';
import '../themes/app_nav.dart';

class SplashPage extends StatefulWidget {
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    loadServerStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  Future<void> loadServerStatus() async {
    var mock = await Future.value(const String.fromEnvironment("mock"));
    if (mock == "true") {
      setState(() {
        AppNav.goTest(context);
      });
      return;
    }
    var serverConfiged = await AppConfig.isServerAddressConfiged();
    if (!serverConfiged) {
      setState(() {
        AppNav.goServerAddressConfig(context);
      });
      return;
    }

    var userLogged = await AppConfig.isUserLogged();
    if (!userLogged) {
      setState(() {
        AppNav.goLogin(context);
      });
      return;
    }
    var home = await Future.value(true);
    if (home) {
      setState(() {
        AppNav.gohome(context);
      });
    }
  }
}
