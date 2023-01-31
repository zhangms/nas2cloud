import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/api/dto/state_response/state_response.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/pages/config.dart';
import 'package:nas2cloud/pages/login.dart';
import 'package:nas2cloud/pages/test.dart';
import 'package:nas2cloud/themes/widgets.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    return FutureBuilder<StateResponse>(
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
      appBar: buildAppBar(),
      body: AppWidgets.getPageLoadingView(),
    );
  }

  buildAppBar() {
    return AppBar(
      leading: Icon(Icons.menu),
      title: FutureBuilder<String>(
          future: AppConfig.getAppName(),
          builder: (context, snapshot) {
            return Text(snapshot.hasData ? snapshot.data! : "Nas2coud");
          }),
    );
  }

  Widget errorPage(String? message) {
    return Scaffold(
      appBar: buildAppBar(),
      body: AppWidgets.getPageErrorView(message ?? "ERROR"),
    );
  }

  Widget getPage(StateResponse resp) {
    // if (1 == 1) {
    //   return TestPage();
    // }
    if (resp.message == "HOST_NOT_CONFIGED") {
      return ConfigPage();
    }
    if (!resp.success) {
      return errorPage(resp.message);
    }
    if (resp.data?.userName?.isEmpty ?? true) {
      AppConfig.clearUserLogin();
      return LoginPage();
    }
    // return FileHomePage();
    return TestPage();
  }
}
