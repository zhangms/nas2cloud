import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_storage.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/pages/app/file_home.dart';
import 'package:nas2cloud/pages/config.dart';
import 'package:nas2cloud/pages/login.dart';
import 'package:provider/provider.dart';

class ScaffoldPage extends StatefulWidget {
  @override
  State<ScaffoldPage> createState() => _ScaffoldPageState();
}

class _ScaffoldPageState extends State<ScaffoldPage> {
  String initStatus = "Loading...";

  Future<String> init() async {
    var complete = await appStorage.init();
    if (!complete) {
      return "ERROR";
    }
    if (!appStorage.isHostAddressConfiged()) {
      return "OK";
    }
    var hostStatus = await api.getHostState(appStorage.getHostAddress());
    if (!hostStatus.success) {
      return hostStatus.message ?? "ERROR";
    }
    appStorage.saveHostState(hostStatus.data!);
    var userInfo = appStorage.getUserInfo();
    if (userInfo == null) {
      return "OK";
    }
    if (userInfo.username == hostStatus.data!.userName) {
      return "OK";
    }
    appStorage.deleteUserLoginInfo();
    return "OK";
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    init().then((value) {
      if (value != initStatus) {
        setState(() {
          initStatus = value;
        });
      }
    });
    if ("OK" != initStatus) {
      return Scaffold(
        body: Center(
          child: Text(initStatus),
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
