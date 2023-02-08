import 'package:flutter/material.dart';

import '../../themes/widgets.dart';
import 'check_update.dart';
import 'setting_theme.dart';

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
