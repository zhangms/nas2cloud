import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/components/setting/setting_page.dart';
import 'package:nas2cloud/components/uploader/pages/page_auto_upload.dart';
import 'package:nas2cloud/themes/widgets.dart';
import 'package:provider/provider.dart';

class HomeDrawer extends StatefulWidget {
  final Function logoutCallback;

  HomeDrawer(this.logoutCallback);

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  late AppState appState;

  @override
  Widget build(BuildContext context) {
    appState = context.watch<AppState>();
    return FutureBuilder<_DrawerModel>(
        future: getDrawerModel(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return buildDrawer(snapshot.data!);
          }
          return AppWidgets.getPageLoadingView();
        });
  }

  Widget buildDrawer(_DrawerModel drawer) {
    Widget avatar = CircleAvatar(
      child: FlutterLogo(),
    );
    if (drawer.userAvatar != null) {
      avatar = CircleAvatar(
        backgroundImage:
            NetworkImage(drawer.userAvatar!, headers: drawer.httpHeaders),
      );
    }
    return ListView(
      children: [
        UserAccountsDrawerHeader(
          accountName: Text((drawer.userName ?? "").toUpperCase()),
          accountEmail: Text(drawer.appName ?? ""),
          currentAccountPicture: avatar,
        ),
        buildPhoto(),
        buildAutoUpload(),
        buildSetting(),
        Divider(),
        buildLogout(),
      ],
    );
  }

  buildSetting() {
    return ListTile(
      title: Text("设置"),
      leading: const Icon(Icons.settings),
      onTap: () {
        Navigator.pop(context);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SettingPage(),
          ),
        );
      },
    );
  }

  ListTile buildLogout() {
    return ListTile(
      title: Text("退出登录"),
      leading: const Icon(Icons.logout),
      onTap: () {
        Navigator.pop(context);
        showDialog(
            context: context,
            builder: ((context) {
              return AlertDialog(
                title: Text("退出登录"),
                content: Text("确认退出？"),
                actions: [
                  TextButton(
                      onPressed: (() {
                        Navigator.of(context).pop();
                      }),
                      child: Text("取消")),
                  TextButton(
                      onPressed: (() {
                        Navigator.of(context).pop();
                        widget.logoutCallback();
                      }),
                      child: Text("确定")),
                ],
              );
            }));
      },
    );
  }

  ListTile buildAutoUpload() {
    return ListTile(
      title: Text("自动上传"),
      leading: const Icon(Icons.cloud_upload),
      onTap: () {
        Navigator.pop(context);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AutoUploadPage(),
          ),
        );
      },
    );
  }

  ListTile buildPhoto() {
    return ListTile(
      title: Text("照片"),
      leading: const Icon(Icons.image),
      onTap: () {
        Navigator.pop(context);
        showMessage("尚未支持");
      },
    );
  }

  void clearMessage() {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  void showMessage(String message) {
    clearMessage();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  Future<_DrawerModel> getDrawerModel() async {
    var state = await AppConfig.getServerStatus();
    var appName = state?.appName;
    var userName = state?.userName;
    var httpHeaders = await Api().httpHeaders();
    var userAvatar = state?.userAvatar;
    if (userAvatar != null) {
      userAvatar = await Api().getStaticFileUrl(userAvatar);
    }
    return _DrawerModel(
        userAvatar: userAvatar,
        userName: userName,
        appName: appName,
        httpHeaders: httpHeaders);
  }
}

class _DrawerModel {
  String? userAvatar;
  String? userName;
  String? appName;
  Map<String, String>? httpHeaders;

  _DrawerModel(
      {this.userAvatar, this.userName, this.appName, this.httpHeaders});
}
