import 'package:flutter/material.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/components/setting/check_update.dart';
import 'package:nas2cloud/components/setting/event_change_theme.dart';
import 'package:nas2cloud/components/setting/setting_theme.dart';
import 'package:nas2cloud/event/bus.dart';
import 'package:nas2cloud/themes/app_nav.dart';
import 'package:nas2cloud/themes/widgets.dart';

class SettingPage extends StatefulWidget {
  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  void initState() {
    super.initState();
    eventBus.on<EventChangeTheme>().listen((event) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: buildBody(),
    );
  }

  buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => AppNav.pop(context),
      ),
      title: AppWidgets.getAppNameText(),
    );
  }

  buildBody() {
    return SafeArea(
      child: FutureBuilder<_SettingPageModel>(
          future: getPageModel(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return AppWidgets.getPageLoadingView();
            }
            return ListView(
              children: [
                SettingThemeWidget(snapshot.data!.theme),
                Divider(),
                CheckUpdateWidget(),
              ],
            );
          }),
    );
  }

  Future<_SettingPageModel> getPageModel() async {
    return _SettingPageModel(
      theme: await AppConfig.getThemeSetting(),
    );
  }
}

class _SettingPageModel {
  final int theme;

  _SettingPageModel({required this.theme});
}
