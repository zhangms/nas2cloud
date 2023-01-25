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
  late String status;

  @override
  void initState() {
    super.initState();
    setInitStateValue();
  }

  void setInitStateValue() {
    status = "Loading...";
  }

  changeStatus(String value) {
    if (status != value) {
      setState(() {
        status = value;
      });
    }
  }

  Future<void> loadHostStatus() async {
    if (!AppStorage.isHostAddressConfiged()) {
      changeStatus("OK");
      return;
    }
    var hostState = await Api.getHostState(AppStorage.getHostAddress());
    if (hostState.success) {
      await AppStorage.saveHostState(hostState.data!);
      changeStatus("OK");
      return;
    }
    changeStatus(hostState.message ?? "HOST_STATUS_ERROR");
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    loadHostStatus();
    if ("OK" != status) {
      return Scaffold(
        body: Center(
          child: Text(status),
        ),
      );
    }
    if (!AppStorage.isHostAddressConfiged()) {
      return ConfigPage();
    }
    if (!AppStorage.isUserLogged()) {
      return LoginPage();
    }
    return FileHomePage();
    // return TestPage();
  }
}
