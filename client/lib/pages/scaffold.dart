import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_storage.dart';
import 'package:nas2cloud/api/uploader/file_uploder.dart';
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
  String status = "Loading...";

  @override
  void initState() {
    super.initState();
    loadHostStatus();
  }

  Future<void> loadHostStatus() async {
    if (!AppStorage.isHostAddressConfiged()) {
      setState(() {
        status = "OK";
      });
      return;
    }
    var hostState = await Api.getHostState(AppStorage.getHostAddress());
    if (hostState.success) {
      setState(() {
        status = "OK";
      });
      return;
    }
    setState(() {
      status = hostState.message ?? "HOST_STATUS_ERROR";
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
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
    FileUploader.get();
    return FileHomePage();
  }
}
