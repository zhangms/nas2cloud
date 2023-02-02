import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/dto/state_response/state_response.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/components/files/file_home.dart';
import 'package:nas2cloud/pages/config.dart';
import 'package:nas2cloud/pages/login.dart';
import 'package:nas2cloud/themes/widgets.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    return FutureBuilder<StateResponse>(
        future: Api().getHostStateIfConfiged(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
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
      title: AppWidgets.getAppNameText(useDefault: true),
    );
  }

  Widget errorPage(String? message) {
    return Scaffold(
      appBar: buildAppBar(),
      body: AppWidgets.getPageErrorView(message ?? "ERROR"),
    );
  }

  Widget getPage(StateResponse resp) {
    if (resp.message == "HOST_NOT_CONFIGED") {
      return ConfigPage();
    }
    if (!resp.success) {
      return errorPage(resp.message);
    }
    if (resp.data?.userName?.isEmpty ?? true) {
      return LoginPage();
    }
    return FileHomePage();
  }
}
