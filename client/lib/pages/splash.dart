import 'package:flutter/material.dart';
import 'package:nas2cloud/api/app_config.dart';

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
    var serverConfiged = await AppConfig.isServerAddressConfiged();
    if (!serverConfiged) {
      setState(() {
        Navigator.of(context).pushReplacementNamed("/config");
      });
      return;
    }

    var userLogged = await AppConfig.isUserLogged();
    if (!userLogged) {
      setState(() {
        Navigator.of(context).pushReplacementNamed("/login");
      });
      return;
    }
    setState(() {
      Navigator.of(context).pushReplacementNamed("/home");
    });
  }
}
