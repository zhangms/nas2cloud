import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/api/dto/file_walk_request.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file_walk_response.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/components/files/file_list.dart';
import 'package:nas2cloud/components/setting/setting_page.dart';
import 'package:nas2cloud/components/uploader/pages/page_auto_upload.dart';
import 'package:nas2cloud/themes/widgets.dart';
import 'package:provider/provider.dart';

class FileHomePage extends StatefulWidget {
  @override
  State<FileHomePage> createState() => _FileHomePageState();
}

class _FileHomePageState extends State<FileHomePage> {
  static const _pageSize = 50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: FutureBuilder<FileWalkResponse>(
          future: walk(),
          builder: (context, snapshot) {
            return SafeArea(child: buildBody(snapshot));
          }),
      drawer: Drawer(
        child: SafeArea(
            child: FutureBuilder<_Drawer>(
                future: getDrawerData(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return AppWidgets.getPageLoadingView();
                  }
                  return buildDrawer(snapshot.data!);
                })),
      ),
    );
  }

  Widget buildBody(AsyncSnapshot<FileWalkResponse> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return AppWidgets.getPageLoadingView();
    }

    var response = snapshot.data!;
    if (!response.success) {
      return AppWidgets.getPageErrorView(response.message ?? "ERROR");
    }
    var files = response.data?.files ?? [];
    if (files.isEmpty) {
      return AppWidgets.getPageEmptyView();
    }
    return ListView(
      children: [
        for (int i = 0; i < files.length; i++) buildListItem(files[i])
      ],
    );
  }

  ListTile buildListItem(File item) {
    return ListTile(
      leading: buildItemIcon(item),
      title: Text(item.name),
      subtitle: Text("${item.modTime}  ${item.size}"),
      trailing: Icon(Icons.navigate_next),
      onTap: () {
        if (item.type == "DIR") {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FileListPage(item.path, item.name),
            ),
          );
        }
      },
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      leading: Builder(builder: (context) {
        return IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        );
      }),
      title: AppWidgets.getAppNameText(),
    );
  }

  Future<FileWalkResponse> walk() async {
    FileWalkRequest request = FileWalkRequest(
        path: "/", pageNo: 0, pageSize: _pageSize, orderBy: "fileName");
    return await Api().postFileWalk(request);
  }

  Widget? buildItemIcon(File item) {
    if (item.type == "DIR") {
      return Icon(Icons.folder);
    }
    return Icon(Icons.insert_drive_file);
  }

  Widget buildDrawer(_Drawer drawer) {
    var appState = context.watch<AppState>();
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
        buildLogout(appState),
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

  ListTile buildLogout(AppState appState) {
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
                        appState.logout();
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

  Future<_Drawer> getDrawerData() async {
    var state = await AppConfig.getHostState();
    var appName = state?.appName;
    var userName = state?.userName;
    var httpHeaders = await Api().httpHeaders();

    var userAvatar = state?.userAvatar;
    if (userAvatar != null) {
      userAvatar = await Api().getStaticFileUrl(userAvatar);
    }
    return _Drawer(
        userAvatar: userAvatar,
        userName: userName,
        appName: appName,
        httpHeaders: httpHeaders);
  }
}

class _Drawer {
  String? userAvatar;
  String? userName;
  String? appName;
  Map<String, String>? httpHeaders;

  _Drawer({this.userAvatar, this.userName, this.appName, this.httpHeaders});
}
