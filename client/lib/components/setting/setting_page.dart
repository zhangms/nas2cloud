import 'package:flutter/material.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/themes/widgets.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatefulWidget {
  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late AppState appState;

  @override
  Widget build(BuildContext context) {
    appState = context.watch<AppState>();
    return Scaffold(
      appBar: buildAppBar(),
      body: buildBody(),
    );
  }

  buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop();
        },
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
                buildAutoUploadSetting(snapshot.data!),
                ...buildColorSetting(snapshot.data!),
              ],
            );
          }),
    );
  }

  Future<_SettingPageModel> getPageModel() async {
    return _SettingPageModel(
      theme: await AppConfig.getThemeSetting(),
      autoUploaWlan: await AppConfig.getAutouploadWlanSetting(),
    );
  }

  List<Widget> buildColorSetting(_SettingPageModel data) {
    return [
      ListTile(
        title: Text("外观"),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ChoiceChip(
            label: Text("跟随系统"),
            selected: data.theme == AppConfig.themeFollowSystem,
            onSelected: (value) {
              appState.changeTheme(AppConfig.themeFollowSystem);
            },
          ),
          ChoiceChip(
            label: Text("浅色模式"),
            selected: data.theme == AppConfig.themeLight,
            onSelected: (value) {
              appState.changeTheme(AppConfig.themeLight);
            },
          ),
          ChoiceChip(
            label: Text("深色模式"),
            selected: data.theme == AppConfig.themeDark,
            onSelected: (value) {
              appState.changeTheme(AppConfig.themeDark);
            },
          ),
        ],
      ),
    ];
  }

  buildAutoUploadSetting(_SettingPageModel data) {
    return ListTile(
      title: Text("仅WLAN下自动上传"),
      trailing: Switch(
          value: data.autoUploaWlan,
          onChanged: (value) {
            AppConfig.setAutouploadWlanSetting(value);
            setState(() {});
          }),
    );
  }
}

class _SettingPageModel {
  final int theme;
  final bool autoUploaWlan;

  _SettingPageModel({required this.theme, required this.autoUploaWlan});
}
