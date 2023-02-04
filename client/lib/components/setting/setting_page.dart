import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/api/dto/result.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/components/downloader/downloader.dart';
import 'package:nas2cloud/themes/app_nav.dart';
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
                ...buildColorSetting(snapshot.data!),
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

  List<Widget> buildColorSetting(_SettingPageModel data) {
    return [
      ListTile(
        title: Text("外观模式"),
      ),
      ListTile(
        title: Row(
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
      ),
      Divider(),
      buildCheckUpdates(),
    ];
  }

  static const String noUpdates = "no_updates";

  buildCheckUpdates() {
    return FutureBuilder<Result>(
        future: Api().getCheckUpdates(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListTile(
              title: Text("更新检查中..."),
            );
          }
          var updates = _getUpdates(snapshot.data!);
          if (!updates.hasUpdate) {
            return ListTile(
              title: Text("已是最新版本"),
            );
          }
          return ListTile(
            title: Text("下载最新版本"),
            trailing: Icon(Icons.navigate_next),
            onTap: () => downloadUpdate(updates),
          );
        });
  }

  _Update _getUpdates(Result result) {
    if (!result.success) {
      return _Update("", "", false);
    }
    var msg = result.message ?? noUpdates;
    if (msg == noUpdates) {
      return _Update("", "", false);
    }
    var list = msg.split(";");
    if (list.length < 2 || list[1] == AppConfig.currentAppVersion) {
      return _Update("", "", false);
    }
    return _Update(list[0], list[1], true);
  }

  downloadUpdate(_Update updates) async {
    Downloader.platform
        .download(await Api().getStaticFileUrl(updates.downlink));
    setState(() {
      AppWidgets.showMessage(context, "已开始下载，从状态栏查看下载进度");
    });
  }
}

class _Update {
  String downlink;
  String version;
  bool hasUpdate;

  _Update(this.downlink, this.version, this.hasUpdate);
}

class _SettingPageModel {
  final int theme;

  _SettingPageModel({required this.theme});
}
