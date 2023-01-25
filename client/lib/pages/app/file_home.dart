import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_storage.dart';
import 'package:nas2cloud/api/dto/file_walk_request.dart';
import 'package:nas2cloud/api/dto/file_walk_response/data.dart' as filewk;
import 'package:nas2cloud/api/dto/file_walk_response/file.dart';
import 'package:nas2cloud/api/dto/state_response/data.dart' as state;
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/pages/app/file_list.dart';
import 'package:provider/provider.dart';

const _pageSize = 50;

class FileHomePage extends StatefulWidget {
  @override
  State<FileHomePage> createState() => _FileHomePageState();
}

class _FileHomePageState extends State<FileHomePage> {
  filewk.Data? walkData;

  @override
  void initState() {
    super.initState();
    initWalk();
  }

  @override
  Widget build(BuildContext context) {
    var hostState = AppStorage.getHostState();
    return Scaffold(
      appBar: buildAppBar(hostState),
      body: SafeArea(child: buildFileListView()),
      drawer: Drawer(
        child: SafeArea(child: buildDrawer()),
      ),
    );
  }

  Widget buildFileListView() {
    if (walkData?.files == null) {
      return ListView(
        children: [],
      );
    }
    int len = walkData!.files!.length;
    if (len == 0) {
      return Center(
        child: Text("NO DATA"),
      );
    }
    return ListView(
      children: [
        for (int i = 0; i < len; i++) buildListItem(walkData!.files![i])
      ],
    );
  }

  ListTile buildListItem(File item) {
    return ListTile(
      leading: buildItemIcon(item),
      title: Text(item.name),
      subtitle: Text("${item.modTime}  ${item.size}"),
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

  AppBar buildAppBar(state.Data? hostState) {
    return AppBar(
      leading: Builder(builder: (context) {
        return IconButton(
          icon: Icon(
            Icons.menu,
          ),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        );
      }),
      title: Text(
        hostState?.appName ?? "Nas2cloud",
      ),
    );
  }

  Future<void> initWalk() async {
    FileWalkRequest request = FileWalkRequest(
        path: "/", pageNo: 0, pageSize: _pageSize, orderBy: "fileName");
    var resp = await Api.postFileWalk(request);
    if (!resp.success || resp.data == null) {
      print("walk file error:${resp.toString()}");
      return;
    }
    setState(() {
      walkData = resp.data;
    });
  }

  Widget? buildItemIcon(File item) {
    if (item.type == "DIR") {
      return Icon(Icons.folder);
    }
    return Icon(Icons.insert_drive_file);
  }

  Widget buildDrawer() {
    var hostState = AppStorage.getHostState();
    var appState = context.watch<AppState>();

    Widget avatar = CircleAvatar(
      child: FlutterLogo(),
    );

    if (hostState?.userAvatar != null) {
      avatar = CircleAvatar(
        backgroundImage: NetworkImage(
            Api.getStaticFileUrl(hostState!.userAvatar!),
            headers: Api.httpHeaders()),
      );
    }

    return ListView(
      children: [
        UserAccountsDrawerHeader(
          accountName: Text((hostState?.userName ?? "").toUpperCase()),
          accountEmail: Text(hostState?.appName ?? ""),
          currentAccountPicture: avatar,
        ),
        ListTile(
          title: Text("照片"),
          leading: const Icon(Icons.image),
          onTap: () {
            Navigator.pop(context);
            showMessage("尚未支持");
          },
        ),
        ListTile(
          title: Text("自动上传"),
          leading: const Icon(Icons.cloud_upload),
          onTap: () {
            Navigator.pop(context);
            showMessage("尚未支持");
          },
        ),
        Divider(),
        ListTile(
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
        ),
      ],
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
}
