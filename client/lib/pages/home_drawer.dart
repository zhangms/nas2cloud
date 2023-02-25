import 'package:flutter/material.dart';
import 'package:nas2cloud/pub/image_loader.dart';

import '../api/api.dart';
import '../api/app_config.dart';
import '../components/photos/photos.dart';
import '../components/setting/setting_page.dart';
import '../components/uploader/pages/page_auto_upload.dart';
import '../components/viewer/photo_viewer.dart';
import '../event/bus.dart';
import '../event/event_logout.dart';
import '../pub/app_nav.dart';
import '../pub/widgets.dart';

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
        backgroundImage: ImageLoader.cacheNetworkImageProvider(
            drawer.userAvatar!, drawer.httpHeaders!),
      );
    }
    return ListView(
      children: [
        UserAccountsDrawerHeader(
          accountName: Text((drawer.userName ?? "").toUpperCase()),
          accountEmail: Text(drawer.appName ?? ""),
          currentAccountPicture: GestureDetector(
              onTap: () => onPressedAvatar(drawer), child: avatar),
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
        // AppMessage.show(context, "尚未支持");
        AppNav.openPage(context, TimelinePhotoGridView());
      },
    );
  }

  Future<_DrawerModel> getDrawerModel() async {
    var state = await AppConfig.getServerStatus();
    var httpHeaders = await Api().httpHeaders();
    return _DrawerModel(
        userAvatar: state?.userAvatar == null
            ? null
            : await Api().getStaticFileUrl(state!.userAvatar!),
        userAvatarLarge: state?.userAvatarLarge == null
            ? null
            : await Api().getStaticFileUrl(state!.userAvatarLarge!),
        userName: state?.userName,
        appName: state?.appName,
        httpHeaders: httpHeaders);
  }

  onPressedAvatar(_DrawerModel drawer) {
    if (drawer.userAvatarLarge != null) {
      AppNav.openPage(context,
          PhotoFullScreenViewer(drawer.userAvatarLarge!, drawer.httpHeaders));
    }
  }
}

class _DrawerModel {
  String? userAvatar;
  String? userAvatarLarge;

  String? userName;
  String? appName;
  Map<String, String>? httpHeaders;

  _DrawerModel(
      {this.userAvatar,
      this.userAvatarLarge,
      this.userName,
      this.appName,
      this.httpHeaders});
}
