import 'package:flutter/material.dart';
import 'package:nas2cloud/components/setting/check_update.dart';
import 'package:nas2cloud/components/setting/setting_theme.dart';
import 'package:nas2cloud/themes/widgets.dart';

class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: buildBody(),
    );
  }

  buildAppBar(BuildContext context) {
    return AppBar(
      leading: AppWidgets.appBarArrowBack(context),
      title: AppWidgets.getAppNameText(),
    );
  }

  buildBody() {
    return SafeArea(
      child: ListView(
        children: [
          SettingThemeWidget(),
          Divider(),
          CheckUpdateWidget(),
        ],
      ),
    );
  }
}
