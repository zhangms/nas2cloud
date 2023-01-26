import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_storage.dart';
import 'package:nas2cloud/api/dto/state_response/state_response.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/pages/app/file_home.dart';
import 'package:nas2cloud/pages/config.dart';
import 'package:nas2cloud/pages/login.dart';
import 'package:provider/provider.dart';

class ScaffoldPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    return FutureBuilder<Object>(
        future: Api.getHostStateIfConfiged(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return buildLoading();
          }
          return getPage(snapshot.data!);
        });
  }

  Widget buildLoading() {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget errorPage(String? message) {
    return Scaffold(
      body: Center(child: Text(message ?? "ERROR")),
    );
  }

  Widget getPage(dynamic response) {
    StateResponse resp = response;
    if (resp.message == "HOST_NOT_CONFIGED") {
      return ConfigPage();
    }
    if (!resp.success) {
      return errorPage(resp.message);
    }
    if (!AppStorage.isUserLogged()) {
      return LoginPage();
    }
    return FileHomePage();
  }
}
