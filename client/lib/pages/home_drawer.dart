import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/components/setting/setting_page.dart';
import 'package:nas2cloud/components/uploader/pages/page_auto_upload.dart';
import 'package:nas2cloud/event/bus.dart';
import 'package:nas2cloud/event/event_logout.dart';
import 'package:nas2cloud/themes/app_nav.dart';
import 'package:nas2cloud/themes/widgets.dart';

class HomeDrawer extends StatefulWidget {
  HomeDrawer();

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DrawerModel>(
        future: getDrawerModel(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return buildDrawer(snapshot.data!);
          }
          return AppWidgets.pageLoadingView();
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
      trailing: Icon(Icons.navigate_next),
      onTap: () {
        AppNav.pop(context);
        AppNav.openPage(context, SettingPage());
      },
    );
  }

  ListTile buildLogout() {
    return ListTile(
      title: Text("退出登录"),
      leading: const Icon(Icons.logout),
      onTap: () {
        AppNav.pop(context);
        showDialog(
            context: context,
            builder: ((context) {
              return AlertDialog(
                title: Text("退出登录"),
                content: Text("确认退出？"),
                actions: [
                  TextButton(
                      onPressed: (() {
                        AppNav.pop(context);
                      }),
                      child: Text("取消")),
                  TextButton(
                      onPressed: (() {
                        AppNav.pop(context);
                        eventBus.fire(EventLogout());
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
      trailing: Icon(Icons.navigate_next),
      onTap: () {
        AppNav.pop(context);
        AppNav.openPage(context, AutoUploadPage());
      },
    );
  }

  ListTile buildPhoto() {
    return ListTile(
      title: Text("照片"),
      leading: const Icon(Icons.image),
      trailing: Icon(Icons.navigate_next),
      onTap: () {
        AppNav.pop(context);
        AppWidgets.showMessage(context, "尚未支持");
      },
    );
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
